import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MultiTouchTestView extends StatefulWidget {
  const MultiTouchTestView({super.key});

  @override
  State<MultiTouchTestView> createState() => _MultiTouchTestViewState();
}

class _MultiTouchTestViewState extends State<MultiTouchTestView> {
  final Map<int, Offset> activePointers = {};
  int maxPointersRecorded = 0;

  final List<Color> touchColors = [
    Colors.redAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.amberAccent,
    Colors.purpleAccent,
    Colors.cyanAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
    Colors.limeAccent,
    Colors.tealAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerDown: (event) {
          setState(() {
            activePointers[event.pointer] = event.position;
            if (activePointers.length > maxPointersRecorded) {
              maxPointersRecorded = activePointers.length;
            }
          });
        },
        onPointerMove: (event) {
          setState(() {
            activePointers[event.pointer] = event.position;
          });
        },
        onPointerUp: (event) {
          setState(() {
            activePointers.remove(event.pointer);
          });
        },
        onPointerCancel: (event) {
          setState(() {
            activePointers.remove(event.pointer);
          });
        },
        child: Stack(
          children: [
            // Touch points visualization
            ...activePointers.entries.map((entry) {
              final id = entry.key;
              final pos = entry.value;
              final color = touchColors[id % touchColors.length];

              return Positioned(
                left: pos.dx - 45,
                top: pos.dy - 45,
                child: IgnorePointer(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 3),
                      color: color.withOpacity(0.25),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${id % 10 + 1}\n(${pos.dx.toInt()}, ${pos.dy.toInt()})',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: color, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            // HUD Top Bar
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          onPressed: () => Get.back(),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ĐANG CHẠM: ${activePointers.length} ĐIỂM',
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Kỷ lục đa điểm: $maxPointersRecorded ngón tay',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              maxPointersRecorded = 0;
                            });
                          },
                          child: const Text('Đặt lại', style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Hint at bottom
            if (activePointers.isEmpty)
              const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Text(
                    'Chạm nhiều ngón tay cùng lúc lên màn hình để kiểm tra',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
