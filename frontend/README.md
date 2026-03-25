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
