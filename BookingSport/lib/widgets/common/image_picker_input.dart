// lib/widgets/common/image_picker_input.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // <<<< GIỮ LẠI NẾU ImageService.pickMultiXFiles trả về XFile và bạn cần kiểu XFile ở đây
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/core_providers.dart'; // Đảm bảo đường dẫn này đúng

class ImagePickerInput extends ConsumerWidget {
  final String label;
  final List<File> currentImages; // Widget này vẫn làm việc với List<File>
  final Function(List<File>) onImagesSelected;
  final Function(int) onImageRemoved;
  final int maxImages;

  const ImagePickerInput({
    super.key,
    required this.label,
    required this.currentImages,
    required this.onImagesSelected,
    required this.onImageRemoved,
    this.maxImages = 5,
  });

  Future<void> _pickImages(WidgetRef ref, BuildContext context) async { // Thêm BuildContext để dùng mounted và ScaffoldMessenger
    final imageService = ref.read(imageServiceProvider);
    // ImageService.pickMultiXFiles trả về List<XFile>
    final List<XFile> pickedXFiles = await imageService.pickMultiXFiles(imageQuality: 60);

    if (pickedXFiles.isNotEmpty) {
      // Chuyển đổi List<XFile> sang List<File> để callback
      final List<File> pickedFiles = pickedXFiles.map((xfile) => File(xfile.path)).toList();

      if ((currentImages.length + pickedFiles.length) > maxImages) {
        if (context.mounted) { // Kiểm tra mounted trước khi dùng context
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Bạn chỉ có thể chọn tối đa $maxImages ảnh.'))
          );
        }
        return;
      }
      onImagesSelected(pickedFiles); // Gọi callback với List<File>
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            ...currentImages.asMap().entries.map((entry) { // Bỏ .toList()
              int idx = entry.key;
              File image = entry.value;
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      image,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: InkWell(
                      onTap: () => onImageRemoved(idx),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha((255 * 0.8).round()), // Sửa deprecated
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            }), // Không có .toList()
            if (currentImages.length < maxImages)
              InkWell(
                onTap: () => _pickImages(ref, context), // Truyền context
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid, width: 1)),
                  child: Icon(Icons.add_a_photo_outlined, color: Colors.grey[600], size: 30),
                ),
              ),
          ],
        ),
      ],
    );
  }
}