import 'package:get/get.dart';
import 'app_routes.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';

import '../modules/apk_manager/bindings/apk_binding.dart';
import '../modules/apk_manager/views/apk_view.dart';

import '../modules/clipboard/bindings/clipboard_binding.dart';
import '../modules/clipboard/views/clipboard_view.dart';

import '../modules/qr_tools/bindings/qr_binding.dart';
import '../modules/qr_tools/views/qr_view.dart';

import '../modules/network_tools/bindings/network_binding.dart';
import '../modules/network_tools/views/network_view.dart';

import '../modules/battery_monitor/bindings/battery_binding.dart';
import '../modules/battery_monitor/views/battery_view.dart';

import '../modules/file_transfer/bindings/file_transfer_binding.dart';
import '../modules/file_transfer/views/file_transfer_view.dart';

import '../modules/privacy_audit/bindings/privacy_binding.dart';
import '../modules/privacy_audit/views/privacy_view.dart';

import '../modules/adb_tools/bindings/adb_binding.dart';
import '../modules/adb_tools/views/adb_view.dart';

import '../modules/device_info/bindings/device_info_binding.dart';
import '../modules/device_info/views/device_info_view.dart';

import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';

class AppPages {
  static const INITIAL = AppRoutes.HOME;

  static final routes = [
    GetPage(
      name: AppRoutes.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.APK,
      page: () => const ApkView(),
      binding: ApkBinding(),
    ),
    GetPage(
      name: AppRoutes.CLIPBOARD,
      page: () => const ClipboardView(),
      binding: ClipboardBinding(),
    ),
    GetPage(
      name: AppRoutes.QR,
      page: () => const QrView(),
      binding: QrBinding(),
    ),
    GetPage(
      name: AppRoutes.NETWORK,
      page: () => const NetworkView(),
      binding: NetworkBinding(),
    ),
    GetPage(
      name: AppRoutes.BATTERY,
      page: () => const BatteryView(),
      binding: BatteryBinding(),
    ),
    GetPage(
      name: AppRoutes.FILE_TRANSFER,
      page: () => const FileTransferView(),
      binding: FileTransferBinding(),
    ),
    GetPage(
      name: AppRoutes.PRIVACY,
      page: () => const PrivacyView(),
      binding: PrivacyBinding(),
    ),
    GetPage(
      name: AppRoutes.ADB,
      page: () => const AdbView(),
      binding: AdbBinding(),
    ),
    GetPage(
      name: AppRoutes.DEVICE_INFO,
      page: () => const DeviceInfoView(),
      binding: DeviceInfoBinding(),
    ),
    GetPage(
      name: AppRoutes.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
  ];
}
