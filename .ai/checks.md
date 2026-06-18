# Checks

- `flutter pub get`
- `flutter analyze`
- `flutter test`

## Last verified

- `flutter test test\widget_test.dart --reporter compact`：通过
- `flutter analyze`：通过
- `git status --short --branch`：失败，当前目录不是 Git 仓库
- `flutter test --reporter compact`：通过
- `flutter build apk --debug`：通过，生成 `dist/jobpilot-v1-debug.apk`
- `flutter build apk --release --target-platform android-arm64`：失败，Flutter release artifacts 下载 connection reset
