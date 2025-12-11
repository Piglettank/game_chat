import 'package:flutter/material.dart';
import 'chat_mixin.dart';
import '../core/tab_title.dart';

class ChatOnlyScreen extends StatefulWidget {
  final String chatId;
  final String userId;
  final String userName;

  const ChatOnlyScreen({
    super.key,
    required this.chatId,
    required this.userId,
    required this.userName,
  });

  @override
  State<ChatOnlyScreen> createState() => _ChatOnlyScreenState();
}

class _ChatOnlyScreenState extends State<ChatOnlyScreen> with ChatMixin {
  @override
  String get chatId => widget.chatId;

  @override
  String get userId => widget.userId;

  @override
  String get userName => widget.userName;

  @override
  void initState() {
    super.initState();
    setTabTitle('Chat');
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
    return Scaffold(
      body: buildChatSection(context),
    );
  }
}
