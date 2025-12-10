import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'tournament.dart' hide Offset;
import 'player_card.dart';

/// A pan gesture recognizer that starts immediately with no movement threshold
class ImmediatePanGestureRecognizer extends PanGestureRecognizer {
  ImmediatePanGestureRecognizer() {
    // Set slop to zero so any movement is detected immediately
    gestureSettings = const DeviceGestureSettings(touchSlop: 0);
  }
}

class HeatBox extends StatefulWidget {
  final Heat heat;
  final Function(Offset)? onMoved;
  final VoidCallback? onUpdated;
  final VoidCallback? onDelete;
  final Function(Offset)? onStartConnectionDrag;
  final Function(Offset)? onUpdateConnectionDrag;
  final Function(String?)? onEndConnectionDrag;
  final Function(Player)? onPlayerDropped;
  final List<Connection> connections;
  final Function(String)? onDeleteConnection;
  final double Function() getScale;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;
  final bool isReadOnly;

  const HeatBox({
    super.key,
    required this.heat,
    this.onMoved,
    this.onUpdated,
    this.onDelete,
    this.onStartConnectionDrag,
    this.onUpdateConnectionDrag,
    this.onEndConnectionDrag,
    this.onPlayerDropped,
    required this.connections,
    this.onDeleteConnection,
    required this.getScale,
    this.onDragStarted,
    this.onDragEnded,
    this.isReadOnly = false,
  });

  @override
  State<HeatBox> createState() => _HeatBoxState();
}

