import 'package:get/get.dart';
import '../controllers/battery_controller.dart';

class BatteryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BatteryController>(() => BatteryController());
  }
}
