import 'package:get/get.dart';
import 'package:batasph_mobile/pages/voice_chat/services/cloud_tts_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_call_audio_service.dart';
import 'package:batasph_mobile/pages/voice_chat/voice_chat_controller.dart';

class VoiceChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CloudTtsService());
    Get.lazyPut(() => VoiceCallAudioService());
    Get.lazyPut(() => VoiceChatController());
  }
}
