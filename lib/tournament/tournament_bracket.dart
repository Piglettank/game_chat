import 'dart:async';
import 'package:flutter/material.dart';
import 'tournament.dart' hide Offset;
import 'saved_tournament_bracket.dart';
import 'tournament_bracket_service.dart';
import 'bracket_canvas.dart';
import 'toolbar.dart';
import '../core/tab_title.dart';

class TournamentBracket extends StatefulWidget {
  final String? bracketId;
  final Tournament? initialTournament;

  const TournamentBracket({super.key, this.bracketId, this.initialTournament});

  @override
  State<TournamentBracket> createState() => _TournamentBracketState();
}

class _TournamentBracketState extends State<TournamentBracket> {
  late Tournament _tournament;
  final TournamentBracketService _service = TournamentBracketService();
  bool _isLoading = false;
  String? _currentBracketId;
  bool _isEditMode = false;
  StreamSubscription<SavedTournamentBracket?>? _bracketSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.initialTournament != null) {
      _tournament = widget.initialTournament!;
      _currentBracketId = widget.bracketId;
      setTabTitle(_tournament.title);
      // Start in view mode if loading existing bracket
      _isEditMode = false;
      if (widget.bracketId != null) {
        _startStreamingBracket(widget.bracketId!);
      }
    } else if (widget.bracketId != null) {
      _loadBracket(widget.bracketId!);
    } else {
      _tournament = Tournament(title: 'New Tournament');
      setTabTitle(_tournament.title);
      // New brackets start in edit mode
      _isEditMode = true;
    }
  }

  @override
  void dispose() {
    setTabTitle('Game Night');
    _bracketSubscription?.cancel();
    super.dispose();
  }

  void _startStreamingBracket(String bracketId) {
    _bracketSubscription?.cancel();
    _bracketSubscription = _service
        .streamBracket(bracketId)
        .listen(
          (bracket) {
            if (bracket != null && mounted && !_isEditMode) {
              // Only update if not in edit mode (to avoid conflicts)
              setState(() {
                _tournament = bracket.tournament;
                setTabTitle(_tournament.title);
              });
            }
          },
          onError: (error) {
            if (mounted) {
              debugPrint('Error streaming bracket: $error');
            }
          },
        );
  }

  Future<void> _loadBracket(String bracketId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bracket = await _service.getBracket(bracketId);
      if (bracket != null && mounted) {
        setState(() {
          _tournament = bracket.tournament;
          _currentBracketId = bracketId;
          _isLoading = false;
          _isEditMode = false; // Start in view mode
        });
        setTabTitle(_tournament.title);
        _startStreamingBracket(bracketId);
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bracket not found'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bracket: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onTournamentChanged() {
    setState(() {});
  }

  void _onTitleChanged(String newTitle) {
    setState(() {
      _tournament.title = newTitle;
      setTabTitle(newTitle);
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
    try {
      if (_currentBracketId != null) {
        // Update existing bracket
        await _service.updateBracket(
          bracketId: _currentBracketId!,
          tournament: _tournament,
        );
        // Exit edit mode after saving
        setState(() {
          _isEditMode = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Bracket updated successfully!'),
              backgroundColor: const Color(0xFF4caf50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        // Create new bracket
        final bracketId = await _service.saveBracket(tournament: _tournament);
        setState(() {
          _currentBracketId = bracketId;
          _isEditMode = false; // Exit edit mode after saving
        });
        _startStreamingBracket(bracketId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Bracket saved successfully!'),
              backgroundColor: const Color(0xFF4caf50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save bracket: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _enterEditMode() {
    setState(() {
      _isEditMode = true;
    });
    // Stop streaming when entering edit mode
    _bracketSubscription?.cancel();
  }

  Future<void> _deleteBracket() async {
    if (_currentBracketId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bracket'),
        content: Text(
          'Are you sure you want to delete "${_tournament.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteBracket(_currentBracketId!);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete bracket: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading bracket...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Toolbar
          BracketToolbar(
            title: _tournament.title,
            onTitleChanged: _onTitleChanged,
            onAddHeat: _isEditMode ? _addHeat : null,
            onSave: _isEditMode ? _saveTournament : null,
            onEdit: !_isEditMode && _currentBracketId != null
                ? _enterEditMode
                : null,
            onBack: _goBack,
            onDelete: _isEditMode && _currentBracketId != null
                ? _deleteBracket
                : null,
            isEditMode: _isEditMode,
          ),
          // Canvas
          Expanded(
            child: BracketCanvas(
              tournament: _tournament,
              onTournamentChanged: _onTournamentChanged,
              onDeleteHeat: _deleteHeat,
              isReadOnly: !_isEditMode,
            ),
          ),
        ],
      ),
    );
  }
}
