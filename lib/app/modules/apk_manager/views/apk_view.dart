import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/usage_guide_sheet.dart';
import '../controllers/apk_controller.dart';

const _apkUsageGuide = UsageGuideData(
  title: 'Quản lý & Trích xuất APK',
  description: 'Trích xuất file cài đặt (.APK) của mọi ứng dụng ra bộ nhớ máy để sao lưu hoặc gửi cho máy khác qua Zalo, Telegram, Drive mà không cần kết nối mạng. Đặc biệt hỗ trợ lọc riêng các ứng dụng cài ngoài (Sideloaded) không qua Google Play Store.',
  steps: [
    'Chọn tab "📦 Chỉ app tải ngoài" để lọc ra toàn bộ các ứng dụng bạn tải về từ trình duyệt, Zalo, APKPure hoặc cài thủ công (bỏ qua app từ CH Play).',
    'Nhập tên ứng dụng hoặc tên gói (package name) vào thanh tìm kiếm phía trên.',
    'Bật tùy chọn "App hệ thống" nếu bạn muốn xem và trích xuất cả ứng dụng mặc định của nhà sản xuất.',
    'Bấm biểu tượng 📥 (Tải về) bên phải mỗi ứng dụng để trích xuất file APK vào thư mục Download của máy.',
    'Sau khi trích xuất xong, bấm nút "CHIA SẺ" trên thông báo để gửi file APK đi.',
    'Chạm vào dòng ứng dụng để xem thông tin chi tiết: Nguồn cài đặt, Phiên bản, SDK đích, Đường dẫn gốc, Quyền hạn đã cấp hoặc mở Cài đặt ứng dụng.',
  ],
  tips: [
    'File APK sau khi trích xuất sẽ nằm tại thư mục /sdcard/Download/AndroidToolbox_APKs/',
    'Có thể dùng file APK này cài đặt offline trên các thiết bị Android khác cùng kiến trúc chip.',
    'Trích xuất APK không làm mất dữ liệu hay ảnh hưởng đến ứng dụng đang chạy.',
  ],
);

class ApkView extends GetView<ApkController> {
  const ApkView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Quản lý APK',
        subtitle: 'Lọc app tải ngoài, sao lưu & trích xuất APK',
        usageGuide: _apkUsageGuide,
        actions: [
          Obx(() => TextButton.icon(
            onPressed: () => controller.toggleSystemApps(),
            icon: Icon(
              controller.includeSystemApps.value
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 18,
            ),
            label: const Text('App hệ thống', style: TextStyle(fontSize: 12)),
          )),
        ],
      ),
      body: Column(
        children: [
          // Banner Hướng dẫn cách dùng nhanh
          const UsageGuideBanner(guide: _apkUsageGuide),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: TextField(
              onChanged: (val) => controller.onSearch(val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm ứng dụng hoặc tên gói...',
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

          // Source Filter Bar (Tất cả / Chỉ app tải ngoài / Từ CH Play)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Obx(() => Row(
              children: [
                _buildFilterChip(
                  label: 'Tất cả (${controller.allApps.length})',
                  value: 'all',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '📦 Chỉ app tải ngoài (${controller.sideloadedCount})',
                  value: 'sideloaded',
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '🛍️ Từ CH Play (${controller.playStoreCount})',
                  value: 'playstore',
                  color: Colors.green,
                ),
              ],
            )),
          ),

          // Count Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Text(
                  controller.sourceFilter.value == 'sideloaded'
                      ? 'Đang hiện ${controller.filteredApps.length} app cài ngoài (Không qua CH Play)'
                      : (controller.sourceFilter.value == 'playstore'
                          ? 'Đang hiện ${controller.filteredApps.length} app từ Google Play'
                          : 'Tìm thấy ${controller.filteredApps.length} ứng dụng'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                )),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Tải lại danh sách',
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        controller.sourceFilter.value == 'sideloaded'
                            ? 'Không tìm thấy ứng dụng nào tải ngoài'
                            : 'Không tìm thấy ứng dụng nào khớp bộ lọc',
                        style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
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
                          color: (app.isSideloaded ? Colors.orange : AppColors.apkColor).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          app.isSideloaded ? Icons.install_mobile_rounded : Icons.android_rounded,
                          color: app.isSideloaded ? Colors.orange : AppColors.apkColor,
                          size: 26,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              app.appName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (app.isFromPlayStore ? Colors.green : Colors.orange).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              app.isFromPlayStore ? 'CH Play' : 'Tải ngoài',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: app.isFromPlayStore ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${app.packageName}\n${app.formattedSize} • v${app.versionName} • ${app.installerSource}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download_for_offline_rounded, color: AppColors.apkColor),
                            tooltip: 'Trích xuất APK',
                            onPressed: () => controller.extractApk(app),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            tooltip: 'Xem chi tiết',
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

  Widget _buildFilterChip({required String label, required String value, required Color color}) {
    final isSelected = controller.sourceFilter.value == value;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
      selected: isSelected,
      selectedColor: color,
      checkmarkColor: Colors.white,
      onSelected: (_) => controller.setSourceFilter(value),
    );
  }
}
