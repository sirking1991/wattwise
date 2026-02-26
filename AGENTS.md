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

- `flutter analyze` should report zero issues. If deprecation warnings appear in future Flutter versions, they are non-blocking.
- The widget test in `test/widget_test.dart` is the default Flutter counter-app boilerplate and does **not** match the actual WattWise app. It is expected to fail.
- To manually test the web build, run `flutter build web --debug` then serve `build/web/` on any HTTP server (e.g. `python3 -m http.server 8080 --directory build/web`).
- The app uses bottom navigation with 3 tabs: Home, History, Settings.
- Key dependencies: `fl_chart` (charts), `pdf`/`csv` (export), `share_plus` (share files), `intl` (formatting).
