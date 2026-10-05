import 'package:batasph_mobile/pages/voice_chat/services/realtime_socket_client.dart';
import 'package:batasph_mobile/pages/voice_chat/services/realtime_socket_client_stub.dart'
    if (dart.library.io) 'package:batasph_mobile/pages/voice_chat/services/realtime_socket_client_io.dart';

RealtimeSocketClient createRealtimeSocketClient() =>
    createRealtimeSocketClientImpl();
