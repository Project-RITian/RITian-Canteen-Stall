import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({Key? key}) : super(key: key);

  // Function to toggle stock status
  Future<void> _toggleStockStatus(String itemId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('foods').doc(itemId).update({
        'isInStock': !currentStatus,
      });
    } catch (e) {
      print('Error toggling stock status: $e');
    }
  }

  // Function to delete food item
  Future<void> _deleteFoodItem(String itemId) async {
    try {
      await FirebaseFirestore.instance.collection('foods').doc(itemId).delete();
    } catch (e) {
      print('Error deleting food item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in'));
    }

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Menu',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  FirebaseFirestore.instance.collection('foods').snapshots(),
              builder: (context, foodSnapshot) {
                if (foodSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (foodSnapshot.hasError) {
                  print('Food fetch error: ${foodSnapshot.error}');
                  return Center(child: Text('Error: ${foodSnapshot.error}'));
                }
                if (!foodSnapshot.hasData || foodSnapshot.data!.docs.isEmpty) {
                  print('No food items found');
                  return const Center(child: Text('No food items available'));
                }

                // Debug: Print raw Firestore data
                print('Raw food items:');
                for (var doc in foodSnapshot.data!.docs) {
                  print('Doc ID: ${doc.id}, Data: ${doc.data()}');
                }

                final foodItems =
                    foodSnapshot.data!.docs.map((doc) {
                      final data = doc.data();
                      return {
                        'id': doc.id,
                        'name': data['name']?.toString() ?? 'Unknown',
                        'price':
                            (data['price'] is num)
                                ? (data['price'] as num).toDouble()
                                : 0.0,
                        'imageUrl': data['imageUrl']?.toString(),
                        'isInStock': data['isInStock'] as bool? ?? true,
                      };
                    }).toList();

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('purchases')
                          .where('type', isEqualTo: 'canteen')
                          .snapshots(),
                  builder: (context, purchaseSnapshot) {
                    final Map<String, int> totalQuantities = {};
                    for (var item in foodItems) {
                      totalQuantities[item['id'] as String] = 0;
                    }

                    if (purchaseSnapshot.hasData) {
                      final orders =
                          purchaseSnapshot.data!.docs
                              .map((doc) => doc.data())
                              .toList();
                      for (var order in orders) {
                        final items = order['items'] as List<dynamic>? ?? [];
                        for (var item in items) {
                          final itemId = item['id']?.toString();
                          final quantity =
                              (item['quantity'] is num)
                                  ? (item['quantity'] as num).toInt()
                                  : 0;
                          if (itemId != null &&
                              totalQuantities.containsKey(itemId)) {
                            totalQuantities[itemId] =
                                totalQuantities[itemId]! + quantity;
                          }
                        }
                      }
                    } else if (purchaseSnapshot.hasError) {
                      print('Purchase fetch error: ${purchaseSnapshot.error}');
                    }

                    return ListView.builder(
                      itemCount: foodItems.length,
                      itemBuilder: (context, index) {
                        final item = foodItems[index];
                        final totalQuantity =
                            totalQuantities[item['id'] as String] ?? 0;
                        final isInStock = item['isInStock'] as bool;

                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              item['name'] as String,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${(item['price'] as double).toStringAsFixed(2)} RITZ',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed:
                                          () => _toggleStockStatus(
                                            item['id'] as String,
                                            isInStock,
                                          ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            isInStock
                                                ? Colors.red[400]
                                                : Colors.green[400],
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                        isInStock ? 'Out of Stock' : 'In Stock',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed:
                                          () => _deleteFoodItem(
                                            item['id'] as String,
                                          ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[400],
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                        'Remove',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Text(
                              'To Cook: $totalQuantity',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0288D1),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
