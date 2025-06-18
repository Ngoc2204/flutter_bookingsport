import 'dart:io'; // Cho File
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // Dùng XFile và ImageSource
import '../../providers/auth_providers.dart';
import '../../providers/core_providers.dart'; // Cho imageServiceProvider
// import '../../models/user_model.dart'; // Bỏ import này nếu không dùng trực tiếp
import '../../core/utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_indicator.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  XFile? _newAvatarXFile;
  String? _currentAvatarUrl;
  bool _deleteCurrentAvatar = false;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateChangesProvider).value;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phone;
      _currentAvatarUrl = user.avatarUrl;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final imageService = ref.read(imageServiceProvider);
    // Gọi hàm mới pickSingleXFile
    final XFile? pickedXFile = await imageService.pickSingleXFile(
      source: ImageSource.gallery, // ImageSource được import từ image_picker.dart
      imageQuality: 50,
    );

    if (pickedXFile != null) {
      setState(() {
        _newAvatarXFile = pickedXFile; // Gán trực tiếp XFile
        _deleteCurrentAvatar = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final userService = ref.read(userServiceProvider);
        // Lấy userId từ user hiện tại
        final currentUserId = ref.read(authStateChangesProvider).value?.id;
        if (currentUserId == null) {
          throw Exception("Không tìm thấy thông tin người dùng để cập nhật.");
        }

        await userService.updateUserProfile(
          userId: currentUserId, // Truyền userId vào hàm updateUserProfile
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          newAvatarXFile: _newAvatarXFile,
          deleteCurrentAvatar: _deleteCurrentAvatar && _newAvatarXFile == null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật hồ sơ thành công!')),
          );
          Navigator.of(context).pop();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dùng watch ở đây để UI rebuild khi user data (ví dụ avatarUrl) thay đổi từ server
    final userAsyncValue = ref.watch(authStateChangesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
      ),
      body: userAsyncValue.when(
        data: (user) {
          if (user == null) {
            // Nên điều hướng về login hoặc hiển thị lỗi nghiêm trọng hơn
            return const Center(child: Text("Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."));
          }
          // Cập nhật _currentAvatarUrl nếu user data thay đổi (ví dụ sau khi upload thành công)
          // Tuy nhiên, vì ta pop màn hình sau khi update thành công, việc này có thể không cần thiết
          // nếu ProfileScreen sẽ tự lấy avatar mới. Nhưng để an toàn nếu có logic khác:
          if (_currentAvatarUrl != user.avatarUrl && _newAvatarXFile == null) {
            _currentAvatarUrl = user.avatarUrl;
          }


          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _newAvatarXFile != null
                              ? FileImage(File(_newAvatarXFile!.path))
                              : (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty && !_deleteCurrentAvatar
                              ? NetworkImage(_currentAvatarUrl!)
                              : null) as ImageProvider?,
                          child: (_newAvatarXFile == null && (_currentAvatarUrl == null || _currentAvatarUrl!.isEmpty || _deleteCurrentAvatar))
                              ? Icon(Icons.person, size: 60, color: Colors.grey.shade700)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickAvatar,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2)),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty && _newAvatarXFile == null)
                    Center(
                      child: TextButton.icon(
                        icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                        label: Text(
                          _deleteCurrentAvatar ? 'Hoàn tác xóa ảnh' : 'Xóa ảnh hiện tại',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                        onPressed: () {
                          setState(() {
                            _deleteCurrentAvatar = !_deleteCurrentAvatar;
                          });
                        },
                      ),
                    ),
                  const SizedBox(height: 32.0),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                    validator: Validators.validateNotEmpty,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    // controller: _emailController, // Không cần controller vì readOnly
                    initialValue: user.email, // Lấy email từ user model
                    decoration: const InputDecoration(labelText: 'Email (Không thể thay đổi)'),
                    readOnly: true,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Số điện thoại'),
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _isLoading ? null : _updateProfile(),
                  ),
                  const SizedBox(height: 24.0),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
                    ),
                  _isLoading
                      ? const Center(child: LoadingIndicator())
                      : CustomButton(
                    onPressed: _updateProfile,
                    text: 'Lưu thay đổi',
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (err, stack) => Scaffold(body: Center(child: Text('Lỗi: ${err.toString()}'))),
      ),
    );
  }
}