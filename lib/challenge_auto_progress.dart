import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/challenges.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/models/challenge.dart';
import 'package:allah_everywhere/services/challenge_service.dart';
import 'package:allah_everywhere/services/mushaf_service.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// A reading or memorisation that could count toward a challenge.
class ChallengeOffer {
  final Challenge challenge;
  final List<int> items;

  const ChallengeOffer(this.challenge, this.items);
}

/// "Add this to your challenge?": notes what the user reads in the Mushaf
/// and memorises in Hifz mode, and when they leave that screen offers to
/// add it to a matching active challenge. Nothing is added without a yes.
class ChallengeAutoProgress {
  ChallengeAutoProgress._();

  static const _offKey = 'challenge_auto_suggest_off';

  /// A Mushaf page counts as read after this long on it (not when flicking
  /// past it).
  static const minDwell = Duration(seconds: 15);

  static final Set<int> _pages = {};
  static final Map<int, Set<int>> _ayahs = {};
  static int? _page;
  static DateTime? _pageSince;

  /// Suggestions are on per challenge unless the user turned them off.
  static bool isEnabled(String challengeId) {
    try {
      final raw = VoidStorage().readData<Object>(_offKey);
      return !(raw is List && raw.contains(challengeId));
    } catch (_) {
      return true;
    }
  }

  static Future<void> setEnabled(String challengeId, bool enabled) async {
    final raw = VoidStorage().readData<Object>(_offKey);
    final off = raw is List ? raw.whereType<String>().toSet() : <String>{};
    enabled ? off.remove(challengeId) : off.add(challengeId);
    await VoidStorage().saveData(_offKey, off.toList());
  }

  /// The Mushaf now shows [page].
  static void notePage(int page, {DateTime? now}) {
    final at = now ?? DateTime.now();
    _closePage(at);
    _page = page;
    _pageSince = at;
  }

  static void _closePage(DateTime now) {
    final page = _page, since = _pageSince;
    if (page != null && since != null && now.difference(since) >= minDwell) _pages.add(page);
    _page = null;
    _pageSince = null;
  }

  /// An ayah was marked "remembered" in Hifz mode.
  static void noteAyahMemorized(int surah, int ayah) => (_ayahs[surah] ??= <int>{}).add(ayah);

  @visibleForTesting
  static Set<int> get pendingPages => _pages;

  @visibleForTesting
  static void reset() {
    _pages.clear();
    _ayahs.clear();
    _page = null;
    _pageSince = null;
  }

  /// Juz whose last page is in [pages].
  static List<int> finishedJuz(Set<int> pages) => [
        for (var juz = 1; juz <= 30; juz++)
          if (pages.contains(juz == 30 ? MushafService.pageCount : MushafService.pageForJuz(juz + 1) - 1)) juz,
      ];

  /// Called when the Mushaf or Hifz screen closes. Does nothing for guests,
  /// offline with nothing cached, or when no active challenge matches.
  static Future<void> flush({ChallengeService? service, BuildContext? context, DateTime? now}) async {
    _closePage(now ?? DateTime.now());
    if (_pages.isEmpty && _ayahs.isEmpty) return;
    final pages = {..._pages};
    final ayahs = {for (final e in _ayahs.entries) e.key: {...e.value}};
    _pages.clear();
    _ayahs.clear();
    try {
      if (service == null && Firebase.apps.isEmpty) return;
      final svc = service ?? ChallengeService();
      if (!svc.isSignedIn) return;
      final offer = await findOffer(svc, pages: pages, ayahs: ayahs);
      if (offer == null) return;
      final ctx = context ?? Get.overlayContext;
      if (ctx == null || !ctx.mounted) return;
      await _ask(ctx, svc, offer);
    } catch (e) {
      VoidLogger.error('Challenge suggestion failed', e);
    }
  }

  /// The first active challenge (soonest deadline) that [pages] or [ayahs]
  /// add something new to.
  static Future<ChallengeOffer?> findOffer(ChallengeService svc,
      {Set<int> pages = const {}, Map<int, Set<int>> ayahs = const {}}) async {
    for (final c in await svc.activeChallenges()) {
      if (!isEnabled(c.id)) continue;
      final candidates = switch (c.itemKind) {
        ChallengeItemKind.pages => pages.toList(),
        ChallengeItemKind.juz => finishedJuz(pages),
        ChallengeItemKind.ayahs => (ayahs[c.surah] ?? const <int>{}).toList(),
        ChallengeItemKind.none => const <int>[],
      };
      if (candidates.isEmpty) continue;
      final mine = await svc.myProgress(c);
      final me = mine.participant;
      if (me == null || me.completedAt != null || mine.progress >= c.target) continue;
      final items = candidates.where((i) => !mine.items.contains(i)).toList()..sort();
      if (items.isNotEmpty) return ChallengeOffer(c, items);
    }
    return null;
  }

  static Future<void> _ask(BuildContext context, ChallengeService svc, ChallengeOffer offer) async {
    final t = AppLocalizations.of(context)!;
    final c = offer.challenge;
    final items = compactRanges(offer.items);
    final message = switch (c.itemKind) {
      ChallengeItemKind.juz => t.challengesAutoJuz(items, c.title),
      ChallengeItemKind.ayahs => t.challengesAutoAyahs(items, c.title),
      _ => t.challengesAutoPages(items, c.title),
    };
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.challengesAutoTitle),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.challengesNotNow)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(t.challengesAddMore)),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    final result = await svc.logProgress(c, items: offer.items);
    if (!context.mounted || result.added <= 0) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(t.challengesAdded)));
    if (result.completedNow) {
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ChallengeCelebrationScreen(challenge: c, service: svc),
      ));
    }
  }
}
