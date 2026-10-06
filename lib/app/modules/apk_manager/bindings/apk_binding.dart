import 'package:get/get.dart';
import '../controllers/apk_controller.dart';

class ApkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApkController>(() => ApkController());
  }
}
