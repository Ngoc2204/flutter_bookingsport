// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/common/custom_button.dart'; // Giả sử bạn dùng CustomButton
import '../../widgets/common/loading_indicator.dart';
import 'register_screen.dart'; // <<<< IMPORT RegisterScreen
import 'forgot_password_screen.dart'; // <<<< IMPORT ForgotPasswordScreen

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage; // Thêm biến để hiển thị lỗi

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    FocusScope.of(context).unfocus(); // Ẩn bàn phím
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null; // Xóa lỗi cũ
      });
      try {
        await ref.read(userServiceProvider).signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        // Điều hướng sẽ được xử lý bởi authStateChangesProvider trong MyApp
      } catch (e) {
        if (mounted) { // Kiểm tra mounted trước khi gọi setState
          setState(() {
            _errorMessage = e.toString().replaceFirst("Exception: ", "");
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(userServiceProvider).signInWithGoogle();
      // Điều hướng tương tự
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập'),
        automaticallyImplyLeading: false, // Không có nút back nếu đây là màn hình đầu
      ),
      body: Center( // Thêm Center để căn giữa nếu nội dung ít
        child: SingleChildScrollView( // Cho phép cuộn nếu nội dung dài
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Cho các nút full width
              children: [
                // Optional: Thêm logo hoặc tiêu đề ứng dụng ở đây
                // Image.asset('assets/logo.png', height: 80),
                // const SizedBox(height: 32),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  validator: (value) => (value == null || !value.contains('@')) ? 'Email không hợp lệ' : null,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 6) ? 'Mật khẩu phải ít nhất 6 ký tự' : null,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _isLoading ? null : _loginUser(),
                ),
                const SizedBox(height: 8), // Giảm khoảng cách
                Align( // Căn phải cho nút "Quên mật khẩu"
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                    },
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                const SizedBox(height: 16), // Tăng lại khoảng cách trước nút chính

                // Hiển thị lỗi (nếu có)
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                _isLoading
                    ? const Center(child: LoadingIndicator()) // Sử dụng widget loading
                    : CustomButton( // Sử dụng CustomButton hoặc ElevatedButton
                  onPressed: _loginUser,
                  text: 'Đăng nhập',
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const SizedBox.shrink()
                    : CustomButton( // Nút đăng nhập Google
                  onPressed: _loginWithGoogle,
                  text: 'Đăng nhập với Google',
                  // icon: Icon(Icons.g_mobiledata_outlined), // Thêm icon nếu CustomButton hỗ trợ
                  color: Colors.white, // Ví dụ màu cho nút Google
                  textColor: Colors.black87,
                  // Thêm style cho viền nếu cần
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có tài khoản? '),
                    TextButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
                      },
                      child: const Text('Đăng ký ngay'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}