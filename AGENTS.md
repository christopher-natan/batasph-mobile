# Repository Guidelines

## Required Read First
Whenever you load this file, load `GUIDELINES.md` in the repository root as well. Treat `GUIDELINES.md` as the authoritative source for structure and implementation rules, especially package-only imports, GetX usage, and the UI → Controller → Service separation.

## Project Structure & Module Organization
`lib/` contains the app code. Use `main.dart` for bootstrap, `app_binding.dart` for app-wide dependency registration, `routes/` for `GetPage` routing, `config/` for app constants, theming, and language settings, `data/` for models plus local/remote access, and `services/` for shared business services. Feature screens live under `lib/pages/<module>/` and should follow the GetX pattern: `*_page.dart`, `*_controller.dart`, and `*_binding.dart`. Static assets live in `assets/fonts`, `assets/images`, `assets/branding`, and `assets/audio/fillers` (Luna's bundled filler clips). The app is a voice call with Atty. Luna; `CLAUDE.md` describes the call architecture.

## Build, Test, and Development Commands
Run these from the repository root:

- `flutter pub get` installs Dart and Flutter dependencies.
- `flutter run` launches the app on the default device.
- `flutter analyze` applies `flutter_lints` and catches structural issues.
- `flutter test` runs the full test suite.
- `flutter build appbundle` creates the Play release build.

## Coding Style & Naming Conventions
Use 2-space indentation and standard Dart formatting. Prefer `dart format .` before opening a PR. Use `package:batasph_mobile/...` imports only; never use relative imports. Keep filenames in `snake_case`. Pages, components, and widgets must contain UI only. Put logic in sibling controllers, and call services only from controllers or other services. Keep module-specific code inside that module until at least two features reuse it. Shared utilities in `lib/utils/` should use the `*_util.dart` suffix. Use `BatasphLogger` instead of `print`.

## Testing Guidelines
Tests live under `test/`, mirroring `lib/`, named `*_test.dart`. Prioritize controller logic, services and route flows; `test/ui/call_design_test.dart` guards the team's screen designs. Use `flutter test test/foo_test.dart` for focused runs.

## Commit & Pull Request Guidelines
Use short, imperative commit subjects such as `Add onboarding binding` or `Refine sources service error handling`. PRs should include a clear summary, affected pages or routes, validation steps (`flutter analyze`, `flutter test`), screenshots for UI changes, and notes for API or config updates.

## Configuration Notes
Keep API settings in `lib/config/config.dart`; do not inline URLs, keys, or limits inside pages or services. Changes to fallback behavior or app-wide services in `app_binding.dart` should be called out explicitly during review.
