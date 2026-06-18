# Known Traps

- The workspace may start as a plain folder with only `Agents.md`, not a Git or Flutter project.
- The `codegraph` MCP server can be available while the local `codegraph` CLI is missing from PATH, blocking index initialization.
- Release APK builds can fail if Flutter release artifacts from `storage.googleapis.com/download.flutter.io` are not reachable; debug APK may still build from cached debug artifacts.
- Real user import spreadsheets may use decorated headers like `岗位名称（必填）` or explicit direction columns; keep parser tests for normalized headers before changing import aliases.
