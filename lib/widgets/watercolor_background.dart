import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Gallery background on warm off-white paper (#FAF9F6) with layered
/// watercolor brushstrokes and soft, realistic paint splatters across the canvas.
class WatercolorBackground extends StatelessWidget {
  final Widget child;

  const WatercolorBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF13161C) : const Color(0xFFFAF9F6);

    return Container(
      color: backgroundColor,
      child: CustomPaint(
        painter: _WatercolorBrushPainter(isDark: isDark),
        child: child,
      ),
    );
  }
}

class _WatercolorBrushPainter extends CustomPainter {
  final bool isDark;

  _WatercolorBrushPainter({required this.isDark});

  // Strictly the existing pastel gallery colors (blush pink, sage/teal, peach, sky blue)
  static const List<Color> _strokePalette = <Color>[
    Color(0xFFF3C6D3),
    Color(0xFFF8E1E7),
    Color(0xFFCDE3DF),
    Color(0xFFD7EAE3),
    Color(0xFFF6DFC8),
    Color(0xFFF6DFD2),
    Color(0xFFD2E6F7),
    Color(0xFFDFEEFA),
  ];

  static const List<Color> _splatterPalette = <Color>[
    Color(0xFF9AC5E8), // soft sky blue
    Color(0xFF9CD4CA), // pale sage/teal
    Color(0xFFECADC4), // soft blush pink
    Color(0xFFF3C79E), // warm peach
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final alphaBoost = isDark ? 0.18 : 1.0;
    final centerX = size.width * 0.5;
    final heroY = math.min(size.height * 0.29, 285.0);
    final heroSpan = math.min(size.width * 0.42, 490.0);

    // 1. Layered brushstrokes right behind the central Hero artwork
    _drawBrushStroke(
      canvas: canvas,
      start: Offset(centerX - heroSpan * 1.25, heroY - 75),
      end: Offset(centerX + heroSpan * 0.35, heroY - 120),
      thickness: 82,
      color: _strokePalette[0].withValues(alpha: 0.46 * alphaBoost),
    );
    _drawBrushStroke(
      canvas: canvas,
      start: Offset(centerX - heroSpan * 1.32, heroY + 25),
      end: Offset(centerX + heroSpan * 1.28, heroY - 82),
      thickness: 108,
      color: _strokePalette[2].withValues(alpha: 0.52 * alphaBoost),
    );
    _drawBrushStroke(
      canvas: canvas,
      start: Offset(centerX - heroSpan * 1.05, heroY + 75),
      end: Offset(centerX + heroSpan * 1.36, heroY - 18),
      thickness: 86,
      color: _strokePalette[3].withValues(alpha: 0.48 * alphaBoost),
    );
    _drawBrushStroke(
      canvas: canvas,
      start: Offset(centerX - heroSpan * 0.25, heroY + 65),
      end: Offset(centerX + heroSpan * 1.28, heroY + 22),
      thickness: 76,
      color: _strokePalette[4].withValues(alpha: 0.46 * alphaBoost),
    );

    // 2. Mid-canvas brushstrokes framing the "Latest Creations" row
    final rowY = heroY + 265;
    _drawBrushStroke(
      canvas: canvas,
      start: Offset(centerX - heroSpan * 1.22, rowY - 12),
      end: Offset(centerX - heroSpan * 0.35, rowY - 42),
      thickness: 54,
      color: _strokePalette[7].withValues(alpha: 0.42 * alphaBoost),
    );
    _drawBrushStroke(
      canvas: canvas,
      start: Offset(centerX + heroSpan * 0.25, rowY + 18),
      end: Offset(centerX + heroSpan * 1.25, rowY - 25),
      thickness: 62,
      color: _strokePalette[1].withValues(alpha: 0.40 * alphaBoost),
    );
    _drawBrushStroke(
      canvas: canvas,
      start: Offset(centerX - heroSpan * 0.45, rowY + 72),
      end: Offset(centerX + heroSpan * 0.65, rowY + 46),
      thickness: 48,
      color: _strokePalette[3].withValues(alpha: 0.35 * alphaBoost),
    );

    // 3. Top-right watercolor sweeps
    _drawBrushStroke(
      canvas: canvas,
      start: Offset(size.width * 0.76, -15),
      end: Offset(size.width + 30, 95),
      thickness: 96,
      color: _strokePalette[6].withValues(alpha: 0.48 * alphaBoost),
    );
    _drawBrushStroke(
      canvas: canvas,
      start: Offset(size.width * 0.82, 28),
      end: Offset(size.width + 25, 145),
      thickness: 68,
      color: _strokePalette[7].withValues(alpha: 0.44 * alphaBoost),
    );
    _drawBrushStroke(
      canvas: canvas,
      start: Offset(size.width * 0.88, 72),
      end: Offset(size.width + 20, 185),
      thickness: 46,
      color: _strokePalette[4].withValues(alpha: 0.36 * alphaBoost),
    );

    // 4. Bottom-left watercolor sweeps
    _drawBrushStroke(
      canvas: canvas,
      start: Offset(-35, size.height * 0.78),
      end: Offset(size.width * 0.28, size.height + 25),
      thickness: 105,
      color: _strokePalette[6].withValues(alpha: 0.46 * alphaBoost),
    );
    _drawBrushStroke(
      canvas: canvas,
      start: Offset(-25, size.height * 0.86),
      end: Offset(size.width * 0.22, size.height + 35),
      thickness: 72,
      color: _strokePalette[2].withValues(alpha: 0.38 * alphaBoost),
    );

    // 5. Bottom-right watercolor sweeps
    _drawBrushStroke(
      canvas: canvas,
      start: Offset(size.width * 0.72, size.height + 20),
      end: Offset(size.width + 35, size.height * 0.76),
      thickness: 98,
      color: _strokePalette[5].withValues(alpha: 0.45 * alphaBoost),
    );
    _drawBrushStroke(
      canvas: canvas,
      start: Offset(size.width * 0.79, size.height + 30),
      end: Offset(size.width + 30, size.height * 0.85),
      thickness: 66,
      color: _strokePalette[0].withValues(alpha: 0.36 * alphaBoost),
    );

    // 6. Soft, realistic watercolor splatters scattered all over the background
    _drawAllOverWatercolorSplatter(canvas, size, alphaBoost);
  }

