# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

BATASPH mobile app: a Flutter client that works like a **phone call with Atty. Luna**, an AI legal guide for Philippine law. You tap Call, the phone rings, Luna picks up, and you talk; she answers out loud in Taglish with the legal basis. There is no text chat and **no offline mode**: every answer streams from `/chat/stream` on the live API (`../batasph-api`).

## Commands

```bash
flutter pub get                 # install dependencies
flutter run                     # run on the default device
flutter analyze                 # lint / static analysis (flutter_lints)
dart format .                   # format before committing
flutter test                    # run all tests
flutter test test/foo_test.dart # run a single test file
flutter test --name "pattern"   # run tests whose names match
flutter build appbundle         # Play release (.aab), signed from android/key.properties
```

SDK: Dart `^3.10.7`. No build_runner or codegen.

**Local API on a device.** `AppConfig.apiBaseUrl` defaults to the production Cloud Run API. Point a debug build at a local `npm run start:dev` with `adb reverse tcp:3000 tcp:3000` and `flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1` (`android/app/src/debug/AndroidManifest.xml` allows cleartext for debug builds only). A release build never takes the override.

Tests mirror `lib/` under `test/`. `test/ui/call_design_test.dart` is the team's design test for Home and the call screen; run it with `--dart-define=WRITE_DESIGN_PREVIEWS=true` to write screenshots to `docs/design-previews/`.

## Read GUIDELINES.md first

@GUIDELINES.md

`GUIDELINES.md` at the repo root is authoritative for structure and style. `AGENTS.md` restates the same rules for other agents; keep the three files consistent when conventions change. The most load-bearing rules:

- **Package imports only.** Never relative (`../`, `./`). Use `package:batasph_mobile/...`.
- **GetX for everything**: state, DI, routing.
- **UI files contain zero logic.** `*_page.dart`, `*_component.dart`, `*_widget.dart` must not import services. Logic goes in a sibling `*_controller.dart`; the flow is UI → Controller → Service.
- **Global vs module scope**: `lib/components/`, `lib/services/`, `lib/utils/` only for things 2+ modules use.
- **Don't silently change behavior**; no fallbacks that paper over missing required data; no dirty fixes.

## Flow and routes

Splash → (first run only) **Onboarding**, one intro screen that asks for the microphone → **Home**, a dialer-style screen with Luna's photo and one Call button → **Voice chat**, the call screen. Ending a call turns the same screen into a summary (last question, legal basis, Done / Call again). Settings is the gear on Home.

Routes (`lib/routes/`): `SPLASH`, `ONBOARDING`, `LOGIN`, `REGISTER`, `VERIFY_EMAIL`, `FORGOT_PASSWORD`, `HOME`, `SETTINGS`, `PROFILE`, `VOICE_CHAT`, `VOICE_SETTINGS`. **Auth is not a gate**; the app is usable as a guest, and login/register/profile (with Delete account, which `vxtory.com/batasph/delete-data` points to) are reached from Settings.

`app_binding.dart` registers two permanent services: `AuthService` and `ChatService`.

## Persona and look

`AppConfig` holds the persona: `personaName` "Atty. Luna", `personaTagline` "BatasPH AI Legal Guide", `personaVoice` `luna`, `personaAvatarAsset` (`assets/images/avatars/luna_face.jpg`, a tight face crop: the source photo in `assets/branding/avatars/` shows another name and diplomas, so never use it uncropped). On screen she is "Atty. Luna"; the API speaks it as "Attorney Luna".

One light palette, no dark mode and no theme picker: Ivory `#F5F1EA` background, Forest `#1F4D3F`, Amber `#C8964F` (`config/theme/app_themes.dart`). The team designed the screens; change logic or copy, not their design, unless asked.

## Data layer

