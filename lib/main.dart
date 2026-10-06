import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/core/constants/app_theme.dart';
import 'app/core/services/clipboard_storage_service.dart';
import 'app/core/services/settings_service.dart';
import 'app/core/services/system_tools_service.dart';
import 'app/core/services/web_server_service.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Storage
  try {
    await GetStorage.init();
  } catch (_) {}

  // Initialize Core Services
  Get.put(SettingsService(), permanent: true);
  Get.put(SystemToolsService(), permanent: true);
  Get.put(WebServerService(), permanent: true);
  Get.put(ClipboardStorageService(), permanent: true);

  runApp(const AndroidToolboxApp());
}

class AndroidToolboxApp extends StatelessWidget {
  const AndroidToolboxApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = Get.find<SettingsService>();
    return Obx(
      () => GetMaterialApp(
        title: 'Android Toolbox',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settingsService.themeMode.value,
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
      ),
    );
  }
}
