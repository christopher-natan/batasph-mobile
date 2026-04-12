import 'package:batasph_mobile/data/models/law_source_model.dart';

class SourcesService {
  final sources = const <LawSourceModel>[
    LawSourceModel(
      title: 'Traffic Laws',
      description: 'LTO-related statutes for drivers and road users.',
      focus: 'Phase 1 focus: RA 4136 and RA 10913',
      laws: [
        'RA 4136 — Land Transportation and Traffic Code',
        'RA 10913 — Anti-Distracted Driving Act',
        'RA 10586 — Anti-Drunk and Drugged Driving Act',
      ],
      links: [
        LawSourceLink(
          label: 'LawPhil: RA 4136',
          url: 'https://lawphil.net/statutes/repacts/ra1964/ra_4136_1964.html',
          note: 'Primary law text',
        ),
        LawSourceLink(
          label: 'LawPhil: RA 10913',
          url: 'https://lawphil.net/statutes/repacts/ra2016/ra_10913_2016.html',
          note: 'Primary law text',
        ),
        LawSourceLink(
          label: 'Official Gazette',
          url: 'https://www.officialgazette.gov.ph',
          note: 'Backup primary source',
        ),
      ],
    ),
    LawSourceModel(
      title: 'Workers\' Rights',
      description: 'Labor-law coverage for wages, leave, and termination basics.',
      focus: 'Phase 2 focus: Labor Code core sections',
      laws: [
        'PD 442 — Labor Code of the Philippines',
        'RA 10361 — Domestic Workers Act',
        'RA 11210 — Expanded Maternity Leave Law',
      ],
      links: [
        LawSourceLink(
          label: 'LawPhil: PD 442',
          url: 'https://lawphil.net/statutes/presdecs/pd1974/pd_442_1974.html',
          note: 'Primary law text',
        ),
        LawSourceLink(
          label: 'DOLE',
          url: 'https://www.dole.gov.ph',
          note: 'Reference summaries only',
        ),
      ],
    ),
    LawSourceModel(
      title: 'Constitutional Rights',
      description: '1987 Constitution with emphasis on the Bill of Rights.',
      focus: 'Phase 1 focus: Article III',
      laws: [
        '1987 Philippine Constitution',
        'Article III — Bill of Rights',
      ],
      links: [
        LawSourceLink(
          label: 'Official Gazette: 1987 Constitution',
          url: 'https://www.officialgazette.gov.ph/constitutions/1987-constitution/',
          note: 'Primary law text',
        ),
        LawSourceLink(
          label: 'LawPhil: 1987 Constitution',
          url: 'https://lawphil.net/consti/cons1987.html',
          note: 'Backup primary source',
        ),
      ],
    ),
  ];
}
