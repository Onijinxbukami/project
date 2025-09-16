import 'package:flutter/material.dart';

class NumericField extends StatefulWidget {
  const NumericField({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NumericFieldState createState() => _NumericFieldState();
}

class _NumericFieldState extends State<NumericField> {
  final TextEditingController _numericController = TextEditingController();
  String? _numericError;

  // Function to validate numeric input
  void _validateNumeric() {
    final input = _numericController.text;

    // Check if the input contains only numbers (no letters or special characters)
    if (input.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(input)) {
      setState(() {
        _numericError = "Only numbers are allowed!";
      });
    } else {
      setState(() {
        _numericError = null; // Clear error if the input is valid
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Numeric input field
        TextField(
          controller: _numericController,
          keyboardType: TextInputType.number,
          onChanged: (value) => _validateNumeric(), // Validate input on change
          decoration: InputDecoration(
            hintText: "Enter a number",
            errorText: _numericError,
            border: InputBorder.none,
          ),
        ),
      ],
    );
  }
}
