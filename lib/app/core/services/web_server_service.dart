import 'dart:async';
import 'dart:io';
import 'package:get/get.dart' hide Response;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:path_provider/path_provider.dart';

class WebServerService extends GetxService {
  static WebServerService get to => Get.find();

  HttpServer? _server;
  final RxBool isRunning = false.obs;
  final RxString serverUrl = ''.obs;
  final RxInt transferredFiles = 0.obs;
  final RxList<String> sharedFilesList = <String>[].obs;

  Directory? _transferDir;

  @override
  void onInit() {
    super.onInit();
    _initTransferDir();
  }

  Future<void> _initTransferDir() async {
    try {
      final extDir = await getExternalStorageDirectory();
      final dir = Directory('${extDir?.path ?? (await getApplicationDocumentsDirectory()).path}/WebShare');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _transferDir = dir;
      _refreshFilesList();
    } catch (e) {
      print('Error init transfer dir: $e');
    }
  }

  Future<void> _refreshFilesList() async {
    if (_transferDir == null || !await _transferDir!.exists()) return;
    final entities = _transferDir!.listSync();
    sharedFilesList.value = entities
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList();
  }

  Future<bool> startServer({int port = 8080}) async {
    if (isRunning.value) return true;

    try {
      await _initTransferDir();
      final localIp = await getLocalIpAddress();

      final router = Router();

      // Home portal page
      router.get('/', (Request request) {
        final html = _generateWebPortalHtml();
        return Response.ok(html, headers: {'content-type': 'text/html; charset=utf-8'});
      });

      // API files list
      router.get('/api/files', (Request request) {
        final files = sharedFilesList.toList();
        return Response.ok('{"files": ${files.map((e) => '"$e"').toList()}}',
            headers: {'content-type': 'application/json'});
      });

      // File download
      router.get('/download/<fileName>', (Request request, String fileName) async {
        final file = File('${_transferDir!.path}/$fileName');
        if (await file.exists()) {
          final stream = file.openRead();
          final length = await file.length();
          return Response.ok(stream, headers: {
            'content-type': 'application/octet-stream',
            'content-disposition': 'attachment; filename="$fileName"',
            'content-length': length.toString(),
          });
        }
        return Response.notFound('Không tìm thấy tệp tin');
      });

      // File upload handler
      router.post('/upload', (Request request) async {
        try {
          final queryParams = request.url.queryParameters;
          final fileName = queryParams['filename'] ?? 'uploaded_${DateTime.now().millisecondsSinceEpoch}.bin';
          final targetFile = File('${_transferDir!.path}/$fileName');
          final sink = targetFile.openWrite();
          await request.read().pipe(sink);
          await sink.close();

          transferredFiles.value++;
          await _refreshFilesList();

          return Response.ok('{"status": "ok", "message": "Uploaded $fileName"}',
              headers: {'content-type': 'application/json'});
        } catch (e) {
          return Response.internalServerError(body: '{"error": "$e"}');
        }
      });

      final handler = const Pipeline()
          .addMiddleware(logRequests())
          .addHandler(router.call);

      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
      isRunning.value = true;
      serverUrl.value = 'http://$localIp:$port';
      return true;
    } catch (e) {
      print('Error starting Web Server: $e');
      isRunning.value = false;
      return false;
    }
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    isRunning.value = false;
    serverUrl.value = '';
  }

