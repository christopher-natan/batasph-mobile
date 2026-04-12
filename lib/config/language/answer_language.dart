enum AnswerLanguage {
  auto,
  english,
  tagalog,
}

AnswerLanguage answerLanguageFromStorage(String? value) {
  return AnswerLanguage.values.firstWhere(
    (language) => language.name == value,
    orElse: () => AnswerLanguage.auto,
  );
}

extension AnswerLanguageX on AnswerLanguage {
  String get label {
    switch (this) {
      case AnswerLanguage.auto:
        return 'Auto';
      case AnswerLanguage.english:
        return 'English';
      case AnswerLanguage.tagalog:
        return 'Tagalog';
    }
  }

  String get description {
    switch (this) {
      case AnswerLanguage.auto:
        return 'Match the user question when possible';
      case AnswerLanguage.english:
        return 'Always reply in English';
      case AnswerLanguage.tagalog:
        return 'Always reply in Tagalog';
    }
  }

  String get legalBasisLabel {
    switch (this) {
      case AnswerLanguage.tagalog:
        return 'Batayan sa Batas';
      case AnswerLanguage.auto:
      case AnswerLanguage.english:
        return 'Legal Basis';
    }
  }
}
