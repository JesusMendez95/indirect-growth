# Indirect Growth - Flutter App

## Project Overview
Personal development mobile app using Flutter with Firebase backend. Helps users track habits, abilities, identity, and personal growth through an RPG-style progression system.

## Tech Stack
- **Frontend**: Flutter 3.x + Dart
- **Backend**: Firebase (Firestore, Auth, Cloud Storage, Cloud Functions)
- **State Management**: Riverpod
- **Local Storage**: Hive
- **Navigation**: GoRouter

## Architecture
Feature-first architecture with clean separation:
```
lib/features/{feature}/
├── data/           # Repository implementations, data sources
├── domain/         # Models, business logic
├── presentation/   # UI (screens, widgets, providers)
└── {feature}.dart  # Barrel export
```

## Key Patterns

### State Management (Riverpod)
- Use `@riverpod` annotations where possible
- Providers go in `presentation/providers/`
- Keep providers focused and small

### Firebase
- All Firebase operations go through repository classes in `data/`
- User ID comes from `FirebaseAuth.instance.currentUser?.uid`
- Firestore paths: `users/{userId}/{collection}/{docId}`

### Navigation
- GoRouter configuration in `lib/app.dart`
- Protected routes check auth state
- Use `context.go()` for navigation

## Firestore Structure
```
users/{userId}/
├── profile: { displayName, createdAt, settings }
├── habits/{habitId}: { name, frequency, category, createdAt, isActive }
├── completions/{date_habitId}: { habitId, date, completed, notes }
├── diaryEntries/{entryId}: { text, mood, mediaUrls[], createdAt }
├── abilities/{abilityId}: { name, category, xp, level }
└── ... (see full schema in docs)
```

## Features (in build order)
1. **auth** - Firebase Auth (email/password, Google)
2. **habits** - Habit tracking with streaks
3. **diary** - Multimedia journal entries
4. **identity** - Beliefs, values, virtues
5. **progression** - RPG stats and abilities
6. **shadow** - Fears, flaws tracking
7. **relationships** - People tracking
8. **capsules** - Time capsules (past/future)

## Commands
```bash
flutter run                 # Run app
flutter test               # Run tests
flutter analyze            # Check for issues
flutter pub get            # Install dependencies
```

## Current Status
- [x] Project setup
- [x] Directory structure
- [x] Core widgets and utilities
- [x] Auth feature (login, register, sign out)
- [x] Habits feature (CRUD, completions, streaks)
- [x] Home dashboard
- [x] Profile screen
- [x] Unit tests for streak calculator
- [ ] Firebase configuration (needs `flutterfire configure`)
- [ ] Diary feature
- [ ] Identity feature
- [ ] Progression feature
- [ ] Shadow feature
- [ ] Relationships feature
- [ ] Capsules feature

## Notes for Claude
- Always read relevant files before making changes
- Test changes incrementally with `flutter run`
- Commit after each working feature
- Check Firebase Console to verify data operations
