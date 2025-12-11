import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'challenge.dart';

enum ReactionTestState {
  notStarted,
  ready,
  tooEarly,
  active,
  completed,
}

class ReactionTestGame extends StatefulWidget {
  final Challenge challenge;
  final String currentUserId;
  final Function(String reactionTimeMs) onReactionTimeRecorded;

  const ReactionTestGame({
    super.key,
    required this.challenge,
    required this.currentUserId,
    required this.onReactionTimeRecorded,
  });

  @override
  State<ReactionTestGame> createState() => _ReactionTestGameState();
}

class _ReactionTestGameState extends State<ReactionTestGame> {
  ReactionTestState _state = ReactionTestState.notStarted;
  Timer? _delayTimer;
  DateTime? _greenStartTime;
  int? _reactionTimeMs;
  final Random _random = Random();

  bool get isChallenger => widget.challenge.challengerId == widget.currentUserId;
  
  bool get hasMadeChoice {
    if (isChallenger) {
      return widget.challenge.challengerChoice != null;
    } else {
      return widget.challenge.challengeeChoice != null;
    }
  }

  String? get myChoice {
    if (isChallenger) {
      return widget.challenge.challengerChoice;
    } else {
      return widget.challenge.challengeeChoice;
    }
  }

  String? get opponentChoice {
    if (isChallenger) {
      return widget.challenge.challengeeChoice;
    } else {
      return widget.challenge.challengerChoice;
    }
  }

  String get opponentName {
    if (isChallenger) {
      return widget.challenge.challengeeName;
    } else {
      return widget.challenge.challengerName;
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _delayTimer?.cancel();
    
    setState(() {
      _state = ReactionTestState.ready;
      _reactionTimeMs = null;
      _greenStartTime = null;
    });

    // Random delay between 2-5 seconds
    final delayMs = 2000 + _random.nextInt(3000);
    _delayTimer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted && _state == ReactionTestState.ready) {
        setState(() {
          _state = ReactionTestState.active;
          _greenStartTime = DateTime.now();
        });
      }
    });
  }

  void _onDotTapped() {
    if (_state == ReactionTestState.ready) {
      // Tapped too early!
      _delayTimer?.cancel();
      setState(() {
        _state = ReactionTestState.tooEarly;
      });
      // Restart after a brief delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && !hasMadeChoice) {
          _startGame();
        }
      });
    } else if (_state == ReactionTestState.active && _greenStartTime != null) {
      // Calculate reaction time
      final now = DateTime.now();
      final reactionTime = now.difference(_greenStartTime!).inMilliseconds;
      
      // Cancel timer just in case
      _delayTimer?.cancel();
      
      setState(() {
        _state = ReactionTestState.completed;
        _reactionTimeMs = reactionTime;
      });
      
      // Show result for 1 second before submitting
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !hasMadeChoice) {
          widget.onReactionTimeRecorded(reactionTime.toString());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.challenge.isCompleted && widget.challenge.result != null) {
      return _buildResultView(context);
    }

    if (hasMadeChoice) {
      return _buildWaitingForOpponentView(context);
    }

    if (_state == ReactionTestState.notStarted) {
      return _buildStartView(context);
    }

    return _buildGameView(context);
  }

  Widget _buildStartView(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '⚡ Reaction Test',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the dot as soon as it turns green!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameView(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getInstructionText(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _onDotTapped,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getDotColor(),
                  boxShadow: [
                    BoxShadow(
                      color: _getDotColor().withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: _state == ReactionTestState.tooEarly
                    ? const Center(
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 48,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            if (_state == ReactionTestState.completed && _reactionTimeMs != null)
              Text(
                '$_reactionTimeMs ms',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getInstructionText() {
    switch (_state) {
      case ReactionTestState.notStarted:
        return 'Press Start when ready';
      case ReactionTestState.ready:
        return 'Wait for green...';
      case ReactionTestState.tooEarly:
        return 'Too early! Wait for green...';
      case ReactionTestState.active:
        return 'TAP NOW!';
      case ReactionTestState.completed:
        return 'Your reaction time:';
    }
  }

  Color _getDotColor() {
    switch (_state) {
      case ReactionTestState.notStarted:
      case ReactionTestState.ready:
        return Colors.red;
      case ReactionTestState.tooEarly:
        return Colors.orange;
      case ReactionTestState.active:
        return Colors.green;
      case ReactionTestState.completed:
        return Colors.green.shade700;
    }
  }

  Widget _buildWaitingForOpponentView(BuildContext context) {
    final myTimeMs = myChoice != null ? int.tryParse(myChoice!) : null;
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Waiting for $opponentName to complete...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            if (myTimeMs != null)
              Text(
                'Your time: $myTimeMs ms',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(BuildContext context) {
    final result = widget.challenge.result!;
    final isWinner = result['winnerId'] == widget.currentUserId;
    final isTie = result['isTie'] as bool? ?? false;

    final myTimeMs = myChoice != null ? int.tryParse(myChoice!) : null;
    final opponentTimeMs = opponentChoice != null ? int.tryParse(opponentChoice!) : null;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isTie
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : isWinner
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                isTie
                    ? 'Tie!'
                    : isWinner
                        ? 'You Win!'
                        : 'You Lose!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      myTimeMs != null ? '$myTimeMs ms' : '?',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isChallenger ? widget.challenge.challengerName : widget.challenge.challengeeName} (me)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const Text('VS'),
                Column(
                  children: [
                    Text(
                      opponentTimeMs != null ? '$opponentTimeMs ms' : '?',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opponentName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
