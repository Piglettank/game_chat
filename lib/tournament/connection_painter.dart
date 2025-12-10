import 'package:flutter/material.dart';
import '../models/tournament.dart' hide Offset;

class ConnectionPainter extends CustomPainter {
  final Tournament tournament;
  final String? draggingFromHeatId;
  final Offset? draggingEndPoint;

  ConnectionPainter({
    required this.tournament,
    this.draggingFromHeatId,
    this.draggingEndPoint,
  });

  // Knob offset from box edge (matches Positioned left/right: -10 in HeatBox)
  // The knob is 20px wide, centered, so its center is at the box edge
  // But we want the line to START from the outer edge of the knob
  static const double knobOffset = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Paint existing connections
    for (final connection in tournament.connections) {
      final fromHeat = tournament.getHeatById(connection.fromHeatId);
      final toHeat = tournament.getHeatById(connection.toHeatId);

      if (fromHeat != null && toHeat != null) {
        // Start from right knob center (box edge + half knob width)
        final startPoint = Offset(
          fromHeat.x + fromHeat.width + knobOffset,
          fromHeat.y + fromHeat.height / 2,
        );
        // End at left knob center (box edge - half knob width)
        final endPoint = Offset(
          toHeat.x - knobOffset,
          toHeat.y + toHeat.height / 2,
        );

        _drawCurvedConnection(
          canvas,
          startPoint,
          endPoint,
          _getConnectionColor(connection),
        );
      }
    }

    // Paint dragging connection
    if (draggingFromHeatId != null && draggingEndPoint != null) {
      final fromHeat = tournament.getHeatById(draggingFromHeatId!);
      if (fromHeat != null) {
        final startPoint = Offset(
          fromHeat.x + fromHeat.width + knobOffset,
          fromHeat.y + fromHeat.height / 2,
        );

        _drawCurvedConnection(
          canvas,
          startPoint,
          draggingEndPoint!,
          const Color(0xFF00bcd4),
          isDragging: true,
        );
      }
    }
  }

  void _drawCurvedConnection(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color, {
    bool isDragging = false,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = isDragging ? 3 : 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isDragging) {
      paint.strokeWidth = 3;
      // Dashed effect for dragging
      final dashPath = Path();
      final path = _createBezierPath(start, end);

      final pathMetrics = path.computeMetrics();
      for (final metric in pathMetrics) {
        double distance = 0;
        bool draw = true;
        while (distance < metric.length) {
          final length = draw ? 10 : 6;
          final extractPath = metric.extractPath(distance, distance + length);
          if (draw) {
            dashPath.addPath(extractPath, Offset.zero);
          }
          distance += length;
          draw = !draw;
        }
      }
      canvas.drawPath(dashPath, paint);
    } else {
      final path = _createBezierPath(start, end);
      canvas.drawPath(path, paint);

      // Draw arrow at the end
      _drawArrow(canvas, start, end, color);
    }

    // Draw small circles at connection points
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(start, 4, circlePaint);
    if (!isDragging) {
      canvas.drawCircle(end, 4, circlePaint);
    }
  }

  Path _createBezierPath(Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Calculate control points for smooth S-curve
    final dx = end.dx - start.dx;
    final controlOffset = dx.abs() * 0.4;

    final cp1 = Offset(start.dx + controlOffset, start.dy);
    final cp2 = Offset(end.dx - controlOffset, end.dy);

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);

    return path;
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Calculate arrow direction at the end of the curve
    final dx = end.dx - start.dx;
    final controlOffset = dx.abs() * 0.4;
    final cp2 = Offset(end.dx - controlOffset, end.dy);

    // Direction from last control point to end
    final direction = (end - cp2);
    final normalizedDir = direction / direction.distance;

    // Arrow size
    const arrowLength = 10.0;
    const arrowWidth = 6.0;

    // Arrow points
    final arrowTip = end;
    final arrowBase = end - normalizedDir * arrowLength;
    final perpendicular = Offset(-normalizedDir.dy, normalizedDir.dx);

    final arrowLeft = arrowBase + perpendicular * arrowWidth;
    final arrowRight = arrowBase - perpendicular * arrowWidth;

    final arrowPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(arrowLeft.dx, arrowLeft.dy)
      ..lineTo(arrowRight.dx, arrowRight.dy)
      ..close();

    canvas.drawPath(arrowPath, paint);
  }

  Color _getConnectionColor(Connection connection) {
    // Generate consistent color based on connection id hash
    final hash = connection.id.hashCode;
    final colors = [
      const Color(0xFFff6b35), // Orange
      const Color(0xFF00bcd4), // Cyan
      const Color(0xFF4caf50), // Green
      const Color(0xFFe91e63), // Pink
      const Color(0xFF9c27b0), // Purple
      const Color(0xFFffeb3b), // Yellow
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    return oldDelegate.tournament != tournament ||
        oldDelegate.draggingFromHeatId != draggingFromHeatId ||
        oldDelegate.draggingEndPoint != draggingEndPoint;
  }
}
