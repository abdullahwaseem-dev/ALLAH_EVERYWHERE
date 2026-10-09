import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:allah_everywhere/challenges.dart' show challengeTypeLabel;
import 'package:allah_everywhere/controllers/theme_controller.dart';
import 'package:allah_everywhere/data/challenge_templates.dart';
import 'package:allah_everywhere/data/garden_hadith_data.dart';
import 'package:allah_everywhere/data/rewards_data.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/login.dart';
import 'package:allah_everywhere/models/challenge.dart';
import 'package:allah_everywhere/services/app_share_service.dart';
import 'package:allah_everywhere/services/hifz_service.dart';
import 'package:allah_everywhere/services/rewards_service.dart';
import 'package:allah_everywhere/services/tasbeeh_service.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/utils/utils/theme/scripture_text.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';
import 'package:allah_everywhere/widgets/reward_cosmetics.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

part 'rewards_certificate.dart';
part 'rewards_garden.dart';

/// Theme colours shared by the rewards screens.
class _P {
  final Color accent, text, sub, card, bg, line;
  final bool dark;

  _P(BuildContext context)
      : dark = Theme.of(context).brightness == Brightness.dark,
        accent = Theme.of(context).brightness == Brightness.dark ? VoidColors.goldDark : VoidColors.gold,
        text = Theme.of(context).brightness == Brightness.dark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep,
        sub = Theme.of(context).brightness == Brightness.dark ? VoidColors.textDarkSecondary : VoidColors.textSecondary,
        card = Theme.of(context).brightness == Brightness.dark ? VoidColors.cardDark : VoidColors.cardLight,
        bg = Theme.of(context).brightness == Brightness.dark ? VoidColors.bgDark : VoidColors.bgLight,
        line = (Theme.of(context).brightness == Brightness.dark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep)
            .withValues(alpha: 0.15);
}

String badgeName(String id, AppLocalizations t) => switch (id) {
      'first_challenge' => t.badgeFirstChallenge,
      'khatam_finisher' => t.badgeKhatamFinisher,
      'steadfast' => t.badgeSteadfast,
      'early_bird' => t.badgeEarlyBird,
      'encourager' => t.badgeEncourager,
      'family_builder' => t.badgeFamilyBuilder,
      'comeback' => t.badgeComeback,
      'first_surah' => t.badgeFirstSurah,
      'dhikr_1000' => t.badgeDhikr1000,
      'dhikr_10000' => t.badgeDhikr10000,
      _ => id,
    };

String badgeHowTo(String id, AppLocalizations t) => switch (id) {
      'first_challenge' => t.badgeFirstChallengeHow,
      'khatam_finisher' => t.badgeKhatamFinisherHow,
      'steadfast' => t.badgeSteadfastHow,
      'early_bird' => t.badgeEarlyBirdHow,
      'encourager' => t.badgeEncouragerHow,
      'family_builder' => t.badgeFamilyBuilderHow,
      'comeback' => t.badgeComebackHow,
      'first_surah' => t.badgeFirstSurahHow,
      'dhikr_1000' => t.badgeDhikr1000How,
      'dhikr_10000' => t.badgeDhikr10000How,
      _ => '',
    };

String cosmeticName(String id, AppLocalizations t) => switch (id) {
      'classic_gold' => t.cosmeticClassicGold,
      'madinah_green' => t.cosmeticMadinahGreen,
      'night_of_qadr' => t.cosmeticNightOfQadr,
      'desert_gold' => t.cosmeticDesertGold,
      'frame_none' => t.cosmeticFrameNone,
      'frame_arch' => t.cosmeticFrameArch,
      'frame_star' => t.cosmeticFrameStar,
      'bead_classic' => t.cosmeticBeadClassic,
      'bead_pearl' => t.cosmeticBeadPearl,
      'bead_glow' => t.cosmeticBeadGlow,
      'avatar_ring' => t.cosmeticAvatarRing,
      'avatar_crescent' => t.cosmeticAvatarCrescent,
      'avatar_star' => t.cosmeticAvatarStar,
      'avatar_garden' => t.cosmeticAvatarGarden,
      _ => id,
    };

/// "The real reward is with Allah. This is only a reminder."
class RealRewardNote extends StatelessWidget {
  const RealRewardNote({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _P(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Iconsax.heart, size: 15.sp, color: p.accent),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(t.rewardsRealReward,
              style: TextStyle(fontSize: 12.5.sp, height: 1.45, fontStyle: FontStyle.italic, color: p.sub)),
        ),
      ],
    );
  }
}

