import 'package:flutter/material.dart';
import 'tournament.dart' hide Offset;

/// A small thumbnail preview of a tournament bracket
class BracketThumbnail extends StatelessWidget {
  final Tournament tournament;
  final double width;
  final double height;

  const BracketThumbnail({
    super.key,
    required this.tournament,
    this.width = 120,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (tournament.heats.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            Icons.grid_view_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            size: 24,
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: CustomPaint(
          size: Size(width, height),
          painter: _BracketThumbnailPainter(tournament: tournament),
        ),
      ),
    );
  }
}

class _BracketThumbnailPainter extends CustomPainter {
  final Tournament tournament;

  _BracketThumbnailPainter({required this.tournament});

  @override
  void paint(Canvas canvas, Size size) {
    if (tournament.heats.isEmpty) return;

    // Calculate bounds of all heats
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final heat in tournament.heats) {
      minX = minX < heat.x ? minX : heat.x;
      minY = minY < heat.y ? minY : heat.y;
      maxX = maxX > (heat.x + heat.width) ? maxX : (heat.x + heat.width);
      maxY = maxY > (heat.y + heat.height) ? maxY : (heat.y + heat.height);
    }

    // Add some padding
    const padding = 20.0;
    minX -= padding;
    minY -= padding;
    maxX += padding;
    maxY += padding;

    final contentWidth = maxX - minX;
    final contentHeight = maxY - minY;

    // Calculate scale to fit content in thumbnail
    final scaleX = size.width / contentWidth;
    final scaleY = size.height / contentHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Center the content
    final scaledWidth = contentWidth * scale;
    final scaledHeight = contentHeight * scale;
    final offsetX = (size.width - scaledWidth) / 2;
    final offsetY = (size.height - scaledHeight) / 2;

    // Transform function
    Offset transform(double x, double y) {
      return Offset(
        offsetX + (x - minX) * scale,
        offsetY + (y - minY) * scale,
      );
    }

    // Draw subtle grid
    _drawGrid(canvas, size);

    // Draw connections first (behind boxes)
    _drawConnections(canvas, scale, transform);

    // Draw heat boxes
    _drawHeats(canvas, scale, transform);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2a2a3a).withOpacity(0.5)
      ..strokeWidth = 0.5;

    const gridSize = 10.0;
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawConnections(Canvas canvas, double scale, Offset Function(double, double) transform) {
    for (final connection in tournament.connections) {
      final fromHeat = tournament.getHeatById(connection.fromHeatId);
      final toHeat = tournament.getHeatById(connection.toHeatId);

      if (fromHeat != null && toHeat != null) {
        final start = transform(
          fromHeat.x + fromHeat.width,
          fromHeat.y + fromHeat.height / 2,
        );
        final end = transform(
          toHeat.x,
          toHeat.y + toHeat.height / 2,
        );

        final paint = Paint()
          ..color = _getConnectionColor(connection)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        final path = Path();
        path.moveTo(start.dx, start.dy);

        final dx = end.dx - start.dx;
        final controlOffset = dx.abs() * 0.4;

        path.cubicTo(
          start.dx + controlOffset, start.dy,
          end.dx - controlOffset, end.dy,
          end.dx, end.dy,
        );

        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawHeats(Canvas canvas, double scale, Offset Function(double, double) transform) {
    for (final heat in tournament.heats) {
      final topLeft = transform(heat.x, heat.y);
      final scaledWidth = heat.width * scale;
      final scaledHeight = heat.height * scale;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(topLeft.dx, topLeft.dy, scaledWidth, scaledHeight),
        const Radius.circular(4),
      );

      // Box fill
      final fillPaint = Paint()
        ..color = heat.isFinal
            ? const Color(0xFF2d2a4a)
            : const Color(0xFF252535)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, fillPaint);

      // Box border
      final borderPaint = Paint()
        ..color = heat.isFinal
            ? const Color(0xFFffd700).withOpacity(0.6)
            : const Color(0xFF3a3a4a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = heat.isFinal ? 1.5 : 1;
      canvas.drawRRect(rect, borderPaint);

      // Draw small player indicators
      if (scale > 0.08) {
        final playerIndicatorPaint = Paint()
          ..color = const Color(0xFF4a4a5a)
          ..style = PaintingStyle.fill;

        final indicatorHeight = 4.0 * scale.clamp(0.5, 1.5);
        final indicatorMargin = 3.0 * scale.clamp(0.5, 1.5);
        final startY = topLeft.dy + 15 * scale;

        for (int i = 0; i < heat.players.length && i < 4; i++) {
          final indicatorRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              topLeft.dx + 4 * scale,
              startY + i * (indicatorHeight + indicatorMargin),
              scaledWidth - 8 * scale,
              indicatorHeight,
            ),
            const Radius.circular(2),
          );
          canvas.drawRRect(indicatorRect, playerIndicatorPaint);
        }
      }
    }
  }

  Color _getConnectionColor(Connection connection) {
    final hash = connection.id.hashCode;
    final colors = [
      const Color(0xFFff6b35),
      const Color(0xFF00bcd4),
      const Color(0xFF4caf50),
      const Color(0xFFe91e63),
      const Color(0xFF9c27b0),
      const Color(0xFFffeb3b),
    ];
    return colors[hash.abs() % colors.length].withOpacity(0.7);
  }

  @override
  bool shouldRepaint(covariant _BracketThumbnailPainter oldDelegate) {
    return oldDelegate.tournament != tournament;
  }
}

