import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/chat_screen.dart';
import 'models/embed_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get config from URL parameters
  EmbedConfig config = EmbedConfig.fromUrlParams();

  // Initialize Firebase
  FirebaseOptions firebaseOptions;
  if (config.firebaseOptions != null) {
    firebaseOptions = config.firebaseOptions!;
  } else {
    firebaseOptions = DefaultFirebaseOptions.currentPlatform;
  }

  await Firebase.initializeApp(options: firebaseOptions);

  runApp(MyApp(config: config));
}

class MyApp extends StatelessWidget {
  final EmbedConfig config;

  const MyApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigoAccent),
        useMaterial3: true,
        fontFamily: 'Verdana',
      ),
      home: Scaffold(
        body: ChatScreen(
          chatId: config.chatId,
          userId: config.userId,
          userName: config.userName,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
