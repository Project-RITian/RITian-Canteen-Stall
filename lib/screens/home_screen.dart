import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'orders_screen.dart';
import 'menu_screen.dart';
import 'add_food_screen.dart';
import 'package:ritian_canteen_v1/screens/add_order_sheer.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _addOrder(Map<String, dynamic> order) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final random = Random();
    String pin;
    bool pinExists;
    do {
      pin = (100 + random.nextInt(900)).toString();
      pinExists =
          (await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('purchases')
                  .where('pin', isEqualTo: pin)
                  .get())
              .docs
              .isNotEmpty;
    } while (pinExists);

    order['pin'] = pin;
    order['type'] = 'canteen';
    order['timestamp'] = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('purchases')
        .add(order);
  }

  Future<void> _removeOrder(String pin) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('purchases')
            .where('pin', isEqualTo: pin)
            .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canteen App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body:
          user == null
              ? const Center(child: Text('Please sign in'))
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream:
                    FirebaseFirestore.instance.collection('foods').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print('Food fetch error: ${snapshot.error}');
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    print('No food items found');
                    // Allow navigation to AddFoodScreen even if no items
                    final screens = [
                      OrdersScreen(
                        foodItems: [],
                        onDeliver: _removeOrder,
                        onAddOrder: _addOrder,
                      ),
                      const MenuScreen(),
                      const AddFoodScreen(),
                    ];
                    return screens[_selectedIndex];
                  }

                  final foodItems =
                      snapshot.data!.docs.map((doc) {
                        final data = doc.data();
                        return {
                          'id': doc.id,
                          'name': data['name']?.toString() ?? 'Unknown',
                          'price':
                              (data['price'] is num)
                                  ? (data['price'] as num).toDouble()
                                  : 0.0,
                        };
                      }).toList();

                  final screens = [
                    OrdersScreen(
                      foodItems: foodItems,
                      onDeliver: _removeOrder,
                      onAddOrder: _addOrder,
                    ),
                    const MenuScreen(),
                    const AddFoodScreen(),
                  ];

                  return screens[_selectedIndex];
                },
              ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Add Food',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF0288D1),
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
      ),
    );
  }
}
