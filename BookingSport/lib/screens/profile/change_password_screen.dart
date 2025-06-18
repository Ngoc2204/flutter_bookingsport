import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../core/utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_indicator.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = null;
        _isError = false;
      });

      try {
        final userService = ref.read(userServiceProvider);
        await userService.changePassword(
          _currentPasswordController.text,
          _newPasswordController.text,
        );

        if (mounted) {
          setState(() {
            _message = 'Đổi mật khẩu thành công!';
            _isError = false;
            // Xóa các trường sau khi thành công
            _currentPasswordController.clear();
            _newPasswordController.clear();
            _confirmNewPasswordController.clear();
          });
          // Có thể pop sau vài giây hoặc để user tự back
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _message = e.toString().replaceFirst("Exception: ", "");
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
        title: const Text('Đổi mật khẩu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
                obscureText: true,
                validator: Validators.validatePassword,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                obscureText: true,
                validator: Validators.validatePassword,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _confirmNewPasswordController,
                decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu mới.';
                  if (value != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp.';
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _isLoading ? null : _changePassword(),
              ),
              const SizedBox(height: 24.0),

              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _message!,
                    style: TextStyle(color: _isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary),
                    textAlign: TextAlign.center,
                  ),
                ),

              _isLoading
                  ? const Center(child: LoadingIndicator())
                  : CustomButton(
                onPressed: _changePassword,
                text: 'Lưu mật khẩu mới',
              ),
            ],
          ),
        ),
      ),
    );
  }
}