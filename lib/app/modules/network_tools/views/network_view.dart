import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../controllers/network_controller.dart';

class NetworkView extends GetView<NetworkController> {
  const NetworkView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Network Suite',
        subtitle: 'IP discovery, ping latency & port scan',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.loadNetworkInfo(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IP Overview Card
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
                            color: AppColors.networkColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.wifi_rounded, color: AppColors.networkColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('LOCAL IP ADDRESS', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Obx(() => Text(
                                controller.localIp.value,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Obx(() {
                      if (controller.interfacesList.isEmpty) {
                        return const Text('No network adapters detected', style: TextStyle(fontSize: 12, color: Colors.grey));
                      }
                      return Column(
                        children: controller.interfacesList.map((iface) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(iface['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text(iface['address'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Ping Tool Section
            const SectionHeader(title: '📡 Latency & Ping Tool'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.pingTargetController,
                            decoration: const InputDecoration(
                              labelText: 'Target Host / IP (e.g. 8.8.8.8)',
                              prefixIcon: Icon(Icons.radar_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Obx(() => ElevatedButton(
                          onPressed: controller.isPinging.value ? null : () => controller.startPing(),
                          child: controller.isPinging.value
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Ping'),
                        )),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Obx(() => Text(
                      controller.pingStatus.value,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.networkColor),
                    )),
                    const SizedBox(height: 10),
                    Obx(() {
                      if (controller.pingHistory.isEmpty) return const SizedBox.shrink();
                      return Row(
                        children: controller.pingHistory.map((p) {
                          final isGood = p < 100;
                          final isWarn = p >= 100 && p < 300;
                          final color = p >= 999 ? Colors.red : (isGood ? Colors.green : (isWarn ? Colors.amber : Colors.orange));
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withOpacity(0.5)),
                            ),
                            child: Text(
                              p >= 999 ? 'Timeout' : '${p}ms',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Port Scanner Section
            const SectionHeader(title: '🔍 Local Port Scanner'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.portTargetController,
                            decoration: const InputDecoration(
                              labelText: 'Host IP to Scan',
                              prefixIcon: Icon(Icons.lan_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Obx(() => ElevatedButton(
                          onPressed: controller.isScanningPorts.value ? null : () => controller.scanPorts(),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.networkColor),
                          child: controller.isScanningPorts.value
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Scan'),
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.scannedPorts.isEmpty) {
                        return const Text('Tap "Scan" to probe common ports (ADB, Web, SSH, FTP...)', style: TextStyle(fontSize: 12, color: Colors.grey));
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.scannedPorts.map((p) {
                          final bool isOpen = p['isOpen'] == true;
                          final color = isOpen ? Colors.green : Colors.grey;
                          return Chip(
                            avatar: Icon(isOpen ? Icons.check_circle_rounded : Icons.cancel_outlined, size: 16, color: color),
                            label: Text('${p['port']} (${p['service']})', style: TextStyle(fontSize: 12, color: isOpen ? Colors.white : null)),
                            backgroundColor: isOpen ? Colors.green.withOpacity(0.25) : null,
                          );
                        }).toList(),
                      );
                    }),
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
