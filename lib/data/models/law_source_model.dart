class LawSourceLink {
  final String label;
  final String url;
  final String note;

  const LawSourceLink({
    required this.label,
    required this.url,
    required this.note,
  });
}

class LawSourceModel {
  final String title;
  final String description;
  final String focus;
  final List<String> laws;
  final List<LawSourceLink> links;

  const LawSourceModel({
    required this.title,
    required this.description,
    required this.focus,
    required this.laws,
    required this.links,
  });
}
