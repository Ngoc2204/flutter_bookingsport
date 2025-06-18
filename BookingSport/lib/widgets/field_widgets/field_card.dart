// lib/widgets/field_widgets/field_card.dart
import 'package:flutter/material.dart';
import 'package:test123/models/field_model.dart'; // Thay your_app_name
import 'package:test123/screens/field/field_detail_screen.dart'; // Thay your_app_name
import 'package:intl/intl.dart';
class FieldCard extends StatelessWidget {
  final FieldModel field;
  const FieldCard({super.key, required this.field});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell( // Đảm bảo có InkWell hoặc GestureDetector
        borderRadius: BorderRadius.circular(12.0), // Cho hiệu ứng ripple đẹp
        onTap: () { // <<<< QUAN TRỌNG: Xử lý onTap ở đây
          debugPrint("FieldCard tapped for field: ${field.name} (ID: ${field.id})"); // Kiểm tra xem onTap có được gọi không
          if (field.id.isNotEmpty) { // Kiểm tra field.id có giá trị
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FieldDetailScreen(fieldId: field.id), // Truyền fieldId
              ),
            );
          } else {
            debugPrint("Field ID is empty, cannot navigate.");
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Không thể xem chi tiết sân do thiếu thông tin ID.'))
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (field.imageUrls.isNotEmpty)
              ClipRRect( // Bo góc cho ảnh
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                child: Image.network(
                  field.imageUrls.first,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container( // Placeholder nếu không có ảnh
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                ),
                child: Icon(Icons.sports_soccer, size: 60, color: Colors.grey[400]),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(field.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis,),
                  const SizedBox(height: 4),
                  Text(field.address, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${NumberFormat("#,##0", "vi_VN").format(field.pricePerHour)} đ/giờ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            fontSize: 15),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(field.averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 14)),
                          Text(' (${field.totalReviews})', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}