import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _confirmFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isCodeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.requestPasswordReset(_emailController.text.trim());

    if (!mounted) return;

    if (success) {
      setState(() => _isCodeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('کد بازیابی به ایمیل شما ارسال شد.'),
          backgroundColor: AppColors.success,
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

  Future<void> _submitReset() async {
    if (!_confirmFormKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.confirmPasswordReset(
      email: _emailController.text.trim(),
      code: _codeController.text.trim(),
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رمز عبور با موفقیت تغییر یافت. لطفاً با رمز جدید وارد شوید.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
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
        title: const Text('بازیابی رمز عبور'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: !_isCodeSent
              ? Form(
                  key: _emailFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'مرحله اول: دریافت کد تأیید',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'ایمیل ثبت‌شده خود را وارد کنید تا کد بازیابی برای شما ارسال شود.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
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
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _requestCode,
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('ارسال کد بازیابی'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _confirmFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'مرحله دوم: ثبت رمز عبور جدید',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'کد ۶ رقمی ارسال‌شده به ${_emailController.text} و رمز عبور جدید را وارد کنید:',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      CustomTextField(
                        controller: _codeController,
                        label: 'کد تایید ۶ رقمی',
                        hint: '123456',
                        prefixIcon: Icons.security_rounded,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'لطفاً کد تایید را وارد کنید.';
                          }
                          if (val.trim().length != 6) {
                            return 'کد تایید باید ۶ رقم باشد.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        controller: _newPasswordController,
                        label: 'رمز عبور جدید',
                        hint: 'حداقل ۸ نویسه',
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        textDirection: TextDirection.ltr,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'لطفاً رمز جدید را وارد کنید.';
                          }
                          if (val.length < 8) {
                            return 'رمز عبور باید حداقل ۸ نویسه باشد.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _submitReset,
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('ذخیره رمز جدید و ورود'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() => _isCodeSent = false);
                        },
                        child: const Text('ویرایش ایمیل / ارسال مجدد'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
