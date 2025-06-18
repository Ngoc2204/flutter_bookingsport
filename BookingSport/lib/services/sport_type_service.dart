import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sport_type_model.dart';
// ... import UserService để kiểm tra admin

class SportTypeService {
  final CollectionReference _sportTypesCollection = FirebaseFirestore.instance.collection('sport_types');
  // final UserService _userService = UserService();

  Stream<List<SportTypeModel>> getActiveSportTypesStream() {
    return _sportTypesCollection
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SportTypeModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // CRUD functions for Admin (create, update, toggleActive)
  // Ví dụ:
  Future<void> createSportType(String id, String name, {String? iconUrl}) async {
    // ... kiểm tra quyền admin ...
    final newSportType = SportTypeModel(id: id, name: name, iconUrl: iconUrl, createdAt: Timestamp.now());
    await _sportTypesCollection.doc(id).set(newSportType.toJson());
  }
}