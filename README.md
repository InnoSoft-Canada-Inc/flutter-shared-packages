# Flutter shared packages

Internal Flutter/Dart packages used across InnoSoft apps. This repository is a **monorepo**: each top-level folder is its own package with its own `pubspec.yaml`.

## Packages

| Package | Description |
|--------|-------------|
| [**fusionflutterlibrary**](fusionflutterlibrary/) | Shared UI utilities — animations, colors, extensions, and helpers (hex colors, search highlighting, etc.). |
| [**logging_system**](logging_system/) | Logging stack with Talker, BLoC/Dio integrations, Firebase Crashlytics, and AWS CloudWatch. |
| [**super_tooltip**](super_tooltip/) | Full-screen overlay tooltips with flexible positioning (fork/vendor copy of [super_tooltip](https://github.com/escamoteur/super_tooltip)). |

See each package’s own `README.md` for API details and examples.

## Use a package in an app

Add a [path dependency](https://dart.dev/tools/pub/dependencies#path-packages) if you have this repo checked out next to your app, or a [Git dependency](https://dart.dev/tools/pub/dependencies#git-packages) to pull a subfolder from GitHub:

```yaml
dependencies:
  fusionflutterlibrary:
    git:
      url: git@github.com:InnoSoft-Canada-Inc/flutter-shared-packages.git
      ref: main
      path: fusionflutterlibrary
```

Replace `fusionflutterlibrary` with `logging_system` or `super_tooltip` and adjust `path` as needed.

## Requirements

- Flutter SDK (see each package’s `pubspec.yaml` for Dart SDK constraints).

## Development

From the package directory:

```bash
cd fusionflutterlibrary   # or logging_system, super_tooltip
flutter pub get
dart analyze              # or flutter test
```

The `logging_system` package also includes an example app under `logging_system/example/`.

## Contributing

Open issues and pull requests in this repository. When changing a package, bump its version in that package’s `pubspec.yaml` and update its changelog if you maintain one.
