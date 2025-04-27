import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ritian_canteen_v1/screens/add_order_sheer.dart';
import '../widgets/custom_numpad.dart';

class OrdersScreen extends StatefulWidget {
  final List<Map<String, dynamic>> foodItems;
  final Function(String) onDeliver;
  final Function(Map<String, dynamic>) onAddOrder;

  const OrdersScreen({
    Key? key,
    required this.foodItems,
    required this.onDeliver,
    required this.onAddOrder,
  }) : super(key: key);

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _enteredPin = '';
  Map<String, dynamic>? _selectedOrder;
  DocumentReference? _selectedOrderRef;

  void _onNumpadPress(String value) async {
    setState(() {
      if (value == 'C') {
        _enteredPin = '';
        _selectedOrder = null;
        _selectedOrderRef = null;
      } else if (value == '<') {
        if (_enteredPin.isNotEmpty) {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        }
      } else if (_enteredPin.length < 3) {
        _enteredPin += value;
        if (_enteredPin.length == 3) {
          _checkPin();
        }
      }
    });
  }

  Future<void> _checkPin() async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collectionGroup('purchases')
            .where('pin', isEqualTo: _enteredPin)
            .where('type', isEqualTo: 'canteen')
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _selectedOrder = querySnapshot.docs.first.data();
        _selectedOrderRef = querySnapshot.docs.first.reference;
        _selectedOrder!['isTakeAway'] ??= false;
      });
      _showOrderDialog();
    } else {
      setState(() {
        _selectedOrder = null;
        _selectedOrderRef = null;
        _enteredPin = '';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid PIN')));
    }
  }

  Future<void> _deleteOrder() async {
    if (_selectedOrder != null && _selectedOrderRef != null) {
      try {
        await _selectedOrderRef!.delete();
        widget.onDeliver(_selectedOrder!['pin']);
        setState(() {
          _enteredPin = '';
          _selectedOrder = null;
          _selectedOrderRef = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order delivered and deleted!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting order: $e')));
      }
    }
  }

  void _showOrderDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Selected Order',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (_selectedOrder!['items'] as List<dynamic>)
                        .map((item) => '${item['name']} x${item['quantity']}')
                        .join(', '),
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take Away: ${_selectedOrder!['isTakeAway'] ? 'Yes' : 'No'}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Cost: ${_selectedOrder!['totalCost'].toStringAsFixed(2)} RITZ',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _enteredPin = '';
                    _selectedOrder = null;
                    _selectedOrderRef = null;
                  });
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteOrder();
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Deliver Order',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in'));
    }

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Enter Order PIN',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Enter 3-Digit PIN',
                          labelStyle: GoogleFonts.poppins(fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 16.0,
                          ),
                        ),
                        controller: TextEditingController(text: _enteredPin),
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder:
                                  (context) => AddOrderSheet(
                                    onAddOrder: widget.onAddOrder,
                                  ),
                            );
                          },
                          child: Text(
                            'Add Order',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFF0288D1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                child: CustomNumpad(onPress: _onNumpadPress),
              ),
            ],
          );
        },
      ),
    );
  }
}
