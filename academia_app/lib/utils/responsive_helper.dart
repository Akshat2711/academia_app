import 'package:flutter/material.dart';

class ResponsiveHelper {
  final BuildContext context;
  late double screenWidth;
  late double screenHeight;

  ResponsiveHelper(this.context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
  }

  // Font size based on screen width
  double fontSize(double percentage) {
    return screenWidth * (percentage / 100);
  }

  // Spacing based on screen height
  double height(double percentage) {
    return screenHeight * (percentage / 100);
  }

  // Padding based on screen width
  double width(double percentage) {
    return screenWidth * (percentage / 100);
  }
}