class _HeatBoxState extends State<HeatBox> {
  late TextEditingController _titleController;
  bool _isEditingTitle = false;
  bool _isHoveringOutputKnob = false;
  bool _isHoveringInputKnob = false;
  bool _isHoveringMoveBar = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.heat.title);
  }

  @override
  void didUpdateWidget(HeatBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heat.title != widget.heat.title && !_isEditingTitle) {
      _titleController.text = widget.heat.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    if (widget.isReadOnly || widget.onUpdated == null) return;
    widget.heat.players.add(
      Player(name: 'Player ${widget.heat.players.length + 1}'),
    );
    widget.onUpdated!();
  }

  void _removePlayer(String playerId) {
    if (widget.isReadOnly || widget.onUpdated == null) return;
    widget.heat.players.removeWhere((p) => p.id == playerId);
    widget.onUpdated!();
  }

  void _updatePlayerName(String playerId, String newName) {
    if (widget.isReadOnly || widget.onUpdated == null) return;
    final player = widget.heat.players.firstWhere((p) => p.id == playerId);
    player.name = newName;
    widget.onUpdated!();
  }

  void _toggleFinal() {
    if (widget.isReadOnly || widget.onUpdated == null) return;
    widget.heat.isFinal = !widget.heat.isFinal;
    widget.onUpdated!();
  }

  BoxDecoration _getBoxDecoration() {
    if (widget.heat.isFinal) {
      return BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFffd700), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFffd700).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      );
    }
    return BoxDecoration(
      color: const Color(0xFF1a1a2e),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF4a4a5a), width: 2),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    if (!widget.isReadOnly && widget.onMoved != null) {
      setState(() => _isDragging = true);
      widget.onDragStarted?.call();
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isDragging && widget.onMoved != null && !widget.isReadOnly) {
      // Get current scale and convert screen delta to canvas delta
      final scale = widget.getScale();
      final effectiveScale = scale > 0 ? scale : 1.0;
      final newX = widget.heat.x + (details.delta.dx / effectiveScale);
      final newY = widget.heat.y + (details.delta.dy / effectiveScale);
      widget.onMoved!(Offset(newX, newY));
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    widget.onDragEnded?.call();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<Player>(
      onAcceptWithDetails: widget.isReadOnly || widget.onPlayerDropped == null
          ? null
          : (details) {
              widget.onPlayerDropped!(details.data);
            },
      builder: (context, candidateData, rejectedData) {
        final isReceivingPlayer = candidateData.isNotEmpty;
        return Container(
          width: widget.heat.width,
          constraints: BoxConstraints(minHeight: widget.heat.height),
          decoration: _getBoxDecoration().copyWith(
            border: isReceivingPlayer
                ? Border.all(color: const Color(0xFF00bcd4), width: 3)
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header row with title and controls
                    Row(
                      children: [
                        // Final toggle
                        GestureDetector(
                          onTap: widget.isReadOnly ? null : _toggleFinal,
                          child: Opacity(
                            opacity: widget.isReadOnly ? 0.5 : 1.0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.heat.isFinal
                                    ? const Color(0xFFffd700)
                                    : const Color(0xFF3a3a4a),
                              ),
                              child: Icon(
                                Icons.emoji_events,
                                size: 16,
                                color: widget.heat.isFinal
                                    ? Colors.black
                                    : Colors.white54,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Title
                        Expanded(
                          child: _isEditingTitle
                              ? TextField(
                                  controller: _titleController,
                                  autofocus: true,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 8,
                                    ),
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (value) {
                                    widget.heat.title = value;
                                    widget.onUpdated?.call();
                                    setState(() {
                                      _isEditingTitle = false;
                                    });
                                  },
                                  onEditingComplete: () {
                                    widget.heat.title = _titleController.text;
                                    widget.onUpdated?.call();
                                    setState(() {
                                      _isEditingTitle = false;
                                    });
                                  },
                                )
                              : GestureDetector(
                                  onDoubleTap: widget.isReadOnly
                                      ? null
                                      : () {
                                          setState(() {
                                            _isEditingTitle = true;
                                          });
                                        },
                                  child: Text(
                                    widget.heat.isFinal
                                        ? '🏆 ${widget.heat.title}'
                                        : widget.heat.title,
                                    style: TextStyle(
                                      color: widget.heat.isFinal
                                          ? const Color(0xFFffd700)
                                          : Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                        // Delete button
                        if (!widget.isReadOnly && widget.onDelete != null)
                          GestureDetector(
                            onTap: widget.onDelete,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF3a3a4a),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Players list
                    ...widget.heat.players.map(
                      (player) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PlayerCard(
                          player: player,
                          onNameChanged: widget.isReadOnly
                              ? (_) {}
                              : (name) => _updatePlayerName(player.id, name),
                          onDelete: widget.isReadOnly
                              ? () {}
                              : () => _removePlayer(player.id),
                        ),
                      ),
                    ),
                    // Add player button
                    if (!widget.isReadOnly)
                      Center(
                        child: GestureDetector(
                          onTap: _addPlayer,
                          child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFF00bcd4,
                            ).withValues(alpha: 0.2),
                            border: Border.all(
                              color: const Color(0xFF00bcd4),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 18,
                            color: Color(0xFF00bcd4),
                          ),
                        ),
                      ),
                    ),
                    if (!widget.isReadOnly) ...[
                      const SizedBox(height: 8),
                      // Drag handle bar at the bottom - using RawGestureDetector for immediate response
                      RawGestureDetector(
                        behavior: HitTestBehavior.opaque,
                        gestures: <Type, GestureRecognizerFactory>{
                          ImmediatePanGestureRecognizer:
                              GestureRecognizerFactoryWithHandlers<
                                ImmediatePanGestureRecognizer
                              >(() => ImmediatePanGestureRecognizer(), (
                                ImmediatePanGestureRecognizer instance,
                              ) {
                                instance
                                  ..onStart = _handlePanStart
                                  ..onUpdate = _handlePanUpdate
                                  ..onEnd = _handlePanEnd;
                              }),
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.move,
                          onEnter: (_) =>
                              setState(() => _isHoveringMoveBar = true),
                          onExit: (_) =>
                              setState(() => _isHoveringMoveBar = false),
                          child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: _isDragging
                                ? const Color(0xFF00bcd4)
                                : _isHoveringMoveBar
                                ? const Color(0xFF3a3a4a)
                                : const Color(0xFF252538),
                            borderRadius: BorderRadius.circular(6),
                            border: _isHoveringMoveBar || _isDragging
                                ? Border.all(
                                    color: _isDragging
                                        ? const Color(0xFF00bcd4)
                                        : const Color(
                                            0xFF00bcd4,
                                          ).withValues(alpha: 0.5),
                                    width: 1,
                                  )
                                : null,
                            boxShadow: _isDragging
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00bcd4,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isDragging
                                    ? Icons.open_with
                                    : Icons.drag_handle,
                                size: _isHoveringMoveBar || _isDragging
                                    ? 20
                                    : 16,
                                color: _isDragging
                                    ? Colors.white
                                    : _isHoveringMoveBar
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isDragging ? 'MOVING...' : 'DRAG TO MOVE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _isDragging
                                      ? Colors.white
                                      : _isHoveringMoveBar
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : Colors.white.withValues(alpha: 0.4),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Left connection knob (input) with hover effect
              Positioned(
                left: -10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: DragTarget<String>(
                    onAcceptWithDetails: widget.isReadOnly ||
                            widget.onEndConnectionDrag == null
                        ? null
                        : (details) {
                            widget.onEndConnectionDrag!(widget.heat.id);
                          },
                    builder: (context, candidateData, rejectedData) {
                      final isReceiving = candidateData.isNotEmpty;
                      return MouseRegion(
                        onEnter: (_) =>
                            setState(() => _isHoveringInputKnob = true),
                        onExit: (_) =>
                            setState(() => _isHoveringInputKnob = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: isReceiving || _isHoveringInputKnob ? 24 : 20,
                          height: isReceiving || _isHoveringInputKnob ? 24 : 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isReceiving
                                ? const Color(0xFF00bcd4)
                                : _isHoveringInputKnob
                                ? const Color(0xFF4a4a5a)
                                : const Color(0xFF3a3a4a),
                            border: Border.all(
                              color: isReceiving
                                  ? const Color(0xFF00bcd4)
                                  : _isHoveringInputKnob
                                  ? const Color(0xFF00bcd4)
                                  : const Color(0xFF5a5a6a),
                              width: 2,
                            ),
                            boxShadow: isReceiving || _isHoveringInputKnob
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00bcd4,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Right connection knob (output) with hover effect
              Positioned(
                right: -10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    onEnter: (_) =>
                        setState(() => _isHoveringOutputKnob = true),
                    onExit: (_) =>
                        setState(() => _isHoveringOutputKnob = false),
                    child: Draggable<String>(
                      data: widget.heat.id,
                      feedback: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00bcd4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF00bcd4,
                              ).withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      onDragStarted: widget.isReadOnly ||
                              widget.onStartConnectionDrag == null
                          ? null
                          : () {
                              widget.onStartConnectionDrag!(
                                Offset(
                                  widget.heat.x + widget.heat.width,
                                  widget.heat.y + (widget.heat.height / 2),
                                ),
                              );
                            },
                      onDragUpdate: widget.isReadOnly ||
                              widget.onUpdateConnectionDrag == null
                          ? null
                          : (details) {
                              widget.onUpdateConnectionDrag!(details.globalPosition);
                            },
                      onDragEnd: widget.isReadOnly ||
                              widget.onEndConnectionDrag == null
                          ? null
                          : (details) {
                              widget.onEndConnectionDrag!(null);
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: _isHoveringOutputKnob ? 26 : 20,
                        height: _isHoveringOutputKnob ? 26 : 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isHoveringOutputKnob
                              ? const Color(0xFFff6b35)
                              : const Color(0xFF3a3a4a),
                          border: Border.all(
                            color: const Color(0xFFff6b35),
                            width: 2,
                          ),
                          boxShadow: _isHoveringOutputKnob
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFff6b35,
                                    ).withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          size: _isHoveringOutputKnob ? 14 : 10,
                          color: _isHoveringOutputKnob
                              ? Colors.white
                              : const Color(0xFFff6b35),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

extension BoxDecorationCopyWith on BoxDecoration {
  BoxDecoration copyWith({Border? border}) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius,
      border: border ?? this.border,
      boxShadow: boxShadow,
      gradient: gradient,
      image: image,
      shape: shape,
    );
  }
}
