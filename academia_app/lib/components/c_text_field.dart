import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class CTextField extends StatelessWidget {
  final String hintTxt;
  final bool ispass;
  final TextEditingController? controller; // Add controller

  const CTextField({
    super.key,
    required this.hintTxt,
    required this.ispass,
    this.controller, // optional
  });

  @override
  Widget build(BuildContext context) {
    final res = ResponsiveHelper(context); // Initialize responsive helper

    return TextField(
      controller: controller, // attach controller
      obscureText: ispass,
      decoration: InputDecoration(
        hintText: hintTxt,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: res.fontSize(4), // 4% of screen width
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.inversePrimary),
        ),
      ),
    );
  }
}
