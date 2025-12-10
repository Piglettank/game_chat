# Challenge System - Firestore Structure Plan

## Overview
This document outlines the Firestore structure for implementing a challenge system where users can challenge other active players to games (starting with Rock Paper Scissors).

## Firestore Structure

### Option 1: Challenges as Subcollection (Recommended)
```
chat/
  {chatId}/
    challenges/
      {challengeId}/
        challengerId: string
        challengerName: string
        challengeeId: string
        challengeeName: string
        gameType: string (e.g., "rock_paper_scissors")
        status: string ("pending" | "accepted" | "rejected" | "in_progress" | "completed" | "expired")
        createdAt: timestamp
        expiresAt: timestamp (optional, for auto-expiring challenges)
        choices: {
          challenger: string | null ("rock" | "paper" | "scissors" | null)
          challengee: string | null ("rock" | "paper" | "scissors" | null)
        }
        result: {
          winnerId: string | null
          winnerName: string | null
          reason: string | null (e.g., "rock beats scissors")
        } | null
```

**Pros:**
- Challenges are scoped to chat rooms
- Easy to query challenges for a specific chat
- Clean separation of concerns
- Can easily add more game types later

**Cons:**
- Slightly more complex path

### Option 2: Global Challenges Collection
```
challenges/
  {challengeId}/
    chatId: string
    challengerId: string
    challengerName: string
    challengeeId: string
    challengeeName: string
    gameType: string
    status: string
    createdAt: timestamp
    expiresAt: timestamp
    choices: { ... }
    result: { ... }
```

**Pros:**
- Simpler top-level structure
- Can query all challenges across chats

**Cons:**
- Need to filter by chatId in queries
- Less organized

## Recommended Structure (Option 1)

### Collection Path
```
chat/{chatId}/challenges/{challengeId}
```

### Document Fields

#### Core Challenge Data
- `challengerId` (string, required): User ID of the person sending the challenge
- `challengerName` (string, required): Display name of challenger
- `challengeeId` (string, required): User ID of the person being challenged
- `challengeeName` (string, required): Display name of challengee
- `gameType` (string, required): Type of game (e.g., "rock_paper_scissors")
- `status` (string, required): Current status of the challenge
  - `"pending"`: Challenge sent, waiting for response
  - `"accepted"`: Challenge accepted, waiting for choices
  - `"rejected"`: Challenge was rejected
  - `"in_progress"`: Both players have made choices, calculating result
  - `"completed"`: Game finished, result available
  - `"expired"`: Challenge expired without response
- `createdAt` (timestamp, required): When challenge was created
- `expiresAt` (timestamp, optional): When challenge expires (e.g., 5 minutes)

#### Game State
- `choices` (map, required): Player choices
  - `challenger` (string | null): Choice made by challenger ("rock" | "paper" | "scissors" | null)
  - `challengee` (string | null): Choice made by challengee ("rock" | "paper" | "scissors" | null)
- `result` (map | null): Game result (null until game completes)
  - `winnerId` (string | null): User ID of winner (null if tie)
  - `winnerName` (string | null): Display name of winner
  - `reason` (string | null): Explanation of result (e.g., "rock beats scissors")
  - `isTie` (boolean): Whether the game was a tie

## Example Document

```json
{
  "challengerId": "user-123",
  "challengerName": "Alice",
  "challengeeId": "user-456",
  "challengeeName": "Bob",
  "gameType": "rock_paper_scissors",
  "status": "accepted",
  "createdAt": "2024-01-15T10:30:00Z",
  "expiresAt": "2024-01-15T10:35:00Z",
  "choices": {
    "challenger": null,
    "challengee": null
  },
  "result": null
}
```

After both players make choices:
```json
{
  "challengerId": "user-123",
  "challengeeId": "user-456",
  "gameType": "rock_paper_scissors",
  "status": "completed",
  "choices": {
    "challenger": "rock",
    "challengee": "scissors"
  },
  "result": {
    "winnerId": "user-123",
    "winnerName": "Alice",
    "reason": "rock beats scissors",
    "isTie": false
  }
}
```

## Query Patterns

### Get pending challenges for a user
```dart
_challengesRef
  .where('challengeeId', isEqualTo: userId)
  .where('status', isEqualTo: 'pending')
  .orderBy('createdAt', descending: true)
```

### Get active challenges (accepted/in_progress) for a user
```dart
_challengesRef
  .where('status', whereIn: ['accepted', 'in_progress'])
  .where(Filter.or(
    Filter('challengerId', isEqualTo: userId),
    Filter('challengeeId', isEqualTo: userId),
  ))
```

### Get completed challenges for a user
```dart
_challengesRef
  .where('status', isEqualTo: 'completed')
  .where(Filter.or(
    Filter('challengerId', isEqualTo: userId),
    Filter('challengeeId', isEqualTo: userId),
  ))
  .orderBy('createdAt', descending: true)
  .limit(20)
```

## Firestore Security Rules (Example)

```javascript
match /chat/{chatId}/challenges/{challengeId} {
  // Users can read challenges they're involved in
  allow read: if request.auth != null && (
    resource.data.challengerId == request.auth.uid ||
    resource.data.challengeeId == request.auth.uid
  );
  
  // Users can create challenges
  allow create: if request.auth != null && 
    request.resource.data.challengerId == request.auth.uid;
  
  // Challengee can accept/reject
  allow update: if request.auth != null && (
    // Challengee can accept/reject
    (request.resource.data.challengeeId == request.auth.uid &&
     request.resource.data.status in ['accepted', 'rejected']) ||
    // Either player can update choices
    (request.resource.data.challengerId == request.auth.uid ||
     request.resource.data.challengeeId == request.auth.uid) &&
    request.resource.data.diff(resource.data).affectedKeys()
      .hasOnly(['choices', 'status', 'result'])
  );
  
  // Users can delete their own challenges
  allow delete: if request.auth != null && (
    resource.data.challengerId == request.auth.uid ||
    resource.data.challengeeId == request.auth.uid
  );
}
```

## Implementation Flow

### 1. Challenge Creation
- User clicks on active player
- Selects game type (Rock Paper Scissors)
- Creates challenge document with status "pending"
- Sets expiration time (e.g., 5 minutes)

### 2. Challenge Acceptance/Rejection
- Challengee sees notification
- Can accept (status → "accepted") or reject (status → "rejected")
- If expired, status → "expired"

### 3. Making Choices
- Once accepted, both players can make their choice
- Update `choices.challenger` or `choices.challengee`
- When both choices are set, trigger result calculation
- Status → "in_progress" → "completed"

### 4. Result Calculation
- Server-side function or client-side logic
- Determine winner based on game rules
- Update `result` field
- Status → "completed"

## Additional Considerations

### Indexes Needed
- Composite index on `challengeeId` + `status` + `createdAt`
- Composite index on `status` + `createdAt` (for active challenges)

### Cleanup
- Consider Cloud Function to auto-expire old challenges
- Or client-side cleanup when querying

### Notifications
- Could add a `notifications` subcollection for challenge notifications
- Or use the challenge status changes as notification triggers

## Future Extensibility

This structure easily supports:
- Multiple game types (just change `gameType` field)
- Tournament brackets
- Game history
- Statistics tracking
- Rematch functionality
