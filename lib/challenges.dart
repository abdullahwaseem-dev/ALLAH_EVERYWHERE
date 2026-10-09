import 'dart:async';
import 'dart:math' as math;
import 'dart:math' show max, min;
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:quran/quran.dart' as quran;
import 'package:share_plus/share_plus.dart';
import 'package:allah_everywhere/challenge_auto_progress.dart';
import 'package:allah_everywhere/data/challenge_templates.dart';
import 'package:allah_everywhere/data/rewards_data.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/login.dart';
import 'package:allah_everywhere/models/challenge.dart';
import 'package:allah_everywhere/rewards.dart';
import 'package:allah_everywhere/services/app_share_service.dart';
import 'package:allah_everywhere/services/challenge_service.dart';
import 'package:allah_everywhere/services/local_notifications_service.dart';
import 'package:allah_everywhere/share_cards/share_backgrounds.dart';
import 'package:allah_everywhere/share_cards/share_strings.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';
import 'package:allah_everywhere/widgets/pressable_tile.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

part 'challenge_celebration.dart';
part 'challenge_detail.dart';
part 'challenge_dua_wall.dart';

/// Theme colours shared by the Challenges screens.
class _Palette {
  final Color accent, text, sub, card, bg, line;

  _Palette(BuildContext context)
      : accent = _dark(context) ? VoidColors.goldDark : VoidColors.gold,
        text = _dark(context) ? VoidColors.textDarkPrimary : VoidColors.oliveDeep,
        sub = _dark(context) ? VoidColors.textDarkSecondary : VoidColors.textSecondary,
        card = _dark(context) ? VoidColors.cardDark : VoidColors.cardLight,
        bg = _dark(context) ? VoidColors.bgDark : VoidColors.bgLight,
        line = (_dark(context) ? VoidColors.textDarkPrimary : VoidColors.oliveDeep).withValues(alpha: 0.15);

  static bool _dark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
}

String challengeTypeLabel(ChallengeType type, AppLocalizations t) => switch (type) {
      ChallengeType.khatam => t.challengesTypeKhatam,
      ChallengeType.readQuran => t.challengesTypeReadQuran,
      ChallengeType.memorizeSurah => t.challengesTypeMemorizeSurah,
      ChallengeType.memorizeHadith => t.challengesTypeMemorizeHadith,
      ChallengeType.dhikr => t.challengesTypeDhikr,
      ChallengeType.fasting => t.challengesTypeFasting,
      ChallengeType.dailyPrayer => t.challengesTypeDailyPrayer,
      ChallengeType.custom => t.challengesTypeCustom,
    };

/// A unit's label; units typed by the creator are shown as they are.
String challengeUnitLabel(String unit, AppLocalizations t) => switch (unit) {
      ChallengeUnits.juz => t.challengesUnitJuz,
      ChallengeUnits.pages => t.challengesUnitPages,
      ChallengeUnits.ayahs => t.challengesUnitAyahs,
      ChallengeUnits.ahadith => t.challengesUnitAhadith,
      ChallengeUnits.count => t.challengesUnitCount,
      ChallengeUnits.days => t.challengesUnitDays,
      _ => unit,
    };

/// "3 days left", "Starts in 2 days" or "Ended".
String challengeTimeLabel(DateTime startAt, DateTime endAt, DateTime now, AppLocalizations t) {
  if (now.isBefore(startAt)) return t.challengesStartsIn(daysUntil(startAt, now));
  if (!now.isBefore(endAt)) return t.challengesEnded;
  return t.challengesDaysLeft(daysUntil(endAt, now));
}

String _surahName(int surah, String languageCode) =>
    languageCode == 'ar' || languageCode == 'ur' ? quran.getSurahNameArabic(surah) : quran.getSurahName(surah);

String _joinErrorText(ChallengeJoinError e, AppLocalizations t) => switch (e) {
      ChallengeJoinError.notFound => t.challengesErrorNotFound,
      ChallengeJoinError.full => t.challengesErrorFull,
      ChallengeJoinError.ended => t.challengesErrorEnded,
      ChallengeJoinError.alreadyMember => t.challengesErrorAlreadyMember,
      ChallengeJoinError.network => t.challengesErrorNetwork,
    };

InputDecoration _fieldDecoration(_Palette p, String label, {String? hint, String? suffix}) => InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      isDense: true,
      labelStyle: TextStyle(fontSize: 13.sp, color: p.sub),
      floatingLabelStyle: TextStyle(color: p.accent),
      hintStyle: TextStyle(fontSize: 13.sp, color: p.sub.withValues(alpha: 0.7)),
      suffixStyle: TextStyle(fontSize: 12.sp, color: p.sub),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: p.line)),
      focusedBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: p.accent)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
    );

