import 'package:flutter/material.dart';
import '../models/challenge.dart';

class ChallengeDialog extends StatelessWidget {
  final String challengeeName;

  const ChallengeDialog({
    super.key,
    required this.challengeeName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Challenge $challengeeName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Select a game:'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(GameType.rockPaperScissors);
            },
            icon: const Icon(Icons.handshake),
            label: const Text('Rock Paper Scissors'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              alignment: Alignment.centerLeft,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
