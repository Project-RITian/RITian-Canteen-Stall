import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomNumpad extends StatelessWidget {
  final Function(String) onPress;

  const CustomNumpad({Key? key, required this.onPress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      padding: EdgeInsets.all(16.0),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
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

  const NumpadButton({Key? key, required this.text, required this.onPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onPress(text),
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(20),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 2,
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
      ),
    );
  }
}