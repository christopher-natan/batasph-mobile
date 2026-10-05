# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

BATASPH mobile app — a Flutter client for a law-grounded Q&A ("Ask Batas") pipeline covering Philippine law, answering in English or Tagalog with legal-basis citations. It talks to a separate backend over HTTP; there is **no offline mode** — every answer comes from `/chat/stream` on the live API.

Two ways to ask: **text chat** (streamed tokens rendered as markdown) and **voice chat** (a phone-call-style screen with record → transcribe → stream → speak turn-taking).

## Commands

```bash
flutter pub get                 # install dependencies
flutter run                     # run on the default device
flutter run -d chrome           # run the web target
flutter analyze                 # lint / static analysis (flutter_lints)
dart format .                   # format before committing
flutter test                    # run all tests
flutter test test/foo_test.dart # run a single test file
flutter test --name "pattern"   # run tests whose names match
flutter build apk               # Android release build
flutter build ios               # iOS release build
```

SDK: Dart `^3.10.7`. No build_runner or codegen — plain Flutter.

There is currently **no `test/` directory**. When adding tests, mirror `lib/` under `test/` and name files `*_test.dart`. A few pure-logic units are already designed to be testable and are the best starting points: `WhisperTurnDetector`, `ListeningRetryGuard`, `VoiceAudioChunkBuffer`, and the `@visibleForTesting` statics `WhisperSttService.resolveEndOfSpeechDelay` / `resolveSilenceWindowSamples`.

The backend must be reachable for anything to work. `AppConfig.apiBaseUrl` is currently a LAN address (`http://192.168.0.88:3000/api/v1`) — expect it to need changing per machine.

## Read GUIDELINES.md first

@GUIDELINES.md

`GUIDELINES.md` at the repo root is authoritative for structure and style (auto-loaded via the `@` import above). `AGENTS.md` restates the same rules for other agents — keep the three files consistent when conventions change. The most load-bearing rules:

- **Package imports only.** Never relative (`../`, `./`). Use `package:batasph_mobile/...`.
- **GetX for everything**: state, DI, routing. No other state solution.
- **UI files contain zero logic.** `*_page.dart`, `*_component.dart`, `*_widget.dart` must not import services and must not contain business logic. Any logic goes in a sibling `*_controller.dart`.
- **Flow is UI → Controller → Service.** Services may only be called from controllers or other services. Service → Service is allowed.
- **Global vs module scope**: `lib/components/`, `lib/services/`, `lib/utils/` are for things shared across 2+ modules. Anything used by only one module lives inside that module (`lib/pages/<module>/services/`, `.../components/`). Global util files are named `*_util.dart`.
- **Page → Component → Widget hierarchy** is strict. A full-screen route pushed via `Get.to()` / `Get.toNamed()` must be promoted to a page under `lib/pages/`, not a component/widget. Components become a folder (not a single file) as soon as they need a controller or sub-widgets. Widgets always live in their own folder under `widgets/`.
- **Don't silently change behavior.** State the trade-off and get approval before removing or altering working behavior. Don't add fallbacks that paper over missing required data — fail visibly and fix the root cause. No dirty fixes.

## Architecture

### Entry and bootstrap
- `lib/main.dart` — `MySharedPref.init()`, then `ScreenUtilInit` (design size `375×812`, `textScaler: noScaling`) wrapping `GetMaterialApp` with `AppBinding`, `AppPages.routes`, and light/dark themes from `MySharedPref.getThemeIsLight()`. Portrait-locked, edge-to-edge.
- `lib/app_binding.dart` registers five **permanent global services**: `AuthService`, `AnswerFeedbackService`, `ChatService`, `SavedAnswersService`, `SourcesService`. Add global singletons here only when they're truly app-wide.

### Routing
- `lib/routes/app_pages.dart` holds `AppPages.routes`; `app_routes.dart` is a `part` file with the `Routes` constants and `_Paths` strings. Route constants are uppercase (`Routes.MAIN_SHELL`).
- Routes: `SPLASH` (initial), `ONBOARDING`, `LOGIN`, `REGISTER`, `VERIFY_EMAIL`, `FORGOT_PASSWORD`, `MAIN_SHELL`, `LEGAL_WEBVIEW`, `PROFILE`, `REPORT_ANSWER`, `SAVED_ANSWERS`, `FEEDBACK_REPORTS`, `VOICE_CHAT`, `VOICE_SETTINGS`.
- `SplashController` gates entry: onboarding not complete → `ONBOARDING`, else `MAIN_SHELL`. **Auth is not a gate** — the app is usable as a guest; login/register are reached from settings/profile. Register → `VERIFY_EMAIL` (6-digit code, signs in on success); a login the API refuses with `403 EMAIL_NOT_VERIFIED` also routes there and requests a fresh code. `FORGOT_PASSWORD` is a two-step page (email → code + new password) that returns the email to the login screen. `ApiErrorUtil` reads API error messages, including the `429` from the auth throttle. `PROFILE` has **Delete account** (confirm dialog → `DELETE /users/me` → local logout → `MAIN_SHELL`), which is what `vxtory.com/batasph/delete-data` and Play's account-deletion policy point to.
- `MAIN_SHELL` is an `IndexedStack` of **three** tabs — home, chat, settings. `MainShellController` lazily marks tabs as loaded (`loadedTabIndexes`) so a tab's page is only built once visited. `MainShellBinding` `Get.lazyPut`s `MainShellController`, `HomeController`, `ChatController`, `SettingsController`.
- Adding a top-level screen: `lib/pages/<name>/{<name>_page.dart,<name>_controller.dart,<name>_binding.dart}`, add `Routes.<NAME>` + `_Paths.<NAME>`, register the `GetPage`.
- **Note:** `lib/pages/sources/` and the globally-registered `SourcesService` (a hardcoded list of law-source links) are currently orphaned — no route, not in the shell, no consumer. Don't assume they're wired up.

### Data layer
- `lib/data/remote/api_client.dart` — singleton `ApiClient` wrapping one `Dio`. Its interceptor does three things every service depends on: attaches `Authorization: Bearer <token>` when `AuthService.token` is set and otherwise falls back to an `x-guest-session-id` header (a persisted UUID from `MySharedPref.getGuestSessionId()`); logs via `BatasphLogger.apiRequest/apiResponse/apiError`; and on a `401` calls `AuthService.handleUnauthorized()` to clear the session. **Always use `ApiClient().client`** — a new `Dio` would silently lose auth, guest identity, and 401 handling.
- `lib/data/remote/*_repository.dart` — thin HTTP layer (`AuthRepository`, `ChatRepository`, `UserRepository`, `AnswerFeedbackRepository`). Repositories are constructed directly by services, not injected.
- `lib/data/local/my_shared_pref.dart` — all persisted state (theme + `AppThemeId`, answer language, onboarding flag, recent searches, auth token/user JSON, guest session id, voice silence seconds, selected voice, speech languages, saved answers). Always go through it; never touch `SharedPreferences` directly.
- `lib/data/models/` — plain models with `fromJson`/`toJson`.

### Chat streaming (the core mechanism)
`ChatRepository.streamMessage` POSTs to `/chat/stream` with `{text, mode, language?, voice?, subjects?}` using `ResponseType.stream` and `receiveTimeout: Duration.zero`, then hand-parses **SSE** frames (split on `\n\n`, `event:` / `data:` lines) into a sealed `ChatStreamEvent` hierarchy in `lib/data/models/chat_stream_event.dart`:

| Event | Payload |
|---|---|
| `UserMessageEvent` | server-canonical user message — replaces the optimistic one |
| `TokenEvent` | one text delta to append |
| `AudioEvent` | base64 TTS chunk + `index` (voice mode only; may arrive out of order) |
| `DoneEvent` | `aiMessageId`, `sources`, `legalBasis`, `disclaimer`, `responseLanguage`, `cached`, `noResults`, `status` |
| `StreamErrorEvent` / `StreamWarningEvent` | terminal error / non-fatal warning (e.g. `voice_synthesis_failed`) |

Unknown event types and unparseable frames are dropped silently. `ChatService` owns the `CancelToken` — there is one in-flight stream at a time, and `cancelStream()` cancels it; a `DioExceptionType.cancel` is a normal cancellation, not a failure.

`mode` selects the pipeline: `'text'` (default, `ChatController`) streams tokens only; `'voice'` (`VoiceChatController`) also streams `AudioEvent` chunks.

`ChatController.sendMessage` appends an optimistic `temp_<ms>` user message, swaps it out on `UserMessageEvent`, accumulates `streamingText`, and on `DoneEvent` commits a real assistant `ChatMessageModel`. While streaming, `_followStreamIfNearBottom` keeps the reply in view only if the reader is already within 120 px of the bottom.

**History is paged** (`AppConfig.chatPageSize`, 30): `_loadHistory` fetches the newest page, `loadMoreMessages` fetches `before: messages.first.timestamp` when the list scrolls within 100 px of the top and restores the scroll offset after prepending. Note the API quirk: `/chat/history` with `limit`/`before` returns **newest-first**, unpaginated returns oldest-first — the controller reverses paged results.

