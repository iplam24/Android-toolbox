import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/apk_controller.dart';

class ApkView extends GetView<ApkController> {
  const ApkView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'APK Manager',
        subtitle: 'Inspect, backup & extract applications',
        actions: [
          Obx(() => TextButton.icon(
            onPressed: () => controller.toggleSystemApps(),
            icon: Icon(
              controller.includeSystemApps.value
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 18,
            ),
            label: const Text('System Apps', style: TextStyle(fontSize: 12)),
          )),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (val) => controller.onSearch(val),
              decoration: InputDecoration(
                hintText: 'Search apps or packages...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => controller.onSearch(''),
                      )
                    : const SizedBox.shrink()),
              ),
            ),
          ),

          // Count Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Text(
                  '${controller.filteredApps.length} Apps Found',
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                )),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () => controller.loadApps(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Apps List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.filteredApps.isEmpty) {
                return const Center(
                  child: Text('No applications found', style: TextStyle(color: Colors.grey)),
                );
              }
              return ListView.builder(
                itemCount: controller.filteredApps.length,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemBuilder: (context, index) {
                  final app = controller.filteredApps[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.apkColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.android_rounded, color: AppColors.apkColor, size: 28),
                      ),
                      title: Text(
                        app.appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        '${app.packageName}\n${app.formattedSize} • v${app.versionName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download_for_offline_rounded, color: AppColors.apkColor),
                            tooltip: 'Extract APK',
                            onPressed: () => controller.extractApk(app),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: () => controller.showAppDetails(app),
                          ),
                        ],
                      ),
                      onTap: () => controller.showAppDetails(app),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
