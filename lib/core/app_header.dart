import 'package:flutter/material.dart';

class AppHeader extends StatefulWidget {
  final IconData icon;
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool isEditable;
  final ValueChanged<String>? onTitleChanged;

  const AppHeader({
    super.key,
    required this.icon,
    required this.title,
    this.actions,
    this.onBack,
    this.isEditable = false,
    this.onTitleChanged,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
  }

  @override
  void didUpdateWidget(AppHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title && _titleController.text != widget.title) {
      // Only update if the text differs (external change, not from user typing)
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final iconSize = isMobile ? 18.0 : 22.0;
    final iconContainerSize = isMobile ? 32.0 : 40.0;
    final fontSize = isMobile ? 16.0 : 20.0;
    final headerHeight = isMobile ? 56.0 : 64.0;
    final horizontalPadding = isMobile ? 16.0 : 20.0;
    final spacing = isMobile ? 12.0 : 16.0;
    final backButtonSize = isMobile ? 28.0 : 32.0;
    final backIconSize = isMobile ? 16.0 : 18.0;

    return Container(
      height: headerHeight,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
          // Back button
          if (widget.onBack != null) ...[
            GestureDetector(
              onTap: widget.onBack,
              child: Container(
                width: backButtonSize,
                height: backButtonSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: backIconSize,
                ),
              ),
            ),
            SizedBox(width: spacing),
          ],
          // Logo / App icon (hidden when in edit mode)
          if (!widget.isEditable) ...[
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFFff6b35), Color(0xFF00bcd4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(widget.icon, color: Colors.white, size: iconSize),
            ),
            SizedBox(width: spacing),
          ],
          // Title (editable if enabled)
          Expanded(
            child: widget.isEditable && widget.onTitleChanged != null
                ? TextField(
                    controller: _titleController,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1a1a2e),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF00bcd4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF00bcd4),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      widget.onTitleChanged!(value);
                    },
                    onSubmitted: (value) {
                      widget.onTitleChanged!(value);
                    },
                  )
                : Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          if (widget.actions != null) ...[
            SizedBox(width: spacing),
            ...widget.actions!,
          ],
        ],
      ),
    );
  }
}