Widget _section(_P p, String title, {String? subtitle}) => Padding(
      padding: EdgeInsets.only(top: 22.h, bottom: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: p.text)),
          if (subtitle != null) ...[
            SizedBox(height: 2.h),
            Text(subtitle, style: TextStyle(fontSize: 12.sp, height: 1.4, color: p.sub)),
          ],
        ],
      ),
    );

Widget _cardBox(_P p, {required Widget child, EdgeInsetsGeometry? padding}) => Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
        side: BorderSide(color: p.accent.withValues(alpha: 0.18)),
      ),
      child: Padding(padding: padding ?? EdgeInsets.all(14.w), child: child),
    );

/// My Rewards (from Profile): badges, certificates, the Jannah Garden and
/// the looks they unlock. Guests see their device badges.
class RewardsScreen extends StatefulWidget {
  final RewardsService? service;

  const RewardsScreen({super.key, this.service});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late final RewardsService _svc = widget.service ?? RewardsService();
  late final Stream<RewardsState> _stream = _svc.watch();
  bool? _visible;

  @override
  void initState() {
    super.initState();
    _svc.checkLocal();
    if (_svc.isSignedIn) {
      _svc.badgesVisible().then((v) {
        if (mounted) setState(() => _visible = v);
      });
    }
  }

  Future<void> _setVisible(bool v) async {
    setState(() => _visible = v);
    try {
      await _svc.setBadgesVisible(v);
    } catch (e) {
      VoidLogger.error('Could not change badge visibility', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _P(context);
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.rewardsTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: p.text)),
        centerTitle: true,
      ),
      body: ReadableWidth(
        child: StreamBuilder<RewardsState>(
          stream: _stream,
          initialData: const RewardsState(),
          builder: (context, snap) {
            final state = snap.data ?? const RewardsState();
            return ListView(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
              children: [
                Text(t.rewardsSubtitle, style: TextStyle(fontSize: 13.5.sp, height: 1.45, color: p.sub)),
                SizedBox(height: 10.h),
                const RealRewardNote(),
                if (!_svc.isSignedIn) ...[
                  SizedBox(height: 14.h),
                  _guestCard(p, t),
                ] else if (_visible != null) ...[
                  SizedBox(height: 8.h),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _visible!,
                    activeThumbColor: p.accent,
                    onChanged: _setVisible,
                    title: Text(t.rewardsShowBadges,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: p.text)),
                    subtitle: Text(t.rewardsShowBadgesSub, style: TextStyle(fontSize: 12.sp, color: p.sub)),
                  ),
                ],
                _section(p, t.rewardsGarden),
                _gardenCard(context, p, t, state),
                _section(p, t.rewardsBadges),
                _badgeGrid(context, p, t, state),
                _section(p, t.rewardsCertificates),
                if (state.certificates.isEmpty)
                  Text(t.rewardsNoCertificates, style: TextStyle(fontSize: 13.sp, color: p.sub))
                else
                  for (final c in state.certificates) _certificateTile(context, p, t, c),
                _section(p, t.rewardsCosmetics, subtitle: t.rewardsCosmeticsSub),
                for (final kind in CosmeticKind.values) _cosmeticGroup(context, p, t, state, kind),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _guestCard(_P p, AppLocalizations t) => _cardBox(
        p,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.rewardsGuestNote, style: TextStyle(fontSize: 13.sp, height: 1.45, color: p.text)),
            SizedBox(height: 8.h),
            TextButton.icon(
              onPressed: () => Get.to(() => const Login()),
              icon: Icon(Iconsax.login, size: 17.sp, color: p.accent),
              label: Text(t.challengesSignIn, style: TextStyle(fontSize: 13.sp, color: p.accent)),
            ),
          ],
        ),
      );

