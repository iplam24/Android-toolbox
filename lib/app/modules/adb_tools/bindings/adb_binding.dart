import 'package:get/get.dart';
import '../controllers/adb_controller.dart';

class AdbBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdbController>(() => AdbController());
  }
}