  /// Draws a single organic tapered watercolor brush stroke with bristle notches.
  void _drawBrushStroke({
    required Canvas canvas,
    required Offset start,
    required Offset end,
    required double thickness,
    required Color color,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) return;

    final ux = dx / length;
    final uy = dy / length;
    final px = -uy;
    final py = ux;

    final p1 =
        Offset(start.dx + px * thickness * 0.38, start.dy + py * thickness * 0.38);
    final p2 = Offset(
      start.dx + dx * 0.35 + px * thickness * 0.56,
      start.dy + dy * 0.35 + py * thickness * 0.56,
    );
    final p3 = Offset(
      start.dx + dx * 0.72 + px * thickness * 0.48,
      start.dy + dy * 0.72 + py * thickness * 0.48,
    );
    final p4 =
        Offset(end.dx + px * thickness * 0.30, end.dy + py * thickness * 0.30);

    final tipMid1 = Offset(
      end.dx + ux * 18 + px * thickness * 0.14,
      end.dy + uy * 18 + py * thickness * 0.14,
    );
    final tipNotch = Offset(
      end.dx - ux * 7,
      end.dy - uy * 7,
    );
    final tipMid2 = Offset(
      end.dx + ux * 16 - px * thickness * 0.18,
      end.dy + uy * 16 - py * thickness * 0.18,
    );

    final b4 =
        Offset(end.dx - px * thickness * 0.34, end.dy - py * thickness * 0.34);
    final b3 = Offset(
      start.dx + dx * 0.68 - px * thickness * 0.54,
      start.dy + dy * 0.68 - py * thickness * 0.54,
    );
    final b2 = Offset(
      start.dx + dx * 0.30 - px * thickness * 0.46,
      start.dy + dy * 0.30 - py * thickness * 0.46,
    );
    final b1 =
        Offset(start.dx - px * thickness * 0.32, start.dy - py * thickness * 0.32);
    final startNotch = Offset(start.dx + ux * 9, start.dy + uy * 9);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..cubicTo(p2.dx, p2.dy, p3.dx, p3.dy, p4.dx, p4.dy)
      ..lineTo(tipMid1.dx, tipMid1.dy)
      ..lineTo(tipNotch.dx, tipNotch.dy)
      ..lineTo(tipMid2.dx, tipMid2.dy)
      ..lineTo(b4.dx, b4.dy)
      ..cubicTo(b3.dx, b3.dy, b2.dx, b2.dy, b1.dx, b1.dy)
      ..lineTo(startNotch.dx, startNotch.dy)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    canvas.drawPath(path, paint);

    final innerPaint = Paint()
      ..color = color.withValues(alpha: (color.a * 0.42).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 0.22
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawLine(
      Offset(start.dx + dx * 0.14, start.dy + dy * 0.14),
      Offset(start.dx + dx * 0.86, start.dy + dy * 0.86),
      innerPaint,
    );
  }

  /// Draws soft, translucent watercolor drops and gentle trailing smears
  /// distributed evenly across the entire background.
  void _drawAllOverWatercolorSplatter(
    Canvas canvas,
    Size size,
    double alphaBoost,
  ) {
    final rng = math.Random(777);

    // 1. Soft watercolor droplets scattered across the whole canvas
    final int dropCount = isDark ? 35 : 130;
    for (int i = 0; i < dropCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final color = _splatterPalette[rng.nextInt(_splatterPalette.length)];

      // Varied sizes: fine mist, soft medium drops, and occasional wider washes
      final roll = rng.nextDouble();
      final double rx;
      final double ry;
      if (roll < 0.55) {
        final r = 1.5 + rng.nextDouble() * 2.5;
        rx = r * (0.85 + rng.nextDouble() * 0.35);
        ry = r * (0.85 + rng.nextDouble() * 0.35);
      } else if (roll < 0.88) {
        final r = 4.0 + rng.nextDouble() * 5.0;
        rx = r * (0.85 + rng.nextDouble() * 0.45);
        ry = r * (0.80 + rng.nextDouble() * 0.40);
      } else {
        final r = 9.0 + rng.nextDouble() * 7.5;
        rx = r * (0.90 + rng.nextDouble() * 0.50);
        ry = r * (0.80 + rng.nextDouble() * 0.45);
      }

      final alpha = (0.18 + rng.nextDouble() * 0.20) * alphaBoost;
      final blurSigma = 2.2 + rng.nextDouble() * 3.8;

      final paint = Paint()
        ..color = color.withValues(alpha: alpha.clamp(0.04, 0.42))
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rng.nextDouble() * math.pi * 2);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        paint,
      );
      canvas.restore();
    }

