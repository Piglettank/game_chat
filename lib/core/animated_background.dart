import 'dart:math';
import 'package:flutter/material.dart';

enum BackgroundAnimationType {
  none,
  floatingIcons,
  gradient,
  particles,
  grid,
  waves,
  starfield,
}

extension BackgroundAnimationTypeExtension on BackgroundAnimationType {
  String get label {
    switch (this) {
      case BackgroundAnimationType.none:
        return 'None';
      case BackgroundAnimationType.floatingIcons:
        return 'Game Icons';
      case BackgroundAnimationType.gradient:
        return 'Gradient';
      case BackgroundAnimationType.particles:
        return 'Confetti';
      case BackgroundAnimationType.grid:
        return 'Grid';
      case BackgroundAnimationType.waves:
        return 'Waves';
      case BackgroundAnimationType.starfield:
        return 'Starfield';
    }
  }

  IconData get icon {
    switch (this) {
      case BackgroundAnimationType.none:
        return Icons.block;
      case BackgroundAnimationType.floatingIcons:
        return Icons.casino;
      case BackgroundAnimationType.gradient:
        return Icons.gradient;
      case BackgroundAnimationType.particles:
        return Icons.celebration;
      case BackgroundAnimationType.grid:
        return Icons.grid_4x4;
      case BackgroundAnimationType.waves:
        return Icons.waves;
      case BackgroundAnimationType.starfield:
        return Icons.star;
    }
  }
}

class AnimatedBackground extends StatelessWidget {
  final BackgroundAnimationType type;
  final Widget child;

  const AnimatedBackground({
    super.key,
    required this.type,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _buildBackground(context),
        ),
        child,
      ],
    );
  }

  Widget _buildBackground(BuildContext context) {
    switch (type) {
      case BackgroundAnimationType.none:
        return const SizedBox.shrink();
      case BackgroundAnimationType.floatingIcons:
        return const _FloatingIconsBackground();
      case BackgroundAnimationType.gradient:
        return const _GradientBackground();
      case BackgroundAnimationType.particles:
        return const _ParticlesBackground();
      case BackgroundAnimationType.grid:
        return const _GridBackground();
      case BackgroundAnimationType.waves:
        return const _WavesBackground();
      case BackgroundAnimationType.starfield:
        return const _StarfieldBackground();
    }
  }
}

class BackgroundAnimationSelector extends StatelessWidget {
  final BackgroundAnimationType currentType;
  final ValueChanged<BackgroundAnimationType> onChanged;

