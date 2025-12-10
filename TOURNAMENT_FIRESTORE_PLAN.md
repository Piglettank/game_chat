# Tournament Bracket Firestore Integration Plan

## Overview
This plan outlines the implementation for saving tournament brackets to Firebase Firestore, displaying a list of saved brackets, and allowing users to edit and save brackets.

**Important**: The tournament bracket JSON stored in Firestore must conform exactly to the structure defined by `Tournament.toJson()` in `lib/models/tournament.dart`. This ensures compatibility with the existing Tournament model and allows seamless serialization/deserialization.

## Firestore Structure

### Collection: `tournamentBrackets`
A top-level collection storing all tournament brackets.

```
tournamentBrackets/
  {bracketId}/
    title: string
    tournamentData: map (JSON conforming to Tournament.toJson() structure)
    createdAt: timestamp
    updatedAt: timestamp
```

### Document Fields

- `title` (string, required): Display name of the tournament bracket
- `tournamentData` (map, required): Tournament JSON object **exactly as returned by `Tournament.toJson()`**:
  ```dart
  {
    'title': string,
    'heats': [
      {
        'id': string,
        'title': string,
        'x': double,
        'y': double,
        'players': [
          {
            'id': string,
            'name': string
          }
        ],
        'isFinal': bool
      }
    ],
    'connections': [
      {
        'id': string,
        'fromHeatId': string,
        'toHeatId': string
      }
    ]
  }
  ```
  This structure matches the `Tournament` model in `lib/models/tournament.dart` and can be reconstructed using `Tournament.fromJson()`.
- `createdAt` (timestamp, required): When bracket was first created
- `updatedAt` (timestamp, required): Last modification time

## Implementation Steps

### Step 1: Create Tournament Bracket Model for Firestore
**File**: `lib/models/saved_tournament_bracket.dart`

Create a model class to represent saved bracket metadata:
- `SavedTournamentBracket` class with:
  - `id`: Document ID
  - `title`: Bracket title (stored separately for quick access, also in tournamentData)
  - `tournament`: Tournament object (reconstructed from tournamentData using `Tournament.fromJson()`)
  - `createdAt`: DateTime
  - `updatedAt`: DateTime
  - `fromFirestore()`: Factory constructor that:
    - Extracts `tournamentData` map from Firestore document
    - Uses `Tournament.fromJson(tournamentData)` to reconstruct Tournament object
  - `toFirestore()`: Convert to Firestore map that:
    - Uses `tournament.toJson()` to get the tournamentData map
    - Stores it in the `tournamentData` field

### Step 2: Create Tournament Bracket Service
**File**: `lib/services/tournament_bracket_service.dart`

Service class similar to `ChatService`:
- `TournamentBracketService` class
- Methods:
  - `getBrackets()`: Stream of all brackets
  - `getBracket(String bracketId)`: Get single bracket
  - `saveBracket(Tournament tournament)`: Save new bracket
  - `updateBracket(String bracketId, Tournament tournament)`: Update existing bracket
  - `deleteBracket(String bracketId)`: Delete bracket
  - `createBracket(String title)`: Create new empty bracket

### Step 3: Create Bracket List Screen
**File**: `lib/tournament/bracket_list_screen.dart`

New screen showing list of saved brackets:
- Display list of brackets with:
  - Title
  - Last updated timestamp
  - Action buttons (Edit, Delete)
- "Create New Bracket" button
- Search/filter functionality (optional)
- Clicking a bracket opens it in edit mode

### Step 4: Update Tournament Bracket Home Screen
**File**: `lib/tournament/tournament_bracket.dart`

Modify `TournamentBracketHome`:
- Add optional `bracketId` parameter to load existing bracket
- Update `_saveTournament()` to save to Firestore instead of file
- Remove file-based save/load (or keep as backup)
- Add auto-save functionality (optional - save on changes)

### Step 5: Update Navigation Flow
**File**: `lib/core/welcome_screen.dart`

Update navigation to tournament:
- Navigate to `BracketListScreen` instead of directly to `TournamentBracketHome`
- Users select a bracket or create new one

