import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/system_tools_service.dart';

class SpeakerWaterEjectView extends StatefulWidget {
  const SpeakerWaterEjectView({super.key});

  @override
  State<SpeakerWaterEjectView> createState() => _SpeakerWaterEjectViewState();
}

class _SpeakerWaterEjectViewState extends State<SpeakerWaterEjectView> with SingleTickerProviderStateMixin {
  final systemTools = SystemToolsService.to;

  bool isPlaying = false;
  double frequency = 165.0;
  String selectedChannel = 'both'; // 'both', 'left', 'right'
  int remainingSeconds = 0;
  Timer? _countdownTimer;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animController.dispose();
    if (isPlaying) {
      systemTools.stopTone();
    }
    super.dispose();
  }

  Future<void> _startWaterEject() async {
    setState(() {
      isPlaying = true;
      remainingSeconds = 12;
    });

    await systemTools.playTone(
      frequency: frequency,
      durationMs: remainingSeconds * 1000,
      channel: selectedChannel,
    );

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 1) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        _stopWaterEject();
      }
    });
  }

  Future<void> _stopWaterEject() async {
    _countdownTimer?.cancel();
    await systemTools.stopTone();
    if (mounted) {
      setState(() {
        isPlaying = false;
        remainingSeconds = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đẩy nước loa & Test Stereo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Banner Hướng dẫn
            Card(
              color: Colors.blue.withOpacity(0.08),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.waves_rounded, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('CƠ CHẾ ĐẨY NƯỚC BẰNG SÓNG ÂM 165Hz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sóng âm tần số thấp 165Hz tạo ra áp lực dao động không khí cực mạnh lên màng loa, '
                      'đẩy các giọt nước li ti kẹt trong màng lưới loa ra ngoài sau khi đi mưa hoặc rơi vào nước.\n'
                      '⚠️ Lưu ý: Hãy tăng âm lượng máy lên 100% và hướng màng loa xuống dưới khi chạy!',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Animated Speaker Visualizer
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final scale = isPlaying ? 1.0 + (_animController.value * 0.18) : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isPlaying
                            ? [Colors.blueAccent, Colors.cyan, AppColors.toolsColor]
                            : [Colors.grey.shade700, Colors.grey.shade900],
                      ),
                      boxShadow: isPlaying
                          ? [
                              BoxShadow(
                                color: Colors.cyan.withOpacity(0.5),
                                blurRadius: 30 * _animController.value + 10,
                                spreadRadius: 8 * _animController.value + 2,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      isPlaying ? Icons.air_rounded : Icons.volume_up_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            if (isPlaying)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyan),
                ),
                child: Text(
                  'ĐANG PHÁT SÓNG ÂM... CÒN $remainingSeconds GIÂY',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan, fontSize: 13),
                ),
              ),
            const SizedBox(height: 24),

            // Tùy chọn Kênh loa (Stereo Left / Right / Both)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('KÊNH ÂM THANH (TEST LOA)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildChannelOption('both', 'Cả 2 loa (Stereo)', Icons.speaker_group_rounded),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildChannelOption('left', 'Chỉ Loa Trái', Icons.speaker_phone_rounded),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildChannelOption('right', 'Chỉ Loa Phải', Icons.speaker_phone_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Frequency Slider
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TẦN SỐ SÓNG ÂM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text('${frequency.round()} Hz', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.toolsColor)),
                      ],
                    ),
                    Slider(
                      value: frequency,
                      min: 100.0,
                      max: 300.0,
                      divisions: 40,
                      label: '${frequency.round()} Hz',
                      onChanged: isPlaying
                          ? null
                          : (val) {
                              setState(() {
                                frequency = val;
                              });
                            },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('100 Hz', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        TextButton(
                          onPressed: isPlaying
                              ? null
                              : () {
                                  setState(() {
                                    frequency = 165.0;
                                  });
                                },
                          child: const Text('Mặc định: 165 Hz (Chuẩn đẩy nước)', style: TextStyle(fontSize: 11)),
                        ),
                        const Text('300 Hz', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isPlaying ? _stopWaterEject : _startWaterEject,
                icon: Icon(isPlaying ? Icons.stop_rounded : Icons.waves_rounded),
                label: Text(
                  isPlaying ? 'DỪNG ĐẨY NƯỚC' : 'BẮT ĐẦU ĐẨY NƯỚC LOA (12S)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPlaying ? Colors.red : Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelOption(String channelKey, String title, IconData icon) {
    final isSelected = selectedChannel == channelKey;
    return InkWell(
      onTap: isPlaying
          ? null
          : () {
              setState(() {
                selectedChannel = channelKey;
              });
            },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.toolsColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.toolsColor : Colors.grey.withOpacity(0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.toolsColor : Colors.grey),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.toolsColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