/// A rounded card. A Material (not a coloured Container) so switches and
/// list tiles inside draw their ink on it.
Widget _card(_Palette p, {required Widget child, EdgeInsetsGeometry? padding}) => SizedBox(
      width: double.infinity,
      child: Material(
        color: p.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
          side: BorderSide(color: p.accent.withValues(alpha: 0.18)),
        ),
        child: Padding(padding: padding ?? EdgeInsets.all(16.w), child: child),
      ),
    );

Widget _primaryButton(_Palette p, String label, VoidCallback? onPressed, {IconData? icon, bool busy = false}) =>
    SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: busy ? null : onPressed,
        icon: busy
            ? SizedBox(width: 18.w, height: 18.w, child: CircularProgressIndicator(strokeWidth: 2, color: p.bg))
            : Icon(icon ?? Iconsax.tick_circle, size: 18.sp),
        label: Text(label, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.bg,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        ),
      ),
    );

/// Challenges hub: sign-in prompt for guests; for signed-in users, Create
/// and Join plus their challenges (active, upcoming, finished).
class ChallengesScreen extends StatelessWidget {
  final ChallengeService? service;

  const ChallengesScreen({super.key, this.service});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final svc = service ?? ChallengeService();
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.challengesTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: p.text)),
        centerTitle: true,
      ),
      body: ReadableWidth(
        child: svc.isSignedIn ? _SignedInHub(service: svc) : const _GuestPrompt(),
      ),
    );
  }
}

class _GuestPrompt extends StatelessWidget {
  const _GuestPrompt();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _card(
          p,
          padding: EdgeInsets.all(22.w),
          child: Column(
            children: [
              CircleAvatar(
                radius: 32.r,
                backgroundColor: p.accent.withValues(alpha: 0.15),
                child: Icon(Iconsax.people, color: p.accent, size: 30.sp),
              ),
              SizedBox(height: 14.h),
              Text(t.challengesGuestTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700, color: p.text)),
              SizedBox(height: 8.h),
              Text(t.challengesGuestBody,
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp, height: 1.5, color: p.sub)),
              SizedBox(height: 18.h),
              _primaryButton(p, t.challengesSignIn, () => Get.to(() => const Login()), icon: Iconsax.login),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignedInHub extends StatelessWidget {
  final ChallengeService service;

  const _SignedInHub({required this.service});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    return StreamBuilder<List<Challenge>>(
      stream: service.myChallenges(),
      builder: (context, snapshot) {
        final list = snapshot.data;
        final now = DateTime.now();
        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
          children: [
            Text(t.challengesSubtitle, style: TextStyle(fontSize: 14.sp, height: 1.4, color: p.sub)),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: _actionTile(p, Iconsax.add_circle, t.challengesCreate,
                      () => Get.to(() => CreateChallengeScreen(service: service))),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _actionTile(
                      p, Iconsax.ticket, t.challengesJoin, () => Get.to(() => JoinChallengeScreen(service: service))),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            if (list == null && !snapshot.hasError)
              Padding(
                padding: EdgeInsets.only(top: 30.h),
                child: Center(child: CircularProgressIndicator(color: p.accent)),
              )
            else if (snapshot.hasError)
              Text(t.challengesErrorNetwork, style: TextStyle(fontSize: 13.sp, color: p.sub))
            else if (list!.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 24.h),
                child: Text(t.challengesEmpty,
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, height: 1.5, color: p.sub)),
              )
            else
              ..._grouped(context, p, t, list, now),
          ],
        );
      },
    );
  }

  Widget _actionTile(_Palette p, IconData icon, String label, VoidCallback onTap) => PressableTile(
        onTap: onTap,
        semanticLabel: label,
        color: p.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 10.w),
          child: Column(
            children: [
              Icon(icon, color: p.accent, size: 26.sp),
              SizedBox(height: 8.h),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: p.text)),
            ],
          ),
        ),
      );

  List<Widget> _grouped(BuildContext context, _Palette p, AppLocalizations t, List<Challenge> list, DateTime now) {
    final out = <Widget>[];
    ChallengeStatus? current;
    for (final c in list) {
      final status = c.statusAt(now);
      if (status != current) {
        current = status;
        out.add(Padding(
          padding: EdgeInsets.only(top: out.isEmpty ? 0 : 10.h, bottom: 8.h),
          child: Text(
            switch (status) {
              ChallengeStatus.active => t.challengesActive,
              ChallengeStatus.upcoming => t.challengesUpcoming,
              ChallengeStatus.finished => t.challengesFinished,
            },
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: p.accent),
          ),
        ));
      }
      out.add(Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: _ChallengeCard(challenge: c, service: service),
      ));
    }
    return out;
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final ChallengeService service;

  const _ChallengeCard({required this.challenge, required this.service});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final c = challenge;
    final time = challengeTimeLabel(c.startAt, c.endAt, DateTime.now(), t);
    return PressableTile(
      onTap: () => Get.to(() => ChallengeDetailScreen(challengeId: c.id, initial: c, service: service)),
      semanticLabel: '${c.title}, $time',
      color: p.card,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: p.accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            StreamBuilder<ChallengeParticipant?>(
              stream: service.myParticipant(c.id),
              builder: (context, snap) => _ProgressRing(percent: snap.data?.percent ?? 0, size: 46.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: p.text)),
                  SizedBox(height: 4.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 2.h,
                    children: [
                      _meta(p, Iconsax.clock, time),
                      _meta(p, Iconsax.people, t.challengesMembers(c.memberCount)),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  _AvatarStack(challengeId: c.id, service: service),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.sub),
          ],
        ),
      ),
    );
  }

  Widget _meta(_Palette p, IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: p.sub),
          SizedBox(width: 4.w),
          Text(text, style: TextStyle(fontSize: 12.sp, color: p.sub)),
        ],
      );
}

