# Function-First Folder Structure Plan

## Current Structure (Type-First)
```
lib/
├── models/
│   ├── active_user.dart
│   ├── challenge.dart
│   ├── embed_config.dart
│   └── message.dart
├── screens/
│   └── chat_screen.dart
├── services/
│   ├── chat_service.dart
│   └── game_service.dart
└── widgets/
    ├── challenge_dialog.dart
    ├── challenge_notification.dart
    ├── challenge_result_message.dart
    └── rock_paper_scissors_game.dart
```

## Proposed Structure (Function-First)

### Option 1: Feature-Based (Recommended)
```
lib/
├── chat/
│   ├── chat_screen.dart
│   ├── chat_service.dart
│   ├── models/
│   │   ├── message.dart
│   │   └── active_user.dart
│   └── widgets/
│       └── (chat-specific widgets if any)
├── challenges/
│   ├── challenge_service.dart (or game_service.dart)
│   ├── models/
│   │   └── challenge.dart
│   └── widgets/
│       ├── challenge_dialog.dart
│       ├── challenge_notification.dart
│       ├── challenge_result_message.dart
│       └── rock_paper_scissors_game.dart
├── core/
│   ├── config/
│   │   └── embed_config.dart
│   └── (shared utilities, constants, etc.)
└── main.dart
```

### Option 2: Domain-Driven (Alternative)
```
lib/
├── features/
│   ├── chat/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── message.dart
│   │   │   │   └── active_user.dart
│   │   │   └── services/
│   │   │       └── chat_service.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── chat_screen.dart
│   │   │   └── widgets/
│   │   │       └── (chat widgets)
│   │   └── chat.dart (barrel export)
│   ├── challenges/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── challenge.dart
│   │   │   └── services/
│   │   │       └── game_service.dart
│   │   ├── presentation/
│   │   │   └── widgets/
│   │   │       ├── challenge_dialog.dart
│   │   │       ├── challenge_notification.dart
│   │   │       ├── challenge_result_message.dart
│   │   │       └── rock_paper_scissors_game.dart
│   │   └── challenges.dart (barrel export)
│   └── core/
│       └── config/
│           └── embed_config.dart
└── main.dart
```

### Option 3: Simplified Feature-Based (Most Practical)
```
lib/
├── chat/
│   ├── chat_screen.dart
│   ├── chat_service.dart
│   ├── message.dart
│   └── active_user.dart
├── challenges/
│   ├── challenge.dart
│   ├── game_service.dart
│   ├── challenge_dialog.dart
│   ├── challenge_notification.dart
│   ├── challenge_result_message.dart
│   └── rock_paper_scissors_game.dart
├── core/
│   └── embed_config.dart
└── main.dart
```

## Recommendation: Option 3 (Simplified Feature-Based)

**Benefits:**
- Clear feature boundaries
- Easy to find related code
- Scales well as features grow
- Less nesting than Option 2
- Simpler than Option 1 for small-medium projects

**Structure:**
- Each feature folder contains everything related to that feature
- Models, services, and widgets live together in the feature folder
- Only create subfolders when a feature grows large (e.g., `chat/widgets/` if you have many chat widgets)
- `core/` for shared/config code

## Migration Steps

1. Create new folder structure
2. Move files to new locations
3. Update all import statements
4. Test that everything still works
5. Remove old empty folders

## File Mapping

### Current → Proposed (Option 3)

```
models/message.dart          → chat/message.dart
models/active_user.dart      → chat/active_user.dart
models/challenge.dart         → challenges/challenge.dart
models/embed_config.dart     → core/embed_config.dart
screens/chat_screen.dart     → chat/chat_screen.dart
services/chat_service.dart    → chat/chat_service.dart
services/game_service.dart    → challenges/game_service.dart
widgets/challenge_dialog.dart → challenges/challenge_dialog.dart
widgets/challenge_notification.dart → challenges/challenge_notification.dart
widgets/challenge_result_message.dart → challenges/challenge_result_message.dart
widgets/rock_paper_scissors_game.dart → challenges/rock_paper_scissors_game.dart
```

## Import Path Changes

### Before:
```dart
import '../models/message.dart';
import '../services/chat_service.dart';
import '../widgets/challenge_dialog.dart';
```

### After (Option 3):
```dart
import '../chat/message.dart';
import '../chat/chat_service.dart';
import '../challenges/challenge_dialog.dart';
```

## Considerations

1. **Shared Code**: If models/services/widgets are used across multiple features, consider:
   - Moving to `core/shared/`
   - Or keeping duplicates if features should be independent

2. **Barrel Exports**: Consider adding `chat/chat.dart` that exports all public APIs:
   ```dart
   export 'chat_screen.dart';
   export 'chat_service.dart';
   export 'message.dart';
   export 'active_user.dart';
   ```

3. **Testing**: Test files should mirror the structure:
   ```
   test/
   ├── chat/
   │   └── chat_service_test.dart
   └── challenges/
       └── game_service_test.dart
   ```
