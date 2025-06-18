// lib/widgets/common/custom_button.dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.color,
    this.textColor,
    this.width,
    this.height = 48.0, // Chiều cao mặc định
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity, // Mặc định full width
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).primaryColor,
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: Text(text),
      ),
    );
  }
}