import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/usage_guide_sheet.dart';
import '../controllers/adb_controller.dart';

const _adbUsageGuide = UsageGuideData(
  title: 'Trung tâm ADB & Nhà phát triển',
  description: 'Mở nhanh các cài đặt chuyên sâu của hệ thống, hướng dẫn ghép nối ADB không dây (Wireless Debugging) không cần dây cáp và theo dõi nhật ký hệ thống (Logcat) trực tiếp trên điện thoại.',
  steps: [
    'Bấm "Tùy chọn nhà phát triển" để mở ngay menu cài đặt chuyên sâu của Android.',
    'Bấm "Gỡ lỗi Wi-Fi" để mở cài đặt Wireless Debugging (yêu cầu Android 11 trở lên).',
    'Ghép nối không dây: Trên điện thoại chọn "Ghép nối bằng mã ghép nối", ghi lại IP, Cổng (Port) và mã PIN 6 số.',
    'Trên terminal máy tính, chạy lệnh:\n  adb pair <IP>:<PORT> <PIN>\n  adb connect <IP>:<PORT_GỠ_LỖI>',
    'Theo dõi nhật ký: Nhập từ khóa (VD: Crash, Error, Fatal, tên package) vào ô lọc để tìm logcat thời gian thực.',
    'Bấm biểu tượng Sao chép ở góc phải thanh tiêu đề để copy toàn bộ nhật ký logcat gửi hỗ trợ kỹ thuật.',
  ],
  tips: [
    'Sau khi ghép nối thành công, bạn có thể cài đặt APK, gỡ lỗi và chạy lệnh shell qua Wi-Fi cực kỳ thuận tiện.',
    'Hệ thống tự động phát hiện dịch vụ Shizuku để biết máy đã sẵn sàng cấp quyền nâng cao hay chưa.',
  ],
);

class AdbView extends GetView<AdbController> {
  const AdbView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Công cụ ADB & Dev',
        subtitle: 'Ghép nối không dây, Shizuku & trình xem Logcat',
        usageGuide: _adbUsageGuide,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Sao chép Logcat',
            onPressed: () => controller.copyLogs(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới Logcat',
            onPressed: () => controller.fetchLogcat(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Hướng dẫn cách dùng nhanh
            const UsageGuideBanner(guide: _adbUsageGuide),
            const SizedBox(height: 8),

            // Quick Shortcuts Grid
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.developer_mode_rounded, size: 18),
                            label: const Text('Tùy chọn Dev', style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.adbColor),
                            onPressed: () => controller.openDevSettings(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.wifi_tethering_rounded, size: 18),
                            label: const Text('Gỡ lỗi Wi-Fi', style: TextStyle(fontSize: 13)),
                            onPressed: () => controller.openWirelessDebugging(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 20, color: Colors.blueAccent),
                            SizedBox(width: 8),
                            Text('Trạng thái Shizuku', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (controller.isShizukuInstalled.value ? Colors.green : Colors.grey).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            controller.isShizukuInstalled.value ? 'ĐÃ CÀI ĐẶT / SẴN SÀNG' : 'CHƯA CÀI ĐẶT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: controller.isShizukuInstalled.value ? Colors.green : Colors.grey,
                            ),
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Wireless ADB Setup Guide Card
            Card(
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.help_outline_rounded, color: AppColors.adbColor),
                title: const Text('Hướng dẫn kết nối ADB không dây', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                children: const [
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. Mở Cài đặt cho nhà phát triển -> Bật "Gỡ lỗi không dây" (Wireless debugging).'),
                        SizedBox(height: 6),
                        Text('2. Nhấn "Ghép nối thiết bị bằng mã ghép nối". Lấy địa chỉ IP, Cổng và mã PIN 6 số.'),
                        SizedBox(height: 6),
                        Text('3. Trên cửa sổ lệnh terminal của máy tính (cùng mạng Wi-Fi), chạy:'),
                        SizedBox(height: 4),
                        SelectableText(
                          'adb pair <IP>:<PORT> <PIN>\nadb connect <IP>:<PORT_DEBUG>',
                          style: TextStyle(fontFamily: 'monospace', color: Colors.cyanAccent, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live Logcat Terminal Card
            const SectionHeader(title: '📜 Nhật ký hệ thống (Logcat Viewer)'),
            Card(
              color: Colors.black.withOpacity(0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Lọc logcat (VD: Activity, Error, Crash, Fatal)...',
                        prefixIcon: Icon(Icons.filter_list_rounded),
                        isDense: true,
                      ),
                      onChanged: (val) => controller.logFilter.value = val,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 320,
                      child: Obx(() {
                        if (controller.isLoadingLogs.value) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final logs = controller.filteredLogs;
                        if (logs.isEmpty) {
                          return const Center(child: Text('Không có nhật ký nào hoặc đã bị lọc hết', style: TextStyle(color: Colors.grey)));
                        }
                        return ListView.builder(
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final line = logs[index];
                            final isError = line.contains(' E ') || line.contains('FATAL') || line.contains('Exception');
                            return Text(
                              line,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: isError ? Colors.redAccent : Colors.greenAccent,
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
