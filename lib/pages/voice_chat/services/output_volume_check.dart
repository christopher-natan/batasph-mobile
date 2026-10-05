import 'package:flutter_volume_controller/flutter_volume_controller.dart';

import 'package:batasph_mobile/utils/logger_util.dart';

/// Reads the device's media volume — the stream the reply voice plays on.
/// Muted or zero means the user would speak and hear nothing back, which
/// looks exactly like a broken app.
class OutputVolumeCheck {
  OutputVolumeCheck._();

  /// True when the media stream is muted or at zero. If the platform cannot
  /// be asked (unsupported, plugin missing in tests) the answer is false:
  /// the check is advisory and must never block a call.
  static Future<bool> isSilent() async {
    try {
      final muted = await FlutterVolumeController.getMute() ?? false;
      final volume = await FlutterVolumeController.getVolume() ?? 1.0;
      BatasphLogger.debug(
        '[Voice] Media volume: ${(volume * 100).round()}% muted=$muted',
      );
      return muted || volume <= 0.0;
    } catch (error) {
      BatasphLogger.warning(
        '[Voice] Could not read media volume',
        error: error,
      );
      return false;
    }
  }
}