    // 2. Soft watercolor smears / trails (like a wet drop with a blurred tail)
    final int trailCount = isDark ? 6 : 26;
    for (int i = 0; i < trailCount; i++) {
      final startX = rng.nextDouble() * size.width;
      final startY = rng.nextDouble() * size.height;
      final angle = rng.nextDouble() * math.pi * 2;
      final trailLen = 22.0 + rng.nextDouble() * 58.0;
      final headRadius = 3.0 + rng.nextDouble() * 5.5;
      final color = _splatterPalette[rng.nextInt(_splatterPalette.length)];
      final alpha = (0.16 + rng.nextDouble() * 0.18) * alphaBoost;

      final endX = startX + math.cos(angle) * trailLen;
      final endY = startY + math.sin(angle) * trailLen;

      // Soft tapered streak fading along the trail
      final streakPaint = Paint()
        ..color = color.withValues(alpha: (alpha * 0.75).clamp(0.04, 0.36))
        ..style = PaintingStyle.stroke
        ..strokeWidth = headRadius * 0.72
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.5);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), streakPaint);

      // Soft round drop at the origin
      final headPaint = Paint()
        ..color = color.withValues(alpha: alpha.clamp(0.05, 0.40))
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      canvas.drawCircle(Offset(startX, startY), headRadius, headPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WatercolorBrushPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}