- `data/remote/api_client.dart`: singleton `ApiClient` wrapping one `Dio`. Its interceptor attaches `Authorization: Bearer <token>` or else an `x-guest-session-id` header, logs every request, and on a `401` calls `AuthService.handleUnauthorized()`. **Always use `ApiClient().client`**; a new `Dio` silently loses auth, guest identity and 401 handling.
- `data/remote/*_repository.dart`: `AuthRepository`, `ChatRepository`, `UserRepository`.
- `data/local/my_shared_pref.dart`: all persisted state (onboarding flag, auth token and user, guest session id, speech languages, **the caller's name**). Never touch `SharedPreferences` directly.

`ChatRepository.streamMessage` POSTs `/chat/stream` (`{text, mode: 'voice', voice}`) and hand-parses SSE into the sealed `ChatStreamEvent` types: `TokenEvent`, `AudioEvent` (sentence MP3 + `index` + `text`; may arrive out of order), `DoneEvent` (`legalBasis`, `sources`, status), `StreamErrorEvent`, `StreamWarningEvent`. `ChatService` owns the `CancelToken`; a cancel is normal, not a failure.

## The call (`lib/pages/voice_chat/`)

The largest and most timing-sensitive part of the app; everything is module-scoped under `services/`. The conversation engine and barge-in are ported from Memori (`memori/memori-mobile`, reference only, never edit it). BatasPH keeps its own config and its own API.

- **Call shell.** `VoiceCallAudioService` synthesizes the phone sounds at runtime: two classic ringback rings (440 + 480 Hz), the clunk of an old handset being picked up, and the "call dropped" beeps at the end. The greeting is prepared and the STT session opened (muted) *during* the rings.
- **Who is calling.** `VoiceGreetingService` greets a first-time caller with "Hi, this is Atty. Luna. May I ask your name?" and a returning one with "…Am I speaking with Chris again?" (three variants each, cached per text under `voice_greetings/v4`). `CallerIdentityService` sends the spoken answer to `POST /caller-identity`, which returns name / confirmed / denied / question / unclear plus any question said alongside. Its on-phone pattern readers answer only when the API is unreachable. A new name is saved in `MySharedPref`; a question said with the name is answered straight away.
- **STT.** Primary `RealtimeSttService` (continuous): one OpenAI Realtime transcription session per call, opened via `POST /realtime-transcription/session` with `silenceDurationMs` from `AppConfig.voiceSilenceSeconds` (2 → a 1.8 s turn end; 1 cut callers off). The recorder's `AudioInterruptionMode.none` is load-bearing. A realtime failure retries once, then falls back to `WhisperSttService` (one recording per turn, `/transcribe`).
- **Answer.** `_sendToBackend` opens the answer stream first, then plays a filler while it runs. Nothing waits on anything: filler, thinking loop and incoming audio run concurrently; `VoiceAudioChunkBuffer` plays chunks in index order as they arrive.
- **Fillers.** 24 short neutral reactions ("Hmm, okay.", "Ahh, alright.") bundled in `assets/audio/fillers/`, each the take chosen by ear from three ElevenLabs generations (listed in `voice_fillers.dart`). These are the app's only audio files. Regenerate and re-choose them if Luna's voice or voice settings change. `ThinkingSoundPlayer` covers any longer wait.
- **Barge-in** (`VoiceBargeIn` in `voice_barge_in_mode.dart`, with `BargeInDetector`, `EchoTextGuard`, `UplinkGate`, `VoiceAudioRoute`): while Luna speaks the mic stays open behind an uplink gate. Speech ducks her, confirmed words stop her and hand the floor over, and a false alarm lets her carry on. Backchannels ("oo", "sige", "opo") never interrupt. The user's Mute always wins.
- **Time limit.** A call lasts at most 3 minutes 30 seconds: at 3:00 Luna warns that thirty seconds are left (said once nobody is talking), and at 3:30 she says goodbye (after finishing an answer in progress) and the call ends.
- **Silence and goodbye.** 10 s of silence → a check-in; 8 s more → farewell. Saying goodbye ("bye", "salamat, yun lang") ends the call (`VoiceFarewellService`).
- **Screen.** No transcript is shown. While Luna prepares or speaks the status reads "Luna is speaking" with the voice animation; the controls are Mute and End.
- **Races.** `_turnId` invalidates a superseded SSE/audio turn, `_callFlowId` a superseded call/listen flow, and every async continuation re-checks its captured id. Preserve these; dropping a check reintroduces cross-turn audio bleed.

## Logging

Use `BatasphLogger` (`lib/utils/logger_util.dart`), never `print`. Prefix messages with a bracketed tag (`[Voice]`, `[STT]`, `[TTS]`, `[BARGE]`, `[Auth]`, …) and ` | key=value` metrics. Files go to `<app documents>/logs/batasph-YYYY-MM-DD.log` (2 MB roll, 7-day retention); on a debug device read them with `adb shell run-as com.vxtory.batasph cat app_flutter/logs/batasph-<date>.log`. Settings → Share Logs hands the newest file to the share sheet.
