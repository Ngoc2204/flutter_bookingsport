import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart'; // Provider cho UserService
import '../../core/utils/validators.dart';    // Sử dụng lại validators
import '../../widgets/common/custom_button.dart'; // Nút tùy chỉnh
import '../../widgets/common/loading_indicator.dart'; // Widget loading

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _infoMessage; // Để hiển thị thông báo thành công hoặc lỗi
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetPasswordEmail() async {
    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _infoMessage = null;
        _isError = false;
      });

      try {
        final userService = ref.read(userServiceProvider);
        await userService.sendPasswordResetEmail(_emailController.text.trim());

        if (mounted) {
          setState(() {
            _infoMessage = 'Một email hướng dẫn đặt lại mật khẩu đã được gửi đến địa chỉ ${_emailController.text.trim()}. Vui lòng kiểm tra hộp thư của bạn (bao gồm cả thư mục spam).';
            _isError = false;
            // _emailController.clear(); // Xóa email sau khi gửi thành công
          });
          // Không tự động pop, để người dùng đọc thông báo
          // Hoặc có thể pop sau vài giây
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _infoMessage = e.toString().replaceFirst("Exception: ", "");
            _isError = true;
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
        title: const Text('Quên mật khẩu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                  'Đặt lại mật khẩu',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Nhập địa chỉ email đã đăng ký của bạn. Chúng tôi sẽ gửi cho bạn một liên kết để đặt lại mật khẩu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 32.0),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Nhập email của bạn',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _isLoading ? null : _sendResetPasswordEmail(),
                ),
                const SizedBox(height: 24.0),

                // Info/Error Message Display
                if (_infoMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _infoMessage!,
                      style: TextStyle(
                        color: _isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Send Reset Email Button
                _isLoading
                    ? const Center(child: LoadingIndicator())
                    : CustomButton(
                  onPressed: _sendResetPasswordEmail,
                  text: 'Gửi email đặt lại',
                ),

                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: _isLoading ? null : () {
                    Navigator.of(context).pop(); // Quay lại màn hình Login
                  },
                  child: const Text('Quay lại Đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}