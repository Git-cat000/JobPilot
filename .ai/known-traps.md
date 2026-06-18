# Known Traps

- The workspace may start as a plain folder with only `Agents.md`, not a Git or Flutter project.
- The `codegraph` MCP server can be available while the local `codegraph` CLI is missing from PATH, blocking index initialization.
- Release APK builds can fail if Flutter release artifacts from `storage.googleapis.com/download.flutter.io` are not reachable; debug APK may still build from cached debug artifacts.
