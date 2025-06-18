import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart'; // Provider cho UserService
import '../../core/utils/validators.dart'; // Giả sử bạn có file validators
import '../../widgets/common/custom_button.dart'; // Nút tùy chỉnh (nếu có)
import '../../widgets/common/loading_indicator.dart'; // Widget loading

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final userService = ref.read(userServiceProvider);
        await userService.signUpWithEmailPassword(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          phone: _phoneController.text.trim(),
          // role: UserRole.user, // Mặc định trong service
        );

        // Sau khi đăng ký thành công, authStateChangesProvider sẽ cập nhật
        // và MyApp sẽ tự động điều hướng đến HomeScreen (nếu user != null)
        // Hoặc bạn có thể điều hướng ở đây nếu cần:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.')),
          );
          Navigator.of(context).pop(); // Quay lại màn hình Login
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
        leading: IconButton( // Nút back
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Tạo tài khoản mới',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32.0),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Họ và tên'),
                  validator: Validators.validateNotEmpty, // Sử dụng hàm validate
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16.0),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16.0),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16.0),

                // Password
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                  validator: Validators.validatePassword,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16.0),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu.';
                    }
                    if (value != _passwordController.text) {
                      return 'Mật khẩu xác nhận không khớp.';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _isLoading ? null : _registerUser(),
                ),
                const SizedBox(height: 24.0),

                // Error Message Display
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Register Button
                _isLoading
                    ? const Center(child: LoadingIndicator())
                    : CustomButton( // Hoặc ElevatedButton
                  onPressed: _registerUser,
                  text: 'Đăng ký',
                ),

                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: _isLoading ? null : () {
                    Navigator.of(context).pop(); // Quay lại màn hình Login
                  },
                  child: const Text('Đã có tài khoản? Đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}