/// A circular progress ring with the percentage in the middle; it eases
/// to a new value instead of jumping.
class _ProgressRing extends StatelessWidget {
  final double percent;
  final double size;
  final double strokeWidth;
  final double? fontSize;

  const _ProgressRing({required this.percent, required this.size, this.strokeWidth = 4, this.fontSize});

  @override
  Widget build(BuildContext context) {
    final p = _Palette(context);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: percent.clamp(0, 100).toDouble()),
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: value / 100,
                strokeWidth: strokeWidth,
                strokeCap: StrokeCap.round,
                backgroundColor: p.line,
                color: p.accent,
              ),
            ),
            Text('${value.floor()}%',
                style: TextStyle(fontSize: fontSize ?? 11.sp, fontWeight: FontWeight.w800, color: p.text)),
          ],
        ),
      ),
    );
  }
}

/// Up to four member avatars, overlapping, for a challenge card.
class _AvatarStack extends StatelessWidget {
  final String challengeId;
  final ChallengeService service;

  const _AvatarStack({required this.challengeId, required this.service});

  @override
  Widget build(BuildContext context) {
    final size = 22.w;
    return StreamBuilder<List<ChallengeParticipant>>(
      stream: service.participants(challengeId, limit: 4),
      builder: (context, snap) {
        final members = snap.data ?? const <ChallengeParticipant>[];
        if (members.isEmpty) return SizedBox(height: size);
        return ExcludeSemantics(
          child: SizedBox(
            height: size,
            width: size + (members.length - 1) * size * 0.65,
            child: Stack(
              children: [
                for (final (i, m) in members.indexed)
                  PositionedDirectional(
                    start: i * size * 0.65,
                    child: _Avatar(name: m.displayName, uid: m.uid, size: size),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shares the invite: the code, how to use it, and the store links.
Future<void> shareChallengeInvite(BuildContext context, String title, String code) async {
  final t = AppLocalizations.of(context)!;
  final origin = AppShareService.originFor(context);
  try {
    await SharePlus.instance.share(ShareParams(
      text: '${t.challengesShareMessage(title, code)}\n\n${AppShareService.downloadText}',
      subject: title,
      sharePositionOrigin: origin,
    ));
  } catch (e) {
    VoidLogger.error('Failed to share the challenge invite', e);
  }
}

/// Bottom sheet with the invite code (copy / share) and, for an existing
/// challenge, Leave or Delete.
/// Returns true when the user left or deleted the challenge from the sheet.
Future<bool?> showChallengeInviteSheet(BuildContext context, Challenge challenge,
    {required ChallengeService service, bool justCreated = false}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _Palette(context).card,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22.r))),
    builder: (sheetContext) => _InviteSheet(challenge: challenge, service: service, justCreated: justCreated),
  );
}

class _InviteSheet extends StatelessWidget {
  final Challenge challenge;
  final ChallengeService service;
  final bool justCreated;

  const _InviteSheet({required this.challenge, required this.service, required this.justCreated});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final c = challenge;
    final isCreator = service.currentUser?.uid == c.creatorUid;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(2.r)),
            ),
            SizedBox(height: 14.h),
            if (justCreated) ...[
              Icon(Iconsax.tick_circle, color: p.accent, size: 34.sp),
              SizedBox(height: 6.h),
              Text(t.challengesCreated, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: p.text)),
              SizedBox(height: 4.h),
            ],
            Text(c.title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: p.text)),
            SizedBox(height: 16.h),
            Text(t.challengesInviteCode, style: TextStyle(fontSize: 12.sp, color: p.sub)),
            SizedBox(height: 6.h),
            Semantics(
              label: '${t.challengesInviteCode}: ${c.inviteCode.split('').join(' ')}',
              excludeSemantics: true,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(c.inviteCode,
                      style: TextStyle(
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 6,
                          color: p.text,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Text(t.challengesInviteHint,
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, height: 1.5, color: p.sub)),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: c.inviteCode));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.challengesCodeCopied)));
                      }
                    },
                    icon: Icon(Iconsax.copy, size: 17.sp, color: p.accent),
                    label: Text(t.challengesCopyCode, style: TextStyle(fontSize: 13.sp, color: p.text)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: p.accent.withValues(alpha: 0.5)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Builder(
                    builder: (buttonContext) => FilledButton.icon(
                      onPressed: () => shareChallengeInvite(buttonContext, c.title, c.inviteCode),
                      icon: Icon(Iconsax.share, size: 17.sp),
                      label: Text(t.challengesShareInvite, style: TextStyle(fontSize: 13.sp)),
                      style: FilledButton.styleFrom(
                        backgroundColor: p.accent,
                        foregroundColor: p.bg,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (!justCreated) ...[
              SizedBox(height: 8.h),
              TextButton.icon(
                onPressed: () async {
                  final left = await confirmLeaveOrDeleteChallenge(context, c, service: service);
                  if (left && context.mounted) Navigator.pop(context, true);
                },
                icon: Icon(isCreator ? Iconsax.trash : Iconsax.logout, size: 17.sp, color: Colors.red.shade400),
                label: Text(isCreator ? t.challengesDelete : t.challengesLeave,
                    style: TextStyle(fontSize: 13.sp, color: Colors.red.shade400)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Asks, then leaves [challenge] (or deletes it, for the creator). Returns
/// true when done.
Future<bool> confirmLeaveOrDeleteChallenge(BuildContext context, Challenge challenge,
    {required ChallengeService service}) async {
  final t = AppLocalizations.of(context)!;
  final isCreator = service.currentUser?.uid == challenge.creatorUid;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Text(isCreator ? t.challengesDeleteConfirm : t.challengesLeaveConfirm),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.challengesCancel)),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(isCreator ? t.challengesDelete : t.challengesLeave, style: TextStyle(color: Colors.red.shade400)),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  try {
    if (isCreator) {
      await service.delete(challenge);
    } else {
      await service.leave(challenge);
    }
    try {
      await LocalNotificationsService().setChallengeReminder(challenge.id, title: challenge.title, endAt: challenge.endAt);
    } catch (e) {
      VoidLogger.error('Could not clear the challenge reminder', e);
    }
    return true;
  } catch (e) {
    VoidLogger.error('Leave/delete challenge failed', e);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.challengesErrorNetwork)));
    }
    return false;
  }
}

/// Create a challenge: pick a template, set the target and length, an
/// optional intention, and whether others see exact numbers.
class CreateChallengeScreen extends StatefulWidget {
  final ChallengeService service;

  const CreateChallengeScreen({super.key, required this.service});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  ChallengeTemplate _template = challengeTemplates.first;
  late String _unit;
  late int _days;
  int _surah = 67; // Al-Mulk: a common family memorisation goal.
  bool _tahajjud = true;
  DateTime? _startDate; // null = start now
  bool _showExact = true;
  bool _titleEdited = false;
  bool _busy = false;
  String? _error;

  final _title = TextEditingController();
  final _target = TextEditingController();
  final _customUnit = TextEditingController();
  final _intention = TextEditingController();
  final _dedication = TextEditingController();
  final _promise = TextEditingController();

  static const _dayPresets = [1, 3, 7, 10, 30, 40];

  @override
  void initState() {
    super.initState();
    _unit = _template.units.first;
    _days = _template.defaultDays;
    _target.text = '${_template.defaultTarget}';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshDefaultTitle();
  }

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _customUnit.dispose();
    _intention.dispose();
    _dedication.dispose();
    _promise.dispose();
    super.dispose();
  }

  void _selectTemplate(ChallengeTemplate tpl) {
    setState(() {
      _template = tpl;
      _unit = tpl.units.isEmpty ? '' : tpl.units.first;
      _days = tpl.defaultDays;
      _target.text = '${tpl.defaultTarget}';
      _error = null;
      if (tpl.type == ChallengeType.custom && !_titleEdited) _title.clear();
    });
    _refreshDefaultTitle();
  }

  /// The title follows the choices until the user types their own.
  void _refreshDefaultTitle() {
    if (_titleEdited || _template.type == ChallengeType.custom) return;
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final name = switch (_template.type) {
      ChallengeType.memorizeSurah => '${t.challengesTypeMemorizeSurah}: ${_surahName(_surah, lang)}',
      ChallengeType.dailyPrayer => _tahajjud ? t.challengesTahajjud : t.challengesFajrOnTime,
      _ => challengeTypeLabel(_template.type, t),
    };
    _title.text = t.challengesDefaultTitle(_days, name);
  }

  int get _effectiveTarget {
    if (_template.type == ChallengeType.khatam) return ChallengeTemplate.khatamTarget(_unit);
    if (_template.type == ChallengeType.memorizeSurah) return quran.getVerseCount(_surah);
    if (_template.targetIsDays) return _days;
    return int.tryParse(_target.text.trim()) ?? 0;
  }

  String get _effectiveUnit => _template.type == ChallengeType.custom ? _customUnit.text.trim() : _unit;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  String? _validate(AppLocalizations t) {
    if (_title.text.trim().isEmpty) return t.challengesErrorTitle;
    final target = _effectiveTarget;
    if (target <= 0 || target > 1000000) return t.challengesErrorTarget;
    if (_template.type == ChallengeType.custom && _effectiveUnit.isEmpty) return t.challengesErrorTarget;
    if (_template.type == ChallengeType.fasting && target > _days) return t.challengesErrorTargetDays;
    return null;
  }

  Future<void> _create() async {
    final t = AppLocalizations.of(context)!;
    final error = _validate(t);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final now = DateTime.now();
    final start = _startDate == null || DateUtils.isSameDay(_startDate, now)
        ? now
        : DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    try {
      final created = await widget.service.create(NewChallenge(
        title: _title.text,
        type: _template.type,
        unit: _effectiveUnit,
        target: _effectiveTarget,
        startAt: start,
        durationDays: _days,
        intention: _intention.text,
        dedication: _dedication.text,
        familyPromise: _promise.text,
        surah: _template.type == ChallengeType.memorizeSurah ? _surah : null,
        showExactNumbers: _showExact,
      ));
      if (!mounted) return;
      setState(() => _busy = false);
      await showChallengeInviteSheet(context, created, service: widget.service, justCreated: true);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      VoidLogger.error('Create challenge failed', e);
      if (mounted) setState(() => _error = t.challengesErrorCreate);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final lang = Localizations.localeOf(context).languageCode;
    final type = _template.type;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.challengesCreate, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: p.text)),
        centerTitle: true,
      ),
      body: ReadableWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
          children: [
            Text(t.challengesChooseType, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: p.text)),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final tpl in challengeTemplates)
                  ChoiceChip(
                    avatar: Icon(tpl.icon, size: 16.sp, color: tpl == _template ? p.bg : p.accent),
                    label: Text(challengeTypeLabel(tpl.type, t)),
                    selected: tpl == _template,
                    onSelected: (_) => _selectTemplate(tpl),
                    showCheckmark: false,
                    selectedColor: p.accent,
                    backgroundColor: p.card,
                    side: BorderSide(color: p.accent.withValues(alpha: 0.35)),
                    labelStyle: TextStyle(
                        fontSize: 13.sp, color: tpl == _template ? p.bg : p.text, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            SizedBox(height: 18.h),
            _card(
              p,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _title,
                    maxLength: ChallengeService.maxTitleLength,
                    onChanged: (_) => _titleEdited = true,
                    style: TextStyle(fontSize: 14.sp, color: p.text),
                    decoration: _fieldDecoration(p, t.challengesTitleLabel),
                  ),
                  SizedBox(height: 8.h),
                  if (type == ChallengeType.khatam || type == ChallengeType.readQuran) ...[
                    SegmentedButton<String>(
                      segments: [
                        for (final u in _template.units) ButtonSegment(value: u, label: Text(challengeUnitLabel(u, t))),
                      ],
                      selected: {_unit},
                      onSelectionChanged: (s) => setState(() => _unit = s.first),
                      showSelectedIcon: false,
                    ),
                    SizedBox(height: 12.h),
                  ],
                  if (type == ChallengeType.memorizeSurah) ...[
                    DropdownButtonFormField<int>(
                      initialValue: _surah,
                      isExpanded: true,
                      decoration: _fieldDecoration(p, t.challengesSurah),
                      dropdownColor: p.card,
                      style: TextStyle(fontSize: 14.sp, color: p.text),
                      items: [
                        for (var s = 1; s <= 114; s++)
                          DropdownMenuItem(
                            value: s,
                            child: Text('$s. ${_surahName(s, lang)} (${quran.getVerseCount(s)})',
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (s) {
                        if (s == null) return;
                        setState(() => _surah = s);
                        _refreshDefaultTitle();
                      },
                    ),
                    SizedBox(height: 12.h),
                  ],
                  if (type == ChallengeType.dailyPrayer) ...[
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(value: true, label: Text(t.challengesTahajjud)),
                        ButtonSegment(value: false, label: Text(t.challengesFajrOnTime)),
                      ],
                      selected: {_tahajjud},
                      onSelectionChanged: (s) {
                        setState(() => _tahajjud = s.first);
                        _refreshDefaultTitle();
                      },
                      showSelectedIcon: false,
                    ),
                    SizedBox(height: 12.h),
                  ],
                  if (type == ChallengeType.custom) ...[
                    TextField(
                      controller: _customUnit,
                      maxLength: 30,
                      style: TextStyle(fontSize: 14.sp, color: p.text),
                      decoration: _fieldDecoration(p, t.challengesCustomUnit),
                    ),
                    SizedBox(height: 4.h),
                  ],
                  _targetRow(p, t),
                  SizedBox(height: 14.h),
                  _durationPicker(p, t),
                  SizedBox(height: 14.h),
                  _startPicker(p, t, lang),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            _card(
              p,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _intention,
                    maxLength: ChallengeService.maxIntentionLength,
                    maxLines: 2,
                    minLines: 1,
                    style: TextStyle(fontSize: 14.sp, color: p.text),
                    decoration: _fieldDecoration(p, t.challengesIntention, hint: t.challengesIntentionHint),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _dedication,
                    maxLength: ChallengeService.maxDedicationLength,
                    style: TextStyle(fontSize: 14.sp, color: p.text),
                    decoration: _fieldDecoration(p, t.challengesDedication, hint: t.challengesDedicationHint),
                  ),
                  Text(t.challengesDedicationNote, style: TextStyle(fontSize: 11.5.sp, height: 1.45, color: p.sub)),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _promise,
                    maxLength: ChallengeService.maxPromiseLength,
                    style: TextStyle(fontSize: 14.sp, color: p.text),
                    decoration: _fieldDecoration(p, t.challengesPromise, hint: t.challengesPromiseHint),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _showExact,
                    activeThumbColor: p.accent,
                    onChanged: (v) => setState(() => _showExact = v),
                    title: Text(t.challengesShowExact,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: p.text)),
                    subtitle: Text(t.challengesShowExactSub, style: TextStyle(fontSize: 12.sp, color: p.sub)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Iconsax.heart, size: 16.sp, color: p.accent),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(t.challengesPurifyIntention,
                      style: TextStyle(fontSize: 12.5.sp, height: 1.5, fontStyle: FontStyle.italic, color: p.sub)),
                ),
              ],
            ),
            if (_error != null) ...[
              SizedBox(height: 12.h),
              Text(_error!, style: TextStyle(fontSize: 13.sp, color: Colors.red.shade400)),
            ],
            SizedBox(height: 16.h),
            _primaryButton(p, t.challengesCreateButton, _create, busy: _busy),
          ],
        ),
      ),
    );
  }

  Widget _targetRow(_Palette p, AppLocalizations t) {
    final fixed = _template.fixedTarget || _template.targetIsDays;
    final unit = _effectiveUnit.isEmpty ? '' : challengeUnitLabel(_effectiveUnit, t);
    if (fixed) {
      return Row(
        children: [
          Text('${t.challengesTarget}: ', style: TextStyle(fontSize: 14.sp, color: p.sub)),
          Flexible(
            child: Text('$_effectiveTarget $unit',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: p.text)),
          ),
        ],
      );
    }
    return TextField(
      controller: _target,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
      onChanged: (_) => setState(() {}),
      style: TextStyle(fontSize: 14.sp, color: p.text),
      decoration: _fieldDecoration(p, t.challengesTarget, suffix: unit),
    );
  }

  Widget _durationPicker(_Palette p, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(t.challengesDuration, style: TextStyle(fontSize: 14.sp, color: p.sub))),
            IconButton(
              tooltip: '-',
              onPressed: _days > 1 ? () => _setDays(_days - 1) : null,
              icon: Icon(Icons.remove_circle_outline, color: p.accent),
            ),
            Text(t.challengesDurationDays(_days),
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: p.text)),
            IconButton(
              tooltip: '+',
              onPressed: _days < ChallengeService.maxDays ? () => _setDays(_days + 1) : null,
              icon: Icon(Icons.add_circle_outline, color: p.accent),
            ),
          ],
        ),
        Wrap(
          spacing: 6.w,
          runSpacing: 6.h,
          children: [
            for (final d in _dayPresets)
              ChoiceChip(
                label: Text(t.challengesDurationDays(d)),
                selected: d == _days,
                showCheckmark: false,
                onSelected: (_) => _setDays(d),
                selectedColor: p.accent.withValues(alpha: 0.2),
                backgroundColor: p.card,
                side: BorderSide(color: p.line),
                labelStyle: TextStyle(fontSize: 12.sp, color: p.text),
              ),
          ],
        ),
      ],
    );
  }

  void _setDays(int days) {
    setState(() => _days = days);
    _refreshDefaultTitle();
  }

  Widget _startPicker(_Palette p, AppLocalizations t, String lang) {
    final dateLabel = _startDate == null ? t.challengesStartOn : DateFormat.yMMMd(lang).format(_startDate!);
    return Row(
      children: [
        Text(t.challengesStart, style: TextStyle(fontSize: 14.sp, color: p.sub)),
        SizedBox(width: 10.w),
        Expanded(
          child: Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              ChoiceChip(
                label: Text(t.challengesStartNow),
                selected: _startDate == null,
                showCheckmark: false,
                onSelected: (_) => setState(() => _startDate = null),
                selectedColor: p.accent.withValues(alpha: 0.2),
                backgroundColor: p.card,
                side: BorderSide(color: p.line),
                labelStyle: TextStyle(fontSize: 12.sp, color: p.text),
              ),
              ChoiceChip(
                avatar: Icon(Iconsax.calendar_1, size: 14.sp, color: p.accent),
                label: Text(dateLabel),
                selected: _startDate != null,
                showCheckmark: false,
                onSelected: (_) => _pickDate(),
                selectedColor: p.accent.withValues(alpha: 0.2),
                backgroundColor: p.card,
                side: BorderSide(color: p.line),
                labelStyle: TextStyle(fontSize: 12.sp, color: p.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Join with an invite code: look it up, show a preview, then join.
class JoinChallengeScreen extends StatefulWidget {
  final ChallengeService service;
  final String? initialCode;

  const JoinChallengeScreen({super.key, required this.service, this.initialCode});

  @override
  State<JoinChallengeScreen> createState() => _JoinChallengeScreenState();
}

class _JoinChallengeScreenState extends State<JoinChallengeScreen> {
  late final _code = TextEditingController(text: ChallengeService.normalizeCode(widget.initialCode ?? ''));
  ChallengePreview? _preview;
  bool _showExact = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (ChallengeService.isValidCode(_code.text)) WidgetsBinding.instance.addPostFrameCallback((_) => _find());
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final t = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
    });
    try {
      final preview = await widget.service.lookup(_code.text);
      if (mounted) setState(() => _preview = preview);
    } on ChallengeJoinException catch (e) {
      if (mounted) setState(() => _error = _joinErrorText(e.reason, t));
    } catch (e) {
      VoidLogger.error('Invite code lookup failed', e);
      if (mounted) setState(() => _error = t.challengesErrorNetwork);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final t = AppLocalizations.of(context)!;
    final preview = _preview;
    if (preview == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.join(preview, showExactNumbers: _showExact);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.challengesJoined)));
      Navigator.pop(context);
    } on ChallengeJoinException catch (e) {
      if (mounted) setState(() => _error = _joinErrorText(e.reason, t));
    } catch (e) {
      VoidLogger.error('Join challenge failed', e);
      if (mounted) setState(() => _error = t.challengesErrorNetwork);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final preview = _preview;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.challengesJoin, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: p.text)),
        centerTitle: true,
      ),
      body: ReadableWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
          children: [
            _card(
              p,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.challengesEnterCode, style: TextStyle(fontSize: 14.sp, color: p.sub)),
                  SizedBox(height: 10.h),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      controller: _code,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      enableSuggestions: false,
                      inputFormatters: [_CodeFormatter()],
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => ChallengeService.isValidCode(_code.text) ? _find() : null,
                      style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w800, letterSpacing: 6, color: p.text),
                      decoration: _fieldDecoration(p, '').copyWith(labelText: null, hintText: 'ABC234'),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  OutlinedButton(
                    onPressed: _busy || !ChallengeService.isValidCode(_code.text) ? null : _find,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: p.accent.withValues(alpha: 0.5)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text(t.challengesFind, style: TextStyle(fontSize: 14.sp, color: p.text)),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: 12.h),
              Text(_error!, style: TextStyle(fontSize: 13.sp, height: 1.4, color: Colors.red.shade400)),
            ],
            if (_busy && preview == null) ...[
              SizedBox(height: 24.h),
              Center(child: CircularProgressIndicator(color: p.accent)),
            ],
            if (preview != null) ...[
              SizedBox(height: 16.h),
              _previewCard(p, t, preview),
              SizedBox(height: 12.h),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _showExact,
                activeThumbColor: p.accent,
                onChanged: (v) => setState(() => _showExact = v),
                title: Text(t.challengesShowExact,
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: p.text)),
                subtitle: Text(t.challengesShowExactSub, style: TextStyle(fontSize: 12.sp, color: p.sub)),
              ),
              SizedBox(height: 12.h),
              _primaryButton(p, t.challengesJoinButton, _join, icon: Iconsax.people, busy: _busy),
            ],
          ],
        ),
      ),
    );
  }

  Widget _previewCard(_Palette p, AppLocalizations t, ChallengePreview preview) {
    final tpl = templateFor(preview.type);
    return _card(
      p,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: p.accent.withValues(alpha: 0.15),
            child: Icon(tpl.icon, color: p.accent, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(preview.title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: p.text)),
                SizedBox(height: 2.h),
                Text(challengeTypeLabel(preview.type, t), style: TextStyle(fontSize: 12.sp, color: p.accent)),
                SizedBox(height: 8.h),
                Text(t.challengesBy(preview.creatorName), style: TextStyle(fontSize: 13.sp, color: p.sub)),
                Text(t.challengesMembers(preview.memberCount), style: TextStyle(fontSize: 13.sp, color: p.sub)),
                Text(challengeTimeLabel(preview.startAt, preview.endAt, DateTime.now(), t),
                    style: TextStyle(fontSize: 13.sp, color: p.sub)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Upper-cases and keeps only invite-code characters (no O/0/I/1), max 6.
class _CodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final code = ChallengeService.normalizeCode(newValue.text);
    final clipped = code.length > ChallengeService.codeLength ? code.substring(0, ChallengeService.codeLength) : code;
    return TextEditingValue(text: clipped, selection: TextSelection.collapsed(offset: clipped.length));
  }
}

/// Home's "active challenge" card: the user's challenge that ends soonest,
/// with their progress and days left. Nothing for guests, before Firebase
/// is ready, or with no active challenge.
class ActiveChallengeCard extends StatefulWidget {
  final EdgeInsetsGeometry padding;
  final ChallengeService? service;

  const ActiveChallengeCard({super.key, this.padding = EdgeInsets.zero, this.service});

  @override
  State<ActiveChallengeCard> createState() => _ActiveChallengeCardState();
}

class _ActiveChallengeCardState extends State<ActiveChallengeCard> {
  ChallengeService? _svc;
  Stream<User?>? _auth;
  String? _uid;
  Stream<List<Challenge>>? _challenges;

  @override
  void initState() {
    super.initState();
    try {
      if (widget.service == null && Firebase.apps.isEmpty) return;
      _svc = widget.service ?? ChallengeService();
      _auth = _svc!.authChanges();
    } catch (e) {
      VoidLogger.error('Active challenge card unavailable', e);
    }
  }

  Stream<List<Challenge>> _challengesFor(String uid) {
    if (_uid != uid || _challenges == null) {
      _uid = uid;
      _challenges = _svc!.myChallenges();
    }
    return _challenges!;
  }

  @override
  Widget build(BuildContext context) {
    final auth = _auth;
    if (auth == null) return const SizedBox.shrink();
    return StreamBuilder<User?>(
      stream: auth,
      initialData: _svc!.currentUser,
      builder: (context, userSnap) {
        final user = userSnap.data;
        if (user == null) return const SizedBox.shrink();
        return StreamBuilder<List<Challenge>>(
          stream: _challengesFor(user.uid),
          builder: (context, snap) {
            final now = DateTime.now();
            final active = (snap.data ?? const <Challenge>[]).where((c) => c.statusAt(now) == ChallengeStatus.active);
            if (active.isEmpty) return const SizedBox.shrink();
            return Padding(padding: widget.padding, child: _card(context, active.first, now));
          },
        );
      },
    );
  }

  Widget _card(BuildContext context, Challenge c, DateTime now) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final svc = _svc!;
    final time = challengeTimeLabel(c.startAt, c.endAt, now, t);
    return PressableTile(
      onTap: () => Get.to(() => ChallengeDetailScreen(challengeId: c.id, initial: c, service: svc)),
      semanticLabel: '${t.challengesTitle}: ${c.title}, $time',
      color: p.card,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: p.accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            StreamBuilder<ChallengeParticipant?>(
              stream: svc.myParticipant(c.id),
              builder: (context, snap) => _ProgressRing(percent: snap.data?.percent ?? 0, size: 50.w, strokeWidth: 5),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.challengesTitle.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: p.accent)),
                  SizedBox(height: 2.h),
                  Text(c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: p.text)),
                  SizedBox(height: 2.h),
                  Text(time, style: TextStyle(fontSize: 12.sp, color: p.sub)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.sub),
          ],
        ),
      ),
    );
  }
}

/// Asks for a short text (a report reason, a dua). Returns the text, or
/// null when cancelled. The dialog owns its controller, so it stays valid
/// through the closing animation.
Future<String?> _showTextDialog(BuildContext context,
    {required String title,
    required String hint,
    required int maxLength,
    required String action,
    int minLines = 1,
    int maxLines = 3,
    bool autofocus = false}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextDialog(
      title: title,
      hint: hint,
      maxLength: maxLength,
      action: action,
      minLines: minLines,
      maxLines: maxLines,
      autofocus: autofocus,
    ),
  );
}

class _TextDialog extends StatefulWidget {
  final String title, hint, action;
  final int maxLength, minLines, maxLines;
  final bool autofocus;

  const _TextDialog({
    required this.title,
    required this.hint,
    required this.action,
    required this.maxLength,
    required this.minLines,
    required this.maxLines,
    required this.autofocus,
  });

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title, style: TextStyle(fontSize: 17.sp)),
      content: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        maxLength: widget.maxLength,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.challengesCancel)),
        TextButton(onPressed: () => Navigator.pop(context, _controller.text), child: Text(widget.action)),
      ],
    );
  }
}
