import 'package:cloud_firestore/cloud_firestore.dart';
import 'tournament.dart';

class SavedTournamentBracket {
  final String id;
  final String title;
  final Tournament tournament;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedTournamentBracket({
    required this.id,
    required this.title,
    required this.tournament,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedTournamentBracket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Extract tournamentData and reconstruct Tournament using fromJson
    final tournamentData = data['tournamentData'] as Map<String, dynamic>;
    final tournament = Tournament.fromJson(tournamentData);

    DateTime createdAtDate = DateTime.now();
    DateTime updatedAtDate = DateTime.now();

    try {
      final createdAtValue = data['createdAt'];
      if (createdAtValue != null) {
        if (createdAtValue is Timestamp) {
          createdAtDate = createdAtValue.toDate();
        }
      }

      final updatedAtValue = data['updatedAt'];
      if (updatedAtValue != null) {
        if (updatedAtValue is Timestamp) {
          updatedAtDate = updatedAtValue.toDate();
        }
      }
    } catch (_) {
      // Use current time as fallback
    }

    return SavedTournamentBracket(
      id: doc.id,
      title: data['title'] as String,
      tournament: tournament,
      createdAt: createdAtDate,
      updatedAt: updatedAtDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    // Use Tournament.toJson() to ensure structure matches model
    return {
      'title': title,
      'tournamentData': tournament.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
