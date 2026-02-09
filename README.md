# Water It

Your personal plant companion app — track your houseplants, get watering reminders, and check the weather so your plants stay happy.

<p align="center">
  <img src="assets/app_icons/android/play_store_512.png" alt="Water It app icon" width="120" />
</p>

## Screenshots

<p align="center">
  <img src="assets/Water It images/Screenshot_20260208-183935.png" alt="Home" width="200" />
  <img src="assets/Water It images/Screenshot_20260208-183949.png" alt="Plants" width="200" />
  <img src="assets/Water It images/Screenshot_20260208-184031.png" alt="Add Plant" width="200" />
  <img src="assets/Water It images/Screenshot_20260208-184128.png" alt="Plant Detail" width="200" />
</p>

## Features

- **Plant Library** — Add, edit, and organize your plants with photos, care details, and notes.
- **Watering Reminders** — Schedule per-plant reminders by frequency, specific weekdays, and preferred time.
- **Weather Dashboard** — Location-based hourly weather forecast so you know when to water.
- **Camera Integration** — Snap up to 4 photos per plant directly from the app.
- **Multiple Layouts** — View your collection as a list, single-column grid, or 2-column grid.
- **Feedback** — Built-in bug reporting via email.

## Tech Stack

| Category | Technology |
|---|---|
| Framework | Flutter / Dart |
| State Management | Flutter BLoC / Cubit |
| Local Storage | SQLite (sqflite) |
| Notifications | flutter_local_notifications |
| Weather | OpenWeather API |
| Location | Geolocator |
| DI | get_it |
| Localization | Flutter gen-l10n (ARB) |

## Architecture

Clean Architecture with layers per feature (`lib/features/`):

```
features/
  plants/
    domain/      # entities, repositories, use cases
    data/        # models, SQLite data source, repository impl
    presentation/ # pages, widgets, BLoC
```

- **Domain** — Business logic and contracts.
- **Data** — SQLite persistence, models, repository implementations.
- **Presentation** — UI, BLoCs/Cubits, widgets.

## Environment Variables

The weather feature requires an [OpenWeather](https://openweathermap.org/) API key. Pass it at build time with `--dart-define`:

```bash
flutter run --dart-define=OPENWEATHER_API_KEY=your_key_here
```

For a release build:

```bash
flutter build apk --dart-define=OPENWEATHER_API_KEY=your_key_here
```

> If the key is missing the app will still work — weather features will simply be unavailable.

## Getting Started

1. **Clone the repo**
   ```bash
   git clone https://github.com/KingDrofd/water_it.git
   cd water_it
   ```
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Run the app**
   ```bash
   flutter run --dart-define=OPENWEATHER_API_KEY=your_key_here
   ```

## Privacy Policy

See [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

