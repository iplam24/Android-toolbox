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
                                  'HỘP CÔNG CỤ ANDROID',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                    letterSpacing: 0.3,
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.speed_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TRẠNG THÁI HỆ THỐNG • HOẠT ĐỘNG',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.primaryLight : AppColors.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Obx(() => Text(
                              '${controller.batteryLevel.value}% • ${controller.batteryTemp.value.toStringAsFixed(1)}°C • ${controller.localIpText}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            )),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Làm mới thông số',
                        onPressed: () => controller.refreshQuickStats(),
                      ),
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
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.95,
                ),
                delegate: SliverChildListDelegate([
                  // 1. 📦 Quản lý APK
                  Obx(() => BentoCard(
                    title: 'Quản lý APK',
                    subtitle: '${controller.installedAppsCount.value} ứng dụng • Lọc tải ngoài',
                    badge: 'LỌC APP NGOÀI',
                    icon: Icons.inventory_2_rounded,
                    accentColor: AppColors.apkColor,
                    onTap: () => Get.toNamed(AppRoutes.APK),
                  )),

                  // 2. 📋 Bộ nhớ tạm
                  Obx(() => BentoCard(
                    title: 'Bộ nhớ tạm',
                    subtitle: '${controller.clipboardService.items.length} mục đã lưu',
                    badge: 'CLIPBOARD',
                    icon: Icons.content_paste_rounded,
                    accentColor: AppColors.clipboardColor,
                    onTap: () => Get.toNamed(AppRoutes.CLIPBOARD),
                  )),

                  // 3. 📡 Mạng & Ping
                  Obx(() => BentoCard(
                    title: 'Mạng & DNS',
                    subtitle: 'Private DNS • ${controller.localIpText}',
                    badge: 'DNS & PING',
                    icon: Icons.wifi_tethering_rounded,
                    accentColor: AppColors.networkColor,
                    onTap: () => Get.toNamed(AppRoutes.NETWORK),
                  )),

                  // 4. 🔋 Pin & Nguồn
                  Obx(() => BentoCard(
                    title: 'Pin & Sức khỏe',
                    subtitle: '${controller.batteryLevel.value}% • ${controller.batteryTemp.value.toStringAsFixed(1)}°C',
                    badge: 'CHAI PIN & CHU KỲ',
                    icon: Icons.battery_charging_full_rounded,
                    accentColor: AppColors.batteryColor,
                    onTap: () => Get.toNamed(AppRoutes.BATTERY),
                  )),

                  // 5. 📁 Truyền tệp Web
                  Obx(() => BentoCard(
                    title: 'Truyền tệp Web',
                    subtitle: controller.webServer.isRunning.value ? 'Đang phát sóng LAN' : 'Kéo thả Wi-Fi & Xác nhận',
                    badge: controller.webServer.isRunning.value ? 'TRỰC TUYẾN' : 'WEB SHARE',
                    icon: Icons.folder_shared_rounded,
                    accentColor: AppColors.fileTransferColor,
                    onTap: () => Get.toNamed(AppRoutes.FILE_TRANSFER),
                  )),

                  // 6. 🔐 Quyền riêng tư
                  Obx(() => BentoCard(
                    title: 'Quyền riêng tư',
                    subtitle: '${controller.highRiskAppsCount.value} app rủi ro',
                    badge: 'KIỂM TOÁN',
                    icon: Icons.security_rounded,
                    accentColor: AppColors.privacyColor,
                    onTap: () => Get.toNamed(AppRoutes.PRIVACY),
                  )),

                  // 7. ⚙️ Công cụ ADB
                  Obx(() => BentoCard(
                    title: 'Công cụ ADB',
                    subtitle: controller.isShizukuRunning.value ? 'Shizuku sẵn sàng' : 'Không dây & Logcat',
                    badge: 'LOGCAT',
                    icon: Icons.terminal_rounded,
                    accentColor: AppColors.adbColor,
                    onTap: () => Get.toNamed(AppRoutes.ADB),
                  )),

                  // 8. 🛠 Cảm biến & Máy
                  BentoCard(
                    title: 'Cảm biến & Test',
                    subtitle: 'Nước, Loa 165Hz & Mic',
                    badge: 'TEST PHẦN CỨNG',
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
}
