import 'dart:async';
import 'package:get/get.dart';
import '../../../core/services/clipboard_storage_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/system_tools_service.dart';
import '../../../core/services/web_server_service.dart';

class HomeController extends GetxController {
  final systemTools = SystemToolsService.to;
  final webServer = WebServerService.to;
  final clipboardService = ClipboardStorageService.to;
  final settingsService = Get.find<SettingsService>();

  final RxInt installedAppsCount = 0.obs;
  final RxInt batteryLevel = 0.obs;
  final RxDouble batteryTemp = 0.0.obs;
  final RxString batteryPlugged = 'Discharging'.obs;
  final RxString localIp = 'Offline'.obs;
  final RxBool isShizukuRunning = false.obs;
  final RxInt highRiskAppsCount = 0.obs;

  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    refreshQuickStats();
    // Refresh stats every 8 seconds if autoRefresh enabled
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (settingsService.autoRefreshStats.value) {
        refreshQuickStats();
      }
    });
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    _loadBackgroundStats();
  }

  Future<void> _loadBackgroundStats() async {
    try {
      if (installedAppsCount.value == 0) {
        final apps = await systemTools.getInstalledPackages(includeSystem: false);
        installedAppsCount.value = apps.length;
      }
      if (highRiskAppsCount.value == 0) {
        final audit = await systemTools.getDangerousPermissionsAudit();
        highRiskAppsCount.value = audit.where((a) => a.riskScore >= 8).length;
      }
    } catch (_) {}
  }

  Future<void> refreshQuickStats() async {
    try {
      // 1. Battery
      final battery = await systemTools.getAdvancedBatteryInfo();
      if (battery != null) {
        batteryLevel.value = battery.level;
        batteryTemp.value = battery.temperature;
        batteryPlugged.value = battery.plugged;
      }

      // 2. Local IP
      final ip = await webServer.getLocalIpAddress();
      localIp.value = ip;

      // 3. Shizuku status
      isShizukuRunning.value = await systemTools.isShizukuInstalled();
    } catch (e) {
      print('Error refreshing quick stats: $e');
    }
  }
}
