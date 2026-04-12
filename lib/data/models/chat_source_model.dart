class ChatSourceModel {
  final String lawId;
  final String title;
  final String citation;
  final String sourceName;
  final String sourceUrl;
  final double? score;
  final List<String> subjects;

  const ChatSourceModel({
    required this.lawId,
    required this.title,
    required this.citation,
    required this.sourceName,
    required this.sourceUrl,
    this.score,
    this.subjects = const [],
  });

  String get label => citation.isNotEmpty ? citation : title;

  factory ChatSourceModel.fromJson(Map<String, dynamic> json) {
    return ChatSourceModel(
      lawId: json['lawId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      citation: json['citation'] as String? ?? '',
      sourceName: json['sourceName'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble(),
      subjects: json['subjects'] != null
          ? List<String>.from(json['subjects'] as List)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'lawId': lawId,
    'title': title,
    'citation': citation,
    'sourceName': sourceName,
    'sourceUrl': sourceUrl,
    if (score != null) 'score': score,
    if (subjects.isNotEmpty) 'subjects': subjects,
  };
}
