# Flocksync

### Prerequisites

- [Flutter SDK](https://flutter.dev/) (3.11.0 or higher)
- [FVM (recommended)](https://fvm.app/)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/DataAgent47/Flocksync.git
   cd Flocksync/frontend
   ```

2. Install dependencies:
    ```bash
    fvm install # For FVM
    fvm use # For FVM
    flutter pub get
    ```

3. Verify your Flutter installation:
   ```bash
   flutter doctor
   ```

4. Run the app
    ```bash
    flutter run
    flutter run -d chrome
    ```

### Backend API

By default it reads localhost:5000, if you are hosting it, change the API accordingly:

```bash
flutter run --dart-define BACKEND_API_URL=http://localhost:5000
```

note for Android emulator: use 10.0.2.2 instead of localhost

### Optional API setup

For OpenStreetMaps
```bash
flutter run \
    --dart-define MAP_TILE_URL_TEMPLATE=https://your-provider/{z}/{x}/{y}.png?key=YOUR_KEY \
    --dart-define MAP_TILE_ATTRIBUTION="Provider; OpenStreetMap" \
    --dart-define MAP_TILE_USER_AGENT_PACKAGE=com.flocksync.frontend
```

### Firebase setup 

If you have the config files, which are named `firebase_options.dart`, then just drop it to `frontend/lib`.

Otherwise, you can generate it yourself by following [instructions here](https://firebase.google.com/docs/flutter/setup?platform=ios).

# Firestore Emulator Setup

Use the Firebase Emulator to test Firestore rules locally without deploying to production. Rule changes are picked up instantly — no deploy needed.

---

## One-time setup

**1. Initialize the emulator (run once in the project root):**
```bash
firebase init emulators
```
When prompted, select **Firestore Emulator**. Accept the default port (`8080`).

**2. Add the emulator flag to `main.dart`** right after `Firebase.initializeApp()`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── Local emulator (dev only) ──────────────────────────────────────────
  const bool kUseEmulator = bool.fromEnvironment('USE_EMULATOR');
  if (kUseEmulator) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  // ───────────────────────────────────────────────────────────────────────

  runApp(const FlockSyncApp());
}
```

---

## Running locally

Open **two terminals**:

**Terminal 1 — start the emulator:**
```bash
firebase emulators:start --only firestore
```

**Terminal 2 — run Flutter pointing at the emulator:**
```bash
flutter run --dart-define=USE_EMULATOR=true
```

To test against **real Firestore** (production), just run without the flag:
```bash
flutter run
```

---

## Emulator UI

While the emulator is running, open your browser to:
```
http://localhost:4000
```
From here you can:
- View and edit documents
- Run queries
- Test rule changes in real time

---

## Testing rules changes

1. Edit `firestore.rules`
2. Save the file — the emulator picks up changes automatically
3. Interact with the app in the simulator — no deploy needed

When your rules are ready for production:
```bash
firebase deploy --only firestore:rules
```

---

## Notes

- The emulator starts with an **empty database** each time. Add test documents manually via the emulator UI or seed them from your app.
- The `--dart-define=USE_EMULATOR=true` flag only affects your local machine. Teammates must opt in by running with the same flag.
- Never commit production Firebase credentials or secrets to the repo.