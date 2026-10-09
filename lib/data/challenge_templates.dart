import 'package:flutter/widgets.dart';
import 'package:iconsax/iconsax.dart';
import 'package:allah_everywhere/models/challenge.dart';

/// A starting point on the Create Challenge screen: the unit choices, the
/// default target and length, and whether the target is fixed by the type
/// (a Khatam is always 30 Juz / 604 pages; a surah is its ayah count).
class ChallengeTemplate {
  final ChallengeType type;
  final IconData icon;
  final List<String> units;
  final int defaultTarget;
  final int defaultDays;

  /// The target follows from the unit (Khatam) or the surah, so it can't be edited.
  final bool fixedTarget;

  /// One tick per day: the target is the number of days.
  final bool targetIsDays;

  const ChallengeTemplate({
    required this.type,
    required this.icon,
    required this.units,
    required this.defaultTarget,
    required this.defaultDays,
    this.fixedTarget = false,
    this.targetIsDays = false,
  });

  /// Target for [unit] when [fixedTarget] (Khatam): the whole Quran.
  static int khatamTarget(String unit) => unit == ChallengeUnits.pages ? 604 : 30;
}

const challengeTemplates = <ChallengeTemplate>[
  ChallengeTemplate(
    type: ChallengeType.khatam,
    icon: Iconsax.book_saved,
    units: [ChallengeUnits.juz, ChallengeUnits.pages],
    defaultTarget: 30,
    defaultDays: 30,
    fixedTarget: true,
  ),
  ChallengeTemplate(
    type: ChallengeType.readQuran,
    icon: Iconsax.book_1,
    units: [ChallengeUnits.juz, ChallengeUnits.pages],
    defaultTarget: 5,
    defaultDays: 7,
  ),
  ChallengeTemplate(
    type: ChallengeType.memorizeSurah,
    icon: Iconsax.teacher,
    units: [ChallengeUnits.ayahs],
    defaultTarget: 30,
    defaultDays: 7,
    fixedTarget: true,
  ),
  ChallengeTemplate(
    type: ChallengeType.memorizeHadith,
    icon: Iconsax.archive_book,
    units: [ChallengeUnits.ahadith],
    defaultTarget: 10,
    defaultDays: 7,
  ),
  ChallengeTemplate(
    type: ChallengeType.dhikr,
    icon: Iconsax.refresh_circle,
    units: [ChallengeUnits.count],
    defaultTarget: 1000,
    defaultDays: 7,
  ),
  ChallengeTemplate(
    type: ChallengeType.fasting,
    icon: Iconsax.moon,
    units: [ChallengeUnits.days],
    defaultTarget: 3,
    defaultDays: 30,
  ),
  ChallengeTemplate(
    type: ChallengeType.dailyPrayer,
    icon: Iconsax.sun_fog,
    units: [ChallengeUnits.days],
    defaultTarget: 7,
    defaultDays: 7,
    targetIsDays: true,
  ),
  ChallengeTemplate(
    type: ChallengeType.custom,
    icon: Iconsax.edit_2,
    units: [],
    defaultTarget: 10,
    defaultDays: 7,
  ),
];

ChallengeTemplate templateFor(ChallengeType type) => challengeTemplates.firstWhere((t) => t.type == type);
