# Decisions

- Use Flutter + Material 3 for the Android-first offline app, following `Agents.md`.
- Keep phase 1 focused on UI shell and placeholders only; SQLite and persistence begin in phase 2.
- Remove generated iOS, desktop, and web platform templates to preserve Android-only scope.
- First-version delivery uses a debug APK because release artifact downloads failed; keep Android compileSdk at 36 to satisfy `file_picker` transitive Android metadata.
- Store custom job status/direction options in local SQLite `app_options` and store language preference in local SQLite `app_settings`, preserving the offline-first boundary.
