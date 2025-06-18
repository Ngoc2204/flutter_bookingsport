// lib/services/field_service.dart
import 'dart:math'; // Cho công thức Haversine
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Cho debugPrint
import 'package:image_picker/image_picker.dart';

import '../models/field_model.dart';
import '../core/enums/user_role.dart'; // Đảm bảo đường dẫn này đúng và UserRole được định nghĩa
import 'user_service.dart';
import 'image_service.dart';

class FieldService {
  final FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;
  final CollectionReference<FieldModel> _fieldsCollection;
  final UserService _userService = UserService();
  final ImageService _imageService = ImageService();

  FieldService()
      : _fieldsCollection = FirebaseFirestore.instance.collection('fields').withConverter<FieldModel>(
    // SỬA ĐỔI CHÍNH Ở ĐÂY:
    fromFirestore: (snapshot, _) => FieldModel.fromFirestore(snapshot),
    toFirestore: (model, _) => model.toJson(), // Giả sử FieldModel có toJson() phù hợp
  );

  Stream<List<FieldModel>> getActiveFieldsStream({SportType? filterBySportType}) {
    Query<FieldModel> query = _fieldsCollection.where('isActive', isEqualTo: true);
    if (filterBySportType != null && filterBySportType != SportType.unknown) {
      query = query.where('sportType', isEqualTo: sportTypeToString(filterBySportType));
    }
    query = query.orderBy('createdAt', descending: true);
    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<FieldModel>> getAllFieldsStreamForAdmin() {
    // Cân nhắc thêm điều kiện kiểm tra quyền admin ở đây hoặc ở tầng UI/provider
    return _fieldsCollection.orderBy('createdAt', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<FieldModel?> getFieldById(String fieldId) async {
    try {
      final docSnapshot = await _fieldsCollection.doc(fieldId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data(); // .data() sẽ trả về FieldModel đã được convert
      }
    } catch (e) {
      debugPrint("FieldService: Lỗi lấy sân theo ID $fieldId: $e");
      // Bạn có thể throw lại lỗi nếu muốn UI xử lý
      // throw Exception("Không thể tải thông tin sân: $e");
    }
    return null;
  }

  Future<DocumentReference<FieldModel>> createField({
    required String name,
    required SportType sportType,
    required String address,
    GeoPoint? location,
    String? description,
    required double pricePerHour,
    required String openingHoursDescription,
    List<String>? amenities,
    String? sizeDescription,
    int? defaultSlotDurationMinutes, // Tham số mới
    List<XFile> imageXFiles = const [],
  }) async {
    final currentUserModel = await _userService.getCurrentUserModel();
    if (currentUserModel == null || (currentUserModel.role != UserRole.admin)) {
      throw Exception("Bạn không có quyền tạo sân.");
    }
    try {
      String fieldDocId = _fieldsCollection.doc().id;
      List<String> imageUrls = [];
      if (imageXFiles.isNotEmpty) {
        imageUrls = await _imageService.uploadMultipleFieldImagesFromXFiles(imageXFiles, fieldDocId);
      }
      final newField = FieldModel(
        id: fieldDocId,
        name: name,
        sportType: sportType,
        address: address,
        location: location,
        description: description,
        imageUrls: imageUrls,
        pricePerHour: pricePerHour,
        openingHoursDescription: openingHoursDescription,
        amenities: amenities,
        sizeDescription: sizeDescription,
        ownerId: currentUserModel.id,
        createdAt: Timestamp.now(),
        isActive: true, // Mặc định sân mới là active
        defaultSlotDurationMinutes: defaultSlotDurationMinutes, // Gán giá trị
        // averageRating, totalReviews sẽ lấy giá trị mặc định từ constructor của FieldModel
      );
      await _fieldsCollection.doc(fieldDocId).set(newField);
      debugPrint("FieldService: Tạo sân với ID $fieldDocId");
      return _fieldsCollection.doc(fieldDocId);
    } catch (e) {
      debugPrint("FieldService: Lỗi tạo sân: $e");
      throw Exception("Lỗi tạo sân: ${e.toString()}");
    }
  }

  Future<void> updateField({
    required String fieldId,
    required String name,
    required SportType sportType,
    required String address,
    GeoPoint? location,
    String? description,
    required double pricePerHour,
    required String openingHoursDescription,
    List<String>? amenities,
    String? sizeDescription,
    int? defaultSlotDurationMinutes, // Tham số mới
    bool? isActive,
    List<XFile> newImageXFiles = const [],
    List<String> existingImageUrlsToKeep = const [],
  }) async {
    final currentUserModel = await _userService.getCurrentUserModel();
    if (currentUserModel == null) throw Exception("Bạn cần đăng nhập để thực hiện.");

    try {
      final fieldDocSnapshot = await _fieldsCollection.doc(fieldId).get();
      if (!fieldDocSnapshot.exists) throw Exception("Không tìm thấy sân để cập nhật.");

      FieldModel currentField = fieldDocSnapshot.data()!;
      if (currentUserModel.role != UserRole.admin && currentField.ownerId != currentUserModel.id) {
        throw Exception("Bạn không có quyền chỉnh sửa sân này.");
      }

      List<String> finalImageUrls = List.from(existingImageUrlsToKeep);
      // Xác định các ảnh cần xóa khỏi Storage
      List<String> urlsToDeleteFromStorage = currentField.imageUrls
          .where((url) => !existingImageUrlsToKeep.contains(url))
          .toList();

      for (String url in urlsToDeleteFromStorage) {
        await _imageService.deleteImageByUrl(url); // Gọi service xóa ảnh
      }

      if (newImageXFiles.isNotEmpty) {
        List<String> uploadedNewUrls = await _imageService.uploadMultipleFieldImagesFromXFiles(newImageXFiles, fieldId);
        finalImageUrls.addAll(uploadedNewUrls);
      }

      Map<String, dynamic> updates = {
        'name': name,
        'sportType': sportTypeToString(sportType),
        'address': address,
        'location': location, // Sẽ ghi null nếu location là null
        'description': description, // Sẽ ghi null nếu description là null
        'pricePerHour': pricePerHour,
        'openingHoursDescription': openingHoursDescription,
        'amenities': amenities, // Sẽ ghi null nếu amenities là null
        'sizeDescription': sizeDescription, // Sẽ ghi null nếu sizeDescription là null
        'imageUrls': finalImageUrls,
        'updatedAt': Timestamp.now(),
        // Chỉ cập nhật defaultSlotDurationMinutes nếu nó được cung cấp (khác null)
        // Nếu bạn muốn cho phép set nó thành null, cần logic khác
        if (defaultSlotDurationMinutes != null) 'defaultSlotDurationMinutes': defaultSlotDurationMinutes,
      };

      if (isActive != null) {
        updates['isActive'] = isActive;
      }

      await _fieldsCollection.doc(fieldId).update(updates);
      debugPrint("FieldService: Cập nhật sân với ID $fieldId");
    } catch (e) {
      debugPrint("FieldService: Lỗi cập nhật sân $fieldId: $e");
      throw Exception("Lỗi cập nhật sân: ${e.toString()}");
    }
  }

  Future<void> setFieldActiveStatus(String fieldId, bool isActive) async {
    final currentUserModel = await _userService.getCurrentUserModel();
    if (currentUserModel == null) throw Exception("Bạn cần đăng nhập.");
    try {
      final fieldDocSnapshot = await _fieldsCollection.doc(fieldId).get();
      if (!fieldDocSnapshot.exists) throw Exception("Không tìm thấy sân.");
      FieldModel currentField = fieldDocSnapshot.data()!;
      if (currentUserModel.role != UserRole.admin && currentField.ownerId != currentUserModel.id) {
        throw Exception("Bạn không có quyền thay đổi trạng thái sân này.");
      }
      await _fieldsCollection.doc(fieldId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
      debugPrint("FieldService: Đặt trạng thái sân $fieldId thành $isActive");
    } catch (e) {
      debugPrint("FieldService: Lỗi đặt trạng thái sân $fieldId: $e");
      throw Exception("Lỗi thay đổi trạng thái sân: ${e.toString()}");
    }
  }

  Future<void> updateFieldRating(String fieldId, double newRatingScore) async {
    DocumentReference<FieldModel> fieldRef = _fieldsCollection.doc(fieldId);
    try {
      await _firestoreInstance.runTransaction((transaction) async {
        DocumentSnapshot<FieldModel> snapshot = await transaction.get(fieldRef);
        if (!snapshot.exists) {
          throw Exception("Sân không tồn tại!");
        }
        FieldModel field = snapshot.data()!;
        int newTotalReviews = field.totalReviews + 1;
        double newAverageRating = ((field.averageRating * field.totalReviews) + newRatingScore) / newTotalReviews;
        transaction.update(fieldRef, {
          'averageRating': double.parse(newAverageRating.toStringAsFixed(1)),
          'totalReviews': newTotalReviews,
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (error) {
      debugPrint("FieldService: Lỗi cập nhật đánh giá sân $fieldId: $error");
      throw Exception("Lỗi cập nhật đánh giá sân: ${error.toString()}");
    }
  }

  Future<List<FieldModel>> getFavoriteFields(List<String> favoriteFieldIds) async {
    if (favoriteFieldIds.isEmpty) return [];
    List<FieldModel> favoriteFields = [];
    List<List<String>> chunks = [];
    for (var i = 0; i < favoriteFieldIds.length; i += 10) { // Firestore 'in' query giới hạn 10 phần tử
      chunks.add(favoriteFieldIds.sublist(i, i + 10 > favoriteFieldIds.length ? favoriteFieldIds.length : i + 10));
    }

    for (List<String> chunk in chunks) {
      if (chunk.isNotEmpty) {
        try {
          final querySnapshot = await _fieldsCollection
              .where(FieldPath.documentId, whereIn: chunk)
              .where('isActive', isEqualTo: true)
              .get();
          for (var doc in querySnapshot.docs) {
            favoriteFields.add(doc.data());
          }
        } catch (e) {
          debugPrint("FieldService: Lỗi lấy danh sách sân yêu thích (chunk: $chunk): $e");
        }
      }
    }
    return favoriteFields;
  }

  Future<List<FieldModel>> searchFields({
    String? keyword,
    SportType? sportType,
    // Cân nhắc thêm các filter khác nếu cần
  }) async {
    Query<FieldModel> query = _fieldsCollection.where('isActive', isEqualTo: true);

    if (sportType != null && sportType != SportType.unknown) {
      query = query.where('sportType', isEqualTo: sportTypeToString(sportType));
    }
    // Firestore không hỗ trợ text search phức tạp trên nhiều trường hiệu quả.
    // Lọc keyword ở client sau khi lấy dữ liệu cơ bản.
    try {
      QuerySnapshot<FieldModel> snapshot = await query.get();
      List<FieldModel> fields = snapshot.docs.map((doc) => doc.data()).toList();

      if (keyword != null && keyword.isNotEmpty) {
        String lowerKeyword = keyword.toLowerCase().trim();
        if (lowerKeyword.isNotEmpty) { // Kiểm tra lại sau khi trim
          fields = fields.where((field) {
            bool nameMatch = field.name.toLowerCase().contains(lowerKeyword);
            bool addressMatch = field.address.toLowerCase().contains(lowerKeyword);
            bool descriptionMatch = field.description?.toLowerCase().contains(lowerKeyword) ?? false;
            // bool sportTypeMatch = sportTypeToString(field.sportType).toLowerCase().contains(lowerKeyword); // Cân nhắc
            return nameMatch || addressMatch || descriptionMatch;
          }).toList();
        }
      }
      return fields;
    } catch (e) {
      debugPrint("FieldService: Lỗi tìm kiếm sân: $e");
      return [];
    }
  }

  Stream<List<FieldModel>> searchFieldsByLocationClientSide({
    required GeoPoint center,
    required double radiusInKm,
    SportType? sportType,
    String? keyword,
  }) {
    Query<FieldModel> query = _fieldsCollection.where('isActive', isEqualTo: true);
    if (sportType != null && sportType != SportType.unknown) {
      query = query.where('sportType', isEqualTo: sportTypeToString(sportType));
    }

    return query.snapshots().map((snapshot) {
      List<FieldModel> potentialFields = snapshot.docs.map((doc) => doc.data()).toList();
      List<FieldModel> fieldsWithinRadius = [];

      for (var field in potentialFields) {
        if (field.location != null) {
          double distanceInKm = _calculateDistance(center, field.location!);
          if (distanceInKm <= radiusInKm) {
            bool passesKeywordFilter = true;
            if (keyword != null && keyword.isNotEmpty) {
              String lowerKeyword = keyword.toLowerCase().trim();
              if (lowerKeyword.isNotEmpty) {
                if (!(field.name.toLowerCase().contains(lowerKeyword) ||
                    field.address.toLowerCase().contains(lowerKeyword) ||
                    (field.description?.toLowerCase().contains(lowerKeyword) ?? false))) {
                  passesKeywordFilter = false;
                }
              }
            }
            if (passesKeywordFilter) {
              fieldsWithinRadius.add(field);
            }
          }
        }
      }
      fieldsWithinRadius.sort((a, b) {
        double distA = (a.location != null) ? _calculateDistance(center, a.location!) : double.infinity;
        double distB = (b.location != null) ? _calculateDistance(center, b.location!) : double.infinity;
        return distA.compareTo(distB);
      });
      return fieldsWithinRadius;
    });
  }

  double _calculateDistance(GeoPoint point1, GeoPoint point2) {
    const double earthRadius = 6371; // km
    double lat1Rad = point1.latitude * (pi / 180);
    double lat2Rad = point2.latitude * (pi / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    double deltaLonRad = (point2.longitude - point1.longitude) * (pi / 180);

    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}