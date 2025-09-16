import 'package:flutter/material.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: lightColor,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo bên trái
            Image.asset(
              'assets/logo.png', // Đường dẫn logo
              height: 40, // Điều chỉnh kích thước logo
            ),
            // Nút Login với hình chữ nhật và chữ ở giữa
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white, // Màu nền của nút
                  borderRadius:
                      const BorderRadius.all(Radius.circular(8)), // Bo góc
                  border: Border.all(color: Colors.blue), // Viền của nút
                ),
                child: TextButton(
                  onPressed: () {
                    // Điều hướng tới trang login
                  },
                  child: const Text(
                    "Login",
                    style: linkTextStyle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: const Center(child: Text("Signup Page")),
    );
  }
}

// Colors
const Color primaryColor = Colors.blue;
const Color secondaryColor = Colors.grey;
const Color lightColor = Colors.white;

// Text Styles
const TextStyle headingStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: Colors.black,
);

const TextStyle titileheadingStyle =
    TextStyle(fontSize: 30, color: Color(0xFF0C266C), height: 0.8);

const TextStyle labelStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w500,
  color: Color(0xFF0C266C),
  letterSpacing: 0.5,
  height: 1.4,
);

const InputDecoration inputFieldDecoration = InputDecoration(
  border: OutlineInputBorder(
    borderSide: BorderSide(
      color: Color(0xFFB0BEC5), // A lighter color for the border
      width: 1.0, // Set border width (you can adjust it)
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(
      color: Color(0xFFB0BEC5), // A lighter color for focused border
      width: 1.5, // You can make it a bit thicker when focused
    ),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(
      color: Color(0xFFB0BEC5), // Lighter color for enabled state
      width: 1.0, // Set the width to 1.0 for a more subtle effect
    ),
  ),
);

const TextStyle buttonTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: lightColor,
);

const TextStyle linkTextStyle = TextStyle(
  fontSize: 16,
  color: primaryColor,
  fontWeight: FontWeight.bold,
);

// Input Decoration

// Padding & Margins
const double horizontalPadding = 24.0;
const double verticalSpacing = 20.0;
const double inputSpacing = 8.0;
