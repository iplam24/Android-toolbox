import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/system_tools_service.dart';
import 'speaker_water_eject_view.dart';

class WaterResistanceTestView extends StatefulWidget {
  const WaterResistanceTestView({super.key});

  @override
  State<WaterResistanceTestView> createState() => _WaterResistanceTestViewState();
}

class _WaterResistanceTestViewState extends State<WaterResistanceTestView> {
  final systemTools = SystemToolsService.to;

  bool hasSensor = false;
  bool isCheckingSensor = true;
  double currentPressure = 0.0;
  double baselinePressure = 0.0;
  double maxDelta = 0.0;
  bool isTesting = false;
  int countdown = 0;
  String testResult = '';
  Color resultColor = Colors.grey;

  Timer? _pollingTimer;
  Timer? _testTimer;

  @override
  void initState() {
    super.initState();
    _checkBarometer();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _testTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkBarometer() async {
    final available = await systemTools.hasBarometerSensor();
    if (mounted) {
      setState(() {
        hasSensor = available;
        isCheckingSensor = false;
      });
      if (available) {
        _startPressurePolling();
      }
    }
  }

  void _startPressurePolling() {
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      final p = await systemTools.getBarometerPressure();
      if (mounted && p > 0) {
        setState(() {
          currentPressure = p;
          if (isTesting) {
            final delta = (currentPressure - baselinePressure).abs();
            if (delta > maxDelta) {
              maxDelta = delta;
            }
          }
        });
      }
    });
  }

  void _startTest() {
    if (!hasSensor) return;
    setState(() {
      isTesting = true;
      countdown = 5;
      baselinePressure = currentPressure;
      maxDelta = 0.0;
      testResult = 'Hãy dùng ngón tay ấn mạnh vào giữa màn hình...';
      resultColor = Colors.amber;
    });

    systemTools.vibrate(durationMs: 150);

    _testTimer?.cancel();
    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 1) {
        setState(() {
          countdown--;
        });
      } else {
        timer.cancel();
        _finishTest();
      }
    });
  }

  void _finishTest() {
    systemTools.vibrate(durationMs: 250);
    setState(() {
      isTesting = false;
      if (maxDelta >= 1.5) {
        testResult = 'ĐẠT TIÊU CHUẨN: Gioăng kháng nước còn rất tốt! (Áp suất chênh lệch: +${maxDelta.toStringAsFixed(2)} hPa)';
        resultColor = Colors.green;
      } else if (maxDelta >= 0.6) {
        testResult = 'TRUNG BÌNH: Thân máy có dấu hiệu suy giảm độ kín (Chênh lệch: +${maxDelta.toStringAsFixed(2)} hPa). Cẩn trọng khi tiếp xúc nước.';
        resultColor = Colors.orange;
      } else {
        testResult = 'KHÔNG ĐẠT: Không phát hiện sự tăng áp bên trong máy (Chênh lệch: +${maxDelta.toStringAsFixed(2)} hPa). Gioăng đã bị hở hoặc máy đã qua sửa chữa!';
        resultColor = Colors.red;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm tra kháng nước (Áp kế)'),
      ),
      body: isCheckingSensor
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hướng dẫn cơ chế
                  Card(
                    color: AppColors.toolsColor.withOpacity(0.08),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: AppColors.toolsColor, size: 20),
                              SizedBox(width: 8),
                              Text('NGUYÊN LÝ ĐO ĐỘ KÍN GIOĂNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.toolsColor)),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Điện thoại kháng nước tiêu chuẩn (IP67/IP68) được dán kín khít bằng keo và gioăng cao su. '
                            'Khi bạn ấn mạnh vào màn hình, thể tích khí bên trong máy bị nén lại làm áp suất tăng tức thời (Delta P). '
                            'Nếu máy bị hở gioăng hoặc đã bị tháo mở máy, khí sẽ thoát ra ngoài và áp suất không tăng.',
                            style: TextStyle(fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (!hasSensor) ...[
                    // Trường hợp máy không có cảm biến áp suất
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: Colors.amber.withOpacity(0.5), width: 1.2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.sensors_off_rounded, size: 48, color: Colors.amber),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Thiết bị không có Cảm biến áp kế (Barometer)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Phần cứng điện thoại của bạn không trang bị cảm biến đo áp suất khí quyển. '
                              'Điều này là bình thường trên hầu hết các dòng máy Android phân khúc tầm trung / cận cao cấp.',
                              style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.cyan.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.lightbulb_rounded, color: Colors.cyan, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'GIẢI PHÁP THỰC TẾ KHI MÁY VÀO NƯỚC',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.cyan),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Nếu máy vừa bị đi mưa hoặc vô tình rơi nước, hãy dùng ngay công cụ Đẩy nước màng loa 165Hz. '
                                    'Màng loa sẽ phát sóng âm rung cực mạnh giúp đẩy hết giọt nước đọng trong lưới loa ra ngoài an toàn!',
                                    style: TextStyle(fontSize: 12, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Get.back();
                                  Get.to(() => const SpeakerWaterEjectView());
                                },
                                icon: const Icon(Icons.waves_rounded),
                                label: const Text('MỞ CÔNG CỤ ĐẨY NƯỚC LOA 165Hz', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyan.shade700,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Thẻ áp suất thời gian thực
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Text('ÁP SUẤT HIỆN TẠI (BAROMETER)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 12),
                            Text(
                              '${currentPressure.toStringAsFixed(2)} hPa',
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.toolsColor),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isTesting
                                  ? 'Đang ấn: Chênh lệch lớn nhất +${maxDelta.toStringAsFixed(2)} hPa (Còn $countdown giây)'
                                  : 'Mức chuẩn ban đầu: ${baselinePressure > 0 ? "${baselinePressure.toStringAsFixed(2)} hPa" : "Sẵn sàng"}',
                              style: TextStyle(fontSize: 12, color: isTesting ? Colors.amber : Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: isTesting ? null : _startTest,
                                icon: Icon(isTesting ? Icons.touch_app_rounded : Icons.play_arrow_rounded),
                                label: Text(
                                  isTesting ? 'ĐANG ĐO... ẤN MẠNH MÀN HÌNH' : 'BẮT ĐẦU ĐO ĐỘ KÍN GIOĂNG',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isTesting ? Colors.amber.shade700 : AppColors.toolsColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Thẻ kết quả
                    if (testResult.isNotEmpty)
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: resultColor, width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Icon(
                                resultColor == Colors.green
                                    ? Icons.check_circle_rounded
                                    : (resultColor == Colors.orange ? Icons.warning_rounded : Icons.cancel_rounded),
                                color: resultColor,
                                size: 32,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  testResult,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: resultColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}
