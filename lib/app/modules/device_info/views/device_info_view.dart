import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../controllers/device_info_controller.dart';

class DeviceInfoView extends GetView<DeviceInfoController> {
  const DeviceInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Device & Hardware Tools',
        subtitle: 'Hardware specs, sensors & screen tests',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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
          return const Center(child: Text('Unable to read hardware specs'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                                  'Android ${h.androidVersion} (API ${h.sdkInt}) • ${h.securityPatch}',
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
                      _buildSpecRow('Board / Chipset', '${h.board} (${h.hardware})'),
                      _buildSpecRow('Manufacturer', h.manufacturer),
                      _buildSpecRow('CPU Architecture', h.supportedAbis.join(', ')),
                      _buildSpecRow('Total RAM', h.formattedTotalRam),
                      _buildSpecRow('Available RAM', h.formattedAvailRam),
                      _buildSpecRow('Internal Storage', '${h.formattedFreeStorage} free of ${h.formattedTotalStorage}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Interactive Hardware Tests
              const SectionHeader(title: '🧪 Hardware Function Tests'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.vibration_rounded, color: Colors.orangeAccent),
                        title: const Text('Haptic / Vibration Test', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Fire a 300ms vibration pulse', style: TextStyle(fontSize: 12)),
                        trailing: ElevatedButton(
                          onPressed: () => controller.testVibration(),
                          child: const Text('Vibrate'),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.tv_rounded, color: Colors.cyanAccent),
                        title: const Text('Dead Pixel & Display Test', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Full-screen RGBW test cycle', style: TextStyle(fontSize: 12)),
                        trailing: ElevatedButton(
                          onPressed: () => controller.openScreenDeadPixelTest(),
                          child: const Text('Start Test'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Real-Time Sensor Monitor
              const SectionHeader(title: '🛰️ Real-Time Sensors Monitor'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ACCELEROMETER (m/s²)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                      const Text('GYROSCOPE (rad/s)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
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

  Widget _buildAxis(String axis, double val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(axis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            val.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
