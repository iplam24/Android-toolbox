import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/system_tools_service.dart';

class DnsPreset {
  final String name;
  final String hostname;
  final String description;
  final String tag;
  final IconData icon;
  final Color color;

  const DnsPreset({
    required this.name,
    required this.hostname,
    required this.description,
    required this.tag,
    required this.icon,
    required this.color,
  });
}

class NetworkController extends GetxController {
  final systemTools = SystemToolsService.to;

  final RxString localIp = 'Đang tải...'.obs;
  final RxList<Map<String, String>> interfacesList = <Map<String, String>>[].obs;

  // Ping Tool State
  final pingTargetController = TextEditingController(text: '8.8.8.8');
  final RxBool isPinging = false.obs;
  final RxList<int> pingHistory = <int>[].obs;
  final RxString pingStatus = 'Sẵn sàng'.obs;

  // Port Scanner State
  final portTargetController = TextEditingController(text: '127.0.0.1');
  final RxBool isScanningPorts = false.obs;
  final RxList<Map<String, dynamic>> scannedPorts = <Map<String, dynamic>>[].obs;

  // Private DNS Presets
  final List<DnsPreset> dnsPresets = const [
    DnsPreset(
      name: 'AdGuard DNS',
      hostname: 'dns.adguard-dns.com',
      description: 'Chặn toàn bộ banner quảng cáo, pop-up, tracker theo dõi trên mọi ứng dụng và trình duyệt',
      tag: 'Chặn QC',
      icon: Icons.block_rounded,
      color: Colors.green,
    ),
    DnsPreset(
      name: 'AdGuard Family',
      hostname: 'family.adguard-dns.com',
      description: 'Chặn quảng cáo, tìm kiếm an toàn và tự động chặn web độc hại, bảo vệ gia đình',
      tag: 'Gia đình',
      icon: Icons.family_restroom_rounded,
      color: Colors.teal,
    ),
    DnsPreset(
      name: 'Cloudflare 1.1.1.1',
      hostname: 'one.one.one.one',
      description: 'Tốc độ phản hồi cực nhanh, mã hóa DNS bảo mật quyền riêng tư, không lưu lịch sử',
      tag: 'Tốc độ cao',
      icon: Icons.bolt_rounded,
      color: Colors.orange,
    ),
    DnsPreset(
      name: 'Cloudflare Security',
      hostname: 'security.cloudflare-dns.com',
      description: 'Tự động chặn truy cập vào các tên miền độc hại, phần mềm tống tiền và phishing',
      tag: 'Chống mã độc',
      icon: Icons.security_rounded,
      color: Colors.deepOrange,
    ),
    DnsPreset(
      name: 'Google DNS',
      hostname: 'dns.google',
      description: 'Hạ tầng máy chủ toàn cầu, phân giải tên miền ổn định, tương thích tuyệt đối',
      tag: 'Ổn định',
      icon: Icons.public_rounded,
      color: Colors.blue,
    ),
    DnsPreset(
      name: 'Quad9 DNS',
      hostname: 'dns.quad9.net',
      description: 'Chặn mã độc từ liên minh bảo mật toàn cầu, phi lợi nhuận và tôn trọng quyền riêng tư',
      tag: 'Bảo mật',
      icon: Icons.verified_user_rounded,
      color: Colors.purple,
    ),
  ];

