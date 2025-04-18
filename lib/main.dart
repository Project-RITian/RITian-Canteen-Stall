import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(CanteenApp());
}

class CanteenApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canteen App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _orders = [];
  final String _foodItemsJson = '''
  [
    {"id": 1, "name": "Burger", "price": 5.0},
    {"id": 2, "name": "Pizza", "price": 8.0},
    {"id": 3, "name": "Sandwich", "price": 4.0},
    {"id": 4, "name": "Fries", "price": 2.5}
  ]
  ''';

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addOrder(Map<String, dynamic> order) {
    setState(() {
      final random = Random();
      String pin;
      do {
        pin = (100 + random.nextInt(900)).toString();
      } while (_orders.any((o) => o['pin'] == pin));
      order['pin'] = pin;
      _orders.add(order);
    });
  }

  void _removeOrder(String pin) {
    setState(() {
      _orders.removeWhere((order) => order['pin'] == pin);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      OrdersScreen(
        orders: _orders,
        foodItems: jsonDecode(_foodItemsJson),
        onDeliver: _removeOrder,
        onAddOrder: _addOrder,
      ),
      MenuScreen(orders: _orders, foodItems: jsonDecode(_foodItemsJson)),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class OrdersScreen extends StatefulWidget {
  final List<Map<String, dynamic>> orders;
  final List<dynamic> foodItems;
  final Function(String) onDeliver;
  final Function(Map<String, dynamic>) onAddOrder;

  OrdersScreen({
    required this.orders,
    required this.foodItems,
    required this.onDeliver,
    required this.onAddOrder,
  });

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _enteredPin = '';
  Map<String, dynamic>? _selectedOrder;

  void _onNumpadPress(String value) {
    setState(() {
      if (value == 'C') {
        _enteredPin = '';
        _selectedOrder = null;
      } else if (value == '<') {
        if (_enteredPin.isNotEmpty) {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        }
      } else if (_enteredPin.length < 3) {
        _enteredPin += value;
        if (_enteredPin.length == 3) {
          _selectedOrder = widget.orders.firstWhere(
            (order) => order['pin'] == _enteredPin,
            orElse: () => {},
          );
          if (_selectedOrder!.isEmpty) {
            _selectedOrder = null;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Invalid PIN')));
            _enteredPin = '';
          }
        }
      }
    });
  }

  void _deliverOrder() {
    if (_selectedOrder != null) {
      widget.onDeliver(_selectedOrder!['pin']);
      setState(() {
        _enteredPin = '';
        _selectedOrder = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Order delivered!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: widget.orders.length,
            itemBuilder: (context, index) {
              final order = widget.orders[index];
              return ListTile(
                title: Text('Order #${order['pin']}'),
                subtitle: Text(
                  order['items']
                      .map((item) => '${item['name']} x${item['quantity']}')
                      .join(', '),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Enter 3-Digit PIN',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: _enteredPin),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder:
                      (context) => AddOrderSheet(
                        foodItems: widget.foodItems,
                        onAddOrder: widget.onAddOrder,
                      ),
                );
              },
              child: Text(
                'Add Order',
                style: TextStyle(fontSize: 14.0, color: Colors.blue),
              ),
            ),
          ),
        ),
        CustomNumpad(onPress: _onNumpadPress),
        if (_selectedOrder != null) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Selected Order: ${_selectedOrder!['items'].map((item) => '${item['name']} x${item['quantity']}').join(', ')}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _deliverOrder,
              child: Text('Deliver Order'),
            ),
          ),
        ],
      ],
    );
  }
}

class CustomNumpad extends StatelessWidget {
  final Function(String) onPress;

  CustomNumpad({required this.onPress});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      padding: EdgeInsets.all(8.0),
      children: [
        for (var i = 1; i <= 9; i++) NumpadButton(text: '$i', onPress: onPress),
        NumpadButton(text: 'C', onPress: onPress),
        NumpadButton(text: '0', onPress: onPress),
        NumpadButton(text: '<', onPress: onPress),
      ],
    );
  }
}

class NumpadButton extends StatelessWidget {
  final String text;
  final Function(String) onPress;

  NumpadButton({required this.text, required this.onPress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        onPressed: () => onPress(text),
        child: Text(text, style: TextStyle(fontSize: 20)),
      ),
    );
  }
}

class MenuScreen extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final List<dynamic> foodItems;

  MenuScreen({required this.orders, required this.foodItems});

  @override
  Widget build(BuildContext context) {
    // Calculate total quantities for each food item
    Map<int, int> totalQuantities = {};
    for (var item in foodItems) {
      totalQuantities[item['id']] = 0;
    }
    for (var order in orders) {
      for (var item in order['items']) {
        final itemId = item['id'] as int;
        final quantity = item['quantity'] as int;
        totalQuantities[itemId] = (totalQuantities[itemId] ?? 0) + quantity;
      }
    }

    return ListView.builder(
      itemCount: foodItems.length,
      itemBuilder: (context, index) {
        final item = foodItems[index];
        final totalQuantity = totalQuantities[item['id']] ?? 0;
        return ListTile(
          title: Text(item['name']),
          subtitle: Text('\$${item['price'].toStringAsFixed(2)}'),
          trailing: Text('To Cook: $totalQuantity'),
        );
      },
    );
  }
}

class AddOrderSheet extends StatefulWidget {
  final List<dynamic> foodItems;
  final Function(Map<String, dynamic>) onAddOrder;

  AddOrderSheet({required this.foodItems, required this.onAddOrder});

  @override
  _AddOrderSheetState createState() => _AddOrderSheetState();
}

class _AddOrderSheetState extends State<AddOrderSheet> {
  Map<int, int> _selectedItems = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add New Order',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ...widget.foodItems.map((item) {
            final itemId = item['id'];
            final quantity = _selectedItems[itemId] ?? 0;
            return ListTile(
              title: Text(item['name']),
              subtitle: Text('\$${item['price'].toStringAsFixed(2)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        if (quantity > 0) _selectedItems[itemId] = quantity - 1;
                        if (_selectedItems[itemId] == 0)
                          _selectedItems.remove(itemId);
                      });
                    },
                  ),
                  Text('$quantity'),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        _selectedItems[itemId] = quantity + 1;
                      });
                    },
                  ),
                ],
              ),
            );
          }).toList(),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_selectedItems.isNotEmpty) {
                final orderItems =
                    _selectedItems.entries.map((entry) {
                      final item = widget.foodItems.firstWhere(
                        (i) => i['id'] == entry.key,
                      );
                      return {
                        'id': entry.key,
                        'name': item['name'],
                        'quantity': entry.value,
                      };
                    }).toList();
                widget.onAddOrder({'items': orderItems});
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please select at least one item')),
                );
              }
            },
            child: Text('Add Order'),
          ),
        ],
      ),
    );
  }
}
