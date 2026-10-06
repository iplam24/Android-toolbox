import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NetworkController extends GetxController {
  final RxString localIp = 'Loading...'.obs;
  final RxList<Map<String, String>> interfacesList = <Map<String, String>>[].obs;

  // Ping Tool State
  final pingTargetController = TextEditingController(text: '8.8.8.8');
  final RxBool isPinging = false.obs;
  final RxList<int> pingHistory = <int>[].obs;
  final RxString pingStatus = 'Idle'.obs;

  // Port Scanner State
  final portTargetController = TextEditingController(text: '127.0.0.1');
  final RxBool isScanningPorts = false.obs;
  final RxList<Map<String, dynamic>> scannedPorts = <Map<String, dynamic>>[].obs;

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
        localIp.value = 'Offline / No Wi-Fi';
      }
    } catch (e) {
      localIp.value = 'Error: $e';
    }
  }

  Future<void> startPing() async {
    if (isPinging.value) return;
    isPinging.value = true;
    pingHistory.clear();
    final target = pingTargetController.text.trim();
    pingStatus.value = 'Pinging $target...';

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
      pingStatus.value = 'Average Latency: ${avg}ms (${validPings.length}/5 received)';
    } else {
      pingStatus.value = 'Destination unreachable / 100% loss';
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
      {'port': 80, 'service': 'HTTP'},
      {'port': 443, 'service': 'HTTPS'},
      {'port': 5555, 'service': 'Wireless ADB'},
      {'port': 8080, 'service': 'HTTP Proxy/Web'},
      {'port': 8888, 'service': 'Alt HTTP'},
      {'port': 9000, 'service': 'Dev Server'},
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
}
