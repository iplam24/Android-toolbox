import 'dart:async';
import 'dart:io';
import 'package:get/get.dart' hide Response;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:path_provider/path_provider.dart';

class WebShareFileInfo {
  final String name;
  final String path;
  final int sizeBytes;
  final String formattedSize;
  final DateTime modified;
  final String category; // 'image', 'video', 'audio', 'doc', 'archive', 'other'

  const WebShareFileInfo({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.formattedSize,
    required this.modified,
    required this.category,
  });

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String detectCategory(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp', 'heic'].contains(ext)) return 'image';
    if (['mp4', 'mkv', 'mov', 'avi', 'webm', '3gp'].contains(ext)) return 'video';
    if (['mp3', 'm4a', 'wav', 'flac', 'aac', 'ogg'].contains(ext)) return 'audio';
    if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(ext)) return 'doc';
    if (['zip', 'rar', '7z', 'tar', 'gz', 'apk'].contains(ext)) return 'archive';
    return 'other';
  }
}

class IncomingFilePrompt {
  final String id;
  final String fileName;
  final int sizeBytes;
  final String formattedSize;
  final String clientIp;
  final String requestedFolder;
  final String tempFilePath;
  final Completer<String?> decisionCompleter; // returns destination folder path or null if rejected

  IncomingFilePrompt({
    required this.id,
    required this.fileName,
    required this.sizeBytes,
    required this.formattedSize,
    required this.clientIp,
    required this.requestedFolder,
    required this.tempFilePath,
    required this.decisionCompleter,
  });
}

class WebServerService extends GetxService {
  static WebServerService get to => Get.find();

  HttpServer? _server;
  final RxBool isRunning = false.obs;
  final RxString serverUrl = ''.obs;
  final RxInt transferredFiles = 0.obs;

  // Settings
  final RxBool askBeforeSave = true.obs;
  final RxString defaultTargetFolder = 'download_webshare'.obs;

  // Active incoming file prompt for phone dialog
  final Rx<IncomingFilePrompt?> activePrompt = Rx<IncomingFilePrompt?>(null);

  final RxList<String> sharedFilesList = <String>[].obs;
  final RxList<WebShareFileInfo> sharedFilesDetails = <WebShareFileInfo>[].obs;

  Directory? _primaryDir;

  @override
  void onInit() {
    super.onInit();
    _initStorageDirectories();
  }

  Future<void> _initStorageDirectories() async {
    try {
      final defaultDir = await resolveFolder(defaultTargetFolder.value);
      _primaryDir = defaultDir;
      await refreshFilesList();
    } catch (e) {
      print('Error init directories: $e');
    }
  }

