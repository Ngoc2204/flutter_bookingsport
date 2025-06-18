// lib/models/field_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum SportType { football, badminton, tennis, volleyball, basketball, unknown }

String sportTypeToString(SportType type) => type.toString().split('.').last;
SportType stringToSportType(String? s) {
  if (s == null) return SportType.unknown;
  return SportType.values.firstWhere(
          (e) => sportTypeToString(e).toLowerCase() == s.toLowerCase(),
      orElse: () => SportType.unknown);
}

class FieldModel {
  String id; // Document ID từ Firestore
  String name; // Tên sân, ví dụ: Sân bóng ABC - Sân số 1
  SportType sportType;
  String address;
  GeoPoint? location; // Vĩ độ, kinh độ để tìm kiếm vị trí
  String? description;
  List<String> imageUrls;
  double pricePerHour; // Giá cơ bản, có thể có cấu trúc giá phức tạp hơn
  String openingHoursDescription; // Mô tả giờ mở cửa dạng text dễ hiểu
  List<String>? amenities; // Tiện ích: "Có mái che", "Nước uống", "Wifi"
  String? sizeDescription; // Mô tả kích thước: "Sân 5", "Sân 7", "Sân Đôi chuẩn"
  String ownerId; // UID của admin/chủ sân quản lý sân này
  double averageRating;
  int totalReviews;
  bool isActive; // Sân có đang hoạt động không
  Timestamp createdAt;
  Timestamp? updatedAt;

  // >>> THÊM THUỘC TÍNH MỚI <<<
  final int? defaultSlotDurationMinutes; // Thời lượng slot mặc định (phút), ví dụ: 60, 90.

  FieldModel({
    required this.id,
    required this.name,
    required this.sportType,
    required this.address,
    this.location,
    this.description,
    this.imageUrls = const [],
    required this.pricePerHour,
    required this.openingHoursDescription,
    this.amenities,
    this.sizeDescription,
    required this.ownerId,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    // >>> THÊM VÀO CONSTRUCTOR <<<
    this.defaultSlotDurationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sportType': sportTypeToString(sportType),
      'address': address,
      'location': location,
      'description': description,
      'imageUrls': imageUrls,
      'pricePerHour': pricePerHour,
      'openingHoursDescription': openingHoursDescription,
      'amenities': amenities ?? [],
      'sizeDescription': sizeDescription,
      'ownerId': ownerId,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      // >>> THÊM VÀO TOJSON <<<
      'defaultSlotDurationMinutes': defaultSlotDurationMinutes,
    };
  }

  // Đổi tên factory method cho nhất quán với thực tế là nó đang đọc từ Firestore snapshot
  factory FieldModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      // Bạn có thể throw lỗi hoặc trả về một FieldModel mặc định/rỗng tùy theo logic ứng dụng
      throw Exception("Field data is null for document ${snapshot.id}");
    }
    return FieldModel(
      id: snapshot.id, // Lấy ID từ DocumentSnapshot
      name: data['name'] as String? ?? 'Tên không xác định',
      sportType: stringToSportType(data['sportType'] as String?),
      address: data['address'] as String? ?? 'Địa chỉ không xác định',
      location: data['location'] as GeoPoint?,
      description: data['description'] as String?,
      imageUrls: (data['imageUrls'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList() ??
          [],
      pricePerHour: (data['pricePerHour'] as num? ?? 0).toDouble(),
      openingHoursDescription: data['openingHoursDescription'] as String? ?? 'Vui lòng liên hệ',
      amenities: (data['amenities'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList(),
      sizeDescription: data['sizeDescription'] as String?,
      ownerId: data['ownerId'] as String? ?? '', // Cung cấp giá trị mặc định nếu null
      averageRating: (data['averageRating'] as num? ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(), // Cung cấp giá trị mặc định
      updatedAt: data['updatedAt'] as Timestamp?,
      // >>> LẤY TỪ DỮ LIỆU FIRESTORE <<<
      defaultSlotDurationMinutes: data['defaultSlotDurationMinutes'] as int?, // Sẽ là null nếu trường không tồn tại hoặc là null
    );
  }

  FieldModel copyWith({
    String? id,
    String? name,
    SportType? sportType,
    String? address,
    GeoPoint? location,
    String? description,
    List<String>? imageUrls,
    double? pricePerHour,
    String? openingHoursDescription,
    List<String>? amenities,
    String? sizeDescription,
    String? ownerId,
    double? averageRating,
    int? totalReviews,
    bool? isActive,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    // >>> THÊM VÀO COPYWITH <<<
    int? defaultSlotDurationMinutes,
    // Thêm một cờ để cho phép set giá trị null một cách tường minh nếu cần
    // bool setDefaultSlotDurationMinutesToNull = false;
  }) {
    return FieldModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sportType: sportType ?? this.sportType,
      address: address ?? this.address,
      location: location ?? this.location,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      openingHoursDescription: openingHoursDescription ?? this.openingHoursDescription,
      amenities: amenities ?? this.amenities,
      sizeDescription: sizeDescription ?? this.sizeDescription,
      ownerId: ownerId ?? this.ownerId,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // >>> CẬP NHẬT TRONG COPYWITH <<<
      defaultSlotDurationMinutes: defaultSlotDurationMinutes ?? this.defaultSlotDurationMinutes,
      // Nếu bạn muốn cho phép set giá trị null một cách tường minh:
      // defaultSlotDurationMinutes: setDefaultSlotDurationMinutesToNull ? null : (defaultSlotDurationMinutes ?? this.defaultSlotDurationMinutes),
    );
  }
}