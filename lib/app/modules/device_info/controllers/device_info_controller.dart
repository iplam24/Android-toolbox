import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../core/services/system_tools_service.dart';
import '../../../data/models/hardware_info_model.dart';

class DeviceInfoController extends GetxController {
  final systemTools = SystemToolsService.to;

  final Rx<HardwareInfoModel?> hardwareInfo = Rx<HardwareInfoModel?>(null);
  final RxBool isLoading = true.obs;
  final RxBool hasBarometer = false.obs;

  // Real-time Sensor Values
  final RxList<double> accelerometerValues = <double>[0, 0, 0].obs;
  final RxList<double> gyroscopeValues = <double>[0, 0, 0].obs;

  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;

  @override
  void onInit() {
    super.onInit();
    loadHardwareInfo();
    _startSensorStreams();
  }

  @override
  void onClose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    super.onClose();
  }

  Future<void> loadHardwareInfo() async {
    isLoading.value = true;
    try {
      final info = await systemTools.getHardwareDeviceInfo();
      hardwareInfo.value = info;
      hasBarometer.value = await systemTools.hasBarometerSensor();
    } finally {
      isLoading.value = false;
    }
  }

  int _lastAccelTime = 0;
  int _lastGyroTime = 0;

  void _startSensorStreams() {
    try {
      _accelSub = accelerometerEventStream().listen((event) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastAccelTime > 250) {
          _lastAccelTime = now;
          accelerometerValues.value = [event.x, event.y, event.z];
        }
      });
      _gyroSub = gyroscopeEventStream().listen((event) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastGyroTime > 250) {
          _lastGyroTime = now;
          gyroscopeValues.value = [event.x, event.y, event.z];
        }
      });
    } catch (e) {
      print('Sensor error: $e');
    }
  }

  void testVibration() {
    systemTools.vibrate(durationMs: 300);
  }

  void openScreenDeadPixelTest() {
    Get.to(() => const ScreenColorTestView());
  }
}

class ScreenColorTestView extends StatefulWidget {
  const ScreenColorTestView({super.key});

  @override
  State<ScreenColorTestView> createState() => _ScreenColorTestViewState();
}

class _ScreenColorTestViewState extends State<ScreenColorTestView> {
  final List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.white,
    Colors.black,
    Colors.yellow,
    Colors.cyan,
    const Color(0xFFFF00FF),
  ];
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors[currentIndex],
      body: InkWell(
        onTap: () {
          setState(() {
            if (currentIndex < colors.length - 1) {
              currentIndex++;
            } else {
              Get.back();
            }
          });
        },
        child: SizedBox.expand(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Chạm màn hình để đổi màu (${currentIndex + 1}/${colors.length}) • Lần cuối để thoát',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
