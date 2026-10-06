import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:android_toolbox/main.dart';
import 'package:android_toolbox/app/core/services/system_tools_service.dart';
import 'package:android_toolbox/app/core/services/web_server_service.dart';
import 'package:android_toolbox/app/core/services/clipboard_storage_service.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '.';
      },
    );

    const systemToolsChannel = MethodChannel('com.toolbox.android/system_tools');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      systemToolsChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getInstalledPackages') return [];
        if (methodCall.method == 'getAdvancedBatteryInfo') {
          return {
            'level': 85,
            'temperature': 31.5,
            'voltage': 4200,
            'technology': 'Li-ion',
            'health': 'Good',
            'plugged': 'AC Charger',
            'currentNow': 1500000,
            'capacity': 85,
          };
        }
        if (methodCall.method == 'isShizukuInstalled') return false;
        if (methodCall.method == 'getDangerousPermissionsAudit') return [];
        return null;
      },
    );

    await GetStorage.init();
    Get.put(SystemToolsService());
    Get.put(WebServerService());
    Get.put(ClipboardStorageService());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Android Toolbox smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AndroidToolboxApp());
    await tester.pump();
    expect(find.text('ANDROID TOOLBOX'), findsOneWidget);
  });
}
