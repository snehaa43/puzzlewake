import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom-painted luminous crescent moon and glowing golden stars widget
/// that faithfully reproduces the dreamy bedtime illustration from the design.
class MoonStarsIllustration extends StatefulWidget {
  final double size;

  const MoonStarsIllustration({
    super.key,
    this.size = 220,
  });

  @override
  State<MoonStarsIllustration> createState() => _MoonStarsIllustrationState();
}

class _MoonStarsIllustrationState extends State<MoonStarsIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _MoonStarsPainter(
              animationValue: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class _MoonStarsPainter extends CustomPainter {
  final double animationValue;

  _MoonStarsPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.44, size.height * 0.48);
    final moonRadius = size.width * 0.42;

    // 1. Dreamy Atmospheric Ambient Glow behind the moon
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9E80).withValues(alpha: 0.25 + 0.08 * animationValue),
          const Color(0xFFFFD54F).withValues(alpha: 0.12 + 0.05 * animationValue),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: moonRadius * 1.5))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);

    canvas.drawCircle(center, moonRadius * 1.35, glowPaint);

    // 2. Crescent Moon Path
    // Outer circle
    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: moonRadius));

    // Inner cutout circle (offset to top-right to create the left crescent)
    final cutoutCenter = Offset(
      center.dx + moonRadius * 0.48,
      center.dy - moonRadius * 0.28,
    );
    final cutoutRadius = moonRadius * 0.88;
    final innerPath = Path()
      ..addOval(Rect.fromCircle(center: cutoutCenter, radius: cutoutRadius));

    // Combined Crescent
    final crescentPath = Path.combine(PathOperation.difference, outerPath, innerPath);

    // Moon Gradient Fill (Smooth peach to soft yellow cream)
    final moonGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFFFFF7C2), // Pale golden highlight at top left
        Color(0xFFFFDE8A), // Warm yellow
        Color(0xFFFFAC70), // Peach/salmon body
        Color(0xFFFF8A65), // Soft coral at bottom tip
        Color(0xFFFF7043),
      ],
      stops: const [0.0, 0.25, 0.65, 0.88, 1.0],
    );

    final moonPaint = Paint()
      ..shader = moonGradient.createShader(
        Rect.fromCircle(center: center, radius: moonRadius),
      )
      ..isAntiAlias = true;

    // Drop shadow under the crescent
    final shadowPaint = Paint()
      ..color = const Color(0xFFFF7043).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    canvas.drawPath(crescentPath, shadowPaint);
    canvas.drawPath(crescentPath, moonPaint);

    // Inner soft crescent highlight edge
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: moonRadius));

    canvas.drawPath(crescentPath, highlightPaint);

    // 3. Golden Stars nestled within the moon crescent
    // Star 1: Large Main Star (Center-right of the crescent)
    final star1Center = Offset(size.width * 0.62, size.height * 0.54);
    final star1Pulse = 1.0 + 0.06 * math.sin(animationValue * 2 * math.pi);
    _drawStar(
      canvas: canvas,
      center: star1Center,
      outerRadius: size.width * 0.13 * star1Pulse,
      innerRadius: size.width * 0.058 * star1Pulse,
      rotation: 0.05,
      glowAlpha: 0.45 + 0.15 * animationValue,
    );

    // Star 2: Medium Top-Left Star
    final star2Center = Offset(size.width * 0.51, size.height * 0.28);
    final star2Pulse = 1.0 + 0.08 * math.cos(animationValue * 2 * math.pi);
    _drawStar(
      canvas: canvas,
      center: star2Center,
      outerRadius: size.width * 0.078 * star2Pulse,
      innerRadius: size.width * 0.035 * star2Pulse,
      rotation: -0.15,
      glowAlpha: 0.4 + 0.2 * (1 - animationValue),
    );

    // Star 3: Small Top-Right Star
    final star3Center = Offset(size.width * 0.73, size.height * 0.35);
    final star3Pulse = 1.0 + 0.07 * math.sin((animationValue + 0.5) * 2 * math.pi);
    _drawStar(
      canvas: canvas,
      center: star3Center,
      outerRadius: size.width * 0.052 * star3Pulse,
      innerRadius: size.width * 0.024 * star3Pulse,
      rotation: 0.2,
      glowAlpha: 0.35 + 0.2 * animationValue,
    );
  }

  void _drawStar({
    required Canvas canvas,
    required Offset center,
    required double outerRadius,
    required double innerRadius,
    required double rotation,
    required double glowAlpha,
  }) {
    // 1. Star ambient glow
    final starGlowPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: glowAlpha.clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, outerRadius * 0.75);
    canvas.drawCircle(center, outerRadius * 0.8, starGlowPaint);

    // 2. Star 5-point path with smooth rounded tips
    final starPath = _createStarPath(
      center: center,
      points: 5,
      outerRadius: outerRadius,
      innerRadius: innerRadius,
      rotation: rotation,
    );

    // Star Gradient (Bright golden yellow to warm amber)
    final starGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFFFFF59D), // Light cream yellow
        Color(0xFFFFD54F), // Golden star yellow
        Color(0xFFFFB300), // Amber
      ],
    );

    final starPaint = Paint()
      ..shader = starGradient.createShader(
        Rect.fromCircle(center: center, radius: outerRadius),
      )
      ..isAntiAlias = true;

    canvas.drawPath(starPath, starPaint);

    // Soft highlight on top
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.7),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius * 0.6))
      ..isAntiAlias = true;

    canvas.drawPath(starPath, highlightPaint);
  }

  Path _createStarPath({
    required Offset center,
    required int points,
    required double outerRadius,
    required double innerRadius,
    required double rotation,
  }) {
    final path = Path();
    final step = math.pi / points;
    double angle = -math.pi / 2 + rotation;

    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? outerRadius : innerRadius;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      angle += step;
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _MoonStarsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