  Future<String> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.168.') ||
              addr.address.startsWith('10.') ||
              addr.address.startsWith('172.')) {
            return addr.address;
          }
        }
      }
      return '127.0.0.1';
    } catch (e) {
      return '127.0.0.1';
    }
  }

  String _generateWebPortalHtml() {
    return '''
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Hộp Công Cụ Android • Chia sẻ tệp Web</title>
  <style>
    :root {
      --primary: #007AFF;
      --bg: #0B0F19;
      --card: #151D2C;
      --border: #26334D;
      --text: #F8FAFC;
      --text-muted: #94A3B8;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      margin: 0;
      padding: 24px;
      display: flex;
      justify-content: center;
    }
    .container {
      width: 100%;
      max-width: 720px;
    }
    .header {
      text-align: center;
      margin-bottom: 32px;
      padding: 24px;
      background: linear-gradient(135deg, rgba(0, 122, 255, 0.15), rgba(0, 229, 255, 0.05));
      border: 1px solid var(--border);
      border-radius: 20px;
    }
    .title {
      font-size: 26px;
      font-weight: 800;
      margin: 0 0 8px 0;
      background: linear-gradient(90deg, #007AFF, #00E5FF);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .card {
      background-color: var(--card);
      border: 1px solid var(--border);
      border-radius: 18px;
      padding: 24px;
      margin-bottom: 24px;
    }
    .upload-zone {
      border: 2px dashed #007AFF;
      border-radius: 14px;
      padding: 32px;
      text-align: center;
      cursor: pointer;
      background: rgba(0, 122, 255, 0.03);
      transition: all 0.2s ease;
    }
    .upload-zone:hover {
      background: rgba(0, 122, 255, 0.08);
    }
    .file-input {
      display: none;
    }
    .btn {
      background: var(--primary);
      color: white;
      border: none;
      padding: 10px 20px;
      border-radius: 10px;
      font-weight: 600;
      cursor: pointer;
      display: inline-block;
      margin-top: 12px;
    }
    .file-list {
      list-style: none;
      padding: 0;
      margin: 0;
    }
    .file-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px 16px;
      border-bottom: 1px solid var(--border);
    }
    .file-item:last-child {
      border-bottom: none;
    }
    .download-link {
      background: rgba(0, 122, 255, 0.15);
      color: #5AC8FA;
      text-decoration: none;
      padding: 6px 14px;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 600;
    }
    .status-text {
      font-size: 13px;
      color: var(--text-muted);
      margin-top: 8px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 class="title">⚡ Chia sẻ tệp Web nội bộ</h1>
      <p style="margin: 0; color: var(--text-muted); font-size: 14px;">Truyền tệp tức thì qua mạng Wi-Fi giữa Điện thoại và Máy tính</p>
    </div>

    <div class="card">
      <h3 style="margin-top: 0;">📤 Tải tệp lên điện thoại</h3>
      <div class="upload-zone" onclick="document.getElementById('fileUpload').click()">
        <p style="margin: 0; font-size: 16px; font-weight: 600;">Kéo thả tệp vào đây hoặc bấm để chọn tệp</p>
        <p style="margin: 4px 0 0 0; font-size: 13px; color: var(--text-muted);">Tệp sẽ được lưu trực tiếp vào thư mục WebShare của điện thoại</p>
        <input type="file" id="fileUpload" class="file-input" onchange="uploadSelectedFile(this.files[0])">
      </div>
      <p id="uploadStatus" class="status-text"></p>
    </div>

    <div class="card">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
        <h3 style="margin: 0;">📥 Tệp có sẵn trên điện thoại</h3>
        <button class="btn" style="margin: 0; padding: 6px 12px; font-size: 12px;" onclick="location.reload()">Làm mới</button>
      </div>
      <ul class="file-list" id="fileListContainer">
        ${sharedFilesList.isEmpty ? '<li style="color: var(--text-muted); padding: 16px; text-align: center;">Chưa có tệp nào được tải lên.</li>' : sharedFilesList.map((f) => '<li class="file-item"><span>📄 $f</span><a class="download-link" href="/download/${Uri.encodeComponent(f)}">Tải về</a></li>').join('')}
      </ul>
    </div>
  </div>

  <script>
    async function uploadSelectedFile(file) {
      if (!file) return;
      const statusEl = document.getElementById('uploadStatus');
      statusEl.textContent = 'Đang tải lên ' + file.name + '...';
      try {
        const response = await fetch('/upload?filename=' + encodeURIComponent(file.name), {
          method: 'POST',
          body: file
        });
        if (response.ok) {
          statusEl.textContent = '✅ Đã tải lên ' + file.name + ' thành công!';
          setTimeout(() => location.reload(), 1000);
        } else {
          statusEl.textContent = '❌ Tải lên thất bại!';
        }
      } catch (err) {
        statusEl.textContent = '❌ Lỗi: ' + err.message;
      }
    }
  </script>
</body>
</html>
''';
  }
}
