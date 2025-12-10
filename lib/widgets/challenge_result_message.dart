import 'package:flutter/material.dart';
import '../models/challenge.dart';

class ChallengeResultMessage extends StatelessWidget {
  final Challenge challenge;

  const ChallengeResultMessage({
    super.key,
    required this.challenge,
  });

  String _getChoiceDisplayName(String? choice) {
    if (choice == null) return 'unknown';
    switch (choice) {
      case 'rock':
        return 'rock';
      case 'paper':
        return 'paper';
      case 'scissors':
        return 'scissors';
      default:
        return choice;
    }
  }

  String _getResultMessage() {
    if (challenge.result == null) return 'Challenge completed';

    final result = challenge.result!;
    final isTie = result['isTie'] as bool? ?? false;

    if (isTie) {
      final challengerChoice = _getChoiceDisplayName(challenge.challengerChoice);
      return '${challenge.challengerName} and ${challenge.challengeeName} tied with $challengerChoice!';
    }

    final winnerName = result['winnerName'] as String? ?? 'Unknown';
    final winnerId = result['winnerId'] as String?;
    final loserName = winnerId == challenge.challengerId
        ? challenge.challengeeName
        : challenge.challengerName;
    
    final winnerChoice = winnerId == challenge.challengerId
        ? _getChoiceDisplayName(challenge.challengerChoice)
        : _getChoiceDisplayName(challenge.challengeeChoice);
    
    final loserChoice = winnerId == challenge.challengerId
        ? _getChoiceDisplayName(challenge.challengeeChoice)
        : _getChoiceDisplayName(challenge.challengerChoice);

    return '$winnerName beat $loserName with $winnerChoice against his $loserChoice!';
  }

  @override
  Widget build(BuildContext context) {
    final result = challenge.result;
    final isTie = result?['isTie'] as bool? ?? false;
    final winnerId = result?['winnerId'] as String;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 4.0,
          horizontal: 8.0,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 10.0,
        ),
        decoration: BoxDecoration(
          color: isTie
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16.0),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isTie ? Icons.handshake : Icons.emoji_events,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Challenge Result',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _getResultMessage(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
