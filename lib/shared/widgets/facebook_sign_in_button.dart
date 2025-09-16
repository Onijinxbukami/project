import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FacebookSignInButton extends StatelessWidget {
  final Future<void> Function()? onPressed;

  const FacebookSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed == null
          ? null
          : () {
              onPressed!(); // Gọi hàm truyền vào
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // Màu nền nhẹ hơn
        elevation: 1, // Giảm độ nổi
        padding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: 24), // Kích thước rộng rãi hơn
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Bo góc mềm mại
          side: const BorderSide(color: Colors.black), // Viền màu nhẹ
        ),
      ),
      icon: const FaIcon(
        FontAwesomeIcons.facebook,
        color: Colors.blue, // Màu xanh đặc trưng của Facebook
        size: 25, // Tăng kích thước icon
      ),
      label: const Text(
        "Facebook sign in",
        style: TextStyle(
          fontSize: 18, // Tăng kích thước chữ
          fontWeight: FontWeight.w600, // Font đậm hơn chút
          color: Colors.black, // Màu chữ dễ nhìn
        ),
      ),
    );
  }
}
