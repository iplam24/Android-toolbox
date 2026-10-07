import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../routes/app_routes.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar / Hero Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/logo.jpg',
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Android Toolbox',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tiện ích hệ thống đa năng',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeaderIconButton(
                          context,
                          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          iconColor: isDark ? Colors.amber : AppColors.primary,
                          tooltip: isDark ? 'Giao diện Sáng' : 'Giao diện Tối',
                          onTap: () => controller.settingsService.toggleTheme(),
                        ),
                        const SizedBox(width: 8),
                        _buildHeaderIconButton(
                          context,
                          icon: Icons.qr_code_scanner_rounded,
                          tooltip: 'Quét & Tạo QR',
                          onTap: () => Get.toNamed(AppRoutes.QR),
                        ),
                        const SizedBox(width: 8),
                        _buildHeaderIconButton(
                          context,
                          icon: Icons.settings_rounded,
                          tooltip: 'Cài đặt hệ thống',
                          onTap: () => Get.toNamed(AppRoutes.SETTINGS),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Live Banner Hero Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              AppColors.primary.withOpacity(0.20),
                              AppColors.accent.withOpacity(0.08),
                            ]
                          : [
                              AppColors.primary.withOpacity(0.10),
                              AppColors.accent.withOpacity(0.05),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? AppColors.primary.withOpacity(0.35)
                          : AppColors.primary.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'HỆ THỐNG HOẠT ĐỘNG',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.primaryLight : AppColors.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => controller.refreshQuickStats(),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: isDark ? Colors.grey : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Obx(() => Row(
                        children: [
                          Expanded(
                            child: _buildStatusMetric(
                              icon: controller.isBatteryCharging.value
                                  ? Icons.battery_charging_full_rounded
                                  : Icons.battery_std_rounded,
                              label: controller.batteryPluggedText,
                              value: '${controller.batteryLevel.value}%',
                              color: controller.isBatteryCharging.value ? AppColors.success : AppColors.batteryColor,
                              isDark: isDark,
                            ),
                          ),
                          Container(width: 1, height: 26, color: isDark ? Colors.white12 : Colors.black12),
                          Expanded(
                            child: _buildStatusMetric(
                              icon: Icons.thermostat_rounded,
                              label: 'NHIỆT ĐỘ',
                              value: '${controller.batteryTemp.value.toStringAsFixed(1)}°C',
                              color: controller.batteryTemp.value > 38 ? Colors.red : Colors.orange,
                              isDark: isDark,
                            ),
                          ),
                          Container(width: 1, height: 26, color: isDark ? Colors.white12 : Colors.black12),
                          Expanded(
                            child: _buildStatusMetric(
                              icon: Icons.wifi_rounded,
                              label: 'MẠNG LAN',
                              value: controller.localIpText,
                              color: AppColors.networkColor,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ),

            // 8 Main Bento Cards (2 Columns)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.02,
                ),
                delegate: SliverChildListDelegate([
                  // 1. 📦 Quản lý APK
                  Obx(() => BentoCard(
                    title: 'Quản lý APK',
                    subtitle: '${controller.installedAppsCount.value} ứng dụng đã cài',
                    badge: 'APK NGOÀI',
                    icon: Icons.inventory_2_rounded,
                    accentColor: AppColors.apkColor,
                    onTap: () => Get.toNamed(AppRoutes.APK),
                  )),

                  // 2. 📋 Bộ nhớ tạm
                  Obx(() => BentoCard(
                    title: 'Bộ nhớ tạm',
                    subtitle: '${controller.clipboardService.items.length} mục đã sao chép',
                    badge: 'CLIPBOARD',
                    icon: Icons.content_paste_rounded,
                    accentColor: AppColors.clipboardColor,
                    onTap: () => Get.toNamed(AppRoutes.CLIPBOARD),
                  )),

                  // 3. 📡 Mạng & Ping
                  Obx(() => BentoCard(
                    title: 'Mạng & DNS',
                    subtitle: controller.localIpText,
                    badge: 'DNS',
                    icon: Icons.wifi_tethering_rounded,
                    accentColor: AppColors.networkColor,
                    onTap: () => Get.toNamed(AppRoutes.NETWORK),
                  )),

                  // 4. 🔋 Pin & Nguồn
                  Obx(() => BentoCard(
                    title: 'Pin & Sức khỏe',
                    subtitle: '${controller.batteryLevel.value}% • ${controller.batteryTemp.value.toStringAsFixed(1)}°C',
                    badge: controller.isBatteryCharging.value ? 'ĐANG SẠC' : 'DÙNG PIN',
                    icon: controller.isBatteryCharging.value ? Icons.battery_charging_full_rounded : Icons.battery_std_rounded,
                    accentColor: controller.isBatteryCharging.value ? AppColors.success : AppColors.batteryColor,
                    onTap: () => Get.toNamed(AppRoutes.BATTERY),
                  )),

                  // 5. 📁 Truyền tệp Web
                  Obx(() => BentoCard(
                    title: 'Truyền tệp Web',
                    subtitle: controller.webServer.isRunning.value ? 'Đang phát sóng LAN' : 'Chia sẻ tệp qua Wi-Fi',
                    badge: controller.webServer.isRunning.value ? 'ONLINE' : 'WEB',
                    icon: Icons.folder_shared_rounded,
                    accentColor: AppColors.fileTransferColor,
                    onTap: () => Get.toNamed(AppRoutes.FILE_TRANSFER),
                  )),

                  // 6. 🔐 Quyền riêng tư
                  Obx(() => BentoCard(
                    title: 'Quyền riêng tư',
                    subtitle: '${controller.highRiskAppsCount.value} app cần chú ý',
                    badge: 'BẢO MẬT',
                    icon: Icons.security_rounded,
                    accentColor: AppColors.privacyColor,
                    onTap: () => Get.toNamed(AppRoutes.PRIVACY),
                  )),

                  // 7. ⚙️ Công cụ ADB
                  Obx(() => BentoCard(
                    title: 'Công cụ ADB',
                    subtitle: controller.isShizukuRunning.value ? 'Shizuku đang chạy' : 'Logcat & Gỡ lỗi ADB',
                    badge: 'LOGCAT',
                    icon: Icons.terminal_rounded,
                    accentColor: AppColors.adbColor,
                    onTap: () => Get.toNamed(AppRoutes.ADB),
                  )),

                  // 8. 🛠 Cảm biến & Máy
                  BentoCard(
                    title: 'Cảm biến & Test',
                    subtitle: 'Kháng nước & Loa 165Hz',
                    badge: 'TEST',
                    icon: Icons.hardware_rounded,
                    accentColor: AppColors.toolsColor,
                    onTap: () => Get.toNamed(AppRoutes.DEVICE_INFO),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final bg = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);
    final border = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }

  Widget _buildStatusMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
