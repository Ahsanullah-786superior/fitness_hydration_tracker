import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An animated, interactive "water bottle" visualizer.
/// - Fill level animates smoothly whenever [progress] changes.
/// - A subtle wave animation runs continuously for a "liquid" feel.
/// - Tapping the visualizer triggers [onTap] (e.g. quick-add a glass).
class WaterVisualizer extends StatefulWidget {
  final double progress; // 0.0 - 1.0+ (can exceed 1 if over goal)
  final int currentMl;
  final int goalMl;
  final VoidCallback? onTap;

  const WaterVisualizer({
    super.key,
    required this.progress,
    required this.currentMl,
    required this.goalMl,
    this.onTap,
  });

  @override
  State<WaterVisualizer> createState() => _WaterVisualizerState();
}

class _WaterVisualizerState extends State<WaterVisualizer>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fillAnimation = Tween<double>(
      begin: 0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(
        CurvedAnimation(parent: _fillController, curve: Curves.easeOutCubic));
    _fillController.forward();
  }

  @override
  void didUpdateWidget(covariant WaterVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _fillAnimation = Tween<double>(
        begin: _fillAnimation.value,
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(
          CurvedAnimation(parent: _fillController, curve: Curves.easeOutCubic));
      _fillController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 180,
        height: 260,
        child: AnimatedBuilder(
          animation: Listenable.merge([_waveController, _fillAnimation]),
          builder: (context, _) {
            return CustomPaint(
              painter: _BottlePainter(
                fill: _fillAnimation.value,
                wavePhase: _waveController.value * 2 * math.pi,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.currentMl} ml',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black38)],
                      ),
                    ),
                    Text(
                      'of ${widget.goalMl} ml',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BottlePainter extends CustomPainter {
  final double fill; // 0.0 - 1.0
  final double wavePhase;

  _BottlePainter({required this.fill, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final bottleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(28),
    );

    // Outline
    final outlinePaint = Paint()
      ..color = Colors.blueGrey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRRect(bottleRect, outlinePaint);

    // Background
    final bgPaint = Paint()..color = Colors.blueGrey.shade50;
    canvas.drawRRect(bottleRect, bgPaint);

    // Clip to bottle shape for the water fill
    canvas.save();
    canvas.clipRRect(bottleRect);

    final waterHeight = size.height * (1 - fill.clamp(0.0, 1.0));

    final wavePaint = Paint()..color = Colors.lightBlue.shade300;
    final wavePath = Path();
    const waveAmplitude = 6.0;
    const waveLength = 60.0;

    wavePath.moveTo(0, waterHeight);
    for (double x = 0; x <= size.width; x++) {
      final y = waterHeight +
          waveAmplitude * math.sin((x / waveLength * 2 * math.pi) + wavePhase);
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);

    // A second, offset wave for depth
    final wavePaint2 = Paint()
      ..color = Colors.blue.shade400.withAlpha((255 * 0.7).round());
    final wavePath2 = Path();
    wavePath2.moveTo(0, waterHeight + 4);
    for (double x = 0; x <= size.width; x++) {
      final y = waterHeight +
          4 +
          waveAmplitude *
              math.sin(
                  (x / waveLength * 2 * math.pi) + wavePhase + math.pi / 2);
      wavePath2.lineTo(x, y);
    }
    wavePath2.lineTo(size.width, size.height);
    wavePath2.lineTo(0, size.height);
    wavePath2.close();
    canvas.drawPath(wavePath2, wavePaint2);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BottlePainter oldDelegate) {
    return oldDelegate.fill != fill || oldDelegate.wavePhase != wavePhase;
  }
}