  Widget _gardenCard(BuildContext context, _P p, AppLocalizations t, RewardsState state) {
    final count = state.plants.length + state.palms;
    return Semantics(
      button: true,
      label: '${t.rewardsGarden}, ${t.rewardsPlants(count)}',
      excludeSemantics: true,
      child: Material(
        color: p.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        child: InkWell(
          onTap: () => Get.to(() => JannahGardenScreen(service: _svc)),
          child: Column(
            children: [
              SizedBox(
                height: 120.h,
                width: double.infinity,
                child: CustomPaint(painter: GardenPainter(state: state, dark: p.dark, compact: true)),
              ),
              Padding(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(t.rewardsPlants(count),
                          style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: p.text)),
                    ),
                    Icon(Icons.chevron_right, color: p.sub),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badgeGrid(BuildContext context, _P p, AppLocalizations t, RewardsState state) {
    final lang = Localizations.localeOf(context).languageCode;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 500 ? 4 : 3;
        final width = (constraints.maxWidth - (columns - 1) * 10.w) / columns;
        return Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: [
            for (final b in badges)
              SizedBox(
                width: width,
                child: _BadgeTile(
                  badge: b,
                  earnedAt: state.badges[b.id],
                  onTap: () => _showBadge(context, p, t, b, state.badges[b.id], lang),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showBadge(BuildContext context, _P p, AppLocalizations t, BadgeDef b, DateTime? earned, String lang) {
    final unlocks = cosmetics.where((c) => c.unlockedBy == b.id).map((c) => cosmeticName(c.id, t)).join(', ');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22.r))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(22.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BadgeMedal(badge: b, earned: earned != null, size: 72.w),
              SizedBox(height: 12.h),
              Text(badgeName(b.id, t),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: p.text)),
              SizedBox(height: 6.h),
              Text(badgeHowTo(b.id, t),
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5.sp, height: 1.45, color: p.sub)),
              SizedBox(height: 8.h),
              Text(earned != null ? t.rewardsEarnedOn(DateFormat.yMMMd(lang).format(earned)) : t.rewardsLocked,
                  style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: p.accent)),
              if (unlocks.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Text(t.rewardsUnlocks(unlocks),
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, color: p.sub)),
              ],
              SizedBox(height: 14.h),
              const RealRewardNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _certificateTile(BuildContext context, _P p, AppLocalizations t, ChallengeCertificate c) {
    final lang = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        child: ListTile(
          onTap: () => Get.to(() => CertificateScreen(certificate: c)),
          leading: CircleAvatar(
            backgroundColor: p.accent.withValues(alpha: 0.15),
            child: Icon(Iconsax.medal_star, color: p.accent, size: 20.sp),
          ),
          title: Text(c.title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: p.text)),
          subtitle: Text('${certificateResultLabel(c.result, t)} · ${DateFormat.yMMMd(lang).format(c.completedAt)}',
              style: TextStyle(fontSize: 12.sp, color: p.sub)),
          trailing: Icon(Icons.chevron_right, color: p.sub),
        ),
      ),
    );
  }

  Widget _cosmeticGroup(BuildContext context, _P p, AppLocalizations t, RewardsState state, CosmeticKind kind) {
    final selected = RewardsService.selected(kind);
    final title = switch (kind) {
      CosmeticKind.accent => t.rewardsAccent,
      CosmeticKind.mushafFrame => t.rewardsMushafFrame,
      CosmeticKind.bead => t.rewardsBeads,
      CosmeticKind.avatarFrame => t.rewardsAvatarFrame,
    };
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: p.sub)),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final c in cosmetics.where((c) => c.kind == kind))
                _cosmeticChip(context, p, t, c, unlocked: state.unlocked(c), selected: c.id == selected),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cosmeticChip(BuildContext context, _P p, AppLocalizations t, CosmeticDef c,
      {required bool unlocked, required bool selected}) {
    final swatch = accentColors[c.id];
    return ChoiceChip(
      avatar: !unlocked
          ? Icon(Iconsax.lock_1, size: 15.sp, color: p.sub)
          : swatch != null
              ? CircleAvatar(radius: 8.r, backgroundColor: p.dark ? swatch.$2 : swatch.$1)
              : null,
      label: Text(cosmeticName(c.id, t)),
      selected: selected,
      showCheckmark: selected,
      checkmarkColor: p.bg,
      selectedColor: p.accent,
      backgroundColor: p.card,
      side: BorderSide(color: unlocked ? p.accent.withValues(alpha: 0.4) : p.line),
      labelStyle: TextStyle(
        fontSize: 12.5.sp,
        fontWeight: FontWeight.w600,
        color: selected ? p.bg : (unlocked ? p.text : p.sub),
      ),
      onSelected: (_) async {
        if (!unlocked) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(t.rewardsUnlockWith(badgeName(c.unlockedBy!, t)))));
          return;
        }
        HapticFeedback.selectionClick();
        await RewardsService.select(c);
        if (c.kind == CosmeticKind.accent && Get.isRegistered<ThemeController>()) {
          await Get.find<ThemeController>().setAccent(c.id);
        }
        if (mounted) setState(() {});
      },
    );
  }
}

/// A round badge: the icon on the accent colour when earned, a grey
/// outline when not.
class BadgeMedal extends StatelessWidget {
  final BadgeDef badge;
  final bool earned;
  final double size;

  const BadgeMedal({super.key, required this.badge, required this.earned, required this.size});

