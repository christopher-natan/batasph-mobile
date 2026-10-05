/// The persona opener from `GET /chat/greeting`: who is speaking and what
/// they say, already resolved to one language by the backend.
class ChatGreetingModel {
  final String personaName;
  final String personaRole;
  final String language;
  final String text;

  const ChatGreetingModel({
    required this.personaName,
    required this.personaRole,
    required this.language,
    required this.text,
  });

  factory ChatGreetingModel.fromJson(Map<String, dynamic> json) {
    final persona = json['persona'] as Map<String, dynamic>? ?? const {};
    return ChatGreetingModel(
      personaName: persona['name'] as String? ?? '',
      personaRole: persona['role'] as String? ?? '',
      language: json['language'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}
