import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class BeautifulProgressRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final String centerLabel;
  final String subLabel;
  final Color? color;
  final Color? trackColor;
  final double strokeWidth;
  final bool animate;

  const BeautifulProgressRing({
    super.key,
    required this.progress,
    this.size = 90,
    required this.centerLabel,
    this.subLabel = '',
    this.color,
    this.trackColor,
    this.strokeWidth = 7,
    this.animate = true,
  });

  @override
  State<BeautifulProgressRing> createState() => _BeautifulProgressRingState();
}

class _BeautifulProgressRingState extends State<BeautifulProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    if (widget.animate) _ctrl.forward();
  }

  @override
  void didUpdateWidget(BeautifulProgressRing old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _anim = Tween<double>(begin: old.progress, end: widget.progress).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = widget.color ?? AppTheme.primaryDark;
    final track = widget.trackColor ?? AppTheme.primaryLight.withOpacity(0.35);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: _anim.value,
              ringColor: ringColor,
              trackColor: track,
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.centerLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: widget.size * 0.175,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  if (widget.subLabel.isNotEmpty)
                    Text(
                      widget.subLabel,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: widget.size * 0.115,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                        height: 1.1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track (background ring) with dotted feel via dash-like segments
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, 2 * pi, false, trackPaint);

    if (progress <= 0) return;

    // Gradient progress arc
    final gradient = SweepGradient(
      startAngle: -pi / 2,
      endAngle: -pi / 2 + 2 * pi * progress,
      colors: [
        ringColor.withOpacity(0.7),
        ringColor,
        ringColor.withOpacity(0.9),
      ],
      tileMode: TileMode.clamp,
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );

    // Glowing dot at the tip
    if (progress > 0.02) {
      final angle = -pi / 2 + 2 * pi * progress;
      final tipX = center.dx + radius * cos(angle);
      final tipY = center.dy + radius * sin(angle);
      final tipOffset = Offset(tipX, tipY);

      final glowPaint = Paint()
        ..color = ringColor.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(tipOffset, strokeWidth * 0.9, glowPaint);

      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tipOffset, strokeWidth * 0.45, dotPaint);

      final dotOutline = Paint()
        ..color = ringColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tipOffset, strokeWidth * 0.3, dotOutline);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.ringColor != ringColor;
}

// ── Mini ring for task items ──────────────────────────────────

class MiniProgressDot extends StatelessWidget {
  final bool isChecked;
  final bool isExpired;
  final VoidCallback? onTap;

  const MiniProgressDot({
    super.key,
    required this.isChecked,
    required this.isExpired,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    IconData icon;
    Color iconColor;

    if (isChecked) {
      bg = AppTheme.taskCheckedBg;
      border = AppTheme.taskCheckedText;
      icon = Icons.check_circle_rounded;
      iconColor = AppTheme.taskCheckedText;
    } else if (isExpired) {
      bg = AppTheme.taskExpiredBg;
      border = AppTheme.taskExpiredText;
      icon = Icons.sentiment_dissatisfied_rounded;
      iconColor = AppTheme.taskExpiredText;
    } else {
      bg = Colors.white;
      border = AppTheme.primaryDark;
      icon = Icons.radio_button_unchecked_rounded;
      iconColor = AppTheme.primaryDark;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 1.5),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}
