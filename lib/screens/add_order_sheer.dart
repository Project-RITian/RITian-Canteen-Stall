import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AddOrderSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddOrder;

  const AddOrderSheet({Key? key, required this.onAddOrder}) : super(key: key);

  @override
  _AddOrderSheetState createState() => _AddOrderSheetState();
}

class _AddOrderSheetState extends State<AddOrderSheet> {
  final Map<String, int> _quantities = {};
  bool _isTakeAway = false;
  List<Map<String, dynamic>> _foodItems = [];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in'));
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Text(
                'Add Order',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('foods')
                          .snapshots(),
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
                      return const Center(
                        child: Text('No food items available'),
                      );
                    }

                    // Update state with food items
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

                    // Update state to make foodItems accessible in onPressed
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _foodItems = foodItems;
                        });
                      }
                    });

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: foodItems.length,
                      itemBuilder: (context, index) {
                        final item = foodItems[index];
                        final itemId = item['id'] as String;
                        _quantities[itemId] ??= 0;

                        return ListTile(
                          title: Text(
                            item['name'] as String,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${(item['price'] as double).toStringAsFixed(2)} RITZ',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  setState(() {
                                    if (_quantities[itemId]! > 0) {
                                      _quantities[itemId] =
                                          _quantities[itemId]! - 1;
                                    }
                                  });
                                },
                              ),
                              Text(
                                _quantities[itemId].toString(),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    _quantities[itemId] =
                                        _quantities[itemId]! + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              CheckboxListTile(
                title: Text(
                  'Take Away',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                value: _isTakeAway,
                onChanged: (value) {
                  setState(() {
                    _isTakeAway = value ?? false;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  final selectedItems =
                      _quantities.entries.where((entry) => entry.value > 0).map(
                        (entry) {
                          // Find item in _foodItems (state)
                          final item = _foodItems.firstWhere(
                            (i) => i['id'] == entry.key,
                            orElse:
                                () => {
                                  'id': entry.key,
                                  'name': 'Unknown',
                                  'price': 0.0,
                                },
                          );
                          return {
                            'id': entry.key,
                            'name': item['name'],
                            'quantity': entry.value,
                            'price': item['price'],
                          };
                        },
                      ).toList();

                  if (selectedItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select at least one item'),
                      ),
                    );
                    return;
                  }

                  final order = {
                    'items': selectedItems,
                    'isTakeAway': _isTakeAway,
                    'type': 'canteen',
                    'timestamp': FieldValue.serverTimestamp(),
                    'totalCost': selectedItems.fold<double>(
                      0.0,
                      (sum, item) =>
                          sum +
                          (item['price'] as double) * (item['quantity'] as int),
                    ),
                  };

                  try {
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

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('purchases')
                        .add(order);

                    widget.onAddOrder(order);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order added successfully!'),
                      ),
                    );
                  } catch (e) {
                    print('Error adding order: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding order: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Add Order',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
