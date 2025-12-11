import 'package:flutter/material.dart';
import 'chat_mixin.dart';
import '../leaderboard/leaderboard_widget.dart';
import '../core/app_header.dart';
import '../core/toolbar_button.dart';
import '../core/tab_title.dart';

class LeaderboardScreen extends StatefulWidget {
  final String chatId;
  final String userId;
  final String userName;

  const LeaderboardScreen({
    super.key,
    required this.chatId,
    required this.userId,
    required this.userName,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with ChatMixin {
  bool _isLeaderboardEditMode = false;
  final GlobalKey<LeaderboardWidgetState> _leaderboardKey =
      GlobalKey<LeaderboardWidgetState>();

  @override
  String get chatId => widget.chatId;

  @override
  String get userId => widget.userId;

  @override
  String get userName => widget.userName;

  @override
  void initState() {
    super.initState();
    setTabTitle('Leaderboard');
    initializeChat();
  }

  @override
  void dispose() {
    setTabTitle('Game Night');
    disposeChat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhoneSize = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Row(
        children: [
          // Leaderboard section (left half)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: _buildLeaderboard(context),
            ),
          ),
          // Chat section (right half) - hidden on phone screens
          if (!isPhoneSize) Expanded(child: buildChatSection(context)),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppHeader(
          icon: Icons.emoji_events,
          title: 'Leaderboard',
          onBack: () => Navigator.of(context).pop(),
          actions: [
            if (_isLeaderboardEditMode) ...[
              ToolbarButton(
                icon: Icons.cancel,
                label: 'Cancel',
                onTap: () {
                  _leaderboardKey.currentState?.cancelEdit();
                  setState(() {
                    _isLeaderboardEditMode = false;
                  });
                },
                hideTextOnMobile: true,
              ),
              const SizedBox(width: 12),
              ToolbarButton(
                icon: Icons.save,
                label: 'Save',
                onTap: () {
                  _leaderboardKey.currentState?.saveLeaderboard();
                },
                isPrimary: true,
                hideTextOnMobile: true,
              ),
            ] else
              ToolbarButton(
                icon: Icons.edit,
                label: 'Edit',
                onTap: () {
                  setState(() {
                    _isLeaderboardEditMode = true;
                  });
                },
                isPrimary: true,
                hideTextOnMobile: true,
              ),
          ],
        ),
        Expanded(
          child: LeaderboardWidget(
            key: _leaderboardKey,
            isEditMode: _isLeaderboardEditMode,
            onSave: () {
              setState(() {
                _isLeaderboardEditMode = false;
              });
            },
          ),
        ),
      ],
    );
  }
}
