/// Repeat-practice settings for a Hifz session, and the exact sequence of
/// recitations and pauses they produce. Pure Dart so it can be unit-tested.
///
/// The whole session is queued in the audio player up front (pauses are
/// clipped silence), so it keeps playing with the screen locked: nothing has
/// to run in Dart between repeats while the app is in the background.
class HifzSettings {
  static const int maxRangeLength = 20;
  static const int minRepeat = 1, maxRepeat = 20;
  static const int minRounds = 1, maxRounds = 10;
  static const int minGapSeconds = 0, maxGapSeconds = 10;
  static const double minSpeed = 0.75, maxSpeed = 1.25;

  /// Times each ayah is recited before moving to the next.
  final int repeatEachAyah;

  /// Times the whole range is played through.
  final int rounds;

  /// Silence after each recitation.
  final int gapSeconds;

  final double speed;

  const HifzSettings({
    this.repeatEachAyah = 3,
    this.rounds = 1,
    this.gapSeconds = 2,
    this.speed = 1.0,
  });

  HifzSettings copyWith({int? repeatEachAyah, int? rounds, int? gapSeconds, double? speed}) => HifzSettings(
        repeatEachAyah: repeatEachAyah ?? this.repeatEachAyah,
        rounds: rounds ?? this.rounds,
        gapSeconds: gapSeconds ?? this.gapSeconds,
        speed: speed ?? this.speed,
      );

  /// Brings every value into its allowed range (stored values may be stale).
  HifzSettings clamped() => HifzSettings(
        repeatEachAyah: repeatEachAyah.clamp(minRepeat, maxRepeat),
        rounds: rounds.clamp(minRounds, maxRounds),
        gapSeconds: gapSeconds.clamp(minGapSeconds, maxGapSeconds),
        speed: speed.isFinite ? speed.clamp(minSpeed, maxSpeed) : 1.0,
      );

  Map<String, dynamic> toMap() =>
      {'repeatEachAyah': repeatEachAyah, 'rounds': rounds, 'gapSeconds': gapSeconds, 'speed': speed};

  factory HifzSettings.fromMap(Object? raw) {
    if (raw is! Map) return const HifzSettings();
    int i(String k, int d) => raw[k] is num ? (raw[k] as num).toInt() : d;
    return HifzSettings(
      repeatEachAyah: i('repeatEachAyah', 3),
      rounds: i('rounds', 1),
      gapSeconds: i('gapSeconds', 2),
      speed: raw['speed'] is num ? (raw['speed'] as num).toDouble() : 1.0,
    ).clamped();
  }
}

/// One item of the session queue: a recitation of [ayah], or a pause.
class HifzStep {
  /// Ayah number in the surah; null for a pause.
  final int? ayah;

  /// 1-based repetition of this ayah within the round.
  final int repeat;

  /// 1-based pass through the whole range.
  final int round;

  /// The ayah this pause follows (for a pause), so the UI keeps it lit.
  final int? afterAyah;

  const HifzStep.recite({required int this.ayah, required this.repeat, required this.round}) : afterAyah = null;

  const HifzStep.pause({required int this.afterAyah, required this.repeat, required this.round}) : ayah = null;

  bool get isPause => ayah == null;

  /// The ayah to highlight while this step plays.
  int get highlightedAyah => ayah ?? afterAyah!;
}

/// Every step of a session over ayahs [from]..[to] (inclusive): each ayah
/// recited [HifzSettings.repeatEachAyah] times, the range played
/// [HifzSettings.rounds] times, with a pause after every recitation except
/// the last one of the session.
List<HifzStep> buildHifzPlan({required int from, required int to, required HifzSettings settings}) {
  assert(from >= 1 && to >= from);
  final s = settings.clamped();
  final steps = <HifzStep>[];
  for (int round = 1; round <= s.rounds; round++) {
    for (int ayah = from; ayah <= to; ayah++) {
      for (int r = 1; r <= s.repeatEachAyah; r++) {
        steps.add(HifzStep.recite(ayah: ayah, repeat: r, round: round));
        final last = round == s.rounds && ayah == to && r == s.repeatEachAyah;
        if (s.gapSeconds > 0 && !last) {
          steps.add(HifzStep.pause(afterAyah: ayah, repeat: r, round: round));
        }
      }
    }
  }
  return steps;
}

/// How long the silence clip for a pause must be so the *heard* pause is
/// [gapSeconds] at playback [speed] (the player speeds up silence too).
Duration pauseClipLength(int gapSeconds, double speed) =>
    Duration(milliseconds: (gapSeconds * 1000 * speed).round());
