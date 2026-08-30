import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:soutnaqi/core/theme/soutnaqi_brand.dart';

class SoutNaqiLogo extends StatelessWidget {
  const SoutNaqiLogo({
    super.key,
    this.size = 48,
    this.wordmark,
    this.subtitle,
    this.wordmarkStyle,
    this.subtitleStyle,
    this.spacing = 12,
  });

  final double size;
  final String? wordmark;
  final String? subtitle;
  final TextStyle? wordmarkStyle;
  final TextStyle? subtitleStyle;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size.square(size),
        painter: const _SoutNaqiMarkPainter(),
      ),
    );

    if (wordmark == null && subtitle == null) {
      return mark;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: spacing),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wordmark != null)
                Text(
                  wordmark!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: wordmarkStyle,
                ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SoutNaqiMarkPainter extends CustomPainter {
  const _SoutNaqiMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);

    final bounds = Rect.fromLTWH(0, 0, side, side);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(side * 0.22)),
      Paint()..color = SoutNaqiBrand.blue,
    );

    final wave = Path();
    final left = side * 0.22;
    final right = side * 0.78;
    final midY = side * 0.5;
    final amplitude = side * 0.16;
    const steps = 48;

    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = left + (right - left) * t;
      final y = midY - math.sin(t * 2 * math.pi) * amplitude;
      if (i == 0) {
        wave.moveTo(x, y);
      } else {
        wave.lineTo(x, y);
      }
    }

    canvas.drawPath(
      wave,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.08
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
