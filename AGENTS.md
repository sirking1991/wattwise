# WattWise

A Flutter mobile app for tracking household energy consumption. Purely client-side with local storage via `shared_preferences` — no backend, no database.

## Cursor Cloud specific instructions

### Environment

- **Flutter SDK** is installed at `/opt/flutter` and added to `PATH` via `~/.bashrc`.
- **Linux desktop** and **Web** targets are both enabled (`flutter config --enable-web --enable-linux-desktop`).
- Available devices: Linux desktop (`linux`) and Chrome (`chrome`).

### Common commands

| Task | Command |
|------|---------|
| Install deps | `flutter pub get` |
| Lint / analyze | `flutter analyze` |
| Run tests | `flutter test` |
| Run on web | `flutter run -d chrome` |
| Build web | `flutter build web` |
| Run on Linux | `flutter run -d linux` |

### Notes

- `flutter analyze` reports 6 info-level deprecation warnings (`MaterialStateProperty` → `WidgetStateProperty`). These are not errors.
- The widget test in `test/widget_test.dart` is the default Flutter counter-app boilerplate and does **not** match the actual WattWise app. It is expected to fail.
- To manually test the web build, run `flutter build web --debug` then serve `build/web/` on any HTTP server (e.g. `python3 -m http.server 8080 --directory build/web`).
