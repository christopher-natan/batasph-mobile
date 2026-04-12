import 'package:batasph_mobile/data/models/chat_source_model.dart';

class ChatMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String mode;
  final List<ChatSourceModel> sources;
  final List<String> legalBasis;
  final String status;
  final String requestedLanguage;
  final String responseLanguage;
  final List<String> requestedSubjects;
  final List<String> inferredSubjects;
  final List<String> appliedSubjects;
  final List<String> matchedSubjects;
  final bool fallbackUsed;
  final String disclaimer;

  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.mode = 'text',
    this.sources = const [],
    this.legalBasis = const [],
    this.status = '',
    this.requestedLanguage = '',
    this.responseLanguage = '',
    this.requestedSubjects = const [],
    this.inferredSubjects = const [],
    this.appliedSubjects = const [],
    this.matchedSubjects = const [],
    this.fallbackUsed = false,
    this.disclaimer = '',
  });

  bool get hasSources => sources.any((source) => source.sourceUrl.isNotEmpty);

  bool get hasLegalBasis => legalBasis.isNotEmpty;

  ChatMessageModel copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? mode,
    List<ChatSourceModel>? sources,
    List<String>? legalBasis,
    String? status,
    String? requestedLanguage,
    String? responseLanguage,
    List<String>? requestedSubjects,
    List<String>? inferredSubjects,
    List<String>? appliedSubjects,
    List<String>? matchedSubjects,
    bool? fallbackUsed,
    String? disclaimer,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      mode: mode ?? this.mode,
      sources: sources ?? this.sources,
      legalBasis: legalBasis ?? this.legalBasis,
      status: status ?? this.status,
      requestedLanguage: requestedLanguage ?? this.requestedLanguage,
      responseLanguage: responseLanguage ?? this.responseLanguage,
      requestedSubjects: requestedSubjects ?? this.requestedSubjects,
      inferredSubjects: inferredSubjects ?? this.inferredSubjects,
      appliedSubjects: appliedSubjects ?? this.appliedSubjects,
      matchedSubjects: matchedSubjects ?? this.matchedSubjects,
      fallbackUsed: fallbackUsed ?? this.fallbackUsed,
      disclaimer: disclaimer ?? this.disclaimer,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      mode: json['mode'] as String? ?? 'text',
      sources: json['sources'] != null
          ? (json['sources'] as List)
                .map(
                  (item) =>
                      ChatSourceModel.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : const [],
      legalBasis: json['legalBasis'] != null
          ? List<String>.from(json['legalBasis'] as List)
          : const [],
      status: json['status'] as String? ?? '',
      requestedLanguage: json['requestedLanguage'] as String? ?? '',
      responseLanguage: json['responseLanguage'] as String? ?? '',
      requestedSubjects: json['requestedSubjects'] != null
          ? List<String>.from(json['requestedSubjects'] as List)
          : const [],
      inferredSubjects: json['inferredSubjects'] != null
          ? List<String>.from(json['inferredSubjects'] as List)
          : const [],
      appliedSubjects: json['appliedSubjects'] != null
          ? List<String>.from(json['appliedSubjects'] as List)
          : const [],
      matchedSubjects: json['matchedSubjects'] != null
          ? List<String>.from(json['matchedSubjects'] as List)
          : const [],
      fallbackUsed: json['fallbackUsed'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'mode': mode,
    'sources': sources.map((source) => source.toJson()).toList(),
    'legalBasis': legalBasis,
    'status': status,
    'requestedLanguage': requestedLanguage,
    'responseLanguage': responseLanguage,
    'requestedSubjects': requestedSubjects,
    'inferredSubjects': inferredSubjects,
    'appliedSubjects': appliedSubjects,
    'matchedSubjects': matchedSubjects,
    'fallbackUsed': fallbackUsed,
    'disclaimer': disclaimer,
  };
}
