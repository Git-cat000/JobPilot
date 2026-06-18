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
- `gh release view v1.0.0 --json url,assets,tagName`：通过，APK release asset uploaded with matching SHA-256
- `flutter test test\services\import_pipeline_test.dart --reporter compact`：通过，覆盖装饰表头和显式岗位方向导入
- `flutter test --reporter compact`：通过
- `flutter analyze`：通过
- `flutter build apk --debug`：通过，刷新 `dist/jobpilot-v1-debug.apk`
- `Get-FileHash dist\jobpilot-v1-debug.apk -Algorithm SHA256`：`6C7A1C439D8865A45215B24D3C244B3047D977ECD5E7AE270195DD6D55AA5152`
