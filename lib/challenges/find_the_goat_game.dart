import 'dart:math';
import 'package:flutter/material.dart';
import 'challenge.dart';

class FindTheGoatGame extends StatefulWidget {
  final Challenge challenge;
  final String currentUserId;
  final Function(String choice) onChoiceSelected;

  const FindTheGoatGame({
    super.key,
    required this.challenge,
    required this.currentUserId,
    required this.onChoiceSelected,
  });

  @override
  State<FindTheGoatGame> createState() => _FindTheGoatGameState();
}

class _FindTheGoatGameState extends State<FindTheGoatGame> {
  final Random _random = Random();
  late int _correctDoor;
  int? _selectedDoor;
  bool _doorsRevealed = false;

  // Negative emojis for wrong doors
  static const List<String> _negativeEmojis = ['💩', '💣', '👻'];

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
  void initState() {
    super.initState();
    // Each player gets their own random correct door (0, 1, or 2)
    _correctDoor = _random.nextInt(3);
  }

  void _selectDoor(int doorIndex) {
    if (hasMadeChoice || _doorsRevealed) return;

    final foundGoat = doorIndex == _correctDoor;

    setState(() {
      _selectedDoor = doorIndex;
      _doorsRevealed = true;
    });

    // Save simple "found" or "not-found" to Firebase
    final choice = foundGoat ? 'found' : 'not-found';

    // Small delay to show the reveal animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      widget.onChoiceSelected(choice);
    });
  }

  String _getDoorEmoji(int doorIndex) {
    if (doorIndex == _correctDoor) {
      return '🐐';
    }
    return _negativeEmojis[doorIndex % _negativeEmojis.length];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.challenge.isCompleted && widget.challenge.result != null) {
      return _buildResultView(context);
    }

    if (hasMadeChoice) {
      return _buildWaitingView(context);
    }

    return _buildGameView(context);
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
              'Find the Goat! 🐐',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick a door to find the goat',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) => _buildDoor(context, index)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoor(BuildContext context, int doorIndex) {
    final isSelected = _selectedDoor == doorIndex;
    final shouldReveal = _doorsRevealed;

    return GestureDetector(
      onTap: () => _selectDoor(doorIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 120,
        decoration: BoxDecoration(
          color: shouldReveal
              ? (doorIndex == _correctDoor
                  ? Colors.green.shade100
                  : Colors.red.shade100)
              : (isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (!shouldReveal)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (shouldReveal)
              Text(
                _getDoorEmoji(doorIndex),
                style: const TextStyle(fontSize: 40),
              )
            else
              Column(
                children: [
                  const Icon(Icons.door_front_door, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Door ${doorIndex + 1}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingView(BuildContext context) {
    final foundGoat = myChoice == 'found';

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Waiting for $opponentName...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              foundGoat ? 'You found the goat! 🐐' : 'You missed! 😢',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: foundGoat ? Colors.green : Colors.red,
              ),
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

    final iFoundGoat = myChoice == 'found';
    final opponentFoundGoat = opponentChoice == 'found';

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
                    ? (iFoundGoat ? 'Tie! Both found the goat! 🐐🐐' : 'Tie! Neither found the goat!')
                    : isWinner
                        ? 'You Win! 🐐'
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
                      iFoundGoat ? '🐐' : '😢',
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      iFoundGoat ? 'Found!' : 'Missed',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
                      opponentFoundGoat ? '🐐' : '😢',
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opponentFoundGoat ? 'Found!' : 'Missed',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