### Voice chat subsystem (`lib/pages/voice_chat/`)
The largest and most timing-sensitive part of the app. The **call shell** (ringing → greeting → hold tone → end tone, call timer) is BatasPH's; the **conversation engine** underneath is ported from Memori (`memori/memori-mobile/lib/pages/voice_chat/` — reference only, never edit it). `VoiceChatBinding` lazily provides `CloudTtsService`, `VoiceCallAudioService`, and `VoiceChatController`; the controller creates its own STT service because it swaps implementations at runtime. Everything is **module-scoped** under `pages/voice_chat/services/`.

- `stt_service.dart` / `tts_service.dart` are the abstract interfaces. `SttService` has defaults for `supportsContinuousListening` / `setMuted` — `extends` it, don't `implements` it.
- **STT, primary — `RealtimeSttService`** (continuous): `POST /realtime-transcription/session` mints an OpenAI client secret, the phone opens a WebSocket (`realtime_socket_client_*.dart`, `dart:io` on mobile, stub elsewhere) and streams PCM16/24 kHz from `record`'s `startStream`. Server VAD segments turns; one session spans the whole call. `setMuted(true)` while Batas is talking (recorder keeps running, nothing sent, `input_audio_buffer.clear` on mute). A 45 s unmuted silence closes the session → `onIdle` → the call goes on hold. Socket drops reconnect once with a fresh secret. The recorder uses `autoGain`, `echoCancel`, and `AudioInterruptionMode.none` — the last one is load-bearing (default focus handling pauses the mic when the reply TTS starts and never resumes).
- **STT, fallback — `WhisperSttService`** (one recording per turn): AAC/16 kHz to a temp file, `WhisperTurnDetector` on `onAmplitudeChanged` decides end-of-turn, multipart upload to `/transcribe`. `_onSttError` swaps to it once per call when realtime fails; `endConversation` disposes and recreates realtime for the next call.
- The silence window derives from `MySharedPref.getVoiceSilenceSeconds()` through `resolveEndOfSpeechDelay` in each STT service (200 ms cushion, 700 ms floor). Change tuning there, not inline.
- **Greeting**: `VoiceGreetingService` fetches the persona opener from `GET /chat/greeting?language=` (the backend's `PERSONA` — "Hi, this is Batas, your legal assistant…") and caches its audio via `SpokenClipCache` at `<app support>/voice_greetings/v1/<voice>/<lang>_<textHash>.mp3`. Prepared in `onInit` so it's in hand before the user taps Call; the STT session is opened **muted behind the ringing** (`_openSessionBehindGreeting`) so the mic is live the instant the greeting ends. A missing greeting (offline) is skipped, never blocks.
- **Fillers + thinking loop**: the instant a transcript is final, `_playFillerThenThinking` speaks a cached filler (`VoiceFillers.checking` for a real question, `.acknowledging` for ≤2-word turns; `VoiceFillerService` warms all clips per voice in the background) then starts `ThinkingSoundPlayer` (a runtime-synthesized loop, no asset) until the first reply audio chunk. The loop is the only window where the mic is unmuted during Batas's turn; transcripts arriving then are logged and dropped (`_awaitingTurnTranscript`).
- **TTS**: `CloudTtsService` calls `/tts/synthesize`, plays MP3 bytes through `audioplayers`, completes a `Completer` on `onPlayerComplete`. `stop()` fades over 3 steps.
- **Call audio**: `VoiceCallAudioService` synthesizes ringing / on-hold / end-call tones at runtime; `helpers/pcm_wav_helper.dart` (`wrapPcmAsWav`, `encodePcm16`) is shared with the thinking loop. No audio assets anywhere.
- **Volume check**: `OutputVolumeCheck.isSilent()` (`flutter_volume_controller`) before the greeting → snackbar if media volume is muted. Advisory only.
- **Ordering**: `AudioEvent`s can arrive out of order, so `VoiceAudioChunkBuffer` only pops the next expected index; `_processAudioQueue` drains it serially, muting STT and stopping the thinking loop before each chunk.
- **State machine**: `VoiceChatState` = idle → connecting → listening → processing → speaking → paused / error. Two counters guard races — `_turnId` (SSE/audio turn) and `_callFlowId` (call/listen flow); every async continuation re-checks its captured id. `_greetingPhase` additionally stops an STT failure during the ringing/greeting from starting a listen underneath the greeting. Preserve these; dropping a check reintroduces cross-turn audio bleed.
- `ListeningRetryGuard` caps consecutive empty Whisper transcriptions (1 auto-retry); on the open realtime session an empty final just keeps listening. Transcription errors get a 1-retry budget after the Whisper swap.
- On `endConversation` the controller asks `ChatController.reloadHistory()` so the voice turns appear in the text chat.
- **Not yet ported from Memori**: FAREWELL intent (needs `intent` on the backend `done` event) and a separate done chime (the end-call tone already covers it).

### Services (global, `lib/services/`)
- `AuthService` (`GetxService`) — holds the JWT in a **static** `_token` (read by the `ApiClient` interceptor without a `Get.find`), hydrates token + cached user from prefs on init, exposes `currentUser` as `Rxn<UserModel>`. `handleUnauthorized()` logs out and either redirects to login (from `PROFILE`) or shows a "session expired" snackbar.
- `ChatService` — streaming + `/chat/history` (get / clear / delete).
- `SavedAnswersService` — bookmarks stored **locally only** in `MySharedPref` as JSON strings; reactive `savedAnswers` list.
- `AnswerFeedbackService` — "report this answer" flow against `/answer-feedback` (POST + GET), reactive `feedbackReports` list feeding the `FEEDBACK_REPORTS` page.
- `SourcesService` — hardcoded law-source list; currently unused (see routing note).

### Config & theming
- `lib/config/config.dart` — `AppConfig` (`apiBaseUrl`, `apiKey`, `appName`, `chatMaxMessageLength`). Change here, never inline.
- `lib/config/theme/` — `MyTheme.getThemeData(isLight:)` builds the `ThemeData`. `app_themes.dart` defines six named palettes (`AppThemeId`: midnightInk, tealHaven, sepiaArchive, plumInk, indigoDust, sageMoss), each with a full light/dark `AppThemeColors` set; the choice persists via `MySharedPref.getAppTheme()`. Both the light/dark toggle and the palette pick go through `MyTheme` so `Get.changeTheme` fires.
- `lib/config/language/answer_language.dart` — `AnswerLanguage` (`auto`/`english`/`tagalog`) with `label`, `description`, and `legalBasisLabel` extensions; `answerLanguageFromStorage` is the parse helper. The enum's `.name` is what gets sent as the `language` field.
- Fonts `Poppins` and `Cairo` are declared in `pubspec.yaml`. Voice avatar images live in `assets/images/avatars/` and are resolved through `VoiceAvatarUtil` (`assetFor` returns null for voices with no image — callers use `fallbackColorFor`).

### Logging
Use `BatasphLogger` (`lib/utils/logger_util.dart`) for all diagnostics. Never `print` or a raw `Logger()`.

- **Levels**: `trace/debug/log/warning/error`; `warning` and `error` take optional `error:` and `stackTrace:` — pass them from `catch (e, st)` rather than interpolating `$e` into the message.
- **Tags**: prefix every message with a bracketed subsystem so log files are greppable — `[Auth]`, `[Chat]`, `[Voice]`, `[STT]`, `[TTS]`, `[Settings]`, `[Feedback]`, `[Saved]`, `[Home]`, `[Splash]`, `[Onboarding]`, `[Logs]`. `[Nav]`, `[Lifecycle]`, `[Session]`, `[Uncaught]` are emitted by the logger itself. Use ` | key=value` pairs for metrics (`'[Chat] Done | 1240ms | tokens=87'`).
- **Sinks**: console (boxed, coloured) always; plus rotating plain-text files under `<app documents>/logs/batasph-YYYY-MM-DD.log` when `AppConfig.fileLoggingEnabled` (via `LogFileOutput` in `lib/utils/log_file_output_util.dart` — never throws, never blocks the UI, 2 MB roll, 7-day retention). All knobs live in `AppConfig` (`loggingEnabled`, `fileLoggingEnabled`, `logLevel`, `logRetentionDays`, `logMaxFileBytes`).
- **Bootstrap**: `main()` calls `await BatasphLogger.init()` first, which installs `FlutterError.onError` / `PlatformDispatcher.onError` hooks and writes a `[Session]` header (OS, build mode, API URL). `main.dart` also wires `AppLifecycleListener` → `lifecycle()` and `GetMaterialApp.routingCallback` → `nav()`, so every route change and foreground/background transition is logged without touching pages.
- **API**: the `ApiClient` interceptor logs every request/response/error with elapsed ms. Stream and byte responses are summarised (`<stream>`, `<N bytes>`), multipart bodies list fields + file sizes — never dump binary into the log.
- **Voice**: `VoiceChatController` logs every state transition via one `ever(state, …)` observer plus per-turn timing (`turn=`, `flow=`, first token / first audio / done ms). `WhisperSttService` logs per `session=` (speech detected, end of speech, upload size, transcribe ms); `CloudTtsService` logs synth ms and bytes.
- **Sharing**: Settings → Support → **Share Logs** flushes and hands the newest file to the OS share sheet (`share_plus`). Use `BatasphLogger.flush()` / `logFiles()` if you need the files elsewhere.
