import 'package:get/get.dart';
import '../../../core/services/system_tools_service.dart';
import '../../../data/models/privacy_audit_model.dart';

class PrivacyController extends GetxController {
  final systemTools = SystemToolsService.to;

  final RxList<PrivacyAuditModel> auditList = <PrivacyAuditModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString selectedFilter = 'all'.obs; // all, High, Medium, Low

  List<PrivacyAuditModel> get filteredList {
    if (selectedFilter.value == 'all') {
      return auditList;
    }
    return auditList.where((a) => a.riskLevel == selectedFilter.value).toList();
  }

  @override
  void onInit() {
    super.onInit();
    runAudit();
  }

  Future<void> runAudit() async {
    isLoading.value = true;
    try {
      final list = await systemTools.getDangerousPermissionsAudit();
      auditList.value = list;
    } finally {
      isLoading.value = false;
    }
  }

  void openAppSettings(String packageName) {
    systemTools.openAppSettings(packageName);
  }
}
