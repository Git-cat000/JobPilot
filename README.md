# JobPilot

JobPilot is an offline-first Flutter app for tracking job applications, interview stages, resumes, notes, imports, exports, and local backups. It does not require an account, does not use a server, does not sync to cloud storage, and does not upload user data by default.

The current Flutter version is **1.2.0+3**. The Flutter package remains `jobpilot_mobile` for technical compatibility; user-visible product names are JobPilot.

## v1.2 Highlights

- Added the `process_terminated` application status for roles that end without being rejected or abandoned.
- Improved application filters with adaptive selection sheets for status and direction.
- Improved XLSX import discovery for real spreadsheets with leading notes, empty sheets, decorated headers, typed cells, repeated header rows, and trailing formatted rows.
- Expanded English UI coverage for navigation, dashboards, lists, detail pages, import preview, statistics, settings, filters, and common dialogs. The application edit form intentionally remains Chinese for now.
- Added a user-triggered update action in Settings that opens the JobPilot GitHub Releases page. There is no background update polling.
- Added a local, read-only Web demo that uses seeded in-memory records and keeps mobile SQLite/import/export behavior unchanged.

## Platforms

| Platform | Status |
| --- | --- |
| Android | Primary mobile target. Uses local SQLite and local file import/export/backup. |
| iOS | Shares the same Dart app logic and local behavior, with Cupertino-style adaptive UI. Building or installing on a real device requires macOS, Xcode, and normal Apple signing setup. |
| Web | Local read-only demo only. No persistence, hosting, imports, exports, backup restore, or editing. |

The iOS simulator workflow in `.github/workflows/ios-simulator-build.yml` builds an unsigned simulator `Runner.app` ZIP artifact. It is not a signed IPA and does not require signing secrets.

## Local Web Demo

Run the read-only demo locally:

```bash
flutter run -d chrome
```

Build static Web output:

```bash
flutter build web
```

Web limitations:

- Seeded demo data only.
- Editing, deletion, import, export, backup, and restore are hidden or disabled.
- No SQLite or file-system persistence.
- The Settings update link remains available and opens GitHub Releases only when clicked.

## Mobile Features

- Create, edit, delete, search, and filter application records.
- Track status, job direction, city, channel, priority, apply date, follow-up date, JD link, resume version, salary range, and remarks.
- Record stages such as written tests, interviews, HR conversations, questions, review notes, and next actions.
- Import CSV/XLSX with header mapping, status detection, direction detection, duplicate checks, and a required preview step before writing data.
- Export CSV/XLSX with readable spreadsheet headers.
- Export and restore local `.jobpack` backups containing the SQLite database and version metadata.
- Dangerous operations such as delete, clear, and backup restore ask for confirmation.

## Privacy

JobPilot is designed for local-first private job tracking:

- No login.
- No server backend.
- No cloud sync.
- No automatic job scraping.
- No automatic upload of job records, resumes, notes, imports, exports, or backups.
- `.jobpack` files are local backup archives; keep them in a safe place.

## Build And Test

Install dependencies:

```bash
flutter pub get
```

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test --reporter compact
```

Run focused tests:

```bash
flutter test test/services/demo_app_controller_test.dart --reporter compact
flutter test test/services/export_pipeline_test.dart --reporter compact
flutter test test/widget_filter_test.dart --reporter compact
```

Build Android debug APK:

```bash
flutter build apk --debug
```

Build Android ARM64 release APK:

```bash
flutter build apk --release --target-platform android-arm64
```

Output: `build/app/outputs/flutter-apk/app-release.apk`
Delivered release filename: `dist/jobpilot-v1.2.0-arm64-release.apk`

Build Web:

```bash
flutter build web
```

Build iOS on macOS:

```bash
flutter pub get
flutter analyze
flutter build ios --debug --no-codesign --simulator
```

For real iOS device installation or release distribution, open the iOS project on macOS with Xcode and configure your own Apple signing team and bundle identifier as needed. This repository does not include signing secrets.

## Repository

GitHub Releases:

```text
https://github.com/Git-cat000/JobPilot/releases
```
