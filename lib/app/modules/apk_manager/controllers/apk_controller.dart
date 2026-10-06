import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/system_tools_service.dart';
import '../../../data/models/app_package_model.dart';

class ApkController extends GetxController {
  final systemTools = SystemToolsService.to;

  final RxList<AppPackageModel> allApps = <AppPackageModel>[].obs;
  final RxList<AppPackageModel> filteredApps = <AppPackageModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool includeSystemApps = false.obs;
  final RxString searchQuery = ''.obs;
  final RxMap<String, String> iconCache = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadApps();
  }

  Future<void> loadApps() async {
    isLoading.value = true;
    try {
      final apps = await systemTools.getInstalledPackages(includeSystem: includeSystemApps.value);
      allApps.value = apps;
      _applyFilter();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load apps: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSystemApps() {
    includeSystemApps.value = !includeSystemApps.value;
    loadApps();
  }

  void onSearch(String query) {
    searchQuery.value = query;
    _applyFilter();
  }

  void _applyFilter() {
    if (searchQuery.value.trim().isEmpty) {
      filteredApps.value = allApps;
    } else {
      final q = searchQuery.value.toLowerCase();
      filteredApps.value = allApps.where((app) {
        return app.appName.toLowerCase().contains(q) ||
            app.packageName.toLowerCase().contains(q);
      }).toList();
    }
  }

  Future<String?> loadAppIcon(String packageName) async {
    if (iconCache.containsKey(packageName)) {
      return iconCache[packageName];
    }
    final icon = await systemTools.getAppIcon(packageName);
    if (icon != null) {
      iconCache[packageName] = icon;
    }
    return icon;
  }

  Future<void> extractApk(AppPackageModel app) async {
    Get.snackbar(
      'Extracting APK',
      'Saving ${app.appName} to Downloads...',
      duration: const Duration(seconds: 2),
      showProgressIndicator: true,
    );

    final extractedPath = await systemTools.extractApk(app.packageName);
    if (extractedPath != null) {
      Get.snackbar(
        'APK Extracted',
        'Saved to: $extractedPath',
        mainButton: TextButton(
          onPressed: () {
            Share.shareXFiles([XFile(extractedPath)], text: 'Exported APK: ${app.appName}');
          },
          child: const Text('SHARE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        duration: const Duration(seconds: 5),
      );
    } else {
      Get.snackbar('Error', 'Failed to extract APK. Check storage permission.');
    }
  }

  Future<void> showAppDetails(AppPackageModel app) async {
    final details = await systemTools.getAppDetails(app.packageName) ?? app;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.android_rounded, size: 36, color: Colors.green),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          details.appName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          details.packageName,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          'v${details.versionName} (${details.versionCode}) • ${details.formattedSize}',
                          style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _buildDetailRow('Target SDK', '${details.targetSdkVersion}'),
              _buildDetailRow('Min SDK', '${details.minSdkVersion}'),
              _buildDetailRow('APK Path', details.apkPath, isPath: true),
              _buildDetailRow('Granted Permissions', '${details.permissionsGranted.length} permissions'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Extract'),
                      onPressed: () {
                        Get.back();
                        extractApk(details);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.settings_rounded, size: 18),
                      label: const Text('Settings'),
                      onPressed: () {
                        systemTools.openAppSettings(details.packageName);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.open_in_new_rounded),
                    tooltip: 'Launch App',
                    onPressed: () {
                      systemTools.openApp(details.packageName);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPath = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: isPath ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
