import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/app_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final currentUser = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);

    final displayName =
        profileAsync.value?['displayName'] ??
        currentUser?.displayName ??
        'Người dùng';
    final email = currentUser?.email ?? 'Chưa đăng nhập';

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt & Tài khoản')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Tài khoản người dùng (Firebase Authentication)
          Text(
            'Tài khoản người dùng',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.15,
                      ),
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Đã xác thực Firebase',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmSignOut(context, ref),
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
                  label: const Text(
                    'Đăng xuất tài khoản',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Giao diện
          Text(
            'Giao diện ứng dụng',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Theo hệ thống'),
                  secondary: const Icon(Icons.brightness_auto_rounded),
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(themeProvider.notifier).setThemeMode(val);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Giao diện sáng (Light)'),
                  secondary: const Icon(Icons.light_mode_rounded),
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(themeProvider.notifier).setThemeMode(val);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Giao diện tối (Dark)'),
                  secondary: const Icon(Icons.dark_mode_rounded),
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(themeProvider.notifier).setThemeMode(val);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Quản lý dữ liệu
          Text(
            'Dữ liệu & Demo',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.playlist_add_check_circle_rounded,
                    color: Color(0xFF1976D2),
                  ),
                  title: const Text('Nạp dữ liệu mẫu (Demo Data)'),
                  subtitle: const Text(
                    'Thêm 7 giao dịch mẫu vào tài khoản của bạn',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await ref.read(expensesProvider.notifier).seedDemoData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đã nạp thành công 7 khoản chi tiêu mẫu!',
                          ),
                          backgroundColor: Color(0xFF2E7D32),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_sweep_rounded,
                    color: Colors.red,
                  ),
                  title: const Text('Xóa toàn bộ chi tiêu'),
                  subtitle: const Text(
                    'Xóa toàn bộ chi tiêu và ảnh trên Firebase của tài khoản',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _confirmClearAll(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Quyền riêng tư & Bảo mật
          Text(
            'Quyền riêng tư & Bảo mật',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: Color(0xFF2E7D32),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phân quyền riêng tư theo tài khoản (User-scoped)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dữ liệu chi tiêu được phân lập hoàn toàn trong Firestore (users/{uid}/expenses) và Firebase Storage. Mỗi tài khoản chỉ có quyền xem và quản lý dữ liệu của chính mình.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Thông tin ứng dụng
          Text(
            'Thông tin đồ án',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Phiên bản ${AppConstants.appVersion}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildInfoLine('Môn học', AppConstants.courseName),
                const SizedBox(height: 6),
                _buildInfoLine('Đề tài', AppConstants.miniProject),
                const SizedBox(height: 6),
                _buildInfoLine('Trường', AppConstants.schoolName),
                const SizedBox(height: 6),
                _buildInfoLine(
                  'Cơ sở dữ liệu',
                  'Firebase Cloud Firestore & Storage',
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất tài khoản?'),
        content: const Text(
          'Bạn sẽ được đưa về màn hình đăng nhập. Dữ liệu chi tiêu vẫn được lưu trữ an toàn trên đám mây Firebase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa toàn bộ?'),
        content: const Text(
          'Thao tác này sẽ xóa vĩnh viễn toàn bộ các bản ghi chi tiêu và các ảnh thanh toán trên Firebase của tài khoản này. Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa toàn bộ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(expensesProvider.notifier).clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa sạch toàn bộ dữ liệu chi tiêu!'),
          ),
        );
      }
    }
  }
}
