import 'challenge.dart';

class GameService {
  /// Calculate result for Rock Paper Scissors game
  static Map<String, dynamic> calculateRockPaperScissorsResult({
    required String challengerChoice,
    required String challengeeChoice,
    required String challengerId,
    required String challengerName,
    required String challengeeId,
    required String challengeeName,
  }) {
    final challenger = RockPaperScissorsChoice.values.firstWhere(
      (e) => e.name == challengerChoice,
    );
    final challengee = RockPaperScissorsChoice.values.firstWhere(
      (e) => e.name == challengeeChoice,
    );

    if (challenger == challengee) {
      return {
        'winnerId': null,
        'winnerName': null,
        'reason': 'It\'s a tie!',
        'isTie': true,
      };
    }

    final challengerWins = _doesBeat(challenger, challengee);
    
    if (challengerWins) {
      return {
        'winnerId': challengerId,
        'winnerName': challengerName,
        'reason': _getWinReason(challenger, challengee),
        'isTie': false,
      };
    } else {
      return {
        'winnerId': challengeeId,
        'winnerName': challengeeName,
        'reason': _getWinReason(challengee, challenger),
        'isTie': false,
      };
    }
  }

  static bool _doesBeat(RockPaperScissorsChoice choice1, RockPaperScissorsChoice choice2) {
    switch (choice1) {
      case RockPaperScissorsChoice.rock:
        return choice2 == RockPaperScissorsChoice.scissors;
      case RockPaperScissorsChoice.paper:
        return choice2 == RockPaperScissorsChoice.rock;
      case RockPaperScissorsChoice.scissors:
        return choice2 == RockPaperScissorsChoice.paper;
    }
  }

  static String _getWinReason(RockPaperScissorsChoice winner, RockPaperScissorsChoice loser) {
    if (winner == RockPaperScissorsChoice.rock && loser == RockPaperScissorsChoice.scissors) {
      return 'rock beats scissors';
    } else if (winner == RockPaperScissorsChoice.paper && loser == RockPaperScissorsChoice.rock) {
      return 'paper beats rock';
    } else if (winner == RockPaperScissorsChoice.scissors && loser == RockPaperScissorsChoice.paper) {
      return 'scissors beats paper';
    }
    return '${winner.name} beats ${loser.name}';
  }

  /// Calculate result for Reaction Test game
  static Map<String, dynamic> calculateReactionTestResult({
    required String challengerChoice,
    required String challengeeChoice,
    required String challengerId,
    required String challengerName,
    required String challengeeId,
    required String challengeeName,
  }) {
    final challengerTime = int.tryParse(challengerChoice) ?? 99999;
    final challengeeTime = int.tryParse(challengeeChoice) ?? 99999;

    if (challengerTime == challengeeTime) {
      return {
        'winnerId': null,
        'winnerName': null,
        'reason': 'It\'s a tie! Both had $challengerTime ms',
        'isTie': true,
        'challengerTime': challengerTime,
        'challengeeTime': challengeeTime,
      };
    }

    final challengerWins = challengerTime < challengeeTime;

    if (challengerWins) {
      return {
        'winnerId': challengerId,
        'winnerName': challengerName,
        'reason': '$challengerTime ms beats $challengeeTime ms',
        'isTie': false,
        'challengerTime': challengerTime,
        'challengeeTime': challengeeTime,
      };
    } else {
      return {
        'winnerId': challengeeId,
        'winnerName': challengeeName,
        'reason': '$challengeeTime ms beats $challengerTime ms',
        'isTie': false,
        'challengerTime': challengerTime,
        'challengeeTime': challengeeTime,
      };
    }
  }
}
