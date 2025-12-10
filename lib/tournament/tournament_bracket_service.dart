import 'package:cloud_firestore/cloud_firestore.dart';
import 'tournament.dart';
import 'saved_tournament_bracket.dart';

class TournamentBracketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _bracketsRef =>
      _firestore.collection('tournamentBrackets');

  /// Stream of all brackets, ordered by most recently updated
  Stream<List<SavedTournamentBracket>> getBrackets() {
    return _bracketsRef
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SavedTournamentBracket.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get a single bracket by ID
  Future<SavedTournamentBracket?> getBracket(String bracketId) async {
    final doc = await _bracketsRef.doc(bracketId).get();
    if (!doc.exists) return null;
    return SavedTournamentBracket.fromFirestore(doc);
  }

  /// Stream a single bracket by ID for real-time updates
  Stream<SavedTournamentBracket?> streamBracket(String bracketId) {
    return _bracketsRef.doc(bracketId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return SavedTournamentBracket.fromFirestore(doc);
    });
  }

  /// Save a new bracket
  Future<String> saveBracket({
    required Tournament tournament,
  }) async {
    final docRef = _bracketsRef.doc();
    // Use Tournament.toJson() to ensure JSON structure matches model
    final tournamentJson = tournament.toJson();
    await docRef.set({
      'title': tournament.title,
      'tournamentData': tournamentJson,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Update an existing bracket
  Future<void> updateBracket({
    required String bracketId,
    required Tournament tournament,
  }) async {
    // Use Tournament.toJson() to ensure JSON structure matches model
    final tournamentJson = tournament.toJson();
    await _bracketsRef.doc(bracketId).update({
      'title': tournament.title,
      'tournamentData': tournamentJson,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a bracket
  Future<void> deleteBracket(String bracketId) async {
    await _bracketsRef.doc(bracketId).delete();
  }
}