### Step 6: Update Toolbar
**File**: `lib/tournament/toolbar.dart`

Update toolbar buttons:
- "Save" button saves to Firestore
- Remove "Load" button (loading happens from list screen)
- Add "Back to List" button
- Add "Delete" button

## JSON Structure Compliance

The `tournamentData` field in Firestore documents must store JSON that exactly matches the structure returned by `Tournament.toJson()`:

```dart
{
  'title': string,
  'heats': [
    {
      'id': string,
      'title': string,
      'x': double,
      'y': double,
      'players': [
        {'id': string, 'name': string}
      ],
      'isFinal': bool
    }
  ],
  'connections': [
    {
      'id': string,
      'fromHeatId': string,
      'toHeatId': string
    }
  ]
}
```

**Implementation Notes**:
- Always use `Tournament.toJson()` when saving to Firestore
- Always use `Tournament.fromJson()` when loading from Firestore
- Never manually construct or modify the JSON structure
- The `title` field is stored both in `tournamentData.title` and as a top-level `title` field for quick queries

## Detailed Implementation

### TournamentBracketService Structure

```dart
class TournamentBracketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get _bracketsRef =>
      _firestore.collection('tournamentBrackets');
  
  // Stream of all brackets
  Stream<List<SavedTournamentBracket>> getBrackets() {
    return _bracketsRef
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) => SavedTournamentBracket.fromFirestore(doc)).toList()
        );
  }
  
  // Save new bracket
  Future<String> saveBracket({
    required Tournament tournament,
  }) async {
    final docRef = _bracketsRef.doc();
    // Use Tournament.toJson() to ensure JSON structure matches model
    final tournamentJson = tournament.toJson();
    await docRef.set({
      'title': tournament.title,
      'tournamentData': tournamentJson, // This matches Tournament.toJson() structure exactly
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }
  
  // Update existing bracket
  Future<void> updateBracket({
    required String bracketId,
    required Tournament tournament,
  }) async {
    // Use Tournament.toJson() to ensure JSON structure matches model
    final tournamentJson = tournament.toJson();
    await _bracketsRef.doc(bracketId).update({
      'title': tournament.title,
      'tournamentData': tournamentJson, // This matches Tournament.toJson() structure exactly
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Delete bracket
  Future<void> deleteBracket(String bracketId) async {
    await _bracketsRef.doc(bracketId).delete();
  }
  
  // Get single bracket
  Future<SavedTournamentBracket?> getBracket(String bracketId) async {
    final doc = await _bracketsRef.doc(bracketId).get();
    if (!doc.exists) return null;
    return SavedTournamentBracket.fromFirestore(doc);
  }
}
```

### SavedTournamentBracket Model

```dart
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
    
    return SavedTournamentBracket(
      id: doc.id,
      title: data['title'] as String,
      tournament: tournament,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    // Use Tournament.toJson() to ensure structure matches model
    return {
      'title': title,
      'tournamentData': tournament.toJson(), // Matches Tournament.toJson() structure
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
```

### Bracket List Screen UI

- ListView/GridView of bracket cards
- Each card shows:
  - Title (large, bold)
  - "Updated [time ago]" (small text)
  - Edit button (opens bracket editor)
  - Delete button
- FloatingActionButton for "Create New Bracket"
- Empty state when no brackets exist

## Migration Strategy

1. Keep existing file-based save/load as fallback
2. When loading from file, offer to save to Firestore
3. Gradually migrate users to Firestore-based storage

## Security Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /tournamentBrackets/{bracketId} {
      // Anyone can read brackets
      allow read: if true;
      
      // Anyone can create, update, or delete brackets
      allow write: if true;
    }
  }
}
```

## Testing Considerations

1. Test creating new brackets
2. Test updating existing brackets
3. Test deleting brackets
4. Test loading brackets list
5. Test concurrent edits (handle conflicts)
6. Test with multiple users
7. Test with/without chatId scoping

## Future Enhancements

1. Real-time collaboration (multiple users editing same bracket)
2. Bracket sharing via URL
3. Bracket templates
4. Export/import functionality
5. Version history
6. Permissions system (view-only, edit, admin)
