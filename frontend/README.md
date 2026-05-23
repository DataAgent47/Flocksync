# Flocksync

### Prerequisites

- [Flutter SDK](https://flutter.dev/) (3.11.0 or higher)
- [FVM (recommended but optional)](https://fvm.app/)

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
   # Run on web browser, or any available device
   flutter run -d chrome
   ```

### Backend API

By default it reads localhost:5050, if you are hosting it, change the API accordingly:

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
    --dart-define MAP_TILE_USER_AGENT_PACKAGE=com.flocksync.flocksync
```

### Firebase setup

Follow the Firebase setup [instructions here.](https://firebase.google.com/docs/flutter/setup?platform=ios). 

If you ever need to re-run setup for some reason (such as a change in API keys), simply run `flutterfire configure`

### Firestore Emulator Setup

Use the Firebase Emulator to test Firestore rules locally without needing to deploy them.

```bash
firebase init emulators
```

When prompted, select **Firestore Emulator**. Accept the default port (`8080`).

To run locally:
``` bash
firebase emulators:start --only firestore
flutter run --dart-define=USE_EMULATOR=true
```