  const BackgroundAnimationSelector({
    super.key,
    required this.currentType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<BackgroundAnimationType>(
      icon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF9c27b0).withValues(alpha: 0.2),
          border: Border.all(
            color: const Color(0xFF9c27b0),
            width: 1,
          ),
        ),
        child: Icon(
          currentType.icon,
          size: 20,
          color: const Color(0xFF9c27b0),
        ),
      ),
      tooltip: 'Change Background',
      onSelected: onChanged,
      itemBuilder: (context) => BackgroundAnimationType.values.map((type) {
        return PopupMenuItem<BackgroundAnimationType>(
          value: type,
          child: Row(
            children: [
              Icon(
                type.icon,
                size: 20,
                color: type == currentType
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                type.label,
                style: TextStyle(
                  fontWeight:
                      type == currentType ? FontWeight.bold : FontWeight.normal,
                  color: type == currentType
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              if (type == currentType) ...[
                const Spacer(),
                Icon(
                  Icons.check,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================================
// FLOATING ICONS BACKGROUND
// ============================================================================

class _FloatingIconsBackground extends StatefulWidget {
  const _FloatingIconsBackground();

  @override
  State<_FloatingIconsBackground> createState() =>
      _FloatingIconsBackgroundState();
}

class _FloatingIconsBackgroundState extends State<_FloatingIconsBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_FloatingIcon> _icons;
  final Random _random = Random();

  static const List<IconData> _gameIcons = [
    Icons.casino,
    Icons.sports_esports,
    Icons.emoji_events,
    Icons.star,
    Icons.favorite,
    Icons.diamond,
    Icons.bolt,
    Icons.local_fire_department,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _icons = List.generate(15, (index) => _generateIcon());
  }

  _FloatingIcon _generateIcon() {
    return _FloatingIcon(
      icon: _gameIcons[_random.nextInt(_gameIcons.length)],
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: 20 + _random.nextDouble() * 30,
      speed: 0.2 + _random.nextDouble() * 0.5,
      rotationSpeed: (_random.nextDouble() - 0.5) * 2,
      opacity: 0.05 + _random.nextDouble() * 0.1,
      phase: _random.nextDouble() * 2 * pi,
    );
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
        return CustomPaint(
          painter: _FloatingIconsPainter(
            icons: _icons,
            progress: _controller.value,
            iconColor: Theme.of(context).colorScheme.primary,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _FloatingIcon {
  final IconData icon;
  final double x;
  final double y;
  final double size;
  final double speed;
  final double rotationSpeed;
  final double opacity;
  final double phase;

  _FloatingIcon({
    required this.icon,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.rotationSpeed,
    required this.opacity,
    required this.phase,
  });
}

class _FloatingIconsPainter extends CustomPainter {
  final List<_FloatingIcon> icons;
  final double progress;
  final Color iconColor;

  _FloatingIconsPainter({
    required this.icons,
    required this.progress,
    required this.iconColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final icon in icons) {
      final y = (icon.y + progress * icon.speed) % 1.2 - 0.1;
      final x = icon.x + sin(progress * 2 * pi + icon.phase) * 0.05;

      final offset = Offset(x * size.width, y * size.height);

      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.icon.codePoint),
          style: TextStyle(
            fontSize: icon.size,
            fontFamily: icon.icon.fontFamily,
            package: icon.icon.fontPackage,
            color: iconColor.withValues(alpha: icon.opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(progress * icon.rotationSpeed * 2 * pi);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingIconsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// GRADIENT BACKGROUND
// ============================================================================

class _GradientBackground extends StatefulWidget {
  const _GradientBackground();

  @override
  State<_GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<_GradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<Color> _colors = [
    Color(0xFF1a1a2e),
    Color(0xFF16213e),
    Color.fromARGB(255, 88, 50, 129),
    Color(0xFF16213e),
    Color.fromARGB(255, 21, 67, 124),
    Color(0xFF1a1a2e),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
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
        final progress = _controller.value;
        final colorIndex = (progress * (_colors.length - 1)).floor();
        final colorProgress = (progress * (_colors.length - 1)) - colorIndex;

        final color1 = Color.lerp(
          _colors[colorIndex % _colors.length],
          _colors[(colorIndex + 1) % _colors.length],
          colorProgress,
        )!;
        final color2 = Color.lerp(
          _colors[(colorIndex + 1) % _colors.length],
          _colors[(colorIndex + 2) % _colors.length],
          colorProgress,
        )!;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color1, color2],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// PARTICLES/CONFETTI BACKGROUND
// ============================================================================

class _ParticlesBackground extends StatefulWidget {
  const _ParticlesBackground();

  @override
  State<_ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<_ParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final Random _random = Random();

  static const List<Color> _confettiColors = [
    Color(0xFFff6b6b),
    Color(0xFF4ecdc4),
    Color(0xFFffe66d),
    Color(0xFF95e1d3),
    Color(0xFFf38181),
    Color(0xFFaa96da),
    Color(0xFFfcbad3),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _particles = List.generate(40, (index) => _generateParticle());
  }

  _Particle _generateParticle() {
    return _Particle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: 4 + _random.nextDouble() * 8,
      speed: 0.3 + _random.nextDouble() * 0.4,
      color: _confettiColors[_random.nextInt(_confettiColors.length)],
      rotationSpeed: (_random.nextDouble() - 0.5) * 4,
      wobbleSpeed: 1 + _random.nextDouble() * 2,
      wobbleAmount: 0.02 + _random.nextDouble() * 0.03,
      phase: _random.nextDouble() * 2 * pi,
    );
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
        return CustomPaint(
          painter: _ParticlesPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final Color color;
  final double rotationSpeed;
  final double wobbleSpeed;
  final double wobbleAmount;
  final double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
    required this.rotationSpeed,
    required this.wobbleSpeed,
    required this.wobbleAmount,
    required this.phase,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlesPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final y = (particle.y + progress * particle.speed) % 1.2 - 0.1;
      final wobble =
          sin(progress * 2 * pi * particle.wobbleSpeed + particle.phase) *
              particle.wobbleAmount;
      final x = particle.x + wobble;

      final offset = Offset(x * size.width, y * size.height);
      final rotation = progress * particle.rotationSpeed * 2 * pi;

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(rotation);

      final paint = Paint()
        ..color = particle.color.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// GRID BACKGROUND
// ============================================================================

class _GridBackground extends StatefulWidget {
  const _GridBackground();

  @override
  State<_GridBackground> createState() => _GridBackgroundState();
}

class _GridBackgroundState extends State<_GridBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
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
        return CustomPaint(
          painter: _GridPainter(
            progress: _controller.value,
            primaryColor: Theme.of(context).colorScheme.primary,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;

  _GridPainter({
    required this.progress,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const gridSize = 50.0;
    final paint = Paint()
      ..color = primaryColor.withValues(alpha: 0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (double x = 0; x < size.width + gridSize; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw traveling light effect
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Horizontal traveling light
    final lightY = (progress * size.height * 1.5) % size.height;
    final nearestGridY = (lightY / gridSize).round() * gridSize;
    canvas.drawLine(
      Offset(0, nearestGridY),
      Offset(size.width, nearestGridY),
      glowPaint,
    );

    // Vertical traveling light
    final lightX = ((progress + 0.5) * size.width * 1.5) % size.width;
    final nearestGridX = (lightX / gridSize).round() * gridSize;
    canvas.drawLine(
      Offset(nearestGridX, 0),
      Offset(nearestGridX, size.height),
      glowPaint,
    );

    // Draw glowing intersection
    final intersectionPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(nearestGridX, nearestGridY),
      4 + sin(progress * 2 * pi) * 2,
      intersectionPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// WAVES BACKGROUND
// ============================================================================

class _WavesBackground extends StatefulWidget {
  const _WavesBackground();

  @override
  State<_WavesBackground> createState() => _WavesBackgroundState();
}

class _WavesBackgroundState extends State<_WavesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
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
        return CustomPaint(
          painter: _WavesPainter(
            progress: _controller.value,
            primaryColor: Theme.of(context).colorScheme.primary,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _WavesPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;

  _WavesPainter({
    required this.progress,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(canvas, size, 0.75, 0.08, primaryColor.withValues(alpha: 0.05), 0);
    _drawWave(
        canvas, size, 0.70, 0.10, primaryColor.withValues(alpha: 0.08), 0.33);
    _drawWave(
        canvas, size, 0.65, 0.12, primaryColor.withValues(alpha: 0.1), 0.66);
  }

  void _drawWave(Canvas canvas, Size size, double baseHeight,
      double waveHeight, Color color, double phaseOffset) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 1) {
      final normalizedX = x / size.width;
      final wave1 = sin((normalizedX * 4 * pi) + (progress + phaseOffset) * 2 * pi);
      final wave2 =
          sin((normalizedX * 2 * pi) + (progress + phaseOffset) * 2 * pi * 0.5) * 0.5;
      final combinedWave = (wave1 + wave2) / 1.5;

      final y =
          size.height * baseHeight + combinedWave * size.height * waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// STARFIELD BACKGROUND
// ============================================================================

class _StarfieldBackground extends StatefulWidget {
  const _StarfieldBackground();

  @override
  State<_StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<_StarfieldBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Star> _stars;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _stars = List.generate(80, (index) => _generateStar());
  }

  _Star _generateStar() {
    return _Star(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: 1 + _random.nextDouble() * 2,
      twinkleSpeed: 0.5 + _random.nextDouble() * 2,
      phase: _random.nextDouble() * 2 * pi,
      baseOpacity: 0.3 + _random.nextDouble() * 0.5,
    );
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
        return CustomPaint(
          painter: _StarfieldPainter(
            stars: _stars,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double twinkleSpeed;
  final double phase;
  final double baseOpacity;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleSpeed,
    required this.phase,
    required this.baseOpacity,
  });
}

class _StarfieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double progress;

  _StarfieldPainter({
    required this.stars,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final twinkle =
          (sin(progress * 2 * pi * star.twinkleSpeed + star.phase) + 1) / 2;
      final opacity = star.baseOpacity * (0.5 + twinkle * 0.5);

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final offset = Offset(star.x * size.width, star.y * size.height);

      // Draw star with glow effect
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(offset, star.size * 2, glowPaint);
      canvas.drawCircle(offset, star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

