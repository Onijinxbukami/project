import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/constants.dart';
import 'package:flutter_application_1/features/auth/signUp/signup_service.dart';

class EmailField extends StatefulWidget {
  final TextEditingController
      emailController; // Controller được truyền từ ngoài
  final String hintText; // Placeholder cho TextField
  final ValidationService? validationService; // Dịch vụ kiểm tra email tùy chọn

  const EmailField({
    super.key,
    required this.emailController,
    this.hintText = "Enter Your Email", // Giá trị mặc định
    this.validationService,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EmailFieldState createState() => _EmailFieldState();
}

class _EmailFieldState extends State<EmailField> {
  String? _emailError;

  void _validateEmail() {
    // Sử dụng validation service nếu được cung cấp
    final validationService = widget.validationService ?? ValidationService();
    final email = widget.emailController.text;
    setState(() {
      _emailError = validationService.validateEmail(email);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) => _validateEmail(),
          decoration: inputFieldDecoration.copyWith(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), // Bo góc nhiều hơn
              borderSide: BorderSide(color: Colors.grey), // Màu viền mặc định
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), // Bo góc khi focus
              borderSide: BorderSide(
                  color: Colors.blue, width: 2), // Màu viền khi focus
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), // Bo góc khi chưa focus
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            hintText: widget.hintText,
            errorText: _emailError,
          ),
        )
      ],
    );
  }
}
