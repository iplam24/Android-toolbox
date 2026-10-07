import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/usage_guide_sheet.dart';
import '../controllers/device_info_controller.dart';
import 'microphone_test_view.dart';
import 'multitouch_test_view.dart';
import 'speaker_water_eject_view.dart';
import 'water_resistance_test_view.dart';

const _deviceInfoUsageGuide = UsageGuideData(
  title: 'Thông tin máy, Cảm biến & Kiểm tra phần cứng',
  description: 'Tra cứu cấu hình phần cứng chi tiết cùng bộ công cụ kiểm tra thực tế: Kháng nước bằng áp kế Barometer, Đẩy nước màng loa 165Hz, Kiểm tra Micro, Cảm ứng đa điểm, Rung và Điểm chết màn hình.',
  steps: [
    'Xem thông số phần cứng tại thẻ "THÔNG TIN THIẾT BỊ": Tên máy, chip SoC, RAM và bộ nhớ trong.',
    'Kiểm tra độ kín kháng nước: Dùng cảm biến áp kế (Barometer) đo áp suất nén khí khi ấn mạnh ngón tay vào màn hình để kiểm tra keo gioăng còn kín hay máy đã qua tháo mở.',
    'Đẩy nước màng loa 165Hz & Test Stereo: Phát sóng âm rung cực mạnh giúp đẩy giọt nước đọng trong màng loa ra ngoài sau khi dính nước và kiểm tra độc lập loa trái / loa phải.',
    'Kiểm tra Micro & Đo âm lượng (dB): Đo biên độ âm thanh thời gian thực và ghi âm thử 5s, có nút nghe lại âm thanh trực tiếp qua loa.',
    'Kiểm tra cảm ứng đa điểm (Multi-Touch): Chạm đồng thời 10 ngón tay để kiểm tra độ nhạy và phát hiện điểm liệt cảm ứng.',
    'Kiểm tra điểm chết màn hình & Mô tơ rung phản hồi.',
  ],
  tips: [
    'Rất hữu dụng khi mua hoặc kiểm tra điện thoại cũ, tránh mua phải máy đã thay vỏ, mất chống nước hoặc liệt cảm ứng.',
    'Nếu máy không có cảm biến áp suất phần cứng, bạn có thể dùng tính năng Đẩy nước loa 165Hz khi máy vô tình rơi nước.',
    'Tăng 100% âm lượng điện thoại khi chạy bài Đẩy nước loa để đạt hiệu quả cao nhất.',
  ],
);

