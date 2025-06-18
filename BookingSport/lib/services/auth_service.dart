// lib/services/auth_service.dart (HOẶC user_service.dart)
// Cho File khi chuyển đổi từ XFile trong ImageService (hoặc nếu ImageService trả về File)
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart'; // Cho XFile và ImageSource

import '../models/user_model.dart';
import '../core/enums/user_role.dart';
import 'image_service.dart'; // <<<< IMPORT ImageService TỪ FILE RIÊNG

class AuthService { // Hoặc UserService
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ImageService _imageService = ImageService(); // Sử dụng ImageService đã import

  // Đổi tên _firestore.collection('users') thành một getter cho ngắn gọn
  CollectionReference get _usersCollection => _firestore.collection('users');

  Stream<UserModel?> get userAuthStateChanges { // Đổi tên từ 'user' để rõ ràng hơn
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      return await _getUserModelFromFirestore(firebaseUser.uid, autoSignOutIfDeleted: true);
    });
  }

  Future<UserModel?> getCurrentUserModel() async { // Đổi tên từ 'getCurrentUser'
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }
    return await _getUserModelFromFirestore(firebaseUser.uid);
  }

  Future<UserModel> signUpWithEmailPassword({ // Đổi tên từ 'registerUser'
    required String fullName,
    required String email,
    required String password, // Đổi rawPassword thành password cho nhất quán
    required String phone,
    UserRole role = UserRole.user,
  }) async {
    if (password.isEmpty) {
      throw Exception("Mật khẩu không được để trống.");
    }
    if (password.length < 6) {
      throw Exception("Mật khẩu phải có ít nhất 6 ký tự.");
    }

    try {
      fb_auth.UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      fb_auth.User firebaseUser = userCredential.user!;

      final newUser = UserModel(
        id: firebaseUser.uid,
        fullName: fullName,
        email: email,
        phone: phone,
        role: role,
        createdAt: Timestamp.now(), // <<<< SỬA: Dùng Timestamp.now()
        // avatarUrl và fcmToken sẽ là null ban đầu
      );

      await _usersCollection.doc(firebaseUser.uid).set(newUser.toJson());
      await firebaseUser.updateDisplayName(fullName); // Cập nhật display name trong Auth

      debugPrint("UserService (SignUp): User $email registered with UID: ${firebaseUser.uid}");
      return newUser;
    } on fb_auth.FirebaseAuthException catch (e) {
      debugPrint("UserService (SignUp) - FirebaseAuthException: ${e.code} - ${e.message}");
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint("UserService (SignUp) - Error: $e");
      throw Exception("Đã xảy ra lỗi không mong muốn khi đăng ký.");
    }
  }

  Future<UserModel> signInWithEmailPassword(String email, String password) async { // Đổi tên từ 'loginUser'
    try {
      fb_auth.UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      fb_auth.User firebaseUser = userCredential.user!;

      final userModel = await _getUserModelFromFirestore(firebaseUser.uid, autoSignOutIfError: true);
      if (userModel == null) {
        throw Exception("Thông tin người dùng không tồn tại hoặc tài khoản có vấn đề.");
      }
      // isDeleted đã được kiểm tra trong _getUserModelFromFirestore nếu autoSignOutIfDeleted = true
      debugPrint("UserService (SignIn): Login successful for user: ${userModel.fullName}");
      return userModel;
    } on fb_auth.FirebaseAuthException catch (e) {
      debugPrint("UserService (SignIn) - FirebaseAuthException: ${e.code} - ${e.message}");
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
      if (userDocSnapshot.exists) {
        userModel = UserModel.fromJson(userDocSnapshot.data() as Map<String, dynamic>, firebaseUser.uid);
        if (userModel.isDeleted) {
          await signOut();
          throw Exception("Tài khoản của bạn đã bị vô hiệu hóa.");
        }
        Map<String, dynamic> updates = {};
        if (userModel.fullName != firebaseUser.displayName && firebaseUser.displayName != null) {
          updates['fullName'] = firebaseUser.displayName;
        }
        if (userModel.avatarUrl != firebaseUser.photoURL && firebaseUser.photoURL != null) {
          updates['avatarUrl'] = firebaseUser.photoURL;
        }
        if (updates.isNotEmpty) {
          updates['updatedAt'] = Timestamp.now(); // <<<< SỬA: Dùng Timestamp.now()
          await userDocRef.update(updates);
          userModel = (await _getUserModelFromFirestore(firebaseUser.uid))!;
        }
      } else {
        userModel = UserModel(
          id: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? "Người dùng Google",
          email: firebaseUser.email!,
          phone: firebaseUser.phoneNumber ?? "",
          role: UserRole.user,
          avatarUrl: firebaseUser.photoURL,
          createdAt: Timestamp.now(), // <<<< SỬA: Dùng Timestamp.now()
        );
        await userDocRef.set(userModel.toJson());
      }

      List<Future> authProfileUpdates = [];
      if (firebaseUser.displayName != userModel.fullName) {
        authProfileUpdates.add(firebaseUser.updateDisplayName(userModel.fullName));
      }
      if (firebaseUser.photoURL != userModel.avatarUrl) {
        authProfileUpdates.add(firebaseUser.updatePhotoURL(userModel.avatarUrl));
      }
      if (authProfileUpdates.isNotEmpty) await Future.wait(authProfileUpdates);

      debugPrint("UserService (GoogleSignIn): Successful for ${userModel.email}");
      return userModel;
    } on fb_auth.FirebaseAuthException catch (e) {
      await _googleSignIn.signOut();
      throw _handleAuthException(e);
    } catch (e) {
      await _googleSignIn.signOut();
      debugPrint("UserService (GoogleSignIn) - Error: $e");
      throw Exception("Đã xảy ra lỗi khi đăng nhập bằng Google.");
    }
  }

  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _firebaseAuth.signOut();
      debugPrint("UserService (SignOut): User signed out.");
    } catch (e) {
      debugPrint("UserService (SignOut) - Error: $e");
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      debugPrint("UserService (PasswordReset): Email sent to $email");
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint("UserService (PasswordReset) - Error: $e");
      throw Exception("Lỗi gửi email đặt lại mật khẩu.");
    }
  }

  Future<UserModel> updateUserProfile({
    required String userId, // Đã có tham số này
    required String fullName,
    required String phone,
    XFile? newAvatarXFile, // Nhận XFile
    bool deleteCurrentAvatar = false,
  }) async {
    final fb_auth.User? currentUserAuth = _firebaseAuth.currentUser;
    if (currentUserAuth == null || currentUserAuth.uid != userId) {
      throw Exception("Hành động không được phép hoặc phiên đăng nhập đã hết hạn.");
    }

    final userDocRef = _usersCollection.doc(userId);

    try {
      DocumentSnapshot userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        throw Exception('Không tìm thấy người dùng (UID: $userId) để cập nhật.');
      }

      UserModel currentUserModel = UserModel.fromJson(userDoc.data() as Map<String, dynamic>, userId); // Bỏ ! ở userDoc.id
      String? oldAvatarUrl = currentUserModel.avatarUrl;
      String? finalAvatarUrl = oldAvatarUrl;

      Map<String, dynamic> updates = {
        'fullName': fullName,
        'phone': phone,
        'updatedAt': Timestamp.now(), // <<<< SỬA: Dùng Timestamp.now()
      };

      if (newAvatarXFile != null) {
        if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
          await _imageService.deleteImageByUrl(oldAvatarUrl);
        }
        // Gọi hàm của ImageService nhận XFile
        finalAvatarUrl = await _imageService.uploadProfileAvatarFromXFile(newAvatarXFile, userId);
        if (finalAvatarUrl == null) {
          debugPrint("UserService: Avatar upload failed, using old avatar.");
          finalAvatarUrl = oldAvatarUrl;
        }
      } else if (deleteCurrentAvatar && oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
        await _imageService.deleteImageByUrl(oldAvatarUrl);
        finalAvatarUrl = null;
      }
      updates['avatarUrl'] = finalAvatarUrl;

      await userDocRef.update(updates);

      List<Future> authUpdates = [];
      if (currentUserAuth.displayName != fullName) {
        authUpdates.add(currentUserAuth.updateDisplayName(fullName));
      }
      if (currentUserAuth.photoURL != finalAvatarUrl) {
        authUpdates.add(currentUserAuth.updatePhotoURL(finalAvatarUrl));
      }
      if (authUpdates.isNotEmpty) {
        await Future.wait(authUpdates);
      }

      debugPrint("UserService: Profile updated for $userId. New avatar: $finalAvatarUrl");
      final updatedUserDoc = await userDocRef.get();
      return UserModel.fromJson(updatedUserDoc.data() as Map<String, dynamic>, updatedUserDoc.id);
    } on FirebaseException catch (e) {
      debugPrint("UserService (UpdateProfile) - FirebaseException: ${e.code} - ${e.message}");
      throw Exception("Lỗi cập nhật hồ sơ: ${e.message}");
    } catch (e) {
      debugPrint("UserService (UpdateProfile) - Error: $e");
      throw Exception("Đã xảy ra lỗi không mong muốn khi cập nhật hồ sơ.");
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async { // Đổi rawPassword
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) throw Exception("Người dùng chưa đăng nhập.");
    if (firebaseUser.email == null) throw Exception("Không thể đổi mật khẩu cho tài khoản không có email.");
    if (newPassword.isEmpty || newPassword.length < 6) {
      throw Exception('Mật khẩu mới không hợp lệ (phải có ít nhất 6 ký tự).');
    }
    if (currentPassword == newPassword) {
      throw Exception('Mật khẩu mới không được trùng với mật khẩu hiện tại.');
    }

    try {
      fb_auth.AuthCredential credential = fb_auth.EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: currentPassword,
      );
      await firebaseUser.reauthenticateWithCredential(credential);
      await firebaseUser.updatePassword(newPassword);
      debugPrint("UserService (ChangePassword): Password changed for ${firebaseUser.email}.");
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint("UserService (ChangePassword) - Error: $e");
      throw Exception("Lỗi đổi mật khẩu: ${e.toString()}");
    }
  }

  Future<void> updateUserFcmToken(String? token) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return;

    try {
      await _usersCollection.doc(firebaseUser.uid).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(), // <<<< SỬA: Nên dùng serverTimestamp
      });
    } catch (e) {
      debugPrint("UserService (UpdateFcmToken) - Error: $e");
    }
  }

  Future<void> toggleFavoriteField(String fieldId) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) throw Exception("Vui lòng đăng nhập để sử dụng tính năng này.");

    try {
      final userDocRef = _usersCollection.doc(firebaseUser.uid);
      DocumentSnapshot userSnapshot = await userDocRef.get();
      if (!userSnapshot.exists) throw Exception("Không tìm thấy thông tin người dùng.");

      List<String> currentFavorites = List<String>.from(
          (userSnapshot.data() as Map<String, dynamic>)['favoriteFieldIds'] as List<dynamic>? ?? []);

      if (currentFavorites.contains(fieldId)) {
        await userDocRef.update({
          'favoriteFieldIds': FieldValue.arrayRemove([fieldId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userDocRef.update({
          'favoriteFieldIds': FieldValue.arrayUnion([fieldId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("UserService (ToggleFavorite) - Error: $e");
      throw Exception("Lỗi cập nhật danh sách yêu thích: ${e.toString()}");
    }
  }

  Stream<List<String>> getFavoriteFieldIdsStream() {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return Stream.value([]);
    }
    return _usersCollection.doc(firebaseUser.uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        return List<String>.from(data['favoriteFieldIds'] as List<dynamic>? ?? []);
      }
      return [];
    });
  }

  Future<UserModel?> _getUserModelFromFirestore(String uid, {bool autoSignOutIfDeleted = false, bool autoSignOutIfError = false}) async {
    try {
      final docSnapshot = await _usersCollection.doc(uid).get();
      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        if (userData['isDeleted'] == true) {
          debugPrint("UserService: User $uid is marked as deleted.");
          if (autoSignOutIfDeleted) {
            await signOut();
          }
          return null;
        }
        return UserModel.fromJson(userData, uid);
      } else {
        debugPrint("UserService: User document for $uid not found in Firestore.");
        if (autoSignOutIfError) {
          await signOut();
        }
      }
    } catch (e) {
      debugPrint("UserService (_getUserModelFromFirestore for $uid) - Error: $e");
      if (autoSignOutIfError) {
        await signOut();
      }
    }
    return null;
  }

  Exception _handleAuthException(fb_auth.FirebaseAuthException e) {
    String message = "Đã xảy ra lỗi xác thực.";
    switch (e.code) {
      case 'weak-password': message = 'Mật khẩu quá yếu.'; break;
      case 'email-already-in-use': message = 'Địa chỉ email này đã được sử dụng.'; break;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': message = 'Email hoặc mật khẩu không chính xác.'; break;
      case 'user-disabled': message = 'Tài khoản này đã bị vô hiệu hóa.'; break;
      case 'invalid-email': message = 'Địa chỉ email không hợp lệ.'; break;
      case 'account-exists-with-different-credential': message = 'Tài khoản đã tồn tại với một phương thức đăng nhập khác.'; break;
      case 'requires-recent-login': message = 'Hành động này yêu cầu đăng nhập gần đây. Vui lòng đăng xuất và đăng nhập lại.'; break;
      default: message = e.message ?? message; break;
    }
    return Exception(message);
  }
}