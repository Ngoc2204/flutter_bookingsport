// lib/services/image_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

class ImageUploadException implements Exception {
  final String message;
  ImageUploadException(this.message);
  @override
  String toString() => "ImageUploadException: $message";
}

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Giới hạn kích thước ảnh (5MB)
  static const int maxFileSizeInBytes = 5 * 1024 * 1024;

  // Chọn một ảnh, trả về XFile?
  Future<XFile?> pickSingleXFile({ImageSource source = ImageSource.gallery, int imageQuality = 70}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: imageQuality);
      return pickedFile;
    } catch (e) {
      debugPrint("ImageService: Error picking single image: $e");
      return null;
    }
  }

  // Chọn nhiều ảnh, trả về List<XFile>
  Future<List<XFile>> pickMultiXFiles({int imageQuality = 70}) async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage(imageQuality: imageQuality);
      return pickedFiles ?? [];
    } catch (e) {
      debugPrint("ImageService: Error picking multiple images: $e");
      return [];
    }
  }

  // Resize ảnh tạo thumbnail, trả về Uint8List hoặc null nếu lỗi
  Uint8List? _resizeImageToThumbnail(Uint8List imageData, {int maxWidth = 200, int maxHeight = 200}) {
    try {
      img.Image? originalImage = img.decodeImage(imageData);
      if (originalImage == null) return null;
      img.Image thumbnail = img.copyResize(originalImage, width: maxWidth, height: maxHeight);
      return Uint8List.fromList(img.encodeJpg(thumbnail));
    } catch (e) {
      debugPrint("ImageService: Error resizing image for thumbnail: $e");
      return null;
    }
  }

  // Upload file, có kiểm tra kích thước file, có thể upload thumbnail
  Future<String?> _uploadFile(File file, String storagePath, {bool uploadThumbnail = false}) async {
    try {
      if (!await file.exists()) {
        throw ImageUploadException("File không tồn tại");
      }

      // Kiểm tra kích thước file
      final int fileSize = await file.length();
      if (fileSize > maxFileSizeInBytes) {
        throw ImageUploadException("Kích thước file vượt quá giới hạn $maxFileSizeInBytes bytes");
      }

      final Reference ref = _storage.ref(storagePath);

      String fileExtension = p.extension(file.path).isNotEmpty
          ? p.extension(file.path).substring(1).toLowerCase()
          : 'jpg';

      String contentType = 'image/jpeg';
      if (fileExtension == 'png') contentType = 'image/png';
      else if (fileExtension == 'gif') contentType = 'image/gif';
      else if (fileExtension == 'webp') contentType = 'image/webp';

      UploadTask uploadTask;
      if (uploadThumbnail) {
        Uint8List fileBytes = await file.readAsBytes();
        Uint8List? thumbnailBytes = _resizeImageToThumbnail(fileBytes);
        if (thumbnailBytes == null) {
          throw ImageUploadException("Lỗi tạo thumbnail");
        }
        uploadTask = ref.putData(
          thumbnailBytes,
          SettableMetadata(contentType: contentType),
        );
      } else {
        uploadTask = ref.putFile(
          file,
          SettableMetadata(contentType: contentType),
        );
      }

      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint("ImageService: Firebase error uploading file to $storagePath: ${e.code} - ${e.message}");
      return null;
    } on ImageUploadException catch (e) {
      debugPrint(e.toString());
      return null;
    } catch (e) {
      debugPrint("ImageService: Generic error uploading file to $storagePath: $e");
      return null;
    }
  }

  // Upload avatar user từ XFile
  Future<String?> uploadProfileAvatarFromXFile(XFile imageXFile, String userId) async {
    final File imageFile = File(imageXFile.path);
    final String fileExtension = p.extension(imageFile.path);
    final String fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
    final String storagePath = 'profile_avatars/$userId/$fileName';
    return await _uploadFile(imageFile, storagePath);
  }

  // Upload ảnh sân từ XFile
  Future<String?> uploadFieldImageFromXFile(XFile imageXFile, String fieldId) async {
    final File imageFile = File(imageXFile.path);
    final String fileExtension = p.extension(imageFile.path);
    final String fileName = 'field_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
    final String storagePath = 'field_images/$fieldId/$fileName';
    return await _uploadFile(imageFile, storagePath);
  }

  // Upload nhiều ảnh sân từ List<XFile>
  Future<List<String>> uploadMultipleFieldImagesFromXFiles(List<XFile> imageXFiles, String fieldId) async {
    final futures = imageXFiles.map((xfile) => uploadFieldImageFromXFile(xfile, fieldId));
    final results = await Future.wait(futures);
    return results.whereType<String>().toList();
  }

  // Upload ảnh review từ XFile
  Future<String?> uploadReviewImageFromXFile(XFile imageXFile, String reviewId) async {
    final File imageFile = File(imageXFile.path);
    final String fileExtension = p.extension(imageFile.path);
    final String fileName = 'review_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
    final String storagePath = 'review_images/$reviewId/$fileName';
    return await _uploadFile(imageFile, storagePath);
  }

  // Upload nhiều ảnh review từ List<XFile>
  Future<List<String>> uploadMultipleReviewImagesFromXFiles(List<XFile> imageXFiles, String reviewId) async {
    final futures = imageXFiles.map((xfile) => uploadReviewImageFromXFile(xfile, reviewId));
    final results = await Future.wait(futures);
    return results.whereType<String>().toList();
  }

  // Xóa ảnh theo URL từ Firebase Storage
  Future<void> deleteImageByUrl(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      debugPrint("ImageService: Attempted to delete null or empty image URL.");
      return;
    }
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint("ImageService: Deleted image from URL: $imageUrl");
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        debugPrint("ImageService: File not found at URL $imageUrl for deletion (already deleted or invalid URL).");
      } else {
        debugPrint("ImageService: Firebase error deleting image by URL $imageUrl: ${e.code} - ${e.message}");
      }
    } catch (e) {
      debugPrint("ImageService: Generic error deleting image by URL $imageUrl: $e");
    }
  }
}
