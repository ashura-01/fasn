import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class FloatingFlower {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  double rotation;
  double rotationSpeed;
  int type; // 0=5-petal 1=4-petal 2=daisy

  FloatingFlower({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.rotation,
    required this.rotationSpeed,
    required this.type,
  });
}

/// Renders the child once, and overlays an independently-animated
/// flower layer on top. The ticker only runs while [enabled] is true,
/// and repainting is isolated to the CustomPaint layer via a
/// ValueListenable-driven repaint — the child subtree never rebuilds.
class FloatingFlowersWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const FloatingFlowersWidget({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<FloatingFlowersWidget> createState() => _FloatingFlowersWidgetState();
}

class _FloatingFlowersWidgetState extends State<FloatingFlowersWidget>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<FloatingFlower> _flowers = [];
  final Random _rng = Random();
  double _screenWidth = 400;
  double _screenHeight = 800;
  final ValueNotifier<int> _repaintNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _initFlowers();
    _ticker = createTicker(_onTick);
    if (widget.enabled) _ticker.start();
  }

  @override
  void didUpdateWidget(FloatingFlowersWidget old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.enabled && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _initFlowers() {
    _flowers.clear();
    for (int i = 0; i < 10; i++) {
      _flowers.add(_randomFlower(initial: true));
    }
  }

  FloatingFlower _randomFlower({bool initial = false}) {
    return FloatingFlower(
      x: _rng.nextDouble() * _screenWidth,
      y: initial ? _rng.nextDouble() * _screenHeight : _screenHeight + 20,
      size: 14 + _rng.nextDouble() * 18,
      speed: 0.3 + _rng.nextDouble() * 0.5,
      opacity: 0.10 + _rng.nextDouble() * 0.16,
      rotation: _rng.nextDouble() * pi * 2,
      rotationSpeed: ((_rng.nextDouble() - 0.5) * 0.02),
      type: _rng.nextInt(3),
    );
  }

  Duration _lastElapsed = Duration.zero;
  void _onTick(Duration elapsed) {
    // Throttle to ~30fps for battery efficiency — flowers move slowly anyway
    if ((elapsed - _lastElapsed).inMilliseconds < 33) return;
    _lastElapsed = elapsed;

    for (int i = 0; i < _flowers.length; i++) {
      final f = _flowers[i];
      f.y -= f.speed;
      f.x += sin(f.y * 0.01) * 0.4;
      f.rotation += f.rotationSpeed;
      if (f.y < -30) _flowers[i] = _randomFlower();
    }
    // Only the painter listens to this — child subtree is untouched
    _repaintNotifier.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaintNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _screenWidth = constraints.maxWidth;
      _screenHeight = constraints.maxHeight;
      return Stack(
        children: [
          widget.child,
          if (widget.enabled)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _repaintNotifier,
                  builder: (_, __) => CustomPaint(
                    painter: _FlowerPainter(_flowers),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _FlowerPainter extends CustomPainter {
  final List<FloatingFlower> flowers;
  _FlowerPainter(this.flowers);

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in flowers) {
      canvas.save();
      canvas.translate(f.x, f.y);
      canvas.rotate(f.rotation);

      final paint = Paint()
        ..color = AppTheme.primary.withOpacity(f.opacity)
        ..style = PaintingStyle.fill;

      _drawFlower(canvas, f, paint);
      canvas.restore();
    }
  }

  void _drawFlower(Canvas c, FloatingFlower f, Paint paint) {
    final r = f.size / 2;
    switch (f.type) {
      case 0: _draw5Petal(c, r, paint); break;
      case 1: _draw4Petal(c, r, paint); break;
      case 2: _drawDaisy(c, r, paint); break;
    }
  }

  void _draw5Petal(Canvas c, double r, Paint paint) {
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * pi / 5) - pi / 2;
      final dx = cos(angle) * r * 0.6;
      final dy = sin(angle) * r * 0.6;
      c.drawOval(Rect.fromCenter(center: Offset(dx, dy), width: r * 0.9, height: r * 1.4), paint);
    }
    c.drawCircle(Offset.zero, r * 0.3, paint);
  }

  void _draw4Petal(Canvas c, double r, Paint paint) {
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2;
      final dx = cos(angle) * r * 0.5;
      final dy = sin(angle) * r * 0.5;
      c.drawOval(Rect.fromCenter(center: Offset(dx, dy), width: r * 0.8, height: r * 1.2), paint);
    }
    c.drawCircle(Offset.zero, r * 0.28, paint);
  }

  void _drawDaisy(Canvas c, double r, Paint paint) {
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final dx = cos(angle) * r * 0.6;
      final dy = sin(angle) * r * 0.6;
      c.drawOval(Rect.fromCenter(center: Offset(dx, dy), width: r * 0.5, height: r), paint);
    }
    final cp = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(paint.color.opacity * 1.5)
      ..style = PaintingStyle.fill;
    c.drawCircle(Offset.zero, r * 0.32, cp);
  }

  @override
  bool shouldRepaint(_FlowerPainter old) => true;
}
