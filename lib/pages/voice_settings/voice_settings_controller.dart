import 'package:get/get.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class VoiceSettingsController extends GetxController {
  static const int maxSpeechLanguages = 3;

  final speechLanguages = RxList<String>(MySharedPref.getSpeechLanguages());

  static const supportedLanguages = <Map<String, String>>[
    {'code': 'en', 'label': 'English'},
    {'code': 'tl', 'label': 'Tagalog / Filipino'},
    {'code': 'ceb', 'label': 'Cebuano'},
    {'code': 'hil', 'label': 'Hiligaynon'},
    {'code': 'ilo', 'label': 'Ilocano'},
    {'code': 'bcl', 'label': 'Bicolano'},
    {'code': 'war', 'label': 'Waray'},
  ];

  Future<void> toggleSpeechLanguage(String code) async {
    if (code == 'en') {
      return;
    }

    if (speechLanguages.contains(code)) {
      speechLanguages.remove(code);
    } else {
      if (speechLanguages.length >= maxSpeechLanguages) {
        Get.snackbar(
          'Language limit reached',
          'Choose up to $maxSpeechLanguages speech languages.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      speechLanguages.add(code);
    }

    BatasphLogger.log('[Settings] Speech languages -> $speechLanguages');
    await MySharedPref.setSpeechLanguages(speechLanguages.toList());
  }
}