class DeviceInfoView extends GetView<DeviceInfoController> {
  const DeviceInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Cảm biến & Phần cứng',
        subtitle: 'Thông số máy, kiểm tra màn hình & cảm biến',
        usageGuide: _deviceInfoUsageGuide,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới thông số',
            onPressed: () => controller.loadHardwareInfo(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final h = controller.hardwareInfo.value;
        if (h == null) {
          return const Center(child: Text('Không thể đọc thông số phần cứng từ máy'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Hướng dẫn cách dùng nhanh
              const UsageGuideBanner(guide: _deviceInfoUsageGuide),
              const SizedBox(height: 8),

              // Device Identity Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.toolsColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.phone_android_rounded, color: AppColors.toolsColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${h.brand.toUpperCase()} ${h.model}',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Android ${h.androidVersion} (API ${h.sdkInt}) • Bản vá ${h.securityPatch}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      _buildSpecRow('Bo mạch / Chipset', '${h.board} (${h.hardware})'),
                      _buildSpecRow('Nhà sản xuất', h.manufacturer),
                      _buildSpecRow('Kiến trúc CPU', h.supportedAbis.join(', ')),
                      _buildSpecRow('Tổng dung lượng RAM', h.formattedTotalRam),
                      _buildSpecRow('RAM còn khả dụng', h.formattedAvailRam),
                      _buildSpecRow('Bộ nhớ trong (ROM)', 'Trống ${h.formattedFreeStorage} / Tổng ${h.formattedTotalStorage}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Interactive Hardware Tests
              const SectionHeader(title: '🧪 Kiểm tra chức năng phần cứng'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Obx(() => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.water_drop_rounded, color: Colors.blue),
                        ),
                        title: Row(
                          children: [
                            const Text('Kiểm tra độ kín kháng nước', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (controller.hasBarometer.value ? Colors.green : Colors.orange).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                controller.hasBarometer.value ? 'Có Áp kế' : 'Không có Áp kế',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: controller.hasBarometer.value ? Colors.green : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          controller.hasBarometer.value
                              ? 'Đo áp suất nén khí bằng Barometer khi ấn màn hình'
                              : 'Máy không có cảm biến áp suất • Xem giải pháp thay thế',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => Get.to(() => const WaterResistanceTestView()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: controller.hasBarometer.value ? Colors.blue.shade700 : Colors.grey.shade700,
                          ),
                          child: Text(controller.hasBarometer.value ? 'Đo áp suất' : 'Chi tiết'),
                        ),
                      )),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.waves_rounded, color: Colors.cyan),
                        ),
                        title: const Text('Đẩy nước loa & Test Stereo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Phát sóng âm 165Hz làm rung đẩy nước và test loa T/P', style: TextStyle(fontSize: 12)),
                        trailing: ElevatedButton(
                          onPressed: () => Get.to(() => const SpeakerWaterEjectView()),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan.shade700),
                          child: const Text('Đẩy nước'),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.mic_rounded, color: Colors.deepPurple),
                        ),
                        title: const Text('Kiểm tra Micro & Đo độ ồn dB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Đo Decibel thời gian thực, ghi âm 5s và nghe lại', style: TextStyle(fontSize: 12)),
                        trailing: ElevatedButton(
                          onPressed: () => Get.to(() => const MicrophoneTestView()),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                          child: const Text('Thử mic'),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.touch_app_rounded, color: Colors.green),
                        ),
                        title: const Text('Kiểm tra cảm ứng đa điểm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Đếm số ngón tay chạm cùng lúc và vẽ điểm chạm', style: TextStyle(fontSize: 12)),
                        trailing: ElevatedButton(
                          onPressed: () => Get.to(() => const MultiTouchTestView()),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                          child: const Text('Đa điểm'),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.teal.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.tv_rounded, color: Colors.teal),
                        ),
                        title: const Text('Kiểm tra điểm chết màn hình', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Chu trình hiển thị 8 màu đơn sắc toàn màn hình', style: TextStyle(fontSize: 12)),
                        trailing: ElevatedButton(
                          onPressed: () => controller.openScreenDeadPixelTest(),
                          child: const Text('Bắt đầu'),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.vibration_rounded, color: Colors.orange),
                        ),
                        title: const Text('Kiểm tra rung phản hồi (Haptic)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Phát một xung rung 300ms', style: TextStyle(fontSize: 12)),
                        trailing: ElevatedButton(
                          onPressed: () => controller.testVibration(),
                          child: const Text('Rung thử'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Real-Time Sensor Monitor
              const SectionHeader(title: '🛰️ Giám sát cảm biến thời gian thực'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CẢM BIẾN GIA TỐC (m/s²)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildAxis('X', controller.accelerometerValues[0]),
                          _buildAxis('Y', controller.accelerometerValues[1]),
                          _buildAxis('Z', controller.accelerometerValues[2]),
                        ],
                      )),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text('CON QUAY HỒI CHUYỂN (rad/s)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildAxis('X', controller.gyroscopeValues[0]),
                          _buildAxis('Y', controller.gyroscopeValues[1]),
                          _buildAxis('Z', controller.gyroscopeValues[2]),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAxis(String name, double val) {
    return Column(
      children: [
        Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.toolsColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            val.toStringAsFixed(2),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.toolsColor),
          ),
        ),
      ],
    );
  }
}
