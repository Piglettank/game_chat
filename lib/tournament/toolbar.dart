import 'package:flutter/material.dart';

class BracketToolbar extends StatefulWidget {
  final String title;
  final Function(String) onTitleChanged;
  final VoidCallback onAddHeat;
  final VoidCallback onSave;
  final VoidCallback onLoad;

  const BracketToolbar({
    super.key,
    required this.title,
    required this.onTitleChanged,
    required this.onAddHeat,
    required this.onSave,
    required this.onLoad,
  });

  @override
  State<BracketToolbar> createState() => _BracketToolbarState();
}

class _BracketToolbarState extends State<BracketToolbar> {
  late TextEditingController _titleController;
  bool _isEditingTitle = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
  }

  @override
  void didUpdateWidget(BracketToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title && !_isEditingTitle) {
      _titleController.text = widget.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF151525),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF2a2a3a), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo / App icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFFff6b35), Color(0xFF00bcd4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.account_tree_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),

          // Tournament Title
          Expanded(
            child: _isEditingTitle
                ? TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1a1a2e),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF00bcd4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF00bcd4),
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (value) {
                      widget.onTitleChanged(value);
                      setState(() {
                        _isEditingTitle = false;
                      });
                    },
                  )
                : GestureDetector(
                    onDoubleTap: () {
                      setState(() {
                        _isEditingTitle = true;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
          ),

          const SizedBox(width: 16),

          // Action buttons
          _ToolbarButton(
            icon: Icons.add_box_outlined,
            label: 'Add Heat',
            onTap: widget.onAddHeat,
            isPrimary: true,
          ),
          const SizedBox(width: 12),
          _ToolbarButton(
            icon: Icons.save_outlined,
            label: 'Save',
            onTap: widget.onSave,
          ),
          const SizedBox(width: 12),
          _ToolbarButton(
            icon: Icons.folder_open_outlined,
            label: 'Load',
            onTap: widget.onLoad,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isPrimary
                ? const Color(0xFF00bcd4).withValues(alpha: 0.2)
                : const Color(0xFF2a2a3a),
            border: Border.all(
              color: isPrimary
                  ? const Color(0xFF00bcd4)
                  : const Color(0xFF3a3a4a),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary ? const Color(0xFF00bcd4) : Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? const Color(0xFF00bcd4) : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
