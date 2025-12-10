import 'package:cloud_firestore/cloud_firestore.dart';
import 'leaderboard_entry.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _leaderboardsRef =>
      _firestore.collection('tournamentLeaderboards');

  // Use a single default leaderboard document
  static const String _defaultLeaderboardId = 'default';

  /// Stream the leaderboard for real-time updates
  Stream<List<LeaderboardEntry>> getLeaderboard() {
    return _leaderboardsRef
        .doc(_defaultLeaderboardId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return <LeaderboardEntry>[];
      final data = doc.data() as Map<String, dynamic>;
      final entries = data['entries'] as List<dynamic>? ?? [];
      return entries
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// Save/update the leaderboard
  Future<void> saveLeaderboard(List<LeaderboardEntry> entries) async {
    final entriesJson = entries.map((e) => e.toJson()).toList();
    await _leaderboardsRef.doc(_defaultLeaderboardId).set({
      'entries': entriesJson,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
