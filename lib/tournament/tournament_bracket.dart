import 'package:flutter/material.dart';
import '../models/tournament.dart' hide Offset;
import '../services/file_service.dart';
import 'bracket_canvas.dart';
import 'toolbar.dart';

class TournamentBracket extends StatelessWidget {
  const TournamentBracket({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tournament Bracket Creator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
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
      home: const TournamentBracketHome(),
    );
  }
}

class TournamentBracketHome extends StatefulWidget {
  const TournamentBracketHome({super.key});

  @override
  State<TournamentBracketHome> createState() => _TournamentBracketHomeState();
}

class _TournamentBracketHomeState extends State<TournamentBracketHome> {
  late Tournament _tournament;

  @override
  void initState() {
    super.initState();
    _tournament = Tournament(title: 'New Tournament');
    // Add some initial heats for demo
    _addInitialHeats();
  }

  void _addInitialHeats() {
    final heat1 = Heat(
      title: 'Heat 1',
      x: 100,
      y: 100,
      players: [
        Player(name: 'Player 1'),
        Player(name: 'Player 2'),
      ],
    );
    final heat2 = Heat(
      title: 'Heat 2',
      x: 100,
      y: 350,
      players: [
        Player(name: 'Player 3'),
        Player(name: 'Player 4'),
      ],
    );
    final semifinal = Heat(title: 'Semi-Final', x: 400, y: 200);
    final finalHeat = Heat(title: 'Final', x: 700, y: 200, isFinal: true);

    _tournament.heats.addAll([heat1, heat2, semifinal, finalHeat]);

    // Add connections
    _tournament.addConnection(
      Connection(fromHeatId: heat1.id, toHeatId: semifinal.id),
    );
    _tournament.addConnection(
      Connection(fromHeatId: heat2.id, toHeatId: semifinal.id),
    );
    _tournament.addConnection(
      Connection(fromHeatId: semifinal.id, toHeatId: finalHeat.id),
    );
  }

  void _onTournamentChanged() {
    setState(() {});
  }

  void _onTitleChanged(String newTitle) {
    setState(() {
      _tournament.title = newTitle;
    });
  }

  void _addHeat() {
    setState(() {
      final heatNumber = _tournament.heats.length + 1;
      _tournament.addHeat(
        Heat(
          title: 'Heat $heatNumber',
          x: 100 + (heatNumber * 50),
          y: 100 + (heatNumber * 30),
        ),
      );
    });
  }

  void _deleteHeat(String heatId) {
    setState(() {
      _tournament.removeHeat(heatId);
    });
  }

  Future<void> _saveTournament() async {
    final success = await FileService.saveTournament(_tournament);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Tournament saved successfully!'
                : 'Failed to save tournament',
          ),
          backgroundColor: success
              ? const Color(0xFF4caf50)
              : const Color(0xFFf44336),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _loadTournament() async {
    final loaded = await FileService.loadTournament();
    if (loaded != null) {
      setState(() {
        _tournament = loaded;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tournament loaded successfully!'),
            backgroundColor: const Color(0xFF4caf50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
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
      child: Scaffold(
        body: Column(
          children: [
            // Toolbar
            BracketToolbar(
              title: _tournament.title,
              onTitleChanged: _onTitleChanged,
              onAddHeat: _addHeat,
              onSave: _saveTournament,
              onLoad: _loadTournament,
            ),
            // Canvas
            Expanded(
              child: BracketCanvas(
                tournament: _tournament,
                onTournamentChanged: _onTournamentChanged,
                onDeleteHeat: _deleteHeat,
              ),
            ),
          ],
        ),
      ),
    );
  }
}