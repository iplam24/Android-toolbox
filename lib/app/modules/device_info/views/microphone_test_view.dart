import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/services/system_tools_service.dart';

class MicrophoneTestView extends StatefulWidget {
  const MicrophoneTestView({super.key});

  @override
  State<MicrophoneTestView> createState() => _MicrophoneTestViewState();
}

class _MicrophoneTestViewState extends State<MicrophoneTestView> {
  final systemTools = SystemToolsService.to;

  bool isRecording = false;
  bool isPlayingRecorded = false;
  bool hasRecordedFile = false;
  int countdownSeconds = 0;
  double currentDb = 0.0;
  double maxDb = 0.0;
  String testResultNote = '';

  Timer? _pollingTimer;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    if (isRecording) {
      systemTools.stopRecordingMic();
    }
    super.dispose();
  }

  Future<void> _startRecordingTest() async {
    final path = await systemTools.startRecordingMic();
    if (path == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể truy cập Microphone. Vui lòng kiểm tra quyền ghi âm!')),
        );
      }
      return;
    }

    setState(() {
      isRecording = true;
      hasRecordedFile = false;
      countdownSeconds = 5;
      maxDb = 0.0;
      testResultNote = 'Hãy nói hoặc vỗ tay gần micro...';
    });

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      final amp = await systemTools.getMaxMicAmplitude();
      if (mounted && isRecording) {
        double db = 0.0;
        if (amp > 0) {
          // Approximate dB scale 0 to 90 dB
          db = (20 * (log(amp) / ln10)).clamp(0.0, 95.0);
        }
        setState(() {
          currentDb = db;
          if (db > maxDb) maxDb = db;
        });
      }
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownSeconds > 1) {
        setState(() {
          countdownSeconds--;
        });
      } else {
        timer.cancel();
        _stopRecordingTest();
      }
    });
  }

  Future<void> _stopRecordingTest() async {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    final path = await systemTools.stopRecordingMic();
    if (mounted) {
      setState(() {
        isRecording = false;
        countdownSeconds = 0;
        currentDb = 0.0;
        hasRecordedFile = path != null;
        if (maxDb >= 60.0) {
          testResultNote = 'Micro hoạt động xuất sắc! Độ nhạy cao (Đỉnh ${maxDb.round()} dB).';
        } else if (maxDb >= 40.0) {
          testResultNote = 'Micro hoạt động bình thường (Đỉnh ${maxDb.round()} dB). Bấm "Nghe lại" để kiểm tra độ trong trẻo.';
        } else {
          testResultNote = 'Âm lượng thu được khá nhỏ (${maxDb.round()} dB). Vui lòng thử nói to hơn hoặc kiểm tra bụi bẩn ở lỗ mic.';
        }
      });
    }
  }

  Future<void> _playRecording() async {
    setState(() {
      isPlayingRecorded = true;
    });
    final ok = await systemTools.playRecordedMic();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể phát lại đoạn ghi âm')),
      );
    }
    // Auto reset play state after 5.5 seconds
    Future.delayed(const Duration(milliseconds: 5500), () {
      if (mounted) {
        setState(() {
          isPlayingRecorded = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (currentDb / 90.0).clamp(0.0, 1.0);
    final dbColor = currentDb > 70 ? Colors.red : (currentDb > 45 ? Colors.green : Colors.blue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm tra Micro & Đo âm lượng'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Banner Hướng dẫn
            Card(
              color: Colors.deepPurple.withOpacity(0.08),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mic_external_on_rounded, color: Colors.deepPurple, size: 20),
                        SizedBox(width: 8),
                        Text('HƯỚNG DẪN KIỂM TRA MICRO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepPurple)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Bấm nút "BẮT ĐẦU GHI ÂM (5S)" và nói thử một câu ("Alo 1 2 3 4...").\n'
                      '2. Quan sát thanh đo biên độ Decibel (dB) theo thời gian thực.\n'
                      '3. Sau 5 giây, bấm nút "NGHE LẠI ĐOẠN GHI ÂM" để trực tiếp thẩm định âm thanh qua loa ngoài xem có bị nghẹt tiếng hay rè không.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Live Decibel Meter Hero Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('BIÊN ĐỘ ÂM THANH THỜI GIAN THỰC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currentDb.toStringAsFixed(1),
                          style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: isRecording ? dbColor : Colors.grey),
                        ),
                        const SizedBox(width: 6),
                        const Text('dB', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isRecording ? 'Đang ghi âm... Còn $countdownSeconds giây (Đỉnh: ${maxDb.toStringAsFixed(1)} dB)' : 'Sẵn sàng ghi âm thử nghiệm',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isRecording ? Colors.amber : Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 14,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(dbColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0 dB (Im lặng)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text('45 dB (Trò chuyện)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text('90+ dB (Rất lớn)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isRecording ? _stopRecordingTest : _startRecordingTest,
                icon: Icon(isRecording ? Icons.stop_rounded : Icons.mic_rounded),
                label: Text(
                  isRecording ? 'DỪNG GHI ÂM NGAY' : 'BẮT ĐẦU GHI ÂM (5 GIÂY)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRecording ? Colors.red : Colors.deepPurple,
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (hasRecordedFile)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: isPlayingRecorded ? null : _playRecording,
                  icon: Icon(isPlayingRecorded ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded),
                  label: Text(
                    isPlayingRecorded ? 'ĐANG PHÁT LẠI ÂM THANH...' : 'NGHE LẠI ĐOẠN GHI ÂM VỪA THU',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Test Note Card
            if (testResultNote.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.green.withOpacity(0.4), width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          testResultNote,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
