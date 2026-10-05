import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:batasph_mobile/pages/voice_chat/services/voice_barge_in_mode.dart';

/// Decides, frame by frame, whether captured audio is worth uplinking.
/// Ported from Memori; thresholds come from [VoiceBargeIn].
///
/// The microphone has to stay open while the assistant speaks so the user can
/// interrupt — but streaming a silent room to a pay-per-minute transcriber is
/// money spent transcribing nothing, and the assistant speaks about as much
/// as the user does, so it roughly doubles the bill.
///
/// The gate is only ever applied to the assistant's turn. The user's own turn
/// streams unconditionally.
///
/// Two details matter more than the threshold itself:
///
/// * **The floor is measured, not assumed.** A fixed dBFS number would be
///   wrong in both a quiet bedroom and a noisy car. The floor is the quietest
///   frame in a short sliding window, and it is only updated while the gate
///   is shut — the room is what it sounds like when nobody is talking, so
///   sustained speech can never drag the threshold up to meet itself and
///   gate a sentence off half way through.
/// * **Nothing is lost when it opens.** The frames from just before the gate
///   opened are held and flushed first. Without that the opening syllable is
///   simply never transmitted — Memori was bitten by that
///   (2026-09-18: a whole sentence arrived as "We." because the microphone
///   was not live yet).
class UplinkGate {
  UplinkGate({
    this.marginDb = VoiceBargeIn.gateMarginDb,
    this.preRoll = const Duration(milliseconds: 320),
    this.hangover = const Duration(milliseconds: 1500),
    this.frameDuration = const Duration(milliseconds: 80),
    this.floorWindow = const Duration(seconds: 4),
    this.maxOpen = VoiceBargeIn.gateMaxOpen,
  });

  /// How far above the room floor counts as someone speaking. Generous on
  /// purpose: missing a real interruption is a worse failure than uplinking
  /// a few seconds of nothing.
  final double marginDb;

  /// How much audio from before the gate opened is kept and sent first.
  final Duration preRoll;

  /// How long the gate stays open after the level drops back, so an ordinary
  /// pause mid-sentence does not chop the uplink in half.
  final Duration hangover;

  /// Nominal length of one captured frame, used to size the pre-roll.
  final Duration frameDuration;

  /// How far back the room floor looks. Long enough not to be moved by a
  /// single noise, short enough to follow a room that changes.
  final Duration floorWindow;

  /// The longest the gate may stay open before it is forced shut and the room
  /// re-measured.
  ///
  /// A cost ceiling, not a feature. The floor is frozen while the gate is
  /// open, so a room that is loud for the whole reply — a television, a cafe,
  /// music — can hold it above its own stale threshold and stream the entire
  /// turn, which is precisely the bill this gate exists to avoid. Nothing
  /// legitimate needs longer: a real interruption is confirmed within about a
  /// second, and confirming ungates entirely.
  final Duration maxOpen;

  /// Starting floor before the room has been heard. Quiet enough that the
  /// first real speech opens the gate rather than being swallowed.
  static const double initialFloorDbfs = -65;

  final _preRoll = Queue<Uint8List>();
  final _recentQuiet = Queue<double>();
  double _floorDbfs = initialFloorDbfs;
  bool _open = false;
  int _framesBelowThreshold = 0;
  int _framesOpen = 0;

  bool get isOpen => _open;

  /// The room floor the threshold is measured against. Logged when the gate
  /// opens, so a gate that never fires can be diagnosed from a device log.
  double get floorDbfs => _floorDbfs;

  @visibleForTesting
  double get thresholdDbfs => _floorDbfs + marginDb;

  int get _preRollFrames =>
      (preRoll.inMilliseconds / frameDuration.inMilliseconds).ceil();

  int get _hangoverFrames =>
      (hangover.inMilliseconds / frameDuration.inMilliseconds).ceil();

  int get _floorFrames =>
      (floorWindow.inMilliseconds / frameDuration.inMilliseconds).ceil();

  int get _maxOpenFrames =>
      (maxOpen.inMilliseconds / frameDuration.inMilliseconds).ceil();

  /// True when the gate was forced shut by [maxOpen] rather than by silence.
  /// Worth logging: it means the threshold is not separating this room.
  bool get lastCloseWasForced => _lastCloseWasForced;

  bool _lastCloseWasForced = false;

  /// Offers one captured frame to the gate.
  ///
  /// Returns the frames to uplink: empty while the room is quiet, the held
  /// pre-roll plus this frame on the moment it opens, and just this frame
  /// while it stays open.
  List<Uint8List> offer(Uint8List frame, double dbfs) {
    _trackFloor(dbfs);

    if (_open && ++_framesOpen >= _maxOpenFrames) {
      // Held open by the room, not by a voice. Shut it and re-measure, so a
      // noisy environment costs one window rather than the whole reply.
      _closeGate(forced: true);
      return const [];
    }

    if (_warmedUp && dbfs >= thresholdDbfs) {
      _framesBelowThreshold = 0;
      if (!_open) {
        _open = true;
        _framesOpen = 0;
        _lastCloseWasForced = false;
        final flush = [..._preRoll, frame];
        _preRoll.clear();
        return flush;
      }
      return [frame];
    }

    if (_open) {
      // Below the threshold, but a pause inside a sentence is not the end of
      // one. Only a sustained drop closes the gate.
      _framesBelowThreshold++;
      if (_framesBelowThreshold < _hangoverFrames) return [frame];
      _closeGate(forced: false);
      return const [];
    }

    _preRoll.addLast(frame);
    while (_preRoll.length > _preRollFrames) {
      _preRoll.removeFirst();
    }
    return const [];
  }

  /// Shuts the gate and drops the stale floor, so the threshold is learned
  /// again from the room as it is now rather than as it was before the gate
  /// opened.
  void _closeGate({required bool forced}) {
    _open = false;
    _framesBelowThreshold = 0;
    _framesOpen = 0;
    _lastCloseWasForced = forced;
    _recentQuiet.clear();
  }

  /// The quietest frame in the recent window, sampled only while the gate is
  /// shut. Speech never enters the estimate, so it cannot raise the bar it is
  /// being measured against.
  void _trackFloor(double dbfs) {
    if (_open) return;
    _recentQuiet.addLast(dbfs);
    while (_recentQuiet.length > _floorFrames) {
      _recentQuiet.removeFirst();
    }
    _floorDbfs = _recentQuiet.reduce(math.min);
  }

  /// The gate may not open until the room has been sampled at least this
  /// much. A permissive threshold during warm-up opened instantly in a noisy
  /// room, which froze the floor at its starting value and saved nothing.
  ///
  /// Nothing is lost while warming up: those frames sit in the pre-roll and
  /// are flushed the moment it opens, so the window is sized to fit inside
  /// the pre-roll.
  bool get _warmedUp => _recentQuiet.length >= _warmUpFrames;

  int get _warmUpFrames => _preRollFrames;

  /// Back to closed, with nothing held over from the last turn.
  void reset() {
    _preRoll.clear();
    _recentQuiet.clear();
    _open = false;
    _framesBelowThreshold = 0;
    _framesOpen = 0;
    _lastCloseWasForced = false;
    _floorDbfs = initialFloorDbfs;
  }
}
