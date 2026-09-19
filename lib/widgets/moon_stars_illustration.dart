import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom-painted luminous illustration that dynamically renders:
/// - A glowing golden Crescent Moon & Stars in Night Mode.
/// - A radiant luminous Sun with golden rays & ambient corona in Day Mode.
class MoonStarsIllustration extends StatefulWidget {
  final double size;
  final bool isDark;

  const MoonStarsIllustration({
    super.key,
    this.size = 220,
    this.isDark = true,
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      child: AnimatedBuilder(
        key: ValueKey(widget.isDark),
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: widget.isDark
                  ? _MoonStarsPainter(animationValue: _controller.value)
                  : _SunPainter(animationValue: _controller.value),
            ),
          );
        },
      ),
    );
  }
}

/// Painter for Night Theme: Crescent Moon & Golden Stars
class _MoonStarsPainter extends CustomPainter {
  final double animationValue;

  _MoonStarsPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.44, size.height * 0.48);
    final moonRadius = size.width * 0.42;

    // 1. Atmospheric Ambient Glow
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
    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: moonRadius));

    final cutoutCenter = Offset(
      center.dx + moonRadius * 0.48,
      center.dy - moonRadius * 0.28,
    );
    final cutoutRadius = moonRadius * 0.88;
    final innerPath = Path()
      ..addOval(Rect.fromCircle(center: cutoutCenter, radius: cutoutRadius));

    final crescentPath = Path.combine(PathOperation.difference, outerPath, innerPath);

    // Moon Gradient
    final moonGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFF7C2), // Pale golden highlight at top left
        Color(0xFFFFDE8A), // Warm yellow
        Color(0xFFFFAC70), // Peach/salmon body
        Color(0xFFFF8A65), // Soft coral at bottom tip
        Color(0xFFFF7043),
      ],
      stops: [0.0, 0.25, 0.65, 0.88, 1.0],
    );

    final moonPaint = Paint()
      ..shader = moonGradient.createShader(
        Rect.fromCircle(center: center, radius: moonRadius),
      )
      ..isAntiAlias = true;

    final shadowPaint = Paint()
      ..color = const Color(0xFFFF7043).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    canvas.drawPath(crescentPath, shadowPaint);
    canvas.drawPath(crescentPath, moonPaint);

    // Inner highlight stroke
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

    // 3. Golden Stars
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
    final starGlowPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: glowAlpha.clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, outerRadius * 0.75);
    canvas.drawCircle(center, outerRadius * 0.8, starGlowPaint);

    final starPath = _createStarPath(
      center: center,
      points: 5,
      outerRadius: outerRadius,
      innerRadius: innerRadius,
      rotation: rotation,
    );

    final starGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFF59D),
        Color(0xFFFFD54F),
        Color(0xFFFFB300),
      ],
    );

    final starPaint = Paint()
      ..shader = starGradient.createShader(
        Rect.fromCircle(center: center, radius: outerRadius),
      )
      ..isAntiAlias = true;

    canvas.drawPath(starPath, starPaint);

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

/// Painter for Day Theme: Radiant Golden Sun with Sunbeams & Corona
class _SunPainter extends CustomPainter {
  final double animationValue;

  _SunPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final sunRadius = size.width * 0.26;

