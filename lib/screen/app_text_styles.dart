// untils/app_text_styles.dart
import 'package:flutter/material.dart';

class AppTextStyles {
  static TextStyle heading(BuildContext context) {
    return TextStyle(
      fontSize: MediaQuery.of(context).size.width * 0.05,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle body(BuildContext context) {
    return TextStyle(
      fontSize: MediaQuery.of(context).size.width * 0.045,
      fontWeight: FontWeight.normal,
    );
  }
}
