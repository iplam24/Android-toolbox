import 'dart:async';
import 'dart:io';
import 'package:get/get.dart' hide Response;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:path_provider/path_provider.dart';

class WebShareFileInfo {
  final String name;
  final int sizeBytes;
  final String formattedSize;

  const WebShareFileInfo({
    required this.name,
    required this.sizeBytes,
    required this.formattedSize,
  });

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class WebServerService extends GetxService {
  static WebServerService get to => Get.find();

  HttpServer? _server;
  final RxBool isRunning = false.obs;
  final RxString serverUrl = ''.obs;
  final RxInt transferredFiles = 0.obs;
  final RxList<String> sharedFilesList = <String>[].obs;
  final RxList<WebShareFileInfo> sharedFilesDetails = <WebShareFileInfo>[].obs;

  Directory? _transferDir;

  @override
  void onInit() {
    super.onInit();
    _initTransferDir();
  }

  Future<Directory> getTransferDir() async {
    if (_transferDir != null && await _transferDir!.exists()) {
      return _transferDir!;
    }
    return await _initTransferDir();
  }

  Future<Directory> _initTransferDir() async {
    Directory dir;
    // Try public Download folder first for easy user access
    try {
      final publicDownload = Directory('/sdcard/Download/WebShare');
      if (!await publicDownload.exists()) {
        await publicDownload.create(recursive: true);
      }
      if (await publicDownload.exists()) {
        dir = publicDownload;
        _transferDir = dir;
        await _refreshFilesList();
        return dir;
      }
    } catch (_) {}

    // Fallback to app external files dir or internal docs
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        dir = Directory('${extDir.path}/WebShare');
      } else {
        final docs = await getApplicationDocumentsDirectory();
        dir = Directory('${docs.path}/WebShare');
      }
    } catch (_) {
      final docs = await getApplicationDocumentsDirectory();
      dir = Directory('${docs.path}/WebShare');
    }

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _transferDir = dir;
    await _refreshFilesList();
    return dir;
  }

  Future<void> _refreshFilesList() async {
    try {
      if (_transferDir == null || !await _transferDir!.exists()) return;
      final entities = _transferDir!.listSync();
      final files = entities.whereType<File>().toList();

      final names = <String>[];
      final details = <WebShareFileInfo>[];

      for (final f in files) {
        final name = f.uri.pathSegments.last;
        final size = f.lengthSync();
        names.add(name);
        details.add(WebShareFileInfo(
          name: name,
          sizeBytes: size,
          formattedSize: WebShareFileInfo.formatBytes(size),
        ));
      }

      sharedFilesList.value = names;
      sharedFilesDetails.value = details;
    } catch (e) {
      print('Error refresh files list: $e');
    }
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
        return Response.ok(html, headers: {
          'content-type': 'text/html; charset=utf-8',
          'cache-control': 'no-cache, no-store, must-revalidate',
        });
      });

      // API files list
      router.get('/api/files', (Request request) {
        final list = sharedFilesDetails.map((f) => {
          'name': f.name,
          'size': f.sizeBytes,
          'formattedSize': f.formattedSize,
        }).toList();
        return Response.ok(
          '{"files": ${list.map((e) => '{"name": "${e['name']}", "formattedSize": "${e['formattedSize']}"}').toList()}}',
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      // File download
      router.get('/download/<fileName>', (Request request, String fileName) async {
        try {
          final decodedName = Uri.decodeComponent(fileName);
          final dir = await getTransferDir();
          final file = File('${dir.path}/$decodedName');
          if (await file.exists()) {
            final stream = file.openRead();
            final length = await file.length();
            return Response.ok(stream, headers: {
              'content-type': 'application/octet-stream',
              'content-disposition': 'attachment; filename="$decodedName"; filename*=UTF-8\'\'${Uri.encodeComponent(decodedName)}',
              'content-length': length.toString(),
            });
          }
          return Response.notFound('Không tìm thấy tệp tin: $decodedName');
        } catch (e) {
          return Response.internalServerError(body: 'Lỗi tải tệp: $e');
        }
      });

      // File upload handler (Stream-safe)
      router.post('/upload', (Request request) async {
        try {
          final dir = await getTransferDir();
          final queryParams = request.url.queryParameters;
          String rawName = queryParams['filename'] ?? 'uploaded_${DateTime.now().millisecondsSinceEpoch}.bin';
          final decodedName = Uri.decodeComponent(rawName);
          final safeName = decodedName.split(RegExp(r'[/\\]')).last.replaceAll(RegExp(r'[*?"<>|:]'), '_');
          final finalName = safeName.isEmpty ? 'upload_${DateTime.now().millisecondsSinceEpoch}.bin' : safeName;

          final targetFile = File('${dir.path}/$finalName');
          final sink = targetFile.openWrite();

          try {
            await for (final chunk in request.read()) {
              sink.add(chunk);
            }
            await sink.flush();
          } finally {
            await sink.close();
          }

          transferredFiles.value++;
          await _refreshFilesList();

          return Response.ok(
            '{"status": "ok", "message": "Uploaded $finalName"}',
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } catch (e, stack) {
          print('Upload error in WebServer: $e\n$stack');
          return Response.internalServerError(
            body: '{"status": "error", "message": "$e"}',
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
      });

      // CORS Preflight & headers middleware
      Handler corsMiddleware(Handler innerHandler) {
        return (Request req) async {
          if (req.method == 'OPTIONS') {
            return Response.ok('', headers: {
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
              'Access-Control-Allow-Headers': '*',
            });
          }
          final res = await innerHandler(req);
          return res.change(headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': '*',
          });
        };
      }

      final handler = const Pipeline()
          .addMiddleware((inner) => corsMiddleware(inner))
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
          if (!addr.isLoopback && (addr.address.startsWith('192.168.') ||
              addr.address.startsWith('10.') ||
              addr.address.startsWith('172.'))) {
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
    final fileRows = sharedFilesDetails.map((f) {
      final escaped = f.name.replaceAll('"', '&quot;');
      final encodedUri = Uri.encodeComponent(f.name);
      return '''
        <li class="file-item">
          <div class="file-info">
            <span class="file-icon">📄</span>
            <div>
              <div class="file-name" title="$escaped">${f.name}</div>
              <div class="file-size">${f.formattedSize}</div>
            </div>
          </div>
          <a class="download-link" href="/download/$encodedUri" download="$escaped">Tải về</a>
        </li>
      ''';
    }).join('\n');

    return '''
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Android Toolbox • Chia sẻ tệp Web</title>
  <style>
    :root {
      --primary: #007AFF;
      --primary-hover: #0056b3;
      --bg: #0B0F19;
      --card: #151D2C;
      --border: #26334D;
      --text: #F8FAFC;
      --text-muted: #94A3B8;
      --success: #34C759;
      --danger: #FF3B30;
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
      margin-bottom: 24px;
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
      padding: 32px 20px;
      text-align: center;
      cursor: pointer;
      background: rgba(0, 122, 255, 0.03);
      transition: all 0.2s ease;
      position: relative;
    }
    .upload-zone:hover, .upload-zone.dragover {
      background: rgba(0, 122, 255, 0.12);
      border-color: #00E5FF;
      transform: scale(1.01);
    }
    .file-input {
      display: none;
    }
    .btn {
      background: var(--primary);
      color: white;
      border: none;
      padding: 8px 16px;
      border-radius: 10px;
      font-weight: 600;
      cursor: pointer;
      display: inline-block;
      transition: background 0.2s;
    }
    .btn:hover {
      background: var(--primary-hover);
    }
    .progress-bar-container {
      display: none;
      width: 100%;
      height: 8px;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 4px;
      overflow: hidden;
      margin-top: 14px;
    }
    .progress-bar-fill {
      width: 0%;
      height: 100%;
      background: linear-gradient(90deg, #007AFF, #00E5FF);
      transition: width 0.1s ease;
    }
    .status-text {
      font-size: 13px;
      color: var(--text-muted);
      margin-top: 12px;
      font-weight: 500;
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
      padding: 12px 14px;
      border-bottom: 1px solid var(--border);
    }
    .file-item:last-child {
      border-bottom: none;
    }
    .file-info {
      display: flex;
      align-items: center;
      gap: 12px;
      overflow: hidden;
      padding-right: 12px;
    }
    .file-icon {
      font-size: 22px;
    }
    .file-name {
      font-weight: 600;
      font-size: 14px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      max-width: 440px;
    }
    .file-size {
      font-size: 12px;
      color: var(--text-muted);
      margin-top: 2px;
    }
    .download-link {
      background: rgba(0, 122, 255, 0.15);
      color: #5AC8FA;
      text-decoration: none;
      padding: 6px 14px;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 600;
      white-space: nowrap;
      transition: all 0.2s;
    }
    .download-link:hover {
      background: var(--primary);
      color: white;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 class="title">⚡ Chia sẻ tệp Web nội bộ</h1>
      <p style="margin: 0; color: var(--text-muted); font-size: 14px;">Truyền tệp tức thì qua Wi-Fi giữa Điện thoại và Máy tính</p>
    </div>

    <div class="card">
      <h3 style="margin-top: 0;">📤 Tải tệp lên điện thoại</h3>
      <div class="upload-zone" id="uploadZone" onclick="document.getElementById('fileUpload').click()">
        <p style="margin: 0; font-size: 16px; font-weight: 600;">Kéo thả tệp vào đây hoặc bấm để chọn tệp</p>
        <p style="margin: 6px 0 0 0; font-size: 13px; color: var(--text-muted);">Tệp sẽ được lưu trực tiếp vào thư mục WebShare của điện thoại</p>
        <input type="file" id="fileUpload" class="file-input" onchange="if(this.files.length) uploadSelectedFile(this.files[0])">
      </div>
      <div class="progress-bar-container" id="progressBarContainer">
        <div class="progress-bar-fill" id="progressBarFill"></div>
      </div>
      <p id="uploadStatus" class="status-text"></p>
    </div>

    <div class="card">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
        <h3 style="margin: 0;">📥 Tệp có sẵn trên điện thoại (${sharedFilesDetails.length})</h3>
        <button class="btn" onclick="location.reload()">Làm mới</button>
      </div>
      <ul class="file-list" id="fileListContainer">
        ${sharedFilesDetails.isEmpty ? '<li style="color: var(--text-muted); padding: 16px; text-align: center;">Chưa có tệp nào được tải lên.</li>' : fileRows}
      </ul>
    </div>
  </div>

  <script>
    const dropZone = document.getElementById('uploadZone');
    const statusEl = document.getElementById('uploadStatus');
    const progressContainer = document.getElementById('progressBarContainer');
    const progressFill = document.getElementById('progressBarFill');

    dropZone.addEventListener('dragover', (e) => {
      e.preventDefault();
      dropZone.classList.add('dragover');
    });

    dropZone.addEventListener('dragleave', () => {
      dropZone.classList.remove('dragover');
    });

    dropZone.addEventListener('drop', (e) => {
      e.preventDefault();
      dropZone.classList.remove('dragover');
      if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
        uploadSelectedFile(e.dataTransfer.files[0]);
      }
    });

    function uploadSelectedFile(file) {
      if (!file) return;

      progressContainer.style.display = 'block';
      progressFill.style.width = '0%';
      statusEl.style.color = 'var(--text-muted)';
      statusEl.textContent = 'Đang bắt đầu tải lên: ' + file.name + '...';

      const xhr = new XMLHttpRequest();
      const url = '/upload?filename=' + encodeURIComponent(file.name);
      xhr.open('POST', url, true);

      xhr.upload.onprogress = function(e) {
        if (e.lengthComputable) {
          const percent = Math.round((e.loaded / e.total) * 100);
          progressFill.style.width = percent + '%';
          const loadedMb = (e.loaded / (1024 * 1024)).toFixed(1);
          const totalMb = (e.total / (1024 * 1024)).toFixed(1);
          statusEl.textContent = 'Đang tải lên: ' + file.name + ' • ' + percent + '% (' + loadedMb + ' MB / ' + totalMb + ' MB)';
        }
      };

      xhr.onload = function() {
        if (xhr.status >= 200 && xhr.status < 300) {
          progressFill.style.width = '100%';
          statusEl.style.color = 'var(--success)';
          statusEl.textContent = '✅ Đã tải lên thành công: ' + file.name + '!';
          setTimeout(() => location.reload(), 1000);
        } else {
          statusEl.style.color = 'var(--danger)';
          statusEl.textContent = '❌ Tải lên thất bại (Mã lỗi ' + xhr.status + '): ' + xhr.responseText;
        }
      };

      xhr.onerror = function() {
        statusEl.style.color = 'var(--danger)';
        statusEl.textContent = '❌ Lỗi kết nối mạng tới máy chủ điện thoại!';
      };

      xhr.send(file);
    }
  </script>
</body>
</html>
''';
  }
}
