import 'package:batasph_mobile/data/remote/api_client.dart';

/// The two API calls behind a call: minting the Realtime session and
/// running the law lookup the model asks for.
class VoiceCallApiService {
  /// A short-lived OpenAI client secret for one call. [savedName] lets Luna
  /// greet a returning caller by name.
  Future<String> createSession({String? savedName}) async {
    final response = await ApiClient().client.post(
      '/voice-call/session',
      data: {'savedName': ?savedName},
    );
    final secret = (response.data as Map<String, dynamic>)['clientSecret'];
    if (secret is! String || secret.isEmpty) {
      throw StateError('Voice call session has no client secret');
    }
    return secret;
  }

  /// The grounded answer for the model's `lookup_philippine_law` call:
  /// `{status, answer, legalBasis, sources, referral, ...}`, passed back to
  /// the model as the tool output.
  Future<Map<String, dynamic>> lookup(String question) async {
    final response = await ApiClient().client.post(
      '/voice-call/lookup',
      data: {'question': question},
    );
    return response.data as Map<String, dynamic>;
  }
}
