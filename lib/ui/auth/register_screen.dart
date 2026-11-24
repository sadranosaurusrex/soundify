import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();

    final success = await auth.register(
      email: email,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      displayName: _displayNameController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ثبت‌نام با موفقیت انجام شد. کد تایید به ایمیل شما ارسال شد.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(email: email),
        ),
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ایجاد حساب کاربری'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'به جمع کاربران ساندیفای بپیوندید',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 28),

                // Display Name
                CustomTextField(
                  controller: _displayNameController,
                  label: 'نام نمایشی (اختیاری)',
                  hint: 'مثال: سجاد محمدی',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 18),

                // Username
                CustomTextField(
                  controller: _usernameController,
                  label: 'نام کاربری',
                  hint: 'sound_user',
                  prefixIcon: Icons.alternate_email_rounded,
                  textDirection: TextDirection.ltr,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'لطفاً نام کاربری را وارد کنید.';
                    }
                    if (val.trim().length < 3) {
                      return 'نام کاربری باید حداقل ۳ کاراکتر باشد.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Email
                CustomTextField(
                  controller: _emailController,
                  label: 'ایمیل',
                  hint: 'user@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'لطفاً ایمیل خود را وارد کنید.';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'فرمت ایمیل نامعتبر است.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Password
                CustomTextField(
                  controller: _passwordController,
                  label: 'رمز عبور',
                  hint: 'حداقل ۸ نویسه',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textDirection: TextDirection.ltr,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'لطفاً رمز عبور را وارد کنید.';
                    }
                    if (val.length < 8) {
                      return 'رمز عبور باید حداقل ۸ نویسه باشد.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                // Register Button
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _submitRegister,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('ثبت‌نام و دریافت کد'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