  Future<Directory> resolveFolder(String folderKey) async {
    String subPath;
    switch (folderKey.toLowerCase()) {
      case 'downloads':
      case 'download':
        subPath = '/sdcard/Download';
        break;
      case 'pictures':
      case 'images':
        subPath = '/sdcard/Pictures';
        break;
      case 'movies':
      case 'videos':
        subPath = '/sdcard/Movies';
        break;
      case 'music':
      case 'audio':
        subPath = '/sdcard/Music';
        break;
      case 'documents':
      case 'docs':
        subPath = '/sdcard/Documents';
        break;
      case 'download_webshare':
      default:
        subPath = '/sdcard/Download/WebShare';
        break;
    }

    final dir = Directory(subPath);
    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
      } catch (_) {
        final ext = await getExternalStorageDirectory();
        final fallback = Directory('${ext?.path ?? (await getApplicationDocumentsDirectory()).path}/WebShare');
        if (!await fallback.exists()) await fallback.create(recursive: true);
        return fallback;
      }
    }
    return dir;
  }

  Future<Directory> _getStagingDir() async {
    final cache = await getTemporaryDirectory();
    final staging = Directory('${cache.path}/webshare_staging');
    if (!await staging.exists()) {
      await staging.create(recursive: true);
    }
    return staging;
  }

  Future<void> refreshFilesList() async {
    try {
      final dir = _primaryDir ?? await resolveFolder(defaultTargetFolder.value);
      if (!await dir.exists()) return;

      final entities = dir.listSync();
      final files = entities.whereType<File>().toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      final names = <String>[];
      final details = <WebShareFileInfo>[];

      for (final f in files) {
        final name = f.uri.pathSegments.last;
        final size = f.lengthSync();
        final mod = f.lastModifiedSync();
        names.add(name);
        details.add(WebShareFileInfo(
          name: name,
          path: f.path,
          sizeBytes: size,
          formattedSize: WebShareFileInfo.formatBytes(size),
          modified: mod,
          category: WebShareFileInfo.detectCategory(name),
        ));
      }

      sharedFilesList.value = names;
      sharedFilesDetails.value = details;
    } catch (e) {
      print('Error refresh files: $e');
    }
  }

  Future<bool> deleteFile(String fileName) async {
    try {
      final dir = _primaryDir ?? await resolveFolder(defaultTargetFolder.value);
      final file = File('${dir.path}/$fileName');
      if (await file.exists()) {
        await file.delete();
        await refreshFilesList();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> moveFile(String fileName, String destinationFolderKey) async {
    try {
      final sourceDir = _primaryDir ?? await resolveFolder(defaultTargetFolder.value);
      final sourceFile = File('${sourceDir.path}/$fileName');
      if (!await sourceFile.exists()) return false;

      final destDir = await resolveFolder(destinationFolderKey);
      final destFile = File('${destDir.path}/$fileName');
      await sourceFile.rename(destFile.path);

      await refreshFilesList();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Answer incoming file prompt from Phone UI
  void answerIncomingFilePrompt(IncomingFilePrompt prompt, bool accept, {String? targetFolderKey}) async {
    if (!accept) {
      try {
        final temp = File(prompt.tempFilePath);
        if (await temp.exists()) await temp.delete();
      } catch (_) {}
      prompt.decisionCompleter.complete(null);
      activePrompt.value = null;
      return;
    }

    try {
      final key = targetFolderKey ?? prompt.requestedFolder;
      final targetDir = await resolveFolder(key);
      final finalFile = File('${targetDir.path}/${prompt.fileName}');

      final temp = File(prompt.tempFilePath);
      if (await temp.exists()) {
        // Copy then delete in case of cross-volume move
        await temp.copy(finalFile.path);
        await temp.delete();
      }

      prompt.decisionCompleter.complete(targetDir.path);
      transferredFiles.value++;
      await refreshFilesList();
    } catch (e) {
      print('Error saving accepted file: $e');
      prompt.decisionCompleter.complete(null);
    } finally {
      activePrompt.value = null;
    }
  }

  Future<bool> startServer({int port = 8080}) async {
    if (isRunning.value) return true;

    try {
      await _initStorageDirectories();
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

      // API list of files
      router.get('/api/files', (Request request) async {
        await refreshFilesList();
        final list = sharedFilesDetails.map((f) => {
          'name': f.name,
          'size': f.sizeBytes,
          'formattedSize': f.formattedSize,
          'category': f.category,
          'modified': f.modified.toIso8601String(),
        }).toList();

        return Response.ok(
          '{"status": "ok", "files": ${list.map((e) => '{"name": "${e['name']}", "size": ${e['size']}, "formattedSize": "${e['formattedSize']}", "category": "${e['category']}"}').toList()}}',
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      // File download
      router.get('/download/<fileName>', (Request request, String fileName) async {
        try {
          final decodedName = Uri.decodeComponent(fileName);
          final dir = _primaryDir ?? await resolveFolder(defaultTargetFolder.value);
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

      // Delete file via Web API
      router.delete('/api/files/<fileName>', (Request request, String fileName) async {
        try {
          final decodedName = Uri.decodeComponent(fileName);
          final ok = await deleteFile(decodedName);
          if (ok) {
            return Response.ok('{"status": "ok", "message": "Deleted $decodedName"}',
                headers: {'content-type': 'application/json; charset=utf-8'});
          } else {
            return Response.notFound('{"status": "error", "message": "File not found"}');
          }
        } catch (e) {
          return Response.internalServerError(body: '{"status": "error", "message": "$e"}');
        }
      });

      // File upload handler with Destination and Confirmation
      router.post('/upload', (Request request) async {
        try {
          final queryParams = request.url.queryParameters;
          String rawName = queryParams['filename'] ?? 'file_${DateTime.now().millisecondsSinceEpoch}.bin';
          final decodedName = Uri.decodeComponent(rawName);
          final safeName = decodedName.split(RegExp(r'[/\\]')).last.replaceAll(RegExp(r'[*?"<>|:]'), '_');
          final finalName = safeName.isEmpty ? 'upload_${DateTime.now().millisecondsSinceEpoch}.bin' : safeName;

          final requestedFolder = queryParams['folder'] ?? defaultTargetFolder.value;
          final clientIp = (request.context['shelf.io.connection_info'] as dynamic)?.remoteAddress?.address ?? 'Thiết bị Web';

          // First stream file to staging/cache
          final stagingDir = await _getStagingDir();
          final stagingFile = File('${stagingDir.path}/${DateTime.now().millisecondsSinceEpoch}_$finalName');
          final sink = stagingFile.openWrite();

          int totalBytes = 0;
          try {
            await for (final chunk in request.read()) {
              sink.add(chunk);
              totalBytes += chunk.length;
            }
            await sink.flush();
          } finally {
            await sink.close();
          }

          final formattedSize = WebShareFileInfo.formatBytes(totalBytes);

          // If user configured to ask before saving on phone:
          if (askBeforeSave.value) {
            final completer = Completer<String?>();
            final prompt = IncomingFilePrompt(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              fileName: finalName,
              sizeBytes: totalBytes,
              formattedSize: formattedSize,
              clientIp: clientIp,
              requestedFolder: requestedFolder,
              tempFilePath: stagingFile.path,
              decisionCompleter: completer,
            );

            // Present prompt to phone user
            activePrompt.value = prompt;

            // Wait for phone response with 60 seconds timeout
            final savedPath = await completer.future.timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                activePrompt.value = null;
                try {
                  stagingFile.deleteSync();
                } catch (_) {}
                return null;
              },
            );

            if (savedPath != null) {
              return Response.ok(
                '{"status": "ok", "message": "Đã được điện thoại chấp nhận và lưu vào $savedPath", "folder": "$savedPath"}',
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            } else {
              return Response.forbidden(
                '{"status": "rejected", "message": "Người dùng điện thoại đã từ chối nhận tệp tin này hoặc hết thời gian chờ."}',
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }
          } else {
            // Auto-save directly to target folder
            final destDir = await resolveFolder(requestedFolder);
            final destFile = File('${destDir.path}/$finalName');
            await stagingFile.copy(destFile.path);
            await stagingFile.delete();

            transferredFiles.value++;
            await refreshFilesList();

            return Response.ok(
              '{"status": "ok", "message": "Tải lên thành công!", "folder": "${destDir.path}"}',
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
        } catch (e, stack) {
          print('Upload error in WebServer: $e\n$stack');
          return Response.internalServerError(
            body: '{"status": "error", "message": "$e"}',
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
      });

      // Global CORS Middleware
      Handler corsMiddleware(Handler innerHandler) {
        return (Request req) async {
          if (req.method == 'OPTIONS') {
            return Response.ok('', headers: {
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
              'Access-Control-Allow-Headers': '*',
            });
          }
          final res = await innerHandler(req);
          return res.change(headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
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
    activePrompt.value = null;
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
    } catch (_) {
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
  <title>Android Toolbox • Web Share Studio</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --primary: #3B82F6;
      --primary-hover: #2563EB;
      --cyan: #06B6D4;
      --accent: linear-gradient(135deg, #3B82F6 0%, #06B6D4 100%);
      --bg: #0A0F1D;
      --card-bg: rgba(17, 24, 39, 0.75);
      --card-border: rgba(255, 255, 255, 0.08);
      --text: #F3F4F6;
      --text-muted: #9CA3AF;
      --success: #10B981;
      --danger: #EF4444;
      --warning: #F59E0B;
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    body {
      font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background-color: var(--bg);
      background-image: 
        radial-gradient(circle at 15% 15%, rgba(59, 130, 246, 0.12) 0%, transparent 40%),
        radial-gradient(circle at 85% 85%, rgba(6, 182, 212, 0.08) 0%, transparent 40%);
      background-attachment: fixed;
      color: var(--text);
      min-height: 100vh;
      padding: 32px 16px;
      display: flex;
      justify-content: center;
    }
    .wrapper {
      width: 100%;
      max-width: 860px;
    }
    .glass-card {
      background: var(--card-bg);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      border: 1px solid var(--card-border);
      border-radius: 20px;
      padding: 26px;
      margin-bottom: 24px;
      box-shadow: 0 10px 30px -10px rgba(0, 0, 0, 0.5);
    }
    .header-bar {
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 16px;
      margin-bottom: 28px;
    }
    .brand-title {
      font-size: 26px;
      font-weight: 800;
      letter-spacing: -0.5px;
      background: var(--accent);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .badge-online {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: rgba(16, 185, 129, 0.12);
      border: 1px solid rgba(16, 185, 129, 0.3);
      padding: 6px 14px;
      border-radius: 9999px;
      font-size: 13px;
      font-weight: 600;
      color: #34D399;
    }
    .dot-pulse {
      width: 8px;
      height: 8px;
      background: #10B981;
      border-radius: 50%;
      box-shadow: 0 0 10px #10B981;
      animation: pulse 1.8s infinite;
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.4; transform: scale(0.85); }
    }
    .section-title {
      font-size: 17px;
      font-weight: 700;
      margin-bottom: 6px;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .section-subtitle {
      font-size: 13px;
      color: var(--text-muted);
      margin-bottom: 18px;
    }
    .form-group {
      margin-bottom: 18px;
    }
    .form-label {
      display: block;
      font-size: 13px;
      font-weight: 600;
      color: var(--text-muted);
      margin-bottom: 8px;
    }
    .select-folder {
      width: 100%;
      background: #1E293B;
      color: #F8FAFC;
      border: 1px solid rgba(255, 255, 255, 0.12);
      padding: 12px 16px;
      border-radius: 12px;
      font-size: 14px;
      font-weight: 600;
      font-family: inherit;
      outline: none;
      cursor: pointer;
      transition: all 0.2s;
    }
    .select-folder:focus {
      border-color: var(--cyan);
      box-shadow: 0 0 0 3px rgba(6, 182, 212, 0.2);
    }
    .drop-zone {
      border: 2px dashed rgba(59, 130, 246, 0.5);
      background: rgba(59, 130, 246, 0.03);
      border-radius: 18px;
      padding: 38px 20px;
      text-align: center;
      cursor: pointer;
      transition: all 0.25s ease;
      position: relative;
    }
    .drop-zone:hover, .drop-zone.active {
      border-color: var(--cyan);
      background: rgba(6, 182, 212, 0.08);
      transform: translateY(-2px);
    }
    .cloud-icon {
      width: 56px;
      height: 56px;
      margin: 0 auto 12px auto;
      color: var(--cyan);
      display: block;
    }
    .btn-browse {
      background: var(--accent);
      color: white;
      border: none;
      padding: 10px 22px;
      border-radius: 12px;
      font-size: 14px;
      font-weight: 700;
      cursor: pointer;
      margin-top: 14px;
      display: inline-block;
      box-shadow: 0 4px 14px rgba(59, 130, 246, 0.4);
      transition: all 0.2s;
    }
    .btn-browse:hover {
      opacity: 0.92;
      transform: translateY(-1px);
    }
    .upload-queue {
      margin-top: 20px;
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    .queue-item {
      background: rgba(30, 41, 59, 0.6);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 14px;
      padding: 14px 18px;
    }
    .queue-meta {
      display: flex;
      justify-content: space-between;
      font-size: 13px;
      margin-bottom: 8px;
      font-weight: 600;
    }
    .progress-bar-bg {
      height: 7px;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 99px;
      overflow: hidden;
    }
    .progress-bar-fill {
      height: 100%;
      background: var(--accent);
      width: 0%;
      transition: width 0.15s ease;
    }
    .queue-status {
      font-size: 12px;
      margin-top: 6px;
      color: var(--text-muted);
    }
    .file-tabs {
      display: flex;
      gap: 8px;
      overflow-x: auto;
      padding-bottom: 12px;
      margin-bottom: 16px;
    }
    .tab-btn {
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(255, 255, 255, 0.08);
      color: var(--text-muted);
      padding: 7px 14px;
      border-radius: 10px;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      white-space: nowrap;
      transition: all 0.2s;
    }
    .tab-btn.active, .tab-btn:hover {
      background: rgba(59, 130, 246, 0.2);
      border-color: rgba(59, 130, 246, 0.5);
      color: white;
    }
    .file-list {
      display: flex;
      flex-direction: column;
      gap: 10px;
    }
    .file-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      background: rgba(30, 41, 59, 0.5);
      border: 1px solid rgba(255, 255, 255, 0.06);
      border-radius: 14px;
      padding: 12px 18px;
      transition: background 0.2s;
    }
    .file-row:hover {
      background: rgba(30, 41, 59, 0.85);
    }
    .file-left {
      display: flex;
      align-items: center;
      gap: 14px;
      min-width: 0;
    }
    .file-icon-box {
      width: 40px;
      height: 40px;
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 20px;
      background: rgba(59, 130, 246, 0.15);
      flex-shrink: 0;
    }
    .file-details {
      min-width: 0;
    }
    .file-name {
      font-size: 14px;
      font-weight: 700;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      max-width: 480px;
    }
    .file-sub {
      font-size: 12px;
      color: var(--text-muted);
      margin-top: 2px;
    }
    .file-actions {
      display: flex;
      gap: 8px;
      flex-shrink: 0;
    }
    .btn-download {
      background: rgba(6, 182, 212, 0.15);
      color: #22D3EE;
      border: 1px solid rgba(6, 182, 212, 0.3);
      padding: 6px 14px;
      border-radius: 9px;
      font-size: 13px;
      font-weight: 600;
      text-decoration: none;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s;
    }
    .btn-download:hover {
      background: var(--cyan);
      color: #0A0F1D;
    }
    .btn-delete {
      background: rgba(239, 68, 68, 0.12);
      color: #F87171;
      border: 1px solid rgba(239, 68, 68, 0.3);
      padding: 6px 10px;
      border-radius: 9px;
      font-size: 13px;
      cursor: pointer;
      transition: all 0.2s;
    }
    .btn-delete:hover {
      background: var(--danger);
      color: white;
    }
    .empty-state {
      text-align: center;
      padding: 40px 16px;
      color: var(--text-muted);
      font-size: 14px;
    }
    @media (max-width: 640px) {
      .file-name { max-width: 200px; }
      body { padding: 16px 8px; }
      .glass-card { padding: 18px; }
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <!-- Header -->
    <div class="header-bar">
      <div class="brand-title">
        <span>⚡</span> Android Toolbox
      </div>
      <div class="badge-online">
        <div class="dot-pulse"></div>
        <span>Đã kết nối trực tiếp qua LAN</span>
      </div>
    </div>

    <!-- Upload Card -->
    <div class="glass-card">
      <div class="section-title">📤 Gửi tệp sang điện thoại</div>
      <div class="section-subtitle">Tệp sẽ được nạp trực tiếp qua Wi-Fi nội bộ tốc độ cao mà không tốn dung lượng 4G</div>

      <!-- Destination Folder Selector -->
      <div class="form-group">
        <label class="form-label">📁 Chọn thư mục lưu trên điện thoại:</label>
        <select id="folderSelect" class="select-folder">
          <option value="download_webshare" selected>📁 Thư mục WebShare (Download/WebShare) - Khuyên dùng</option>
          <option value="download">📥 Thư mục Tải về gốc (/sdcard/Download)</option>
          <option value="pictures">🖼️ Thư viện Ảnh (/sdcard/Pictures)</option>
          <option value="movies">🎬 Video & Phim (/sdcard/Movies)</option>
          <option value="music">🎵 Âm nhạc & Nhạc chuông (/sdcard/Music)</option>
          <option value="documents">📄 Tài liệu (/sdcard/Documents)</option>
        </select>
      </div>

      <!-- Drop Zone -->
      <div class="drop-zone" id="dropZone" onclick="document.getElementById('fileInput').click()">
        <svg class="cloud-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"></path>
        </svg>
        <div style="font-size: 16px; font-weight: 700;">Kéo & Thả tệp vào đây</div>
        <div style="font-size: 13px; color: var(--text-muted); margin-top: 4px;">Hỗ trợ ảnh, video, tài liệu, nhạc, file nén ZIP, APK...</div>
        <button class="btn-browse" type="button">Chọn tệp từ máy tính</button>
        <input type="file" id="fileInput" multiple style="display: none;" onchange="handleFileSelect(this.files)">
      </div>

      <!-- Upload Queue Visualizer -->
      <div id="uploadQueue" class="upload-queue"></div>
    </div>

    <!-- Explorer Card -->
    <div class="glass-card">
      <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; margin-bottom: 16px;">
        <div>
          <div class="section-title">📥 Tệp có sẵn trên điện thoại</div>
          <div class="section-subtitle" style="margin-bottom: 0;">Nhấn tải về máy tính hoặc quản lý tệp trực tiếp</div>
        </div>
        <button class="tab-btn" onclick="fetchFilesList()">🔄 Làm mới danh sách</button>
      </div>

      <!-- Category Filter Tabs -->
      <div class="file-tabs">
        <button class="tab-btn active" onclick="setCategoryFilter('all', this)">Tất cả</button>
        <button class="tab-btn" onclick="setCategoryFilter('image', this)">🖼️ Hình ảnh</button>
        <button class="tab-btn" onclick="setCategoryFilter('video', this)">🎬 Video</button>
        <button class="tab-btn" onclick="setCategoryFilter('doc', this)">📄 Tài liệu</button>
        <button class="tab-btn" onclick="setCategoryFilter('archive', this)">📦 APK & Nén</button>
      </div>

      <!-- Files List -->
      <div id="fileListContainer" class="file-list">
        <div class="empty-state">Đang tải danh sách tệp...</div>
      </div>
    </div>
  </div>

  <script>
    let currentCategory = 'all';
    let allFiles = [];

    const dropZone = document.getElementById('dropZone');
    const folderSelect = document.getElementById('folderSelect');
    const queueContainer = document.getElementById('uploadQueue');
    const listContainer = document.getElementById('fileListContainer');

    // Drag and Drop
    ['dragenter', 'dragover'].forEach(name => {
      dropZone.addEventListener(name, (e) => {
        e.preventDefault();
        dropZone.classList.add('active');
      });
    });

    ['dragleave', 'drop'].forEach(name => {
      dropZone.addEventListener(name, (e) => {
        e.preventDefault();
        dropZone.classList.remove('active');
      });
    });

    dropZone.addEventListener('drop', (e) => {
      if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
        handleFileSelect(e.dataTransfer.files);
      }
    });

    function handleFileSelect(files) {
      if (!files || files.length === 0) return;
      for (let i = 0; i < files.length; i++) {
        uploadSingleFile(files[i]);
      }
    }

    function uploadSingleFile(file) {
      const folder = folderSelect.value;
      const itemId = 'queue_' + Date.now() + '_' + Math.random().toString(36).substring(2, 6);

      const itemEl = document.createElement('div');
      itemEl.className = 'queue-item';
      itemEl.id = itemId;
      itemEl.innerHTML = `
        <div class="queue-meta">
          <span style="max-width: 480px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">📄 \${file.name}</span>
          <span id="\${itemId}_pct" style="color: var(--cyan);">0%</span>
        </div>
        <div class="progress-bar-bg">
          <div class="progress-bar-fill" id="\${itemId}_bar"></div>
        </div>
        <div class="queue-status" id="\${itemId}_status">Đang kết nối tới điện thoại...</div>
      `;
      queueContainer.prepend(itemEl);

      const statusEl = document.getElementById(itemId + '_status');
      const pctEl = document.getElementById(itemId + '_pct');
      const barEl = document.getElementById(itemId + '_bar');

      const xhr = new XMLHttpRequest();
      const url = '/upload?filename=' + encodeURIComponent(file.name) + '&folder=' + encodeURIComponent(folder);
      xhr.open('POST', url, true);

      let startTime = Date.now();

      xhr.upload.onprogress = function(e) {
        if (e.lengthComputable) {
          const pct = Math.round((e.loaded / e.total) * 100);
          pctEl.textContent = pct + '%';
          barEl.style.width = pct + '%';

          const elapsedSec = (Date.now() - startTime) / 1000;
          const speedMb = elapsedSec > 0 ? (e.loaded / (1024 * 1024) / elapsedSec).toFixed(1) : 0;
          const loadedMb = (e.loaded / (1024 * 1024)).toFixed(1);
          const totalMb = (e.total / (1024 * 1024)).toFixed(1);

          if (pct < 100) {
            statusEl.textContent = 'Đang tải lên: ' + loadedMb + 'MB / ' + totalMb + 'MB (' + speedMb + ' MB/s)';
          } else {
            statusEl.textContent = '⏳ Đã truyền tải xong! Đang chờ điện thoại xác nhận lưu...';
            statusEl.style.color = 'var(--warning)';
          }
        }
      };

      xhr.onload = function() {
        if (xhr.status >= 200 && xhr.status < 300) {
          barEl.style.width = '100%';
          pctEl.textContent = '100%';
          pctEl.style.color = 'var(--success)';
          statusEl.style.color = 'var(--success)';
          statusEl.textContent = '✅ Đã được điện thoại chấp nhận và lưu thành công!';
          fetchFilesList();
        } else if (xhr.status === 403) {
          statusEl.style.color = 'var(--danger)';
          statusEl.textContent = '❌ Người dùng điện thoại đã từ chối nhận tệp này.';
        } else {
          statusEl.style.color = 'var(--danger)';
          statusEl.textContent = '❌ Lỗi tải lên (Mã lỗi ' + xhr.status + '): ' + xhr.responseText;
        }
      };

      xhr.onerror = function() {
        statusEl.style.color = 'var(--danger)';
        statusEl.textContent = '❌ Lỗi kết nối mạng tới điện thoại!';
      };

      xhr.send(file);
    }

    async function fetchFilesList() {
      try {
        const res = await fetch('/api/files');
        const data = await res.json();
        allFiles = data.files || [];
        renderFileList();
      } catch (err) {
        listContainer.innerHTML = '<div class="empty-state">Không thể kết nối lấy danh sách tệp: ' + err.message + '</div>';
      }
    }

    function setCategoryFilter(cat, btn) {
      currentCategory = cat;
      document.querySelectorAll('.file-tabs .tab-btn').forEach(b => b.classList.remove('active'));
      if (btn) btn.classList.add('active');
      renderFileList();
    }

    function renderFileList() {
      const filtered = currentCategory === 'all' 
        ? allFiles 
        : allFiles.filter(f => f.category === currentCategory);

      if (filtered.length === 0) {
        listContainer.innerHTML = '<div class="empty-state">Chưa có tệp nào trong mục này.</div>';
        return;
      }

      listContainer.innerHTML = filtered.map(f => {
        let icon = '📄';
        if (f.category === 'image') icon = '🖼️';
        if (f.category === 'video') icon = '🎬';
        if (f.category === 'audio') icon = '🎵';
        if (f.category === 'doc') icon = '📑';
        if (f.category === 'archive') icon = '📦';

        const encoded = encodeURIComponent(f.name);
        return `
          <div class="file-row">
            <div class="file-left">
              <div class="file-icon-box">\${icon}</div>
              <div class="file-details">
                <div class="file-name" title="\${f.name}">\${f.name}</div>
                <div class="file-sub">\${f.formattedSize}</div>
              </div>
            </div>
            <div class="file-actions">
              <a class="btn-download" href="/download/\${encoded}" download="\${f.name}">
                <span>Tải về</span>
              </a>
              <button class="btn-delete" onclick="deleteRemoteFile('\${encoded}')" title="Xóa tệp khỏi điện thoại">🗑️</button>
            </div>
          </div>
        `;
      }).join('');
    }

    async function deleteRemoteFile(encodedName) {
      if (!confirm('Bạn có chắc muốn xóa tệp này trên điện thoại?')) return;
      try {
        const res = await fetch('/api/files/' + encodedName, { method: 'DELETE' });
        if (res.ok) {
          fetchFilesList();
        } else {
          alert('Không thể xóa tệp');
        }
      } catch (e) {
        alert('Lỗi: ' + e.message);
      }
    }

    // Initial load
    fetchFilesList();
  </script>
</body>
</html>
''';
  }
}
