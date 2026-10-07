import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/usage_guide_sheet.dart';
import '../controllers/battery_controller.dart';

const _batteryUsageGuide = UsageGuideData(
  title: 'Chẩn đoán pin & Sức khỏe chuyên sâu',
  description: 'Giám sát chi tiết mức năng lượng, nhiệt độ cell pin theo thời gian thực, điện áp, công suất sạc (Watt), số chu kỳ sạc (Charge Cycle count), dung lượng thực tế (mAh) và tỷ lệ chai pin.',
  steps: [
    'Xem phần trăm pin hiện tại và trạng thái nguồn điện (Đang dùng pin, Củ sạc AC, Cổng USB, Sạc không dây).',
    'Xem ô "CHẨN ĐOÁN SỨC KHỎE PIN": Theo dõi Tỷ lệ sức khỏe thực tế (%) và Mức độ chai pin (%). Pin smartphone còn trên 80% là ở tình trạng rất tốt.',
    'Xem "Số chu kỳ sạc": Mỗi chu kỳ tương ứng 100% dung lượng nạp xả trọn vẹn. Trung bình pin giữ độ bền cao nhất trong 500 - 800 chu kỳ sạc.',
    'So sánh "Dung lượng thực tế" so với "Dung lượng thiết kế" (mAh) để biết pin còn tích trữ được bao nhiêu năng lượng.',
    'Theo dõi ô "NHIỆT ĐỘ PIN": Màu xanh lá (< 36°C) là lý tưởng, màu cam (36-40°C) là ấm, màu đỏ (> 40°C) là quá nhiệt. Khi nhiệt độ cao, bạn nên ngưng tác vụ nặng hoặc tháo ốp lưng khi sạc.',
    'Theo dõi "CÔNG SUẤT SẠC" (Watt) và dòng điện (mA): Kiểm tra xem củ sạc và cáp sạc có kích hoạt đúng công suất sạc nhanh hay không.',
  ],
  tips: [
    'Giữ pin trong khoảng 20% đến 80% là khoảng tối ưu nhất giúp kéo dài tuổi thọ cell pin.',
    'Tránh vừa cắm sạc vừa chơi game nặng khiến máy nóng cục bộ, đẩy nhanh tốc độ lão hóa pin.',
    'Dữ liệu chu kỳ và dung lượng được đọc trực tiếp từ hệ thống quản lý năng lượng (Power Supply SysFS) của phần cứng.',
  ],
);

class BatteryView extends GetView<BatteryController> {
  const BatteryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Chẩn đoán pin & Nguồn',
        subtitle: 'Sức khỏe pin, chu kỳ sạc, chai pin & công suất sạc',
        usageGuide: _batteryUsageGuide,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới thông số',
            onPressed: () => controller.loadBattery(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final b = controller.batteryInfo.value;
        if (b == null) {
          return const Center(child: Text('Không thể đọc thông số pin từ hệ thống'));
        }

        final isCharging = b.isCharging;
        final temp = b.temperature;
        final tempColor = temp > 40.0 ? Colors.red : (temp > 36.0 ? Colors.orange : Colors.green);

        final healthPct = b.healthPercent;
        final healthColor = healthPct >= 90.0
            ? Colors.green
            : (healthPct >= 80.0
                ? Colors.teal
                : (healthPct >= 70.0 ? Colors.orange : Colors.red));
        final healthGradeText = healthPct >= 90.0
            ? 'Tình trạng xuất sắc (Như mới)'
            : (healthPct >= 80.0
                ? 'Hoạt động tốt (Chai nhẹ)'
                : (healthPct >= 70.0
                    ? 'Lão hóa vừa phải'
                    : 'Pin chai nhiều (Khuyên thay)'));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Hướng dẫn cách dùng nhanh
              const UsageGuideBanner(guide: _batteryUsageGuide),
              const SizedBox(height: 8),

              // Battery Level Hero Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCharging ? Icons.battery_charging_full_rounded : Icons.battery_std_rounded,
                            size: 48,
                            color: isCharging ? AppColors.success : AppColors.batteryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${b.level}%',
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isCharging ? AppColors.success : AppColors.batteryColor).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          controller.pluggedText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCharging ? AppColors.success : AppColors.batteryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: b.level / 100.0,
                          minHeight: 12,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            b.level < 20 ? Colors.red : (isCharging ? AppColors.success : AppColors.batteryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Deep Battery Health & Wear Diagnostics Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: healthColor.withOpacity(0.3), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: healthColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.health_and_safety_rounded, color: healthColor, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SỨC KHỎE PIN & ĐỘ CHAI PIN',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  healthGradeText,
                                  style: TextStyle(fontSize: 12, color: healthColor, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: healthColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${healthPct.toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: healthColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (healthPct / 100.0).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.red.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Số chu kỳ sạc (Cycle Count)',
                        b.cycleCount > 0 ? '${b.cycleCount} chu kỳ' : 'Không có cảm biến',
                      ),
                      _buildDetailRow(
                        'Mức độ chai pin (Wear Level)',
                        '${b.wearLevel.toStringAsFixed(1)}%',
                      ),
                      _buildDetailRow(
                        'Dung lượng thực tế hiện tại',
                        '${b.actualFullCapacityMah.toStringAsFixed(0)} mAh',
                      ),
                      _buildDetailRow(
                        'Dung lượng thiết kế ban đầu',
                        '${b.designCapacityMah.toStringAsFixed(0)} mAh',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Metrics 2x2 Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'NHIỆT ĐỘ PIN',
                      '${b.temperature.toStringAsFixed(1)} °C',
                      Icons.thermostat_rounded,
                      tempColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildMetricCard(
                      'ĐIỆN ÁP PIN',
                      '${(b.voltage / 1000.0).toStringAsFixed(2)} V',
                      Icons.bolt_rounded,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'TÌNH TRẠNG TỔNG QUAN',
                      controller.healthText,
                      Icons.favorite_rounded,
                      Colors.pinkAccent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildMetricCard(
                      'CÔNG SUẤT SẠC',
                      b.wattage > 0 ? '${b.wattage.toStringAsFixed(1)} W' : 'Đang dùng pin',
                      Icons.speed_rounded,
                      Colors.cyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Additional Hardware Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CHI TIẾT MẠCH NGUỒN & PHẦN CỨNG PIN',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Công nghệ cell pin', b.technology),
                      _buildDetailRow(
                        'Dòng điện tức thời',
                        b.currentNow != 0
                            ? '${(b.currentNow / 1000.0).toStringAsFixed(0)} mA (${b.currentNow > 0 ? "Đang sạc" : "Đang xả"})'
                            : '0 mA',
                      ),
                      if (b.currentAverage != 0)
                        _buildDetailRow(
                          'Dòng điện trung bình',
                          '${(b.currentAverage / 1000.0).toStringAsFixed(0)} mA',
                        ),
                      _buildDetailRow('Mức pin được báo từ OS', '${b.capacity}%'),
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

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
