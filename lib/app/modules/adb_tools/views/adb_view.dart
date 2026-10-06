import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../controllers/adb_controller.dart';

class AdbView extends GetView<AdbController> {
  const AdbView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'ADB & Developer Hub',
        subtitle: 'Wireless pairing, Shizuku & logcat viewer',
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy Logcat',
            onPressed: () => controller.copyLogs(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Logs',
            onPressed: () => controller.fetchLogcat(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            label: const Text('Dev Options', style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.adbColor),
                            onPressed: () => controller.openDevSettings(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.wifi_tethering_rounded, size: 18),
                            label: const Text('Wireless ADB', style: TextStyle(fontSize: 13)),
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
                            Text('Shizuku Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (controller.isShizukuInstalled.value ? Colors.green : Colors.grey).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            controller.isShizukuInstalled.value ? 'INSTALLED / DETECTED' : 'NOT INSTALLED',
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
                title: const Text('Wireless ADB Pairing Guide', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                children: const [
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. Go to Developer Options -> enable "Wireless debugging".'),
                        SizedBox(height: 6),
                        Text('2. Tap "Pair device with pairing code". Note the IP, Port & 6-digit Wi-Fi PIN.'),
                        SizedBox(height: 6),
                        Text('3. On your PC terminal, run:'),
                        SizedBox(height: 4),
                        SelectableText(
                          'adb pair <IP>:<PORT> <PIN>\nadb connect <IP>:<DEBUG_PORT>',
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
            const SectionHeader(title: '📜 System Logcat Viewer'),
            Card(
              color: Colors.black.withOpacity(0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Filter logcat (e.g. Activity, Error, Fatal)...',
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
                          return const Center(child: Text('No log output or filtered out', style: TextStyle(color: Colors.grey)));
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
                                fontSize: 10,
                                height: 1.3,
                                color: isError ? Colors.redAccent : Colors.white70,
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
