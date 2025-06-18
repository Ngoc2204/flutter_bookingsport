// lib/screens/review/review_form_screen.dart
import 'dart:io'; // Cho File
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // Cho XFile và ImageSource
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../providers/review_providers.dart';
import '../../providers/core_providers.dart'; // Cho imageServiceProvider
// import '../../core/utils/validators.dart'; // Bỏ nếu không dùng
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_indicator.dart';
// import '../../widgets/common/image_picker_input.dart'; // Bỏ nếu không dùng

// Argument class
class ReviewFormScreenArgs {
  final String bookingId;
  final String fieldId;
  final String fieldName;

  const ReviewFormScreenArgs({
    required this.bookingId,
    required this.fieldId,
    required this.fieldName,
  });
}

class ReviewFormScreen extends ConsumerStatefulWidget {
  final ReviewFormScreenArgs args;

  const ReviewFormScreen({super.key, required this.args});

  @override
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 3.0;
  final List<File> _selectedImages = []; // <<<< Vẫn là List<File>, khai báo final
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final imageService = ref.read(imageServiceProvider);
    // ImageService.pickMultiXFiles trả về List<XFile>
    final List<XFile> pickedXFiles = await imageService.pickMultiXFiles(imageQuality: 60);

    if (pickedXFiles.isNotEmpty) {
      // Chuyển đổi List<XFile> sang List<File> để lưu vào _selectedImages
      final List<File> pickedFiles = pickedXFiles.map((xfile) => File(xfile.path)).toList();

      if ((_selectedImages.length + pickedFiles.length) > 5) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn chỉ có thể chọn tối đa 5 ảnh.')));
        return;
      }
      setState(() {
        _selectedImages.addAll(pickedFiles);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    FocusScope.of(context).unfocus();
    if (_rating == 0.0) {
      setState(() => _errorMessage = "Vui lòng chọn số sao đánh giá.");
      return;
    }

    // if (_formKey.currentState!.validate()) { // Bỏ comment nếu có validator cho comment
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reviewService = ref.read(reviewServiceProvider);
      await reviewService.createReview(
        fieldId: widget.args.fieldId,
        bookingId: widget.args.bookingId,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        // Chuyển List<File> thành List<XFile> khi gọi service
        imageXFiles: _selectedImages.map((file) => XFile(file.path)).toList(), // <<<< SỬA Ở ĐÂY
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cảm ơn bạn đã gửi đánh giá!')),
        );
        int popCount = 0;
        Navigator.of(context).popUntil((route) {
          popCount++;
          return popCount == 2 || route.isFirst;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    // } // Đóng if của validate
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đánh giá sân ${widget.args.fieldName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Chia sẻ trải nghiệm của bạn', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Center(
                child: RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating;
                      if (_rating > 0 && _errorMessage != null && _errorMessage!.contains("Vui lòng chọn số sao")) {
                        _errorMessage = null;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Bình luận của bạn (tùy chọn)',
                  hintText: 'Sân rất tốt, dịch vụ tuyệt vời...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 20),
              Text('Hình ảnh kèm theo (tùy chọn, tối đa 5 ảnh):', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              _buildImagePickerSection(),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14), textAlign: TextAlign.center),
                ),
              _isLoading
                  ? const Center(child: LoadingIndicator())
                  : CustomButton(onPressed: _submitReview, text: 'Gửi đánh giá'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            ..._selectedImages.asMap().entries.map((entry) {
              int idx = entry.key;
              File image = entry.value; // _selectedImages là List<File>
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(image, width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: InkWell(
                      onTap: () => _removeImage(idx),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha((255 * 0.8).round()), // Đã sửa deprecated
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            }), // Bỏ .toList() ở đây nếu dùng Dart 2.3+ (spread operator hoạt động với Iterable)
            if (_selectedImages.length < 5)
              InkWell(
                onTap: _pickImages,
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