import 'package:get/get.dart';
import '../controllers/file_transfer_controller.dart';

class FileTransferBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FileTransferController>(() => FileTransferController());
  }
}
