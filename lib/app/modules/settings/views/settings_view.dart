import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Cài đặt hệ thống',
        subtitle: 'Giao diện sáng/tối, trải nghiệm & tùy chọn',
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Giao diện & Chủ đề
            _buildSectionHeader('GIAO DIỆN & MÀU SẮC', Icons.palette_rounded, AppColors.primary),
            const SizedBox(height: 12),
            _buildThemeSelector(isDark),
            const SizedBox(height: 24),

            // Section 2: Trải nghiệm & Hiệu năng
            _buildSectionHeader('TRẢI NGHIỆM & PHẢN HỒI', Icons.touch_app_rounded, AppColors.accent),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  Obx(() => SwitchListTile.adaptive(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.vibration_rounded, color: AppColors.primary, size: 22),
                    ),
                    title: Text(
                      'Rung phản hồi xúc giác',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textPrimary),
                    ),
                    subtitle: Text(
                      'Rung nhẹ (Haptic) khi chạm, sao chép hoặc thực hiện thao tác',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    value: controller.settingsService.hapticEnabled.value,
                    onChanged: (val) => controller.toggleHaptic(val),
                  )),
                  Divider(height: 1, color: borderColor),
                  Obx(() => SwitchListTile.adaptive(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.batteryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.sync_rounded, color: AppColors.batteryColor, size: 22),
                    ),
                    title: Text(
                      'Tự động làm mới thông số',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textPrimary),
                    ),
                    subtitle: Text(
                      'Tự động cập nhật % pin, nhiệt độ và IP tại màn hình chính',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    value: controller.settingsService.autoRefreshStats.value,
                    onChanged: (val) => controller.toggleAutoRefresh(val),
                  )),
                  Divider(height: 1, color: borderColor),
                  Obx(() => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.fileTransferColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lan_rounded, color: AppColors.fileTransferColor, size: 22),
                    ),
                    title: Text(
                      'Cổng máy chủ Web Share',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textPrimary),
                    ),
                    subtitle: Text(
                      'Cổng chia sẻ tệp nội bộ (Mặc định: 8080)',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ':${controller.settingsService.serverPort.value}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    onTap: () => _showPortDialog(context),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: Quản lý & Dọn dẹp dữ liệu
            _buildSectionHeader('DỮ LIỆU & BỘ NHỚ', Icons.cleaning_services_rounded, AppColors.error),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  Obx(() => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.clipboardColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_sweep_rounded, color: AppColors.clipboardColor, size: 22),
                    ),
                    title: Text(
                      'Xóa lịch sử Clipboard',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textPrimary),
                    ),
                    subtitle: Text(
                      'Hiện có ${controller.clipboardService.items.length} mục đã lưu',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => controller.clearClipboardHistory(),
                  )),
                  Divider(height: 1, color: borderColor),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.restart_alt_rounded, color: Colors.orange, size: 22),
                    ),
                    title: Text(
                      'Khôi phục cài đặt mặc định',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textPrimary),
                    ),
                    subtitle: Text(
                      'Đặt lại giao diện, haptic và các tùy chọn',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => controller.resetToDefaults(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 4: Về ứng dụng & Mã nguồn
            _buildSectionHeader('THÔNG TIN & NGUỒN MỞ', Icons.info_outline_rounded, AppColors.success),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Android Toolbox',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'v1.2.0 • Stable Release',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Xây dựng bằng Flutter 3.47+, Dart & GetX',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () => controller.copyGithubUrl(),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.code_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GitHub Repository',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'iplam24/Android-toolbox',
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Copy',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(bool isDark) {
    return Obx(() {
      final currentMode = controller.settingsService.themeMode.value;

      return Row(
        children: [
          Expanded(
            child: _buildThemeCard(
              title: 'Hệ thống',
              icon: Icons.brightness_auto_rounded,
              mode: ThemeMode.system,
              isSelected: currentMode == ThemeMode.system,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildThemeCard(
              title: 'Sáng',
              icon: Icons.light_mode_rounded,
              mode: ThemeMode.light,
              isSelected: currentMode == ThemeMode.light,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildThemeCard(
              title: 'Tối',
              icon: Icons.dark_mode_rounded,
              mode: ThemeMode.dark,
              isSelected: currentMode == ThemeMode.dark,
              isDark: isDark,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildThemeCard({
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required bool isSelected,
    required bool isDark,
  }) {
    final activeBg = isSelected
        ? AppColors.primary.withOpacity(0.18)
        : (isDark ? AppColors.cardDark : AppColors.cardLight);
    final activeBorder = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return InkWell(
      onTap: () => controller.setThemeMode(mode),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: activeBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: activeBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : (isDark ? Colors.grey : Colors.blueGrey),
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
            const SizedBox(height: 4),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  void _showPortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi cổng Web Share'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập số cổng mạng (1024 - 65535) cho máy chủ chia sẻ tệp:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.portController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '8080',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => controller.savePort(),
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }
}
