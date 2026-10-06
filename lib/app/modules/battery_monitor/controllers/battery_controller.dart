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
}
