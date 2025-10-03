import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class CButton extends StatelessWidget {
  final String text;
  final void Function()? onPressed;

  const CButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final res = ResponsiveHelper(context); // Initialize responsive helper

    return SizedBox(
      width: res.width(100), // 100% of screen width
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          padding: EdgeInsets.symmetric(vertical: res.height(2)), // 2% of screen height
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(res.width(3)), // 3% of screen width
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: const Color.fromARGB(255, 240, 237, 237),
            fontSize: res.fontSize(4.5), // 4.5% of screen width
          ),
        ),
      ),
    );
  }
}
