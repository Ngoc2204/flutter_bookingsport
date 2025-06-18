// lib/services/user_service.dart
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart'; // Đảm bảo UserModel.fromJson và toJson được định nghĩa đúng
import '../core/enums/user_role.dart'; // Đảm bảo UserRole enum được định nghĩa ở đây
import 'image_service.dart';

class UserService {
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ImageService _imageService = ImageService();

  CollectionReference<Map<String, dynamic>> get _usersCollection => _firestore.collection('users');

  Stream<UserModel?> get userAuthStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      return await _getUserModelFromFirestore(firebaseUser.uid, autoSignOutIfDeleted: true);
    });
  }

  Future<UserModel?> getCurrentUserModel() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }
    return await _getUserModelFromFirestore(firebaseUser.uid);
  }

  Future<UserModel> signUpWithEmailPassword({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    UserRole role = UserRole.user,
  }) async {
    if (password.isEmpty) throw Exception("Mật khẩu không được để trống.");
    if (password.length < 6) throw Exception("Mật khẩu phải có ít nhất 6 ký tự.");

    try {
      fb_auth.UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      fb_auth.User firebaseUser = userCredential.user!;

      final newUser = UserModel(
        id: firebaseUser.uid,
        fullName: fullName.trim(),
        email: email.trim().toLowerCase(),
        phone: phone.trim(),
        role: role,
        createdAt: Timestamp.now(),
        favoriteFieldIds: [],
        isDeleted: false,
      );

      await _usersCollection.doc(firebaseUser.uid).set(newUser.toJson()); // Bỏ forCreate

      await firebaseUser.updateDisplayName(newUser.fullName);

      return newUser;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint("UserService (SignUp) - Error: $e");
      throw Exception("Đã xảy ra lỗi không mong muốn khi đăng ký.");
    }
  }

  Future<UserModel> signInWithEmailPassword(String email, String password) async {
    try {
      fb_auth.UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      fb_auth.User firebaseUser = userCredential.user!;

      final userModel = await _getUserModelFromFirestore(firebaseUser.uid, autoSignOutIfError: true);
      if (userModel == null) {
        await signOut();
        throw Exception("Thông tin người dùng không tồn tại hoặc tài khoản có vấn đề. Vui lòng liên hệ hỗ trợ.");
      }
      if (userModel.isDeleted == true) {
        await signOut();
        throw Exception("Tài khoản của bạn đã bị vô hiệu hóa.");
      }
      return userModel;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint("UserService (SignIn) - Error: $e");
      throw Exception("Đã xảy ra lỗi không mong muốn khi đăng nhập.");
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUserAccount = await _googleSignIn.signIn();
      if (googleUserAccount == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUserAccount.authentication;
      final fb_auth.AuthCredential credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final fb_auth.UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final fb_auth.User firebaseUser = userCredential.user!;

      final userDocRef = _usersCollection.doc(firebaseUser.uid);
      final userDocSnapshot = await userDocRef.get();

      UserModel userModel;
      Map<String, dynamic>? existingUserData = userDocSnapshot.data();

      if (userDocSnapshot.exists && existingUserData != null) {
        userModel = UserModel.fromJson(existingUserData, firebaseUser.uid);
        if (userModel.isDeleted == true) {
          await signOut();
          throw Exception("Tài khoản của bạn đã bị vô hiệu hóa.");
        }
        Map<String, dynamic> updates = {};
        if (userModel.fullName != firebaseUser.displayName && firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty) {
          updates['fullName'] = firebaseUser.displayName;
        }
        if (userModel.avatarUrl != firebaseUser.photoURL && firebaseUser.photoURL != null) {
          updates['avatarUrl'] = firebaseUser.photoURL;
        }
        if (updates.isNotEmpty) {
          updates['updatedAt'] = FieldValue.serverTimestamp();
          await userDocRef.update(updates);
          final updatedSnapshot = await userDocRef.get();
          final updatedData = updatedSnapshot.data();
          if (updatedData != null) {
            userModel = UserModel.fromJson(updatedData, firebaseUser.uid);
          }
        }
      } else {
        userModel = UserModel(
          id: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? "Người dùng Google",
          email: firebaseUser.email!,
          phone: firebaseUser.phoneNumber ?? "",
          role: UserRole.user,
          avatarUrl: firebaseUser.photoURL,
          createdAt: Timestamp.now(),
          favoriteFieldIds: [],
          isDeleted: false,
        );
        await userDocRef.set(userModel.toJson()); // Bỏ forCreate
      }

      List<Future> authProfileUpdates = [];
      if (firebaseUser.displayName != userModel.fullName) {
        authProfileUpdates.add(firebaseUser.updateDisplayName(userModel.fullName));
      }
      if (firebaseUser.photoURL != userModel.avatarUrl) {
        authProfileUpdates.add(firebaseUser.updatePhotoURL(userModel.avatarUrl));
      }
      if (authProfileUpdates.isNotEmpty) {
        try {
          await Future.wait(authProfileUpdates);
        } catch (authUpdateError) {
          debugPrint("UserService (GoogleSignIn) - Error updating Firebase Auth profile: $authUpdateError");
        }
      }
      return userModel;
    } on fb_auth.FirebaseAuthException catch (e) {
      await _googleSignIn.signOut().catchError((error, stackTrace) {
        debugPrint("UserService (GoogleSignIn) - Error signing out from Google after FirebaseAuthException: $error");
        return null;
      });
      throw _handleAuthException(e);
    } catch (e) {
      await _googleSignIn.signOut().catchError((error, stackTrace) {
        debugPrint("UserService (GoogleSignIn) - Error signing out from Google after general error: $error");
        return null;
      });
      debugPrint("UserService (GoogleSignIn) - Error: $e");
      throw Exception("Đã xảy ra lỗi khi đăng nhập bằng Google.");
    }
  }

  Future<void> signOut() async {
    try {
      final googleUser = _googleSignIn.currentUser;
      if (googleUser != null) {
        await _googleSignIn.signOut();
        debugPrint("UserService (SignOut): Google user signed out.");
      }
      await _firebaseAuth.signOut();
      debugPrint("UserService (SignOut): Firebase Auth user signed out.");
    } catch (e) {
      debugPrint("UserService (SignOut) - Error signing out: $e");
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      debugPrint("UserService (PasswordReset): Email sent to $email");
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint("UserService (PasswordReset) - Error: $e");
      throw Exception("Lỗi gửi email đặt lại mật khẩu.");
    }
  }

  Future<UserModel> updateUserProfile({
    required String userId,
    required String fullName,
    required String phone,
    XFile? newAvatarXFile,
    bool deleteCurrentAvatar = false,
  }) async {
    final fb_auth.User? currentUserAuth = _firebaseAuth.currentUser;
    if (currentUserAuth == null || currentUserAuth.uid != userId) {
      throw Exception("Hành động không được phép hoặc phiên đăng nhập đã hết hạn.");
    }

    final userDocRef = _usersCollection.doc(userId);

    try {
      DocumentSnapshot<Map<String, dynamic>> userDocSnap = await userDocRef.get();
      final existingData = userDocSnap.data(); // Lấy data một lần
      if (!userDocSnap.exists || existingData == null) { // Kiểm tra cả exists và data
        throw Exception('Không tìm thấy người dùng (UID: $userId) để cập nhật.');
      }

      UserModel currentUserModel = UserModel.fromJson(existingData, userId);
      String? oldAvatarUrl = currentUserModel.avatarUrl;
      String? finalAvatarUrl = oldAvatarUrl;

      Map<String, dynamic> updates = {};
      bool profileDataChanged = false;

      if (currentUserModel.fullName != fullName.trim()) {
        updates['fullName'] = fullName.trim();
        profileDataChanged = true;
      }
      if (currentUserModel.phone != phone.trim()) {
        updates['phone'] = phone.trim();
        profileDataChanged = true;
      }

      bool avatarOperationAttempted = false;
      if (newAvatarXFile != null) {
        avatarOperationAttempted = true;
        if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
          await _imageService.deleteImageByUrl(oldAvatarUrl).catchError((e) {
            debugPrint("UserService (UpdateProfile) - Error deleting old avatar: $e");
          });
        }
        finalAvatarUrl = await _imageService.uploadProfileAvatarFromXFile(newAvatarXFile, userId);
        updates['avatarUrl'] = finalAvatarUrl;
      } else if (deleteCurrentAvatar && oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
        avatarOperationAttempted = true;
        await _imageService.deleteImageByUrl(oldAvatarUrl).catchError((e) {
          debugPrint("UserService (UpdateProfile) - Error deleting avatar: $e");
        });
        finalAvatarUrl = null;
        updates['avatarUrl'] = null;
      }

      if (profileDataChanged || avatarOperationAttempted) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await userDocRef.update(updates);
      }

      List<Future> authUpdates = [];
      if (updates.containsKey('fullName') && currentUserAuth.displayName != updates['fullName']) {
        authUpdates.add(currentUserAuth.updateDisplayName(updates['fullName']));
      }
      if (avatarOperationAttempted && currentUserAuth.photoURL != finalAvatarUrl) {
        authUpdates.add(currentUserAuth.updatePhotoURL(finalAvatarUrl));
      }
      if (authUpdates.isNotEmpty) {
        try {
          await Future.wait(authUpdates);
        } catch (authUpdateError) {
          debugPrint("UserService (UpdateProfile) - Error updating Firebase Auth profile: $authUpdateError");
        }
      }

      debugPrint("UserService: Profile updated for $userId. New avatar URL: $finalAvatarUrl");
      final updatedUserDocSnap = await userDocRef.get();
      final updatedData = updatedUserDocSnap.data();
      if (!updatedUserDocSnap.exists || updatedData == null) {
        throw Exception("Lỗi khi lấy lại thông tin người dùng sau cập nhật.");
      }
      return UserModel.fromJson(updatedData, updatedUserDocSnap.id);

    } on fb_auth.FirebaseAuthException catch (e) {
      debugPrint("UserService (UpdateProfile) - FirebaseAuthException: ${e.code} - ${e.message}");
      throw _handleAuthException(e);
    } on FirebaseException catch (e) {
      debugPrint("UserService (UpdateProfile) - FirebaseException: ${e.code} - ${e.message}");
      throw Exception("Lỗi khi cập nhật hồ sơ: ${e.message}");
    } catch (e) {
      debugPrint("UserService (UpdateProfile) - General Error: $e");
      throw Exception("Đã xảy ra lỗi không mong muốn khi cập nhật hồ sơ.");
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) throw Exception("Người dùng chưa đăng nhập.");
    if (firebaseUser.email == null) throw Exception("Không thể đổi mật khẩu cho tài khoản không có email.");
    if (newPassword.isEmpty || newPassword.length < 6) throw Exception('Mật khẩu mới phải có ít nhất 6 ký tự.');
    if (currentPassword == newPassword) throw Exception('Mật khẩu mới không được trùng với mật khẩu hiện tại.');

    try {
      fb_auth.AuthCredential credential = fb_auth.EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: currentPassword,
      );
      await firebaseUser.reauthenticateWithCredential(credential);
      await firebaseUser.updatePassword(newPassword);
      debugPrint("UserService (ChangePassword): Password changed for ${firebaseUser.email}.");
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Mật khẩu hiện tại không chính xác.');
      }
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint("UserService (ChangePassword) - Error: $e");
      throw Exception("Lỗi đổi mật khẩu: ${e.toString()}");
    }
  }

  Future<void> updateUserFcmToken(String? token) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      debugPrint("UserService (UpdateFcmToken): User not logged in, skipping FCM token update.");
      return;
    }
    try {
      await _usersCollection.doc(firebaseUser.uid).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint("UserService (UpdateFcmToken): FCM token updated for ${firebaseUser.uid}. Token: $token");
    } catch (e) {
      debugPrint("UserService (UpdateFcmToken) - Error updating FCM token for ${firebaseUser.uid}: $e");
    }
  }

  Future<void> toggleFavoriteField(String fieldId) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw Exception("Vui lòng đăng nhập để sử dụng tính năng này.");
    }
    final userDocRef = _usersCollection.doc(firebaseUser.uid);
    try {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot = await userDocRef.get();
      final userData = userSnapshot.data(); // Lấy data một lần
      if (!userSnapshot.exists || userData == null) { // Kiểm tra cả exists và data
        throw Exception("Không tìm thấy thông tin người dùng.");
      }
      List<String> currentFavorites = List<String>.from(userData['favoriteFieldIds'] as List<dynamic>? ?? []);

      FieldValue updateValue;
      if (currentFavorites.contains(fieldId)) {
        updateValue = FieldValue.arrayRemove([fieldId]);
      } else {
        updateValue = FieldValue.arrayUnion([fieldId]);
      }
      await userDocRef.update({
        'favoriteFieldIds': updateValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("UserService (ToggleFavorite) - Error for user ${firebaseUser.uid}, field $fieldId: $e");
      throw Exception("Lỗi cập nhật danh sách yêu thích: ${e.toString()}");
    }
  }

  Stream<List<String>> getFavoriteFieldIdsStream() {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return Stream.value([]);
    }
    return _usersCollection.doc(firebaseUser.uid).snapshots().map((snapshot) {
      final data = snapshot.data(); // Lấy data một lần
      if (snapshot.exists && data != null) { // Kiểm tra cả exists và data
        return List<String>.from(data['favoriteFieldIds'] as List<dynamic>? ?? []);
      }
      return [];
    });
  }

  Future<UserModel?> _getUserModelFromFirestore(String uid, {bool autoSignOutIfDeleted = false, bool autoSignOutIfError = false}) async {
    try {
      debugPrint("UserService (_getUserModelFromFirestore): Fetching user doc for UID: $uid");
      final docSnapshot = await _usersCollection.doc(uid).get();
      final userData = docSnapshot.data(); // Lấy data một lần

      if (docSnapshot.exists && userData != null) { // Kiểm tra cả exists và data
        debugPrint("UserService (_getUserModelFromFirestore): Document for $uid exists. Data: $userData");
        if (userData['isDeleted'] == true) {
          debugPrint("UserService (_getUserModelFromFirestore): User $uid is marked as deleted.");
          if (autoSignOutIfDeleted) {
            await signOut();
          }
          return null;
        }
        try {
          UserModel model = UserModel.fromJson(userData, uid);
          debugPrint("UserService (_getUserModelFromFirestore): Successfully parsed UserModel for $uid.");
          return model;
        } catch (parseError, stackTrace) {
          debugPrint("UserService (_getUserModelFromFirestore): Error parsing UserModel for $uid. Data was: $userData. Error: $parseError");
          debugPrint(stackTrace.toString());
          if (autoSignOutIfError) { await signOut(); }
          return null;
        }
      } else {
        debugPrint("UserService (_getUserModelFromFirestore): User document for $uid NOT FOUND or data is null (Exists: ${docSnapshot.exists}).");
        if (autoSignOutIfError && _firebaseAuth.currentUser?.uid == uid) {
          await signOut();
        }
      }
    } catch (e, stackTrace) {
      debugPrint("UserService (_getUserModelFromFirestore for $uid) - General Error: $e");
      debugPrint(stackTrace.toString());
      if (autoSignOutIfError && _firebaseAuth.currentUser?.uid == uid) {
        await signOut();
      }
    }
    debugPrint("UserService (_getUserModelFromFirestore): Returning null for UID: $uid");
    return null;
  }

  Exception _handleAuthException(fb_auth.FirebaseAuthException e) {
    String message = "Đã xảy ra lỗi xác thực không mong muốn.";
    debugPrint("UserService (_handleAuthException): code: ${e.code}, message: ${e.message}");
    switch (e.code) {
      case 'weak-password': message = 'Mật khẩu bạn chọn quá yếu. Vui lòng chọn mật khẩu mạnh hơn.'; break;
      case 'email-already-in-use': message = 'Địa chỉ email này đã được sử dụng bởi một tài khoản khác.'; break;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        message = 'Email hoặc mật khẩu không chính xác. Vui lòng thử lại.'; break;
      case 'user-disabled': message = 'Tài khoản của bạn đã bị vô hiệu hóa bởi quản trị viên.'; break;
      case 'invalid-email': message = 'Địa chỉ email không hợp lệ. Vui lòng kiểm tra lại.'; break;
      case 'account-exists-with-different-credential': message = 'Tài khoản đã tồn tại với một phương thức đăng nhập khác. Vui lòng đăng nhập bằng phương thức đó.'; break;
      case 'requires-recent-login': message = 'Hành động này yêu cầu bạn phải đăng nhập lại để xác thực. Vui lòng đăng xuất và đăng nhập lại.'; break;
      case 'network-request-failed': message = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.'; break;
      default: message = e.message ?? message; break;
    }
    return Exception(message);
  }

  Future<List<UserModel>> getAllUsers({DocumentSnapshot? startAfterDoc, int limit = 15}) async {
    Query<Map<String, dynamic>> query = _usersCollection.orderBy('createdAt', descending: true);
    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }
    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data(); // data là Map<String, dynamic>
      return UserModel.fromJson(data, doc.id);
    }).toList();
  }

  Future<void> updateUserRoleByAdmin(String targetUserId, UserRole newRole) async {
    final currentUser = await getCurrentUserModel();
    if (currentUser == null || currentUser.role != UserRole.admin) {
      throw Exception("Bạn không có quyền thực hiện thao tác này.");
    }
    if (currentUser.id == targetUserId && newRole != UserRole.admin) {
      throw Exception("Admin không thể tự thay đổi vai trò của chính mình thành người dùng thường.");
    }
    await _usersCollection.doc(targetUserId).update({
      'role': userRoleToString(newRole), // Giả sử có hàm userRoleToString
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint("UserService (Admin): Updated role for $targetUserId to $newRole by ${currentUser.id}");
  }

  Stream<List<UserModel>> getAllUsersStreamForAdmin() {
    return _usersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) {
      final data = doc.data(); // data là Map<String, dynamic>
      return UserModel.fromJson(data, doc.id);
    }).toList());
  }

  Future<void> setUserActiveStatusByAdmin(String targetUserId, bool isDeletedStatus) async {
    final currentUser = await getCurrentUserModel();
    if (currentUser == null || currentUser.role != UserRole.admin) {
      throw Exception("Bạn không có quyền thực hiện thao tác này.");
    }
    if (currentUser.id == targetUserId) {
      throw Exception("Admin không thể tự khóa/mở khóa tài khoản của chính mình theo cách này.");
    }
    await _usersCollection.doc(targetUserId).update({
      'isDeleted': isDeletedStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint("UserService (Admin): Set isDeleted=$isDeletedStatus for $targetUserId by ${currentUser.id}");
  }
}