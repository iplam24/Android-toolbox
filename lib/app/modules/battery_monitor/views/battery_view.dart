import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/battery_controller.dart';

class BatteryView extends GetView<BatteryController> {
  const BatteryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Battery Diagnostics',
        subtitle: 'Health, temperature, voltage & wattage',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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
          return const Center(child: Text('Unable to read battery telemetry'));
        }

        final isCharging = b.isCharging;
        final temp = b.temperature;
        final tempColor = temp > 40.0 ? Colors.red : (temp > 36.0 ? Colors.orange : Colors.green);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
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
                          b.plugged.toUpperCase(),
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

              // Metrics 2x2 Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'TEMPERATURE',
                      '${b.temperature.toStringAsFixed(1)} °C',
                      Icons.thermostat_rounded,
                      tempColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildMetricCard(
                      'VOLTAGE',
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
                      'HEALTH',
                      b.health,
                      Icons.favorite_rounded,
                      Colors.pinkAccent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildMetricCard(
                      'POWER SPEED',
                      b.wattage > 0 ? '${b.wattage.toStringAsFixed(1)} W' : 'N/A',
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
                        'BATTERY DETAILS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Chemistry / Tech', b.technology),
                      _buildDetailRow('Current Draw', '${b.currentNow} µA'),
                      _buildDetailRow('Capacity', '${b.capacity} %'),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
