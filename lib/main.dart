import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'core/welcome_screen.dart';
import 'core/name_entry_screen.dart';
import 'core/edit_name_screen.dart';
import 'chat/chat_screen.dart' show LeaderboardScreen;
import 'chat/chat_only_screen.dart' show ChatScreen;
import 'tournament/bracket_list_screen.dart';
import 'tournament/tournament_bracket.dart';
import 'tournament/tournament.dart';
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

  static const String _chatId = 'tournament-chat';

  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/name-entry',
        name: 'name-entry',
        builder: (context, state) => NameEntryScreen(chatId: _chatId),
      ),
      // More specific routes must come before less specific ones
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) {
          final hasStoredUser = UserStorage.hasUserData();
          return ChatScreen(
            chatId: _chatId,
            userId: hasStoredUser ? UserStorage.getUserId() : '',
            userName: hasStoredUser ? UserStorage.getUserName()! : '',
          );
        },
      ),
      GoRoute(
        path: '/tournament',
        name: 'tournament',
        builder: (context, state) {
          final hasStoredUser = UserStorage.hasUserData();
          return LeaderboardScreen(
            chatId: _chatId,
            userId: hasStoredUser ? UserStorage.getUserId() : '',
            userName: hasStoredUser ? UserStorage.getUserName()! : '',
          );
        },
      ),
      GoRoute(
        path: '/brackets',
        name: 'brackets',
        builder: (context, state) => const BracketListScreen(),
      ),
      GoRoute(
        path: '/bracket/:id',
        name: 'bracket',
        builder: (context, state) {
          final bracketId = state.pathParameters['id']!;
          // Check if there's initial tournament data in extra
          final extra = state.extra as Map<String, dynamic>?;
          final initialTournament = extra?['initialTournament'] as Tournament?;
          return TournamentBracket(
            bracketId: bracketId,
            initialTournament: initialTournament,
          );
        },
      ),
      GoRoute(
        path: '/bracket',
        name: 'bracket-new',
        builder: (context, state) => const TournamentBracket(),
      ),
      GoRoute(
        path: '/edit-name',
        name: 'edit-name',
        builder: (context, state) {
          final hasStoredUser = UserStorage.hasUserData();
          return EditNameScreen(
            chatId: _chatId,
            userId: hasStoredUser ? UserStorage.getUserId() : '',
            userName: hasStoredUser ? UserStorage.getUserName()! : '',
          );
        },
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) {
          final hasStoredUser = UserStorage.hasUserData();
          if (hasStoredUser) {
            return WelcomeScreen(
              chatId: _chatId,
              userId: UserStorage.getUserId(),
              userName: UserStorage.getUserName()!,
            );
          } else {
            return NameEntryScreen(chatId: _chatId);
          }
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
