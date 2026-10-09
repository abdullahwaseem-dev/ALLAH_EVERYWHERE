part of 'challenges.dart';

/// The Dua Wall of a finished challenge: members write one short dua for
/// each member who completed it, and those who completed write one back
/// for everyone. Only members can see it.
class DuaWallScreen extends StatefulWidget {
  final Challenge challenge;
  final ChallengeService? service;

  const DuaWallScreen({super.key, required this.challenge, this.service});

  @override
  State<DuaWallScreen> createState() => _DuaWallScreenState();
}

class _DuaWallScreenState extends State<DuaWallScreen> {
  late final ChallengeService _svc = widget.service ?? ChallengeService();
  late final Stream<List<ChallengeParticipant>> _members = _svc.participants(widget.challenge.id);
  late final Stream<List<ChallengeDua>> _duas = _svc.duas(widget.challenge.id);

  Challenge get c => widget.challenge;
  String? get _uid => _svc.currentUser?.uid;

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _write(String toUid, String title) async {
    final t = AppLocalizations.of(context)!;
    final text = await _showTextDialog(
      context,
      title: title,
      hint: t.duaWallHint,
      maxLength: ChallengeService.maxDuaLength,
      action: t.challengesSend,
      minLines: 2,
      maxLines: 4,
      autofocus: true,
    );
    if (text == null || text.trim().isEmpty) return;
    try {
      await _svc.writeDua(c, toUid, text);
      _snack(t.duaWallSent);
    } catch (e) {
      VoidLogger.error('Writing a dua failed', e);
      _snack(t.challengesErrorSend);
    }
  }

  void _actions(ChallengeDua dua) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final mine = dua.fromUid == _uid;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22.r))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!mine)
              ListTile(
                leading: Icon(Iconsax.flag, color: p.sub),
                title: Text(t.challengesReport, style: TextStyle(fontSize: 14.sp, color: p.text)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    await _svc.reportDua(c, dua, '');
                    _snack(t.challengesReported);
                  } catch (e) {
                    _snack(t.challengesErrorNetwork);
                  }
                },
              ),
            if (mine || c.creatorUid == _uid)
              ListTile(
                leading: Icon(Iconsax.trash, color: Colors.red.shade400),
                title: Text(t.challengesDeleteItem, style: TextStyle(fontSize: 14.sp, color: Colors.red.shade400)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    await _svc.deleteDua(c, dua);
                  } catch (e) {
                    _snack(t.challengesErrorNetwork);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.duaWallTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: p.text)),
        centerTitle: true,
      ),
      body: ReadableWidth(
        child: StreamBuilder<List<ChallengeParticipant>>(
          stream: _members,
          builder: (context, ms) => StreamBuilder<List<ChallengeDua>>(
            stream: _duas,
            builder: (context, ds) {
              final members = ms.data;
              final duas = ds.data;
              if (members == null || duas == null) {
                return Center(
                  child: ms.hasError || ds.hasError
                      ? Text(t.challengesErrorNetwork, style: TextStyle(fontSize: 13.sp, color: p.sub))
                      : CircularProgressIndicator(color: p.accent),
                );
              }
              return _wall(p, t, members, duas);
            },
          ),
        ),
      ),
    );
  }

  Widget _wall(_Palette p, AppLocalizations t, List<ChallengeParticipant> members, List<ChallengeDua> duas) {
    final completers = members.where((m) => m.completedAt != null || m.percent >= 100).toList();
    final me = _uid;
    final iCompleted = completers.any((m) => m.uid == me);
    final written = {for (final d in duas) if (d.fromUid == me) d.toUid};
    final forAll = duas.where((d) => d.toUid == ChallengeDua.everyone).toList();
    // My own wall first, then everyone else who completed.
    completers.sort((a, b) => a.uid == me ? -1 : (b.uid == me ? 1 : 0));
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
      children: [
        Text(c.title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: p.text)),
        SizedBox(height: 4.h),
        Text(t.duaWallIntro, style: TextStyle(fontSize: 13.sp, height: 1.45, color: p.sub)),
        SizedBox(height: 16.h),
        if (completers.isEmpty)
          Text(t.duaWallNone, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5.sp, height: 1.5, color: p.sub)),
        for (final m in completers) ...[
          _wallCard(
            p,
            t,
            title: m.uid == me ? t.duaWallForYou : t.duaWallFor(m.displayName),
            avatar: _Avatar(name: m.displayName, uid: m.uid, size: 38.w),
            duas: duas.where((d) => d.toUid == m.uid).toList(),
            action: m.uid == me || written.contains(m.uid)
                ? null
                : () => _write(m.uid, t.duaWallFor(m.displayName)),
            done: m.uid != me && written.contains(m.uid),
          ),
          SizedBox(height: 12.h),
        ],
        if (forAll.isNotEmpty || iCompleted)
          _wallCard(
            p,
            t,
            title: t.duaWallEveryone,
            avatar: CircleAvatar(
              radius: 19.w,
              backgroundColor: p.accent.withValues(alpha: 0.15),
              child: Icon(Iconsax.people, color: p.accent, size: 18.sp),
            ),
            duas: forAll,
            action: iCompleted && !written.contains(ChallengeDua.everyone)
                ? () => _write(ChallengeDua.everyone, t.duaWallWriteEveryone)
                : null,
            actionLabel: t.duaWallWriteEveryone,
            done: written.contains(ChallengeDua.everyone),
          ),
      ],
    );
  }

  Widget _wallCard(_Palette p, AppLocalizations t,
      {required String title,
      required Widget avatar,
      required List<ChallengeDua> duas,
      VoidCallback? action,
      String? actionLabel,
      bool done = false}) {
    return _card(
      p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              avatar,
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: p.text)),
                    Text(t.duaWallCount(duas.length), style: TextStyle(fontSize: 12.sp, color: p.sub)),
                  ],
                ),
              ),
            ],
          ),
          if (duas.isNotEmpty) SizedBox(height: 10.h),
          for (final d in duas)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: () => _actions(d),
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.fromName, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: p.accent)),
                    SizedBox(height: 2.h),
                    Text(d.text, style: TextStyle(fontSize: 14.sp, height: 1.45, color: p.text)),
                  ],
                ),
              ),
            ),
          if (action != null) ...[
            SizedBox(height: 6.h),
            _primaryButton(p, actionLabel ?? t.duaWallWrite, action, icon: Iconsax.edit_2),
          ] else if (done) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(Iconsax.tick_circle, size: 16.sp, color: p.accent),
                SizedBox(width: 6.w),
                Text(t.duaWallWritten, style: TextStyle(fontSize: 12.5.sp, color: p.accent)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
