import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/usage_guide_sheet.dart';
import '../controllers/network_controller.dart';

const _networkUsageGuide = UsageGuideData(
  title: 'Mạng, DNS riêng tư & Đo độ trễ',
  description: 'Tra cứu IP, đo độ trễ Ping, quét cổng dịch vụ (Port Scanner), danh sách cấu hình DNS riêng tư chặn quảng cáo (Private DNS DoT) và công cụ đo tốc độ phân giải DNS.',
  steps: [
    'Cấu hình DNS riêng tư (Private DNS): Bấm nút "Sao chép" ở một trong các máy chủ DNS (như AdGuard chặn quảng cáo hoặc Cloudflare tốc độ cao), sau đó bấm "Mở cài đặt DNS" để dán tên máy chủ vào mục Private DNS của Android.',
    'Kiểm tra tốc độ phân giải DNS (DNS Benchmark): Bấm "Đo tốc độ DNS" để gửi truy vấn đến loạt tên miền lớn, đo thời gian phản hồi (ms) và xếp loại tốc độ DNS máy bạn đang dùng.',
    'Xem địa chỉ IP nội bộ của máy (Local IP) và danh sách adapter mạng ở thẻ thông tin trên cùng.',
    'Đo Ping độ trễ: Nhập tên miền (VD: google.com) hoặc địa chỉ IP (VD: 8.8.8.8, 1.1.1.1) vào ô kiểm tra rồi bấm nút "Ping" để tính độ trễ trung bình.',
    'Quét cổng dịch vụ (Port Scanner): Nhập địa chỉ IP muốn kiểm tra rồi bấm "Quét cổng" để dò tìm các cổng mạng đang mở.',
  ],
  tips: [
    'Private DNS (DNS over TLS) trên Android mã hóa toàn bộ truy vấn tên miền, giúp ngăn nhà mạng theo dõi và chặn quảng cáo toàn hệ thống.',
    'DNS AdGuard (dns.adguard-dns.com) chặn sạch banner và video quảng cáo trong app mà không hao pin hay cần cài VPN.',
    'Độ trễ phân giải DNS dưới 30ms cho cảm giác lướt web tức thì, mở app không bị khựng.',
  ],
);

class NetworkView extends GetView<NetworkController> {
  const NetworkView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mạng & Ping',
        subtitle: 'Tra cứu IP, đo độ trễ & quét cổng mạng',
        usageGuide: _networkUsageGuide,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới mạng',
            onPressed: () => controller.loadNetworkInfo(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Hướng dẫn cách dùng nhanh
            const UsageGuideBanner(guide: _networkUsageGuide),
            const SizedBox(height: 8),

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
                              const Text('ĐỊA CHỈ IP NỘI BỘ', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
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
                        return const Text('Không phát hiện card mạng nào', style: TextStyle(fontSize: 12, color: Colors.grey));
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
            const SectionHeader(title: '📡 Đo độ trễ & Ping mạng'),
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
                              labelText: 'Máy chủ / IP đích (VD: 8.8.8.8)',
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
                              p >= 999 ? 'Mất gói' : '${p}ms',
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
            const SectionHeader(title: '🔍 Quét cổng dịch vụ (Port Scanner)'),
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
                              labelText: 'Địa chỉ IP cần quét',
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
                              : const Text('Quét cổng'),
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.scannedPorts.isEmpty) {
                        return const Text('Bấm "Quét cổng" để kiểm tra các cổng thông dụng (ADB, Web, SSH, FTP...)', style: TextStyle(fontSize: 12, color: Colors.grey));
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
            const SizedBox(height: 24),

            // Private DNS Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionHeader(title: '🛡️ DNS riêng tư (Chặn quảng cáo)'),
                TextButton.icon(
                  onPressed: () => controller.openPrivateDnsSettings(),
                  icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                  label: const Text('Mở cài đặt DNS', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn máy chủ bên dưới và sao chép Hostname để dán vào mục "DNS riêng tư" (Private DNS) của Android:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 14),
                    ...controller.dnsPresets.map((preset) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: preset.color.withOpacity(0.3), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: preset.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(preset.icon, color: preset.color, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          preset.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: preset.color.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            preset.tag,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: preset.color),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      preset.description,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    preset.hostname,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => controller.copyDnsHostname(preset),
                                  icon: const Icon(Icons.copy_rounded, size: 14),
                                  label: const Text('Sao chép', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // DNS Benchmark Section
            const SectionHeader(title: '⚡ Kiểm tra tốc độ phân giải DNS'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.speed_rounded, color: Colors.amber, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DNS BENCHMARK',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Đo độ trễ phân giải địa chỉ IP qua các tên miền phổ biến',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Obx(() => ElevatedButton(
                          onPressed: controller.isBenchmarkingDns.value ? null : () => controller.runDnsBenchmark(),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
                          child: controller.isBenchmarkingDns.value
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Đo tốc độ DNS'),
                        )),
                      ],
                    ),
                    Obx(() {
                      if (controller.dnsBenchmarkSummary.value.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            controller.dnsBenchmarkSummary.value,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    const SizedBox(height: 12),
                    Obx(() {
                      if (controller.dnsBenchmarkResults.isEmpty) {
                        return const Text(
                          'Bấm "Đo tốc độ DNS" để kiểm tra xem hệ thống DNS hiện tại có phân giải mượt mà không.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      }
                      return Column(
                        children: controller.dnsBenchmarkResults.map((r) {
                          final int ms = r['latencyMs'] as int;
                          final bool success = r['success'] as bool;
                          final Color color = !success || ms >= 999
                              ? Colors.red
                              : (ms < 30 ? Colors.green : (ms < 80 ? Colors.teal : Colors.orange));
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                                      size: 16,
                                      color: color,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      r['name'] ?? '',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${r['domain']})',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: color.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    success ? '${ms}ms' : 'Lỗi',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }
}