  @override
  Widget build(BuildContext context) {
    final p = _P(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: earned
            ? LinearGradient(
                colors: [p.accent, Color.alphaBlend(p.accent.withValues(alpha: 0.6), p.card)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: earned ? null : Border.all(color: p.sub.withValues(alpha: 0.5), width: 1.5),
        boxShadow: earned ? [BoxShadow(color: p.accent.withValues(alpha: 0.3), blurRadius: 10)] : null,
      ),
      child: Icon(badge.icon, size: size * 0.45, color: earned ? p.bg : p.sub.withValues(alpha: 0.6)),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeDef badge;
  final DateTime? earnedAt;
  final VoidCallback onTap;

  const _BadgeTile({required this.badge, required this.earnedAt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _P(context);
    final lang = Localizations.localeOf(context).languageCode;
    final earned = earnedAt != null;
    return Semantics(
      button: true,
      label: '${badgeName(badge.id, t)}, ${earned ? t.rewardsEarnedOn(DateFormat.yMMMd(lang).format(earnedAt!)) : t.rewardsLocked}',
      excludeSemantics: true,
      child: Material(
        color: p.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: BorderSide(color: earned ? p.accent.withValues(alpha: 0.3) : p.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
            child: Column(
              children: [
                BadgeMedal(badge: badge, earned: earned, size: 46.w),
                SizedBox(height: 8.h),
                Text(badgeName(badge.id, t),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: earned ? p.text : p.sub)),
                SizedBox(height: 2.h),
                Text(earned ? DateFormat.yMMMd(lang).format(earnedAt!) : badgeHowTo(badge.id, t),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5.sp, height: 1.3, color: p.sub)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The new-badge moment: a short, calm reveal with a haptic, not a casino
/// effect.
Future<void> showBadgeUnlocked(BuildContext context, String badgeId) async {
  final badge = badgeById(badgeId);
  if (badge == null) return;
  HapticFeedback.mediumImpact();
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration:
        MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 450),
    pageBuilder: (dialogContext, _, __) => _BadgeUnlockDialog(badge: badge),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack), child: child),
    ),
  );
}

class _BadgeUnlockDialog extends StatelessWidget {
  final BadgeDef badge;

  const _BadgeUnlockDialog({required this.badge});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _P(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.w),
        child: Material(
          color: p.card,
          borderRadius: BorderRadius.circular(24.r),
          child: Padding(
            padding: EdgeInsets.all(22.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.rewardsNewBadge.toUpperCase(),
                    style: TextStyle(fontSize: 11.sp, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: p.accent)),
                SizedBox(height: 14.h),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 1200),
                  curve: Curves.easeOut,
                  builder: (context, v, child) => Container(
                    padding: EdgeInsets.all(14.w * v),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.accent.withValues(alpha: 0.12 * v),
                    ),
                    child: child,
                  ),
                  child: BadgeMedal(badge: badge, earned: true, size: 76.w),
                ),
                SizedBox(height: 14.h),
                Text(badgeName(badge.id, t),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.w800, color: p.text)),
                SizedBox(height: 6.h),
                Text(badgeHowTo(badge.id, t),
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5.sp, height: 1.45, color: p.sub)),
                SizedBox(height: 14.h),
                const RealRewardNote(),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(t.rewardsClose, style: TextStyle(fontSize: 13.sp, color: p.sub)),
                      ),
                    ),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Get.to(() => const RewardsScreen());
                        },
                        style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: p.bg),
                        child: Text(t.rewardsView, style: TextStyle(fontSize: 13.sp)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Runs for the whole session (started from the main tab bar): awards
/// device badges when Tasbeeh or Hifz progress changes, copies them to the
/// account on sign-in, and shows each new badge once.
class RewardsWatcher {
  RewardsWatcher._();

  static bool _started = false;
  static StreamSubscription<RewardsState>? _sub;
  static final _queue = <String>[];
  static bool _showing = false;

  static void start() {
    if (_started) return;
    _started = true;
    final svc = RewardsService();
    void check() => svc.checkLocal();
    TasbeehService.changes.addListener(check);
    HifzService.changes.addListener(check);
    check();
    _listen(svc);
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseAuth.instance.authStateChanges().skip(1).listen((_) async {
          final fresh = RewardsService();
          await fresh.syncLocal();
          _listen(fresh);
        });
        unawaited(svc.syncLocal());
      }
    } catch (e) {
      VoidLogger.error('Rewards watcher could not follow sign-in', e);
    }
  }

  static void _listen(RewardsService svc) {
    _sub?.cancel();
    _sub = svc.watch().listen((state) async {
      final fresh = await RewardsService.takeUnseen(state);
      _queue.addAll(fresh);
      _drain();
    });
  }

  static Future<void> _drain() async {
    if (_showing) return;
    _showing = true;
    while (_queue.isNotEmpty) {
      final context = Get.overlayContext;
      if (context == null || !context.mounted) break;
      await showBadgeUnlocked(context, _queue.removeAt(0));
    }
    _showing = false;
  }
}
