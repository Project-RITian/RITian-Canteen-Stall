import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({Key? key}) : super(key: key);

  @override
  _AddFoodScreenState createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  File? _selectedImage;
  String? _selectedCategory;
  bool _isUploading = false;

  final List<String> _categories = [
    'Chinese',
    'Beverages',
    'Snacks',
    'South Indian',
  ];

  @override
  void initState() {
    super.initState();
    // Debug: Confirm categories are initialized
    print('Categories initialized: $_categories');
  }

  Future<void> _pickImage() async {
    try {
      print('Attempting to pick image...');
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        print('Image picked: ${pickedFile.path}');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No image selected')));
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _addFoodItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a cover image')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload image to Firebase Storage
      print('Uploading image to Firebase Storage...');
      final storageRef = FirebaseStorage.instance.ref().child(
        'food_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final uploadTask = await storageRef.putFile(_selectedImage!);
      final imageUrl = await uploadTask.ref.getDownloadURL();
      print('Image uploaded, URL: $imageUrl');

      // Add food item to Firestore
      print('Adding food item to Firestore...');
      final foodData = {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'imageUrl': imageUrl,
        'category': _selectedCategory,
        'createdAt': FieldValue.serverTimestamp(),
      };
      print('Food data: $foodData');
      await FirebaseFirestore.instance.collection('foods').add(foodData);
      print('Food item added to Firestore');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food item added successfully!')),
      );

      // Clear form
      _nameController.clear();
      _priceController.clear();
      setState(() {
        _selectedImage = null;
        _selectedCategory = null;
        _isUploading = false;
      });
    } catch (e) {
      print('Error adding food item: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding food item: $e')));
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in'));
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Add New Food',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Food Name',
                    labelStyle: GoogleFonts.poppins(fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a food name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Price (RITZ)',
                    labelStyle: GoogleFonts.poppins(fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: GoogleFonts.poppins(fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
                  hint: Text(
                    'Select a category',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  dropdownColor: Colors.white,
                  items:
                      _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    print('Selected category: $value');
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        _selectedImage != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                            : Center(
                              child: Text(
                                'Tap to select cover image',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isUploading ? null : _addFoodItem,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            'Add Food Item',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
