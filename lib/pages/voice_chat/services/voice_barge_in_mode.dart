/// How much of the barge-in machinery is live.
///
/// Ported from Memori, staged the same way: opening the microphone while the
/// assistant speaks is only safe once the platform echo canceller is shown
/// to remove our own voice on a real device. [VoiceEchoProbe] logs the
/// figure (`[BARGE] echo TOTAL ... leak=`) every call, in every mode.
enum VoiceBargeInMode {
  /// The microphone is muted for the whole assistant turn (half-duplex).
  off,

  /// The voice-communication route is applied (engaging the echo canceller)
  /// but the microphone is still muted while we speak. Measures the AEC with
  /// no change in behaviour.
  routed,

  /// The microphone stays open while we speak and reaches the transcriber,
  /// but nothing acts on it. Costs transcription minutes; a measurement mode.
  observe,

  /// Full barge-in: speech over the reply ducks it, confirmed words stop it,
  /// and a false alarm lets it carry on.
  on,
}

/// BatasPH's barge-in configuration. Memori has its own; the two apps tune
/// independently. Values start from the figures Memori measured on device
/// and are adjusted here as BatasPH's own device logs come in.
class VoiceBargeIn {
  const VoiceBargeIn._();

  static const mode = VoiceBargeInMode.on;

  /// How long a duck waits for words before it is treated as a false alarm
  /// and the reply comes back up.
  static const falseAlarmWindow = Duration(milliseconds: 1200);

  /// Words needed to confirm an interruption. One is mostly noise or a
  /// backchannel; two is the smallest real one ("no wait", "teka lang").
  static const minWords = 2;

  /// Sounds that mean "I am listening", not "stop talking". BatasPH callers
  /// speak English, Tagalog and Taglish, so both are here.
  static const backchannels = <String>{
    // English
    'mm', 'mmm', 'mhm', 'mhmm', 'hm', 'hmm', 'huh', 'uh', 'um', 'er', 'ah',
    'oh', 'ok', 'okay', 'yeah', 'yep', 'yes', 'yup', 'right', 'sure', 'wow',
    'nice', 'cool', 'i', 'see', 'got', 'it',
    // Tagalog
    'oo', 'opo', 'o', 'po', 'sige', 'ayun', 'ayan', 'talaga', 'ganun',
    'ganon', 'eh', 'naman', 'nga', 'tama', 'totoo', 'okey',
  };

  /// Wait after our own audio ends before the microphone reopens, so the
  /// tail still in the speaker buffer is not transcribed as the user.
  static const micReopenGuard = Duration(milliseconds: 300);

  /// Reply volume while ducked: near silent, but still playing, so a false
  /// alarm fades back instead of restarting.
  static const duckedVolume = 0.05;
  static const duckDownDuration = Duration(milliseconds: 90);
  static const duckUpDuration = Duration(milliseconds: 220);

  /// Uplink gate for our own turn: how far above the measured room floor
  /// counts as someone speaking, and how long the gate may stay open.
  static const gateMarginDb = 8.0;
  static const gateMaxOpen = Duration(seconds: 6);

  /// True when playback goes out over the voice-communication route, which is
  /// what engages the platform echo canceller on the capture side.
  static bool get appliesVoiceRoute => mode != VoiceBargeInMode.off;

  /// True when the microphone stays open while the assistant speaks.
  static bool get keepsMicOpen =>
      mode == VoiceBargeInMode.observe || mode == VoiceBargeInMode.on;

  /// True when overlapping speech actually interrupts the reply.
  static bool get interrupts => mode == VoiceBargeInMode.on;
}
