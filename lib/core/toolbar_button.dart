import 'package:flutter/material.dart';

class ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDelete;

  const ToolbarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isDelete = false,
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
                : isDelete
                    ? const Color(0xFFff6b35).withValues(alpha: 0.2)
                    : const Color(0xFF2a2a3a),
            border: Border.all(
              color: isPrimary
                  ? const Color(0xFF00bcd4)
                  : isDelete
                      ? const Color(0xFFff6b35)
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
                color: isPrimary
                    ? const Color(0xFF00bcd4)
                    : isDelete
                        ? const Color(0xFFff6b35)
                        : Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? const Color(0xFF00bcd4)
                      : isDelete
                          ? const Color(0xFFff6b35)
                          : Colors.white70,
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
