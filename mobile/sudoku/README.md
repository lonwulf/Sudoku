# sudoku

Sudoku mobile app (Flutter).

## Configuration

Settings are passed at build time with `--dart-define-from-file`. Each build
type has its own file in `config/`, which is git-ignored:

| File                   | Used for                 | `API_BASE_URL`              |
|------------------------|--------------------------|-----------------------------|
| `config/debug.json`    | `flutter run` (debug)    | Local backend, http allowed |
| `config/release.json`  | release builds           | Production, https required  |

Copy `config/example.json` to create them. Keys: `APP_ENV`, `API_BASE_URL`,
`API_VERSION`, `SENTRY_DSN`.

```sh
flutter run --dart-define-from-file=config/debug.json
flutter run --release --dart-define-from-file=config/release.json
flutter build appbundle --dart-define-from-file=config/release.json
```

In Android Studio, use the shared **sudoku (debug)** and **sudoku (release)**
run configurations (`/.run` at the repository root).
