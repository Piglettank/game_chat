import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/welcome_screen.dart';
import 'core/name_entry_screen.dart';
import 'services/user_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user data exists in localStorage
    final hasStoredUser = UserStorage.hasUserData();
    const chatId = 'tournament-chat';

    Widget homeWidget;
    if (hasStoredUser) {
      // Use stored user data
      final userId = UserStorage.getUserId();
      final userName = UserStorage.getUserName()!;
      homeWidget = WelcomeScreen(
        chatId: chatId,
        userId: userId,
        userName: userName,
      );
    } else {
      // Show name entry screen
      homeWidget = NameEntryScreen(chatId: chatId);
    }

    return MaterialApp(
      title: 'Game Night',
      theme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0d0d1a),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00bcd4),
          secondary: const Color(0xFFff6b35),
          surface: const Color(0xFF1a1a2e),
        ),
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter'),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1a1a2e),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF3a3a4a)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF00bcd4), width: 2),
          ),
        ),
      ),
      home: homeWidget,
      debugShowCheckedModeBanner: false,
    );
  }
}
