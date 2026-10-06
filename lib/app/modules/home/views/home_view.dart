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
                                  'ANDROID TOOLBOX',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Swiss-knife system utilities',
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
                          tooltip: 'Quét QR',
                          onTap: () => Get.toNamed(AppRoutes.QR),
                        ),
                        const SizedBox(width: 8),
                        _buildHeaderIconButton(
                          context,
                          icon: Icons.settings_rounded,
                          tooltip: 'Cài đặt',
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
                              'SYSTEM STATUS • READY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.primaryLight : AppColors.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Obx(() => Text(
                              '${controller.batteryLevel.value}% • ${controller.batteryTemp.value.toStringAsFixed(1)}°C • ${controller.localIp.value}',
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
                  // 1. 📦 APK Manager
                  Obx(() => BentoCard(
                    title: 'APK Manager',
                    subtitle: '${controller.installedAppsCount.value} Installed',
                    badge: 'EXTRACT',
                    icon: Icons.inventory_2_rounded,
                    accentColor: AppColors.apkColor,
                    onTap: () => Get.toNamed(AppRoutes.APK),
                  )),

                  // 2. 📋 Clipboard
                  Obx(() => BentoCard(
                    title: 'Clipboard',
                    subtitle: '${controller.clipboardService.items.length} Clips Saved',
                    badge: 'HISTORY',
                    icon: Icons.content_paste_rounded,
                    accentColor: AppColors.clipboardColor,
                    onTap: () => Get.toNamed(AppRoutes.CLIPBOARD),
                  )),

                  // 3. 📡 Network
                  Obx(() => BentoCard(
                    title: 'Network',
                    subtitle: controller.localIp.value,
                    badge: 'PING/SCAN',
                    icon: Icons.wifi_tethering_rounded,
                    accentColor: AppColors.networkColor,
                    onTap: () => Get.toNamed(AppRoutes.NETWORK),
                  )),

                  // 4. 🔋 Battery
                  Obx(() => BentoCard(
                    title: 'Battery',
                    subtitle: '${controller.batteryLevel.value}% • ${controller.batteryTemp.value}°C',
                    badge: controller.batteryPlugged.value.toUpperCase(),
                    icon: Icons.battery_charging_full_rounded,
                    accentColor: AppColors.batteryColor,
                    onTap: () => Get.toNamed(AppRoutes.BATTERY),
                  )),

                  // 5. 📁 File Transfer
                  Obx(() => BentoCard(
                    title: 'File Transfer',
                    subtitle: controller.webServer.isRunning.value ? 'Server Active' : 'Web Share Ready',
                    badge: controller.webServer.isRunning.value ? 'ONLINE' : 'HTTP',
                    icon: Icons.folder_shared_rounded,
                    accentColor: AppColors.fileTransferColor,
                    onTap: () => Get.toNamed(AppRoutes.FILE_TRANSFER),
                  )),

                  // 6. 🔐 Privacy & Perms
                  Obx(() => BentoCard(
                    title: 'Privacy',
                    subtitle: '${controller.highRiskAppsCount.value} High Risk Apps',
                    badge: 'AUDIT',
                    icon: Icons.security_rounded,
                    accentColor: AppColors.privacyColor,
                    onTap: () => Get.toNamed(AppRoutes.PRIVACY),
                  )),

                  // 7. ⚙️ ADB & Dev
                  Obx(() => BentoCard(
                    title: 'ADB & Dev',
                    subtitle: controller.isShizukuRunning.value ? 'Shizuku Ready' : 'Wireless ADB',
                    badge: 'LOGCAT',
                    icon: Icons.terminal_rounded,
                    accentColor: AppColors.adbColor,
                    onTap: () => Get.toNamed(AppRoutes.ADB),
                  )),

                  // 8. 🛠 Tools & Sensors
                  BentoCard(
                    title: 'Device Tools',
                    subtitle: 'Sensors & Screen',
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
}
