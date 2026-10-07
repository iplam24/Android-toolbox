import 'dart:async';
import 'package:get/get.dart';
import '../../../core/services/system_tools_service.dart';
import '../../../data/models/battery_info_model.dart';

class BatteryController extends GetxController {
  final systemTools = SystemToolsService.to;

  final Rx<BatteryInfoModel?> batteryInfo = Rx<BatteryInfoModel?>(null);
  final RxBool isLoading = true.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    loadBattery();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => loadBattery());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> loadBattery() async {
    final info = await systemTools.getAdvancedBatteryInfo();
    if (info != null) {
      batteryInfo.value = info;
    }
    isLoading.value = false;
  }

  String get pluggedText {
    final b = batteryInfo.value;
    if (b == null) return 'Không rõ';
    if (!b.isCharging) {
      if (b.status.toLowerCase() == 'full' || b.level >= 100) return 'PIN ĐẦY (100%)';
      return 'ĐANG DÙNG PIN';
    }
    final p = b.plugged.toLowerCase();
    if (p.contains('ac')) return 'SẠC AC (CỦ SẠC)';
    if (p.contains('usb')) return 'SẠC USB (MÁY TÍNH)';
    if (p.contains('wireless')) return 'SẠC KHÔNG DÂY';
    return 'ĐANG SẠC PIN';
  }

  String get healthText {
    final b = batteryInfo.value;
    if (b == null) return 'Tốt';
    final h = b.health.toLowerCase();
    if (h.contains('good')) return 'Tốt';
    if (h.contains('overheat')) return 'Quá nhiệt';
    if (h.contains('dead')) return 'Hỏng cell';
    if (h.contains('over_voltage')) return 'Quá điện áp';
    if (h.contains('unspecified_failure')) return 'Lỗi nguồn';
    if (h.contains('cold')) return 'Quá lạnh';
    return b.health;
  }
}