  // DNS Benchmark State
  final RxBool isBenchmarkingDns = false.obs;
  final RxList<Map<String, dynamic>> dnsBenchmarkResults = <Map<String, dynamic>>[].obs;
  final RxString dnsBenchmarkSummary = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadNetworkInfo();
  }

  @override
  void onClose() {
    pingTargetController.dispose();
    portTargetController.dispose();
    super.onClose();
  }

  Future<void> loadNetworkInfo() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      final list = <Map<String, String>>[];
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          list.add({
            'name': iface.name,
            'address': addr.address,
            'host': addr.host,
          });
        }
      }

      interfacesList.value = list;
      if (list.isNotEmpty) {
        localIp.value = list.first['address'] ?? '127.0.0.1';
        portTargetController.text = localIp.value;
      } else {
        localIp.value = 'Ngoại tuyến / Chưa kết nối Wi-Fi';
      }
    } catch (e) {
      localIp.value = 'Lỗi: $e';
    }
  }

  Future<void> startPing() async {
    if (isPinging.value) return;
    isPinging.value = true;
    pingHistory.clear();
    final target = pingTargetController.text.trim();
    pingStatus.value = 'Đang gửi gói tin tới $target...';

    for (int i = 0; i < 5; i++) {
      final stopwatch = Stopwatch()..start();
      try {
        final socket = await Socket.connect(target, 53, timeout: const Duration(milliseconds: 1500));
        stopwatch.stop();
        socket.destroy();
        pingHistory.add(stopwatch.elapsedMilliseconds);
      } catch (_) {
        // Fallback test via http connect
        try {
          final socket = await Socket.connect(target, 80, timeout: const Duration(milliseconds: 1500));
          stopwatch.stop();
          socket.destroy();
          pingHistory.add(stopwatch.elapsedMilliseconds);
        } catch (_) {
          pingHistory.add(999); // timeout marker
        }
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }

    final validPings = pingHistory.where((p) => p < 999).toList();
    if (validPings.isNotEmpty) {
      final avg = (validPings.reduce((a, b) => a + b) / validPings.length).round();
      pingStatus.value = 'Độ trễ trung bình: ${avg}ms (nhận ${validPings.length}/5 gói)';
    } else {
      pingStatus.value = 'Không thể kết nối đích / Mất gói 100% (Hết thời gian chờ)';
    }

    isPinging.value = false;
  }

  Future<void> scanPorts() async {
    if (isScanningPorts.value) return;
    isScanningPorts.value = true;
    scannedPorts.clear();

    final target = portTargetController.text.trim();

    final commonPorts = [
      {'port': 21, 'service': 'FTP'},
      {'port': 22, 'service': 'SSH'},
      {'port': 53, 'service': 'DNS'},
      {'port': 80, 'service': 'HTTP Web'},
      {'port': 443, 'service': 'HTTPS Bảo mật'},
      {'port': 5555, 'service': 'ADB Không dây'},
      {'port': 8080, 'service': 'Máy chủ Web / Proxy'},
      {'port': 8888, 'service': 'HTTP Thay thế'},
      {'port': 9000, 'service': 'Cổng Dev'},
    ];

    for (final item in commonPorts) {
      final int port = item['port'] as int;
      final String svc = item['service'] as String;

      bool isOpen = false;
      try {
        final socket = await Socket.connect(target, port, timeout: const Duration(milliseconds: 300));
        isOpen = true;
        socket.destroy();
      } catch (_) {
        isOpen = false;
      }

      scannedPorts.add({
        'port': port,
        'service': svc,
        'isOpen': isOpen,
      });
    }

    isScanningPorts.value = false;
  }

  Future<void> openPrivateDnsSettings() async {
    final success = await systemTools.openPrivateDnsSettings();
    if (!success) {
      Get.snackbar(
        'Không thể mở',
        'Vui lòng vào Cài đặt -> Mạng & Internet -> DNS riêng tư trên điện thoại',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void copyDnsHostname(DnsPreset preset) {
    Clipboard.setData(ClipboardData(text: preset.hostname));
    Get.snackbar(
      'Đã sao chép Hostname DNS',
      'Đã copy "${preset.hostname}". Hãy bấm "Mở cài đặt DNS" để dán vào cấu hình máy!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          openPrivateDnsSettings();
        },
        child: const Text('MỞ CÀI ĐẶT', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> runDnsBenchmark() async {
    if (isBenchmarkingDns.value) return;
    isBenchmarkingDns.value = true;
    dnsBenchmarkResults.clear();
    dnsBenchmarkSummary.value = 'Đang kiểm tra độ trễ phân giải DNS...';

    final testDomains = [
      {'domain': 'google.com', 'name': 'Google Global'},
      {'domain': 'cloudflare.com', 'name': 'Cloudflare CDN'},
      {'domain': 'vnexpress.net', 'name': 'Báo VNExpress'},
      {'domain': 'youtube.com', 'name': 'YouTube Stream'},
      {'domain': 'github.com', 'name': 'GitHub Developer'},
      {'domain': 'facebook.com', 'name': 'Facebook Meta'},
    ];

    int totalMs = 0;
    int successCount = 0;

    for (final item in testDomains) {
      final domain = item['domain']!;
      final name = item['name']!;
      final sw = Stopwatch()..start();
      try {
        final addresses = await InternetAddress.lookup(domain);
        sw.stop();
        final ms = sw.elapsedMilliseconds;
        totalMs += ms;
        successCount++;
        dnsBenchmarkResults.add({
          'domain': domain,
          'name': name,
          'latencyMs': ms,
          'ip': addresses.isNotEmpty ? addresses.first.address : 'OK',
          'success': true,
        });
      } catch (e) {
        sw.stop();
        dnsBenchmarkResults.add({
          'domain': domain,
          'name': name,
          'latencyMs': 999,
          'ip': 'Lỗi phân giải',
          'success': false,
        });
      }
      await Future.delayed(const Duration(milliseconds: 150));
    }

    if (successCount > 0) {
      final avg = (totalMs / successCount).round();
      final rating = avg < 25
          ? 'Cực nhanh (< 25ms)'
          : (avg < 60 ? 'Rất tốt (25-60ms)' : (avg < 120 ? 'Bình thường' : 'Chậm (> 120ms)'));
      dnsBenchmarkSummary.value = 'Độ trễ trung bình: ${avg}ms • Đánh giá: $rating';
    } else {
      dnsBenchmarkSummary.value = 'Không thể phân giải tên miền. Vui lòng kiểm tra lại mạng.';
    }

    isBenchmarkingDns.value = false;
  }
}

