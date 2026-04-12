# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

BATASPH mobile app — a Flutter client for a law-grounded Q&A ("Ask Batas") pipeline. English and Tagalog responses with legal-basis citations. Backend is a separate service reached over HTTP; the mobile app is currently a shell that falls back to localized stub responses when the API is unreachable.

## Commands

```bash
flutter pub get                 # install dependencies
flutter run                     # run on the default device
flutter run -d chrome           # run the web target
flutter analyze                 # lint / static analysis (flutter_lints)
flutter test                    # run all tests
flutter test test/foo_test.dart # run a single test file
flutter test --name "pattern"   # run tests whose names match
flutter build apk               # Android release build
flutter build ios               # iOS release build
```

SDK: Dart `^3.10.7`. No custom build runners or codegen — plain Flutter.

## Read GUIDELINES.md first

@GUIDELINES.md

`GUIDELINES.md` at the repo root is authoritative for structure and style (auto-loaded via the `@` import above). Every change must follow it. The most load-bearing rules:

- **Package imports only.** Never relative (`../`, `./`). Use `package:batasph_mobile/...`.
- **GetX for everything**: state, DI, routing. No other state solution.
- **UI files contain zero logic.** `*_page.dart`, `*_component.dart`, `*_widget.dart` must not import services and must not contain business logic. Any logic goes in a sibling `*_controller.dart`.
- **Flow is UI → Controller → Service.** Services may only be called from controllers or other services. Service → Service is allowed.
- **Global vs module scope**: `lib/components/`, `lib/services/`, `lib/utils/` are for things shared across 2+ modules. Anything used by only one module lives inside that module (`lib/pages/<module>/services/`, `.../components/`). Global util files are named `*_util.dart`.
- **Page → Component → Widget hierarchy** is strict. A full-screen route pushed via `Get.to()` / `Get.toNamed()` must be promoted to a page under `lib/pages/`, not a component/widget. Components become a folder (not a single file) as soon as they need a controller or sub-widgets. Widgets always live in their own folder under `widgets/`, even when it's a single file.
- **Don't silently change behavior.** Before removing or altering any working behavior, state the trade-off and get approval. Don't add fallbacks that paper over missing required data — fail visibly and fix the root cause. No dirty fixes.

## Architecture

### Entry and bootstrap
- `lib/main.dart` initializes `MySharedPref`, wraps the app in `ScreenUtilInit` (design size `375×812`, `textScaler: noScaling`), and launches `GetMaterialApp` with `AppBinding`, `AppPages.routes`, and the light/dark theme from `MySharedPref.getThemeIsLight()`.
- `lib/app_binding.dart` registers **global permanent services** (`AskBatasService`, `SourcesService`) via `Get.put(..., permanent: true)`. Add global singletons here only when they're truly app-wide.

### Routing
- `lib/routes/app_pages.dart` defines `AppPages.routes` (list of `GetPage` entries). `app_routes.dart` is a `part` file holding `Routes` constants and `_Paths` string paths. Use uppercase route constants (`Routes.MAIN_SHELL`).
- Top-level routes today: `SPLASH`, `ONBOARDING`, `MAIN_SHELL`, `LEGAL_WEBVIEW`. `MAIN_SHELL` is a tabbed shell that hosts the `home`, `chat`, `sources`, and `settings` pages; its `MainShellBinding` `Get.lazyPut`s all four controllers plus `MainShellController`.
- Adding a new top-level screen: create `lib/pages/<name>/{<name>_page.dart,<name>_controller.dart,<name>_binding.dart}`, add a `Routes.<NAME>` + `_Paths.<NAME>` in `app_routes.dart`, and register the `GetPage` in `app_pages.dart`.

### Module/DI layout
- Every page module owns its `*_binding.dart`. Inside a binding, prefer `Get.lazyPut(() => ...)` for module controllers; reserve `Get.put(..., permanent: true)` for truly global services in `AppBinding`.
- Module-local services and components live under `lib/pages/<module>/services/` and `lib/pages/<module>/components/` — do not hoist them to `lib/services/` or `lib/components/` until a second module actually needs them.

### Data layer
- `lib/data/remote/api_client.dart` is a singleton `ApiClient` wrapping a single `Dio` instance. `baseUrl` and `x-api-key` come from `AppConfig` (`lib/config/config.dart`). It attaches a logging interceptor (`BatasphLogger.apiRequest/apiResponse/apiError`) — new services should reuse `ApiClient().client` rather than constructing their own `Dio`.
- `lib/data/local/my_shared_pref.dart` wraps `shared_preferences` for persisted settings (theme, language, onboarding flags). Always go through it instead of touching `SharedPreferences` directly.
- `lib/data/models/` holds plain Dart models (e.g. `AskResponseModel`, `ChatMessageModel`, `LawSourceModel`) with `fromJson`/`toJson`.

### Services (current)
- `AskBatasService.ask(...)` POSTs to `/ask` with `{question, subjects?, language?}` and returns an `AskResponseModel`. On `DioException` it logs a warning and returns a localized **offline stub** using `answerLanguageFromStorage(...)` — that behavior is intentional (shell can demo without a backend). Don't remove it without approval; if you add new endpoints, follow the same pattern of real call + explicit offline fallback where appropriate.
- `SourcesService` handles law-source listings consumed by the `sources` page.

### Config & theming
- `lib/config/config.dart` — `AppConfig` constants (`apiBaseUrl`, `apiKey`, `appName`, `chatMaxMessageLength`). Change here, not inline.
- `lib/config/theme/` — `MyTheme`, `app_themes.dart`, light/dark color files, `my_fonts.dart`, `my_styles.dart`, and a `theme_extensions/` folder. `Poppins` and `Cairo` font families are declared in `pubspec.yaml` under `assets/fonts/`.
- `lib/config/language/answer_language.dart` — `AnswerLanguage` enum (`auto`, `english`, `tagalog`) and the `answerLanguageFromStorage` helper used by services to pick response language.

### Logging
- Use `BatasphLogger` from `lib/utils/logger_util.dart` for all diagnostics (it wraps `package:logger` and has `apiRequest/apiResponse/apiError/warning/...` helpers). Don't use `print` or raw `Logger()` instances.
