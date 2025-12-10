import 'package:flutter/material.dart';
import 'tournament.dart' hide Offset;

class PlayerCard extends StatefulWidget {
  final Player player;
  final Function(String) onNameChanged;
  final VoidCallback onDelete;

  const PlayerCard({
    super.key,
    required this.player,
    required this.onNameChanged,
    required this.onDelete,
  });

  @override
  State<PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<PlayerCard> {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.player.name);
  }

  @override
  void didUpdateWidget(PlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player.name != widget.player.name && !_isEditing) {
      _controller.text = widget.player.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Draggable<Player>(
        data: widget.player,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: 180,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a3e),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00bcd4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00bcd4).withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.content_copy,
                  size: 14,
                  color: Color(0xFF00bcd4),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.player.name,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.4, child: _buildCard()),
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _isHovering ? const Color(0xFF2a2a42) : const Color(0xFF252538),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isHovering
              ? const Color(0xFF00bcd4)
              : const Color(0xFF3a3a4a),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Drag handle icon (shows on hover)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _isHovering ? 1.0 : 0.0,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                Icons.drag_indicator,
                size: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
          // Player icon
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.cyan.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.person, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          // Name field
          Expanded(
            child: _isEditing
                ? TextField(
                    controller: _controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 4,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) {
                      widget.onNameChanged(value);
                      setState(() => _isEditing = false);
                    },
                    onEditingComplete: () {
                      widget.onNameChanged(_controller.text);
                      setState(() => _isEditing = false);
                    },
                  )
                : GestureDetector(
                    onDoubleTap: () => setState(() => _isEditing = true),
                    child: Text(
                      widget.player.name,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
          // Delete button
          GestureDetector(
            onTap: widget.onDelete,
            child: const Icon(Icons.close, size: 16, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
