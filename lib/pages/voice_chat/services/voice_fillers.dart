/// What Luna says the instant the caller's turn is final, while the answer
/// is already being prepared, so there is no silence.
///
/// Neutral reactions on purpose: they are played before anything is known
/// about the turn, so each must fit a name, a yes/no, or a legal question
/// alike. The thinking loop carries any longer wait.
///
/// The clips are bundled, not synthesized: each is the take chosen by ear
/// (2026-10-05) out of three generated in Luna's ElevenLabs voice, since
/// every synthesis reads "Hmm" and "Ahh" a little differently. Adding or
/// changing a phrase means generating takes and choosing one again.
class VoiceFillers {
  VoiceFillers._();

  static const String _folder = 'assets/audio/fillers';

  /// Clip asset → what it says (for the logs).
  static const Map<String, String> clips = {
    '$_folder/01.mp3': 'Hmm, okay.',
    '$_folder/02.mp3': 'Ahh, alright.',
    '$_folder/03.mp3': 'Mm, sige.',
    '$_folder/04.mp3': 'Ah, gets ko.',
    '$_folder/05.mp3': 'Okay, I see.',
    '$_folder/06.mp3': 'Hmm, sige sige.',
    '$_folder/07.mp3': 'Ahh, okay.',
    '$_folder/08.mp3': 'Mm-hm, okay.',
    '$_folder/09.mp3': 'Ah, I see.',
    '$_folder/10.mp3': 'Okay, okay.',
    '$_folder/11.mp3': 'Hmm, I see.',
    '$_folder/12.mp3': 'Ahh, sige.',
    '$_folder/13.mp3': 'Oh, okay.',
    '$_folder/14.mp3': 'Alright, alright.',
    '$_folder/15.mp3': 'Mm, okay.',
    '$_folder/16.mp3': 'Hmm, gets.',
    '$_folder/17.mp3': 'Ahh, I see, I see.',
    '$_folder/18.mp3': 'Okay, sige.',
    '$_folder/19.mp3': 'Oh, I see.',
    '$_folder/20.mp3': 'Hmm, alright.',
    '$_folder/21.mp3': 'Ah, okay po.',
    '$_folder/22.mp3': 'Ayun, okay.',
    '$_folder/23.mp3': 'Mm, I get it.',
    '$_folder/24.mp3': 'Sige, sige.',
  };
}
