import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/player_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshDeviceSecurity();
    });
  }

  void _showEditProfileDialog() {
    final auth = context.read<AuthProvider>();
    final nameCtrl = TextEditingController(text: auth.currentUser?.displayName ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('ویرایش مشخصات', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'نام نمایشی جدید'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('انصراف', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await auth.updateProfile(displayName: nameCtrl.text.trim());
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('خروج از حساب', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'آیا مایلید از حساب کاربری خود خارج شوید؟',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('انصراف', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(80, 40),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              context.read<PlayerProvider>().stopAndClose();
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('خروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final security = auth.deviceSecurity;

    final displayName = user?.displayName ?? user?.username ?? 'کاربر ساندیفای';
    final username = user?.username ?? 'user';
    final email = user?.email ?? '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('پروفایل کاربری و امنیت'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // User Avatar & Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@$username',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
                    onPressed: _showEditProfileDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: Authentication & Security
            const Text(
              'امنیت و احراز هویت',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Biometric Toggle
                  SwitchListTile(
                    activeThumbColor: AppColors.primary,
                    secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                    title: const Text(
                      'ورود بیومتریک',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'استفاده از اثر انگشت یا اسکن چهره برای ورود به برنامه',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    value: auth.isBiometricEnabled,
                    onChanged: (val) {
                      auth.toggleBiometric(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: Device Security Integrity Check
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'وضعیت امنیتی دستگاه',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => auth.refreshDeviceSecurity(),
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primary),
                  label: const Text(
                    'بررسی مجدد',
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Root status row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: AppColors.textSecondary, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'دسترسی روت (Root):',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (security?.isRooted ?? false)
                              ? AppColors.error.withValues(alpha: 0.2)
                              : AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (security?.isRooted ?? false) ? 'ناامن (روت شده)' : 'ایمن (بدون روت)',
                          style: TextStyle(
                            color: (security?.isRooted ?? false)
                                ? AppColors.error
                                : AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.divider, height: 24),

                  // Emulator status row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.phone_android_rounded, color: AppColors.textSecondary, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'نوع محیط اجرا:',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (security?.isEmulator ?? false)
                              ? AppColors.warning.withValues(alpha: 0.2)
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (security?.isEmulator ?? false) ? 'شبیه‌ساز (Emulator)' : 'دستگاه واقعی (Physical)',
                          style: TextStyle(
                            color: (security?.isEmulator ?? false)
                                ? AppColors.warning
                                : AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.divider, height: 24),

                  // Overall device health
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_user_rounded, color: AppColors.textSecondary, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'وضعیت کلی محیط:',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          ),
                        ],
                      ),
                      Text(
                        (security?.isSecure ?? true)
                            ? 'محیط معتبر و مورد تایید'
                            : 'هشدار امنیتی محیط',
                        style: TextStyle(
                          color: (security?.isSecure ?? true)
                              ? AppColors.success
                              : AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Logout Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                foregroundColor: AppColors.error,
              ),
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('خروج از حساب کاربری'),
            ),
            const SizedBox(height: 100), // padding for mini player
          ],
        ),
      ),
    );
  }
}
