import 'package:flutter/material.dart';
import '../models/challenge.dart';

class RockPaperScissorsGame extends StatelessWidget {
  final Challenge challenge;
  final String currentUserId;
  final Function(RockPaperScissorsChoice) onChoiceSelected;

  const RockPaperScissorsGame({
    super.key,
    required this.challenge,
    required this.currentUserId,
    required this.onChoiceSelected,
  });

  bool get isChallenger => challenge.challengerId == currentUserId;
  bool get hasMadeChoice {
    if (isChallenger) {
      return challenge.challengerChoice != null;
    } else {
      return challenge.challengeeChoice != null;
    }
  }

  String? get myChoice {
    if (isChallenger) {
      return challenge.challengerChoice;
    } else {
      return challenge.challengeeChoice;
    }
  }

  String? get opponentChoice {
    if (isChallenger) {
      return challenge.challengeeChoice;
    } else {
      return challenge.challengerChoice;
    }
  }

  String get opponentName {
    if (isChallenger) {
      return challenge.challengeeName;
    } else {
      return challenge.challengerName;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (challenge.isCompleted && challenge.result != null) {
      return _buildResultView(context);
    }

    if (hasMadeChoice) {
      return _buildWaitingView(context);
    }

    return _buildChoiceView(context);
  }

  Widget _buildChoiceView(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your move:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildChoiceButton(
                  context,
                  RockPaperScissorsChoice.rock,
                  '✊',
                ),
                _buildChoiceButton(
                  context,
                  RockPaperScissorsChoice.paper,
                  '✋',
                ),
                _buildChoiceButton(
                  context,
                  RockPaperScissorsChoice.scissors,
                  '✌️',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton(
    BuildContext context,
    RockPaperScissorsChoice choice,
    String emoji,
  ) {
    return InkWell(
      onTap: () => onChoiceSelected(choice),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              choice.name.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingView(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Waiting for $opponentName to make their choice...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You chose: ${_getChoiceEmoji(myChoice)} ${myChoice?.toUpperCase()}',
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
    final result = challenge.result!;
    final isWinner = result['winnerId'] == currentUserId;
    final isTie = result['isTie'] as bool? ?? false;
    final reason = result['reason'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.all(8.0),
      color: isTie
          ? Theme.of(context).colorScheme.surfaceVariant
          : isWinner
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isTie
                  ? 'It\'s a Tie!'
                  : isWinner
                      ? 'You Win! 🎉'
                      : 'You Lost 😢',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      _getChoiceEmoji(challenge.challengerChoice),
                      style: const TextStyle(fontSize: 48),
                    ),
                    Text(challenge.challengerName),
                  ],
                ),
                const Text('VS'),
                Column(
                  children: [
                    Text(
                      _getChoiceEmoji(challenge.challengeeChoice),
                      style: const TextStyle(fontSize: 48),
                    ),
                    Text(challenge.challengeeName),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _getChoiceEmoji(String? choice) {
    if (choice == null) return '❓';
    switch (choice) {
      case 'rock':
        return '✊';
      case 'paper':
        return '✋';
      case 'scissors':
        return '✌️';
      default:
        return '❓';
    }
  }
}