    // 1. Sun Corona Outer Glow
    final glowRadius = size.width * 0.46;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.35 + 0.1 * animationValue),
          const Color(0xFFFF9800).withValues(alpha: 0.18 + 0.06 * animationValue),
          const Color(0xFFFF7043).withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(center, glowRadius, glowPaint);

    // 2. Animated Radiant Sunbeams / Sun Rays (12 rays)
    final numRays = 12;
    final baseRayAngle = (animationValue * 0.08) * math.pi; // subtle slow rotation

    for (int i = 0; i < numRays; i++) {
      final angle = (i * 2 * math.pi / numRays) + baseRayAngle;
      final isMajorRay = i % 2 == 0;

      // Pulsing ray length
      final lengthMultiplier = isMajorRay
          ? (1.0 + 0.08 * math.sin((animationValue + i * 0.2) * 2 * math.pi))
          : (0.85 + 0.06 * math.cos((animationValue + i * 0.2) * 2 * math.pi));

      final rayStartDist = sunRadius + 6;
      final rayEndDist = (sunRadius + (isMajorRay ? 24.0 : 15.0)) * lengthMultiplier;

      final p1 = Offset(
        center.dx + rayStartDist * math.cos(angle - 0.09),
        center.dy + rayStartDist * math.sin(angle - 0.09),
      );
      final p2 = Offset(
        center.dx + rayEndDist * math.cos(angle),
        center.dy + rayEndDist * math.sin(angle),
      );
      final p3 = Offset(
        center.dx + rayStartDist * math.cos(angle + 0.09),
        center.dy + rayStartDist * math.sin(angle + 0.09),
      );

      final rayPath = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(
          center.dx + (rayStartDist + (rayEndDist - rayStartDist) * 0.6) * math.cos(angle),
          center.dy + (rayStartDist + (rayEndDist - rayStartDist) * 0.6) * math.sin(angle),
          p2.dx,
          p2.dy,
        )
        ..lineTo(p3.dx, p3.dy)
        ..close();

      final rayGradient = LinearGradient(
        begin: Alignment.center,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFFE082),
          isMajorRay ? const Color(0xFFFFB300) : const Color(0xFFFFA726),
          const Color(0xFFFF7043).withValues(alpha: 0.6),
        ],
      );

      final rayPaint = Paint()
        ..shader = rayGradient.createShader(Rect.fromCircle(center: center, radius: rayEndDist))
        ..isAntiAlias = true;

      // Ray drop glow
      final rayGlow = Paint()
        ..color = const Color(0xFFFFB300).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawPath(rayPath, rayGlow);
      canvas.drawPath(rayPath, rayPaint);
    }

    // 3. Sun Body Sphere with Smooth Warm Radiant Gradient
    final sunGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFFDE7), // Luminous pale yellow-white highlight
        Color(0xFFFFF176), // Bright sunshine yellow
        Color(0xFFFFD54F), // Golden yellow
        Color(0xFFFFB300), // Deep amber
        Color(0xFFFF8A65), // Coral glow at bottom-right
        Color(0xFFFF7043),
      ],
      stops: [0.0, 0.2, 0.45, 0.72, 0.9, 1.0],
    );

    final sunPaint = Paint()
      ..shader = sunGradient.createShader(
        Rect.fromCircle(center: center, radius: sunRadius),
      )
      ..isAntiAlias = true;

    // Soft drop shadow under the sun
    final sunShadow = Paint()
      ..color = const Color(0xFFFF8A65).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    canvas.drawCircle(center, sunRadius, sunShadow);
    canvas.drawCircle(center, sunRadius, sunPaint);

    // 4. Edge Highlight Ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.85),
          Colors.white.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: sunRadius))
      ..isAntiAlias = true;

    canvas.drawCircle(center, sunRadius, ringPaint);

    // 5. Floating Morning Sparkles
    _drawSparkle(
      canvas: canvas,
      center: Offset(size.width * 0.78, size.height * 0.3),
      size: 14 * (1.0 + 0.15 * math.sin(animationValue * 2 * math.pi)),
    );
    _drawSparkle(
      canvas: canvas,
      center: Offset(size.width * 0.22, size.height * 0.68),
      size: 10 * (1.0 + 0.18 * math.cos(animationValue * 2 * math.pi)),
    );
    _drawSparkle(
      canvas: canvas,
      center: Offset(size.width * 0.76, size.height * 0.72),
      size: 8 * (1.0 + 0.2 * math.sin((animationValue + 0.5) * 2 * math.pi)),
    );
  }

  void _drawSparkle({
    required Canvas canvas,
    required Offset center,
    required double size,
  }) {
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFFFD54F),
          Color(0x00FFD54F),
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size * 1.2))
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SunPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
