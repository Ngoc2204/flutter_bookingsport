// lib/widgets/common/empty_list_placeholder.dart
import 'package:flutter/material.dart';

class EmptyListPlaceholder extends StatelessWidget {
  final String message;
  final IconData iconData;

  const EmptyListPlaceholder({
    super.key,
    required this.message,
    this.iconData = Icons.inbox_outlined, // Icon mặc định
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}