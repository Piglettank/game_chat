import 'package:flutter/material.dart';
import '../models/tournament.dart' hide Offset;
import 'heat_box.dart';
import 'connection_painter.dart';

class BracketCanvas extends StatefulWidget {
  final Tournament tournament;
  final VoidCallback onTournamentChanged;
  final Function(String heatId) onDeleteHeat;
  final bool isReadOnly;

  const BracketCanvas({
    super.key,
    required this.tournament,
    required this.onTournamentChanged,
    required this.onDeleteHeat,
    this.isReadOnly = false,
  });

  @override
  State<BracketCanvas> createState() => _BracketCanvasState();
}

class _BracketCanvasState extends State<BracketCanvas> {
  final TransformationController _transformationController =
      TransformationController();

  // For connection dragging
  String? _draggingFromHeatId;
  Offset? _draggingEndPoint;

  // For disabling canvas pan when dragging a box
  bool _isBoxDragging = false;

  static const double gridSize = 20.0;
  static const double canvasWidth = 4000.0;
  static const double canvasHeight = 3000.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  double _snapToGrid(double value) {
    return (value / gridSize).round() * gridSize;
  }

  void _onHeatMoved(String heatId, Offset newPosition) {
    final heat = widget.tournament.getHeatById(heatId);
    if (heat != null) {
      // Store the raw position (no snapping during drag)
      // This allows small movements to accumulate
      heat.x = newPosition.dx;
      heat.y = newPosition.dy;
      widget.onTournamentChanged();
    }
  }

  void _onHeatDragEnded(String heatId) {
    final heat = widget.tournament.getHeatById(heatId);
    if (heat != null) {
      // Snap to grid only when drag ends
      heat.x = _snapToGrid(heat.x);
      heat.y = _snapToGrid(heat.y);
      widget.onTournamentChanged();
    }
  }

  void _onHeatUpdated() {
    widget.onTournamentChanged();
  }

  void _startConnectionDrag(String fromHeatId, Offset startPoint) {
    setState(() {
      _draggingFromHeatId = fromHeatId;
      _draggingEndPoint = startPoint;
    });
  }

  void _updateConnectionDrag(Offset point) {
    // Convert global position to canvas position
    final matrix = _transformationController.value;
    final inverseMatrix = Matrix4.inverted(matrix);
    final canvasPoint = MatrixUtils.transformPoint(inverseMatrix, point);

    setState(() {
      _draggingEndPoint = canvasPoint;
    });
  }

  void _endConnectionDrag(String? toHeatId) {
    if (_draggingFromHeatId != null && toHeatId != null) {
      // Don't allow self-connections
      if (_draggingFromHeatId != toHeatId) {
        widget.tournament.addConnection(
          Connection(fromHeatId: _draggingFromHeatId!, toHeatId: toHeatId),
        );
        widget.onTournamentChanged();
      }
    }
    setState(() {
      _draggingFromHeatId = null;
      _draggingEndPoint = null;
    });
  }

  void _cancelConnectionDrag() {
    setState(() {
      _draggingFromHeatId = null;
      _draggingEndPoint = null;
    });
  }

  void _onPlayerDroppedOnHeat(String targetHeatId, Player player) {
    final targetHeat = widget.tournament.getHeatById(targetHeatId);
    if (targetHeat != null) {
      // Create a copy of the player with a new ID
      final newPlayer = Player(name: player.name);
      targetHeat.players.add(newPlayer);
      widget.onTournamentChanged();
    }
  }

  void _deleteConnection(String connectionId) {
    widget.tournament.removeConnection(connectionId);
    widget.onTournamentChanged();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (_) {
            // Cancel connection drag if tapping elsewhere
            if (_draggingFromHeatId != null) {
              _cancelConnectionDrag();
            }
          },
          child: InteractiveViewer(
            transformationController: _transformationController,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.1,
            maxScale: 2.0,
            // Disable pan when dragging a box
            panEnabled: !_isBoxDragging,
            scaleEnabled: true,
            child: SizedBox(
              width: canvasWidth,
              height: canvasHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Grid background
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GridPainter(gridSize: gridSize),
                    ),
                  ),
                  // Connection lines
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ConnectionPainter(
                        tournament: widget.tournament,
                        draggingFromHeatId: _draggingFromHeatId,
                        draggingEndPoint: _draggingEndPoint,
                      ),
                    ),
                  ),
                  // Heat boxes
                  ...widget.tournament.heats.map(
                    (heat) => Positioned(
                      left: heat.x,
                      top: heat.y,
                      child: HeatBox(
                        key: ValueKey(heat.id),
                        heat: heat,
                        getScale: () =>
                            _transformationController.value.getMaxScaleOnAxis(),
                        onMoved: widget.isReadOnly ? null : (newPos) => _onHeatMoved(heat.id, newPos),
                        onUpdated: widget.isReadOnly ? null : _onHeatUpdated,
                        onDelete: widget.isReadOnly ? null : () => widget.onDeleteHeat(heat.id),
                        onStartConnectionDrag: widget.isReadOnly ? null : (startPoint) =>
                            _startConnectionDrag(heat.id, startPoint),
                        onUpdateConnectionDrag: widget.isReadOnly ? null : _updateConnectionDrag,
                        onEndConnectionDrag: widget.isReadOnly ? null : _endConnectionDrag,
                        onPlayerDropped: widget.isReadOnly ? null : (player) =>
                            _onPlayerDroppedOnHeat(heat.id, player),
                        connections: widget.tournament.getConnectionsFromHeat(
                          heat.id,
                        ),
                        onDeleteConnection: widget.isReadOnly ? null : _deleteConnection,
                        onDragStarted: widget.isReadOnly ? null : () =>
                            setState(() => _isBoxDragging = true),
                        onDragEnded: widget.isReadOnly ? null : () {
                          setState(() => _isBoxDragging = false);
                          _onHeatDragEnded(heat.id);
                        },
                        isReadOnly: widget.isReadOnly,
                      ),
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

/// Paints the grid background
class GridPainter extends CustomPainter {
  final double gridSize;

  GridPainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2a2a3a)
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize;
  }
}
