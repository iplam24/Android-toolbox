import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/system_tools_service.dart';
import '../../../data/models/app_package_model.dart';

class ApkController extends GetxController {
  final systemTools = SystemToolsService.to;

  final RxList<AppPackageModel> allApps = <AppPackageModel>[].obs;
  final RxList<AppPackageModel> filteredApps = <AppPackageModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool includeSystemApps = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString sourceFilter = 'all'.obs; // 'all', 'sideloaded', 'playstore'
  final RxMap<String, String> iconCache = <String, String>{}.obs;

  int get sideloadedCount => allApps.where((a) => a.isSideloaded).length;
  int get playStoreCount => allApps.where((a) => a.isFromPlayStore).length;

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
      Get.snackbar('Lỗi', 'Không thể tải danh sách ứng dụng: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSystemApps() {
    includeSystemApps.value = !includeSystemApps.value;
    loadApps();
  }

  void setSourceFilter(String filter) {
    sourceFilter.value = filter;
    _applyFilter();
  }

  void onSearch(String query) {
    searchQuery.value = query;
    _applyFilter();
  }

  void _applyFilter() {
    var list = allApps.toList();

    if (sourceFilter.value == 'sideloaded') {
      list = list.where((app) => app.isSideloaded).toList();
    } else if (sourceFilter.value == 'playstore') {
      list = list.where((app) => app.isFromPlayStore).toList();
    }

    if (searchQuery.value.trim().isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      list = list.where((app) {
        return app.appName.toLowerCase().contains(q) ||
            app.packageName.toLowerCase().contains(q);
      }).toList();
    }

    filteredApps.value = list;
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
      'Đang trích xuất APK',
      'Đang lưu ${app.appName} vào thư mục Download...',
      duration: const Duration(seconds: 2),
      showProgressIndicator: true,
      backgroundColor: AppColors.apkColor.withOpacity(0.9),
      colorText: Colors.white,
    );

    final extractedPath = await systemTools.extractApk(app.packageName);
    if (extractedPath != null) {
      Get.snackbar(
        'Đã trích xuất APK thành công',
        'Đã lưu tại: $extractedPath',
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        mainButton: TextButton(
          onPressed: () {
            Share.shareXFiles([XFile(extractedPath)], text: 'Bộ cài đặt APK: ${app.appName}');
          },
          child: const Text('CHIA SẺ', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
        ),
        duration: const Duration(seconds: 5),
      );
    } else {
      Get.snackbar(
        'Lỗi',
        'Không thể trích xuất APK. Hãy kiểm tra quyền lưu trữ.',
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
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
                      color: AppColors.apkColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.android_rounded, size: 36, color: AppColors.apkColor),
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (details.isFromPlayStore ? Colors.green : Colors.orange).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                details.isFromPlayStore ? '🛍️ Google Play' : '📦 Cài ngoài (APK)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: details.isFromPlayStore ? Colors.green : Colors.orange,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${details.formattedSize} • v${details.versionName}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _buildDetailRow('Nguồn cài đặt', details.installerSource.isNotEmpty ? details.installerSource : 'Không rõ'),
              _buildDetailRow('SDK Đích (Target SDK)', '${details.targetSdkVersion}'),
              _buildDetailRow('SDK Tối thiểu (Min SDK)', '${details.minSdkVersion}'),
              _buildDetailRow('Đường dẫn APK', details.apkPath, isPath: true),
              _buildDetailRow('Số quyền được cấp', '${details.permissionsGranted.length} quyền'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Trích xuất'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.apkColor),
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
                      label: const Text('Cài đặt app'),
                      onPressed: () {
                        systemTools.openAppSettings(details.packageName);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.open_in_new_rounded),
                    tooltip: 'Mở ứng dụng',
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
            width: 140,
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
