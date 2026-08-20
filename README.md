# Academia App

Academia App is a Flutter client for student academic workflows. It brings attendance, marks, timetable, calendar, study materials, announcements, mess information, important links, nearby chat, and club/social features into one app. It also caches selected data locally for faster repeat access and offline fallback.

The repository contains the Flutter application in [`academia_app/`](academia_app/) and older/supporting content-management scripts in [`exeriment_ground/`](exeriment_ground/). The latter is not required to build the mobile app.

## How It Works

1. [`lib/main.dart`](academia_app/lib/main.dart) restores local login state, starts the app, and performs Firebase/notification setup in the background.
2. The login flow sends the user's institution credentials to the configured scraper API. A successful response is cached in `SharedPreferences` and used to open the dashboard.
3. Dashboard screens load feature-specific data through the service classes in [`lib/services/`](academia_app/lib/services/), primarily from Firestore or the scraper API.
4. Cached values are used where implemented, including announcements and student-portal results. Firebase Cloud Messaging and local notifications provide notification support.

The app currently depends on project-owned backend services and Firebase resources. A fresh clone will not be fully functional until those services and platform Firebase configuration are supplied.

The backend API is open source and maintained separately at [academia_scrapper_api_fast](https://github.com/Akshat2711/academia_scrapper_api_fast).

## Repository Layout

| Path | Purpose |
| --- | --- |
| `academia_app/lib/` | Flutter application code |
| `academia_app/lib/screens/` | Main feature screens and flows |
| `academia_app/lib/services/` | Firestore, HTTP, caching, and notification services |
| `academia_app/lib/components/`, `widgets/` | Reusable UI pieces |
| `academia_app/lib/club_events_social/` | Club and social features |
| `academia_app/assets/` | Images, logos, and Lottie animations |
| `academia_app/android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` | Flutter platform runners |
| `academia_app/test/` | Flutter tests |
| `exeriment_ground/` | Optional Python/content-upload experiments; review before publishing |
| `complete_calender.txt` | Project data/content artifact |

## Prerequisites

- Flutter SDK compatible with Dart `^3.9.2` (see [`pubspec.yaml`](academia_app/pubspec.yaml)).
- Android Studio and an Android SDK for Android development, or Xcode for iOS/macOS development.
- A configured Firebase project if using Firestore or notifications.
- Access to compatible backend endpoints for login and student-portal data.
- Git.

Verify the Flutter installation with:

```sh
flutter doctor
```

## Setup

From the repository root:

```sh
cd academia_app
flutter pub get
```

### Firebase and backend configuration

Firebase platform configuration is intentionally ignored by Git. For a local setup, obtain configuration for the development Firebase project from the project owner and generate the platform files with the FlutterFire CLI:

```sh
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `lib/firebase_options.dart` and platform configuration such as Android `google-services.json`. Do not commit those files from a private project without confirming the Firebase rules, API-key restrictions, and ownership first. Firebase web/mobile API keys are identifiers rather than server credentials, but they still need appropriate project restrictions and should not be confused with admin service-account keys.

The app currently has backend URLs embedded in the Dart source, including the login/scraper API and institutional links. There is no `.env` or runtime configuration layer yet. Before distributing a reusable public build, move environment-specific endpoints to a documented configuration mechanism and provide a safe development endpoint.

## Run

List available devices and run the app:

```sh
cd academia_app
flutter devices
flutter run
```

To target a specific device:

```sh
flutter run -d <device-id>
```

Some features require network access, a working backend, Firebase permissions, and valid institutional credentials. The app is not a standalone replacement for those services.

## Tests and Analysis

```sh
cd academia_app
flutter analyze
flutter test
```

The current test file is still Flutter's starter counter test and does not match the current `MyApp` constructor or application UI. Treat `flutter test` as a known failing check until that test is replaced with tests for the actual app, or update the app/test contract together.

## Common Issues

- **Firebase initialization fails:** run `flutterfire configure` for the intended Firebase project and confirm Firestore/messaging rules and platform registrations.
- **Login or student-portal requests fail:** the external scraper API may be unavailable, changed, or inaccessible from the device. Check its contract and status before changing the Flutter client.
- **Notifications do not arrive:** verify Firebase Cloud Messaging setup, platform permissions, and notification-channel configuration.
- **A platform build fails after switching machines:** run `flutter clean`, then `flutter pub get`; also check the platform SDK requirements reported by `flutter doctor`.
- **Linux is unsupported by the current Firebase options:** `firebase_options.dart` currently throws for Linux, so Linux builds need an explicit Firebase configuration decision.

## Contributing

Contributions are welcome, but please discuss substantial changes before starting work because the app integrates with private institutional and backend services.

- Branches should follow `akshat/<type>/<short-description>`, for example `akshat/fix/login-timeout` or `akshat/feature/attendance-chart`.
- Use imperative, focused commit subjects such as `Fix cached announcement refresh` or `Add attendance chart tests`.
- Keep commits focused and avoid committing generated files, credentials, private data, or local machine paths.
- Before opening a PR, run `flutter analyze` and the relevant tests, and describe any unavailable external service or skipped check.
- PR titles should state the user-facing or engineering change, for example `Fix stale announcement cache`.
- Include screenshots or a short recording for meaningful UI changes, and explain migration/configuration steps for backend or Firebase changes.

## Open-Source Readiness Checklist

Before making the repository public:

1. Rotate and revoke the Google OAuth client secret in `exeriment_ground/content_extraction/drive_api.json` and any Firebase Admin service-account credentials in `exeriment_ground/`. Do not publish those files or their history.
2. Check the complete Git history, not only the working tree, for secrets. If a secret was ever committed, revoke it and remove it from history with an approved history-rewrite process.
3. Confirm that the Firebase project, Firestore data, institutional URLs, images, logos, and announcement content may be exposed and redistributed. Replace private URLs/data with documented placeholders where needed.
4. Decide on and add a `LICENSE` file. No license is currently present; without one, external users do not have clear permission to reuse the code.
5. Replace hardcoded backend URLs and user-credential handling with an explicit, documented configuration and security design. The app currently stores the institutional password in local preferences and sends it to a third-party scraper service.
6. Replace the starter test, add tests for login/error/cache behavior, and verify a clean-clone setup on at least one supported platform.
7. Review whether `exeriment_ground/`, `complete_calender.txt`, and other content artifacts belong in the public repository. Remove them or document their purpose and data ownership before release.

The root `.gitignore` includes patterns for the sensitive/generated files found during this review, but ignore rules do not remove files already committed and are not a substitute for credential rotation.

## Support

For questions, bug reports, or setup issues, contact the developer at [akshatsrivastava206@gmail.com](mailto:akshatsrivastava206@gmail.com).