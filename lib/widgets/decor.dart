import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fondo espacial: degradado oscuro, estrellas y resplandores de portal.
class PortalBackground extends StatelessWidget {
  const PortalBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B1E12), AppColors.background, Color(0xFF061419)],
            ),
          ),
        ),
        const RepaintBoundary(child: CustomPaint(painter: _StarsPainter())),
        const Positioned(
          top: -140,
          left: -100,
          child: _Glow(color: AppColors.portal, size: 360),
        ),
        const Positioned(
          bottom: -160,
          right: -120,
          child: _Glow(color: AppColors.cyan, size: 400),
        ),
        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0),
          ]),
        ),
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(137); // semilla fija: siempre las mismas estrellas
    final paint = Paint();
    for (var i = 0; i < 140; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 0.4 + random.nextDouble() * 1.3;
      paint.color = Colors.white.withValues(alpha: 0.15 + random.nextDouble() * 0.6);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tarjeta translúcida con desenfoque (efecto vidrio).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Logo de portal que gira lentamente.
class PortalLogo extends StatefulWidget {
  const PortalLogo({super.key, this.size = 120});

  final double size;

  @override
  State<PortalLogo> createState() => _PortalLogoState();
}

class _PortalLogoState extends State<PortalLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _controller,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(colors: [
                  AppColors.portal,
                  Color(0xFF1B5E20),
                  AppColors.cyan,
                  Color(0xFFB2FF59),
                  AppColors.portal,
                ]),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.portal.withValues(alpha: 0.55),
                    blurRadius: size * 0.4,
                    spreadRadius: size * 0.02,
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: size * 0.74,
            height: size * 0.74,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                Color(0xFFE6FFB3),
                AppColors.portal,
                Color(0xFF2E7D32),
              ]),
            ),
          ),
          RotationTransition(
            turns: ReverseAnimation(_controller),
            child: Icon(Icons.cyclone_rounded,
                size: size * 0.55, color: const Color(0xFF1B3A10)),
          ),
        ],
      ),
    );
  }
}

/// Texto con degradado verde portal → cian.
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFC6FF7A), AppColors.portal, AppColors.cyan],
      ).createShader(bounds),
      child: Text(text, style: style, textAlign: textAlign),
    );
  }
}

/// Tarjeta de sección con icono y título (formularios y detalle).
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.color = AppColors.portal,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBox(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Icono dentro de un cuadrado redondeado con fondo tenue del mismo color.
class IconBox extends StatelessWidget {
  const IconBox(this.icon, {super.key, this.color = AppColors.portal, this.size = 20});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.55),
      ),
      child: Icon(icon, size: size, color: color),
    );
  }
}

/// Aparición suave (desvanecido + desplazamiento) la primera vez que se muestra.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final total = const Duration(milliseconds: 450) + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, offset * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
