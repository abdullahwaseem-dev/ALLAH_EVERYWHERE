part of 'challenges.dart';

/// The first letter of [name] for an avatar, or "?" when it is empty.
String _initial(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
}

/// A member's avatar: their initial on a tint of the accent colour (the
/// shade depends on the uid, so members are easy to tell apart).
class _Avatar extends StatelessWidget {
  final String name;
  final String uid;
  final double size;

  const _Avatar({required this.name, required this.uid, required this.size});

  @override
  Widget build(BuildContext context) {
    final p = _Palette(context);
    final shade = 0.14 + (uid.hashCode.abs() % 4) * 0.07;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.alphaBlend(p.accent.withValues(alpha: shade), p.card),
        border: Border.all(color: p.card, width: 1.5),
      ),
      child: Text(_initial(name),
          style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w800, color: p.text, height: 1)),
    );
  }
}

String _reactionLabel(String key, AppLocalizations t) => switch (key) {
      'mashaallah' => t.challengesReactMashaAllah,
      'barakallah' => t.challengesReactBarakAllah,
      'ameen' => t.challengesReactAmeen,
      'dua' => '🤲',
      'love' => '❤️',
      _ => key,
    };

/// "3 days left", "Ends in 5h 12m", "Starts in 2 days" or "Ended".
String _countdown(Challenge c, DateTime now, AppLocalizations t) {
  if (now.isBefore(c.startAt)) return t.challengesStartsIn(daysUntil(c.startAt, now));
  if (!now.isBefore(c.endAt)) return t.challengesEnded;
  final left = c.endAt.difference(now);
  if (left.inHours < 24) return t.challengesEndsInHours('${left.inHours}', '${left.inMinutes % 60}');
  return t.challengesDaysLeft(daysUntil(c.endAt, now));
}

/// Whether [m] can be nudged by the user today: someone else, not finished,
/// and nothing logged today.
bool _canNudge(Challenge c, ChallengeParticipant m, String? myUid, DateTime now) =>
    m.uid != myUid &&
    m.completedAt == null &&
    m.percent < 100 &&
    !m.loggedDays.contains(challengeDayKey(now)) &&
    c.statusAt(now) == ChallengeStatus.active;

/// The text of a progress update, e.g. "Ahmed finished Juz 12".
String _progressText(Challenge c, ChallengeFeedItem item, String name, AppLocalizations t) {
  final value = item.value;
  if (value == null) return t.challengesFeedPrivate(name);
  if (item.items.isNotEmpty) {
    final items = compactRanges(item.items);
    switch (c.itemKind) {
      case ChallengeItemKind.juz:
        return t.challengesFeedJuz(name, items);
      case ChallengeItemKind.pages:
        return t.challengesFeedPages(name, items);
      case ChallengeItemKind.ayahs:
        return t.challengesFeedAyahs(name, items);
      case ChallengeItemKind.none:
        break;
    }
  }
  return t.challengesFeedAmount(name, '$value', challengeUnitLabel(c.unit, t));
}

/// Challenges whose screen is open, so a push for one of them doesn't
/// also show a banner.
final _openChallenges = <String>[];

bool isChallengeOpen(String challengeId) => _openChallenges.contains(challengeId);

/// Opens a challenge's screen (from a notification), unless it is already
/// the one on top.
void openChallenge(String challengeId) {
  if (_openChallenges.isNotEmpty && _openChallenges.last == challengeId) return;
  Get.to(() => ChallengeDetailScreen(challengeId: challengeId));
}

/// The challenge screen: the user's progress, the members' leaderboard and
/// a chat-style feed, all updating live.
class ChallengeDetailScreen extends StatefulWidget {
  final String challengeId;

  /// Shown until the live copy arrives (e.g. from the list).
  final Challenge? initial;
  final ChallengeService? service;

  const ChallengeDetailScreen({super.key, required this.challengeId, this.initial, this.service});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  late final ChallengeService _svc = widget.service ?? ChallengeService();
  late final Stream<Challenge?> _challengeStream = _svc.watch(widget.challengeId);
  late final Stream<List<ChallengeParticipant>> _membersStream = _svc.participants(widget.challengeId);
  late Stream<List<ChallengeFeedItem>> _feedStream = _svc.feed(widget.challengeId);
  int _feedLimit = ChallengeService.feedPageSize;
  final _message = TextEditingController();
  Timer? _ticker;
  bool _busy = false;
  bool _sending = false;

  /// The user's exact count when they share only their percentage.
  int? _privateProgress;
  bool _privateLoaded = false;
  List<ChallengeParticipant> _members = const [];
  final Map<String, List<String>> _badges = {};
  final Set<String> _badgesRequested = {};

  String? get _uid => _svc.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _openChallenges.add(widget.challengeId);
    // Keeps the countdown current.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _openChallenges.remove(widget.challengeId);
    _ticker?.cancel();
    _message.dispose();
    super.dispose();
  }

  Future<void> _loadPrivate(Challenge c) async {
    _privateLoaded = true;
    try {
      final mine = await _svc.myProgress(c);
      if (mounted) setState(() => _privateProgress = mine.progress);
    } catch (e) {
      VoidLogger.error('Could not load my challenge progress', e);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // --- Logging ---------------------------------------------------------------

  Future<void> _addOne(Challenge c) async {
    final t = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      if (c.itemKind == ChallengeItemKind.none) {
        await _afterLog(c, await _svc.logProgress(c, amount: 1));
      } else {
        final mine = await _svc.myProgress(c);
        final max = _itemCount(c);
        int? next;
        for (var i = 1; i <= max; i++) {
          if (!mine.items.contains(i)) {
            next = i;
            break;
          }
        }
        if (next != null) await _afterLog(c, await _svc.logProgress(c, items: [next]));
      }
    } catch (e) {
      VoidLogger.error('Logging challenge progress failed', e);
      _snack(t.challengesErrorNetwork);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openLogSheet(Challenge c) async {
    final t = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    MyChallengeProgress mine;
    try {
      mine = await _svc.myProgress(c);
    } catch (e) {
      VoidLogger.error('Could not load my challenge progress', e);
      _snack(t.challengesErrorNetwork);
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    final request = await showModalBottomSheet<_LogRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _Palette(context).card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22.r))),
      builder: (_) => _LogSheet(challenge: c, mine: mine, itemCount: _itemCount(c)),
    );
    if (request == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _afterLog(c, await _svc.logProgress(c, amount: request.amount, items: request.items));
    } catch (e) {
      VoidLogger.error('Logging challenge progress failed', e);
      _snack(t.challengesErrorNetwork);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _afterLog(Challenge c, ProgressResult result) async {
    if (result.added <= 0 || !mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _privateProgress = result.progress;
      _busy = false;
    });
    if (result.completedNow) {
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ChallengeCelebrationScreen(challenge: c, members: _members, service: _svc),
      ));
    }
  }

  // --- Members ---------------------------------------------------------------

  Future<void> _nudge(Challenge c, ChallengeParticipant m) async {
    final t = AppLocalizations.of(context)!;
    try {
      final sent = await _svc.nudge(c, m.uid);
      _snack(sent ? t.challengesNudgeSent : t.challengesNudgeAlready);
    } catch (e) {
      VoidLogger.error('Nudge failed', e);
      _snack(t.challengesErrorNetwork);
    }
  }

  Future<void> _remove(Challenge c, ChallengeParticipant m) async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(t.challengesRemoveConfirm(m.displayName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.challengesCancel)),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t.challengesRemoveMember, style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.removeMember(c, m.uid);
    } catch (e) {
      VoidLogger.error('Removing a member failed', e);
      _snack(t.challengesErrorNetwork);
    }
  }

  void _showMember(Challenge c, ChallengeParticipant m) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final now = DateTime.now();
    final isMe = m.uid == _uid;
    final canRemove = c.creatorUid == _uid && !isMe;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22.r))),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(name: m.displayName, uid: m.uid, size: 56.w),
              SizedBox(height: 8.h),
              Text(isMe ? '${m.displayName} (${t.challengesYou})' : m.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: p.text)),
              SizedBox(height: 4.h),
              Text(
                m.showExactNumbers && m.progress != null
                    ? '${t.challengesProgressOf('${m.progress}', '${c.target}', challengeUnitLabel(c.unit, t))} · ${m.percent.floor()}%'
                    : '${m.percent.floor()}%',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: p.sub),
              ),
              if (!m.showExactNumbers) Text(t.challengesPercentOnly, style: TextStyle(fontSize: 12.sp, color: p.sub)),
              if (m.completedAt != null) ...[
                SizedBox(height: 6.h),
                Text(t.challengesCompletedLabel,
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: p.accent)),
              ],
              if (_canNudge(c, m, _uid, now)) ...[
                SizedBox(height: 16.h),
                _primaryButton(p, t.challengesNudge, () {
                  Navigator.pop(sheetContext);
                  _nudge(c, m);
                }, icon: Iconsax.notification_bing),
              ],
              if (canRemove) ...[
                SizedBox(height: 8.h),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _remove(c, m);
                  },
                  icon: Icon(Iconsax.user_remove, size: 17.sp, color: Colors.red.shade400),
                  label: Text(t.challengesRemoveMember, style: TextStyle(fontSize: 13.sp, color: Colors.red.shade400)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openNudgeSheet(Challenge c) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final now = DateTime.now();
    final eligible = _members.where((m) => _canNudge(c, m, _uid, now)).toList();
    final sent = <String>{};
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22.r))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
              children: [
                Text(t.challengesNudgeTitle,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: p.text)),
                SizedBox(height: 4.h),
                Text(t.challengesNudgeSub, style: TextStyle(fontSize: 12.5.sp, height: 1.4, color: p.sub)),
                SizedBox(height: 12.h),
                if (eligible.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Text(t.challengesNudgeAllDone,
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: p.accent)),
                  ),
                for (final m in eligible)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      children: [
                        _Avatar(name: m.displayName, uid: m.uid, size: 36.w),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(m.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: p.text)),
                        ),
                        TextButton.icon(
                          onPressed: sent.contains(m.uid)
                              ? null
                              : () async {
                                  setSheet(() => sent.add(m.uid));
                                  await _nudge(c, m);
                                },
                          icon: Icon(sent.contains(m.uid) ? Iconsax.tick_circle : Iconsax.notification_bing,
                              size: 16.sp, color: p.accent),
                          label: Text(t.challengesNudge, style: TextStyle(fontSize: 13.sp, color: p.accent)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Feed --------------------------------------------------------------------

  Future<void> _send(Challenge c) async {
    final text = _message.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _svc.sendMessage(c, text);
      _message.clear();
    } catch (e) {
      VoidLogger.error('Sending a challenge message failed', e);
      if (mounted) _snack(AppLocalizations.of(context)!.challengesErrorSend);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleReaction(Challenge c, ChallengeFeedItem item, String key) async {
    HapticFeedback.selectionClick();
    try {
      await _svc.toggleReaction(c, item, key);
    } catch (e) {
      VoidLogger.error('Reaction failed', e);
      if (mounted) _snack(AppLocalizations.of(context)!.challengesErrorNetwork);
    }
  }

  Future<void> _report(Challenge c, ChallengeFeedItem item) async {
    final t = AppLocalizations.of(context)!;
    final text = await _showTextDialog(
      context,
      title: t.challengesReportTitle,
      hint: t.challengesReportHint,
      maxLength: ChallengeService.maxReportLength,
      action: t.challengesReport,
    );
    if (text == null) return;
    try {
      await _svc.report(c, item, text);
      _snack(t.challengesReported);
    } catch (e) {
      VoidLogger.error('Report failed', e);
      _snack(t.challengesErrorNetwork);
    }
  }

  void _itemActions(Challenge c, ChallengeFeedItem item) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final mine = item.uid == _uid;
    final canDelete = mine || c.creatorUid == _uid;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22.r))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.challengesReact, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: p.sub)),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final key in challengeReactionKeys)
                    _reactionChip(p, t, key, item.reactionCount(key), item.reactedBy(_uid ?? '', key), () {
                      Navigator.pop(sheetContext);
                      _toggleReaction(c, item, key);
                    }, large: true),
                ],
              ),
              SizedBox(height: 8.h),
              if (!mine)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Iconsax.flag, color: p.sub),
                  title: Text(t.challengesReport, style: TextStyle(fontSize: 14.sp, color: p.text)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _report(c, item);
                  },
                ),
              if (canDelete)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Iconsax.trash, color: Colors.red.shade400),
                  title: Text(t.challengesDeleteItem, style: TextStyle(fontSize: 14.sp, color: Colors.red.shade400)),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    try {
                      await _svc.deleteItem(c, item);
                    } catch (e) {
                      VoidLogger.error('Deleting a feed item failed', e);
                      _snack(t.challengesErrorNetwork);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Menu --------------------------------------------------------------------

  Future<void> _onMenu(String action, Challenge c, ChallengeParticipant? me) async {
    final t = AppLocalizations.of(context)!;
    switch (action) {
      case 'invite':
        final left = await showChallengeInviteSheet(context, c, service: _svc);
        if (left == true && mounted) Navigator.pop(context);
      case 'mute':
        try {
          await _svc.setMuted(c, !(me?.muted ?? false));
        } catch (e) {
          VoidLogger.error('Mute failed', e);
          _snack(t.challengesErrorNetwork);
        }
      case 'auto':
        await ChallengeAutoProgress.setEnabled(c.id, !ChallengeAutoProgress.isEnabled(c.id));
        if (mounted) setState(() {});
      case 'reminder':
        await _pickReminder(c);
      case 'reminderOff':
        await LocalNotificationsService().setChallengeReminder(c.id, title: c.title, endAt: c.endAt);
        _snack(t.challengesReminderOff);
        if (mounted) setState(() {});
      case 'leave':
        final left = await confirmLeaveOrDeleteChallenge(context, c, service: _svc);
        if (left && mounted) Navigator.pop(context);
    }
  }

  /// Daily local "Log your progress" reminder at a time the user picks.
  Future<void> _pickReminder(Challenge c) async {
    final t = AppLocalizations.of(context)!;
    final notifications = LocalNotificationsService();
    if (!notifications.notificationsEnabled) {
      _snack(t.challengesReminderNeedsNotifications);
      return;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: notifications.challengeReminderTime(c.id) ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked == null || !mounted) return;
    final ok = await notifications.setChallengeReminder(c.id, title: c.title, endAt: c.endAt, time: picked);
    if (!mounted) return;
    _snack(ok ? t.challengesReminderSet(picked.format(context)) : t.challengesErrorNetwork);
    setState(() {});
  }

  // --- Build -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    return StreamBuilder<Challenge?>(
      stream: _challengeStream,
      initialData: widget.initial,
      builder: (context, snap) {
        final c = snap.data;
        final gone = snap.hasError ||
            (snap.connectionState == ConnectionState.active && c == null) ||
            (c != null && _uid != null && !c.memberUids.contains(_uid));
        if (c != null && !gone && !_privateLoaded) _loadPrivate(c);
        return Scaffold(
          backgroundColor: p.bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
            title: Text(gone || c == null ? t.challengesTitle : c.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.sp, color: p.text)),
            centerTitle: true,
            actions: [
              if (c != null && !gone) ...[
                IconButton(
                  tooltip: t.challengesInvite,
                  onPressed: () => _onMenu('invite', c, null),
                  icon: Icon(Iconsax.user_add, color: p.text),
                ),
                _menu(p, t, c),
              ],
            ],
          ),
          body: ReadableWidth(
            child: gone
                ? _notAvailable(p, t)
                : c == null
                    ? Center(child: CircularProgressIndicator(color: p.accent))
                    : StreamBuilder<List<ChallengeParticipant>>(
                        stream: _membersStream,
                        builder: (context, ms) {
                          _members = ms.data ?? _members;
                          _loadBadges(_members);
                          return _body(context, p, t, c, _members);
                        },
                      ),
          ),
        );
      },
    );
  }

  Widget _notAvailable(_Palette p, AppLocalizations t) => Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.info_circle, color: p.sub, size: 36.sp),
              SizedBox(height: 12.h),
              Text(t.challengesNotAvailable,
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, height: 1.5, color: p.sub)),
            ],
          ),
        ),
      );

  ChallengeParticipant? get _me => _members.where((m) => m.uid == _uid).firstOrNull;

  Widget _menu(_Palette p, AppLocalizations t, Challenge c) {
    final isCreator = c.creatorUid == _uid;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: p.text),
      color: p.card,
      onSelected: (v) => _onMenu(v, c, _me),
      // Built when opened: the members (and the reminder) load after the
      // app bar is first drawn.
      itemBuilder: (_) {
        final me = _me;
        final reminder = LocalNotificationsService().challengeReminderTime(c.id);
        return [
          PopupMenuItem(value: 'invite', child: Text(t.challengesInvite, style: TextStyle(color: p.text))),
          if (me != null)
            CheckedPopupMenuItem(
                value: 'mute', checked: me.muted, child: Text(t.challengesMute, style: TextStyle(color: p.text))),
          if (me != null && c.statusAt(DateTime.now()) != ChallengeStatus.finished) ...[
            PopupMenuItem(
              value: 'reminder',
              child: Text(
                reminder == null ? t.challengesReminder : '${t.challengesReminder}: ${reminder.format(context)}',
                style: TextStyle(color: p.text),
              ),
            ),
            if (reminder != null)
              PopupMenuItem(
                  value: 'reminderOff', child: Text(t.challengesReminderTurnOff, style: TextStyle(color: p.text))),
          ],
          if (c.itemKind != ChallengeItemKind.none)
            CheckedPopupMenuItem(
              value: 'auto',
              checked: ChallengeAutoProgress.isEnabled(c.id),
              child: Text(t.challengesAutoSuggest, style: TextStyle(color: p.text)),
            ),
          PopupMenuItem(
            value: 'leave',
            child:
                Text(isCreator ? t.challengesDelete : t.challengesLeave, style: TextStyle(color: Colors.red.shade400)),
          ),
        ];
      },
    );
  }

  Widget _body(BuildContext context, _Palette p, AppLocalizations t, Challenge c, List<ChallengeParticipant> members) {
    final now = DateTime.now();
    final me = members.where((m) => m.uid == _uid).firstOrNull;
    final byUid = {for (final m in members) m.uid: m};
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _header(p, t, c, me, now),
                    if (c.statusAt(now) == ChallengeStatus.finished) ...[
                      SizedBox(height: 12.h),
                      _summaryBanner(p, t, c, members),
                    ],
                    SizedBox(height: 18.h),
                    _sectionTitle(p, t.challengesMembersTitle),
                    SizedBox(height: 10.h),
                    _leaderboard(p, t, c, members),
                    SizedBox(height: 18.h),
                    _sectionTitle(p, t.challengesFeedTitle),
                    SizedBox(height: 10.h),
                  ]),
                ),
              ),
              _feedSliver(p, t, c, byUid),
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
            ],
          ),
        ),
        _composer(p, t, c, now),
      ],
    );
  }

  Widget _sectionTitle(_Palette p, String text) =>
      Text(text, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: p.accent));

  Widget _header(_Palette p, AppLocalizations t, Challenge c, ChallengeParticipant? me, DateTime now) {
    final tpl = templateFor(c.type);
    final percent = me?.percent ?? 0;
    final progress = me?.progress ?? _privateProgress ?? 0;
    final status = c.statusAt(now);
    return _card(
      p,
      child: Column(
        children: [
          Row(
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
                    Text(c.title, style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: p.text)),
                    SizedBox(height: 2.h),
                    Text('${challengeTypeLabel(c.type, t)} · ${t.challengesBy(c.creatorName)}',
                        style: TextStyle(fontSize: 12.sp, color: p.sub)),
                  ],
                ),
              ),
            ],
          ),
          if (c.intention.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: p.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Iconsax.heart, size: 15.sp, color: p.accent),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(c.intention,
                        style: TextStyle(fontSize: 13.sp, height: 1.45, fontStyle: FontStyle.italic, color: p.text)),
                  ),
                ],
              ),
            ),
          ],
          if (c.dedication.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _headerNote(p, Iconsax.lovely, t.certDedicated(c.dedication)),
          ],
          if (c.familyPromise.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _headerNote(p, Iconsax.gift, t.challengesPromiseLabel(c.familyPromise)),
          ],
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.timer_1, size: 15.sp, color: p.accent),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(_countdown(c, now, t),
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: p.text)),
                ),
              ],
            ),
          ),
          if (me != null) ...[
            SizedBox(height: 16.h),
            Semantics(
              label: t.challengesYourProgress('${percent.floor()}'),
              excludeSemantics: true,
              child: _ProgressRing(percent: percent, size: 128.w, strokeWidth: 10, fontSize: 26.sp),
            ),
            SizedBox(height: 8.h),
            Text(t.challengesProgressOf('$progress', '${c.target}', challengeUnitLabel(c.unit, t)),
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp, color: p.sub)),
            SizedBox(height: 14.h),
            _logButtons(p, t, c, me, status, now),
          ],
        ],
      ),
    );
  }

  Widget _logButtons(
      _Palette p, AppLocalizations t, Challenge c, ChallengeParticipant me, ChallengeStatus status, DateTime now) {
    Widget note(IconData icon, String text) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17.sp, color: p.accent),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(text,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: p.text)),
            ),
          ],
        );
    if (status == ChallengeStatus.upcoming) return note(Iconsax.calendar_1, t.challengesNotStarted);
    if (me.completedAt != null || me.percent >= 100) return note(Iconsax.tick_circle, t.challengesAllItemsDone);
    if (status == ChallengeStatus.finished) return const SizedBox.shrink();
    if (c.oncePerDay) {
      if (me.loggedDays.contains(challengeDayKey(now))) return note(Iconsax.tick_circle, t.challengesLoggedToday);
      return _primaryButton(p, t.challengesLogProgress, () => _addOne(c), icon: Iconsax.add_circle, busy: _busy);
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _busy ? null : () => _addOne(c),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: p.accent.withValues(alpha: 0.6)),
              padding: EdgeInsets.symmetric(vertical: 13.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
            child: Text('+1', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: p.text)),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          flex: 2,
          child: _primaryButton(p, t.challengesLogProgress, () => _openLogSheet(c), icon: Iconsax.add, busy: _busy),
        ),
      ],
    );
  }

  Widget _summaryBanner(_Palette p, AppLocalizations t, Challenge c, List<ChallengeParticipant> members) {
    final done = members.where((m) => m.completedAt != null || m.percent >= 100).length;
    return _card(
      p,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Iconsax.cup, color: p.accent, size: 26.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.challengesSummaryTitle,
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: p.text)),
                    Text(t.challengesSummaryCompleted('$done', '${members.length}'),
                        style: TextStyle(fontSize: 13.sp, color: p.sub)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _primaryButton(p, t.duaWallOpen, () => Get.to(() => DuaWallScreen(challenge: c, service: _svc)),
              icon: Iconsax.lovely),
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showChallengeSummary(context, c, members, service: _svc),
              icon: Icon(Iconsax.share, size: 17.sp, color: p.accent),
              label: Text(t.challengesShareResult, style: TextStyle(fontSize: 14.sp, color: p.text)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: p.accent.withValues(alpha: 0.5)),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerNote(_Palette p, IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15.sp, color: p.accent),
          SizedBox(width: 8.w),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13.sp, height: 1.4, color: p.text))),
        ],
      );

  /// Up to two of a member's badges (unless they hid them), beside their name.
  Widget _badgeIcons(_Palette p, String uid) {
    final ids = (_badges[uid] ?? const <String>[]).reversed.take(2).toList();
    if (ids.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 3.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final id in ids)
            if (badgeById(id) != null) Icon(badgeById(id)!.icon, size: 11.sp, color: p.accent),
        ],
      ),
    );
  }

  void _loadBadges(List<ChallengeParticipant> members) {
    final uids = members.map((m) => m.uid).toSet();
    if (uids.isEmpty || uids.every(_badgesRequested.contains)) return;
    _badgesRequested.addAll(uids);
    _svc.memberBadges(uids).then((found) {
      if (mounted) setState(() => _badges.addAll(found));
    });
  }

  Widget _leaderboard(_Palette p, AppLocalizations t, Challenge c, List<ChallengeParticipant> members) {
    if (members.isEmpty) return SizedBox(height: 60.h);
    final leader = members.first.percent > 0 ? members.first.uid : null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final m in members)
            Padding(
              padding: EdgeInsetsDirectional.only(end: 10.w),
              child: _memberChip(p, t, c, m, leader: m.uid == leader),
            ),
        ],
      ),
    );
  }

  Widget _memberChip(_Palette p, AppLocalizations t, Challenge c, ChallengeParticipant m, {required bool leader}) {
    final isMe = m.uid == _uid;
    final completed = m.completedAt != null || m.percent >= 100;
    final value = m.showExactNumbers && m.progress != null ? '${m.progress}/${c.target}' : '${m.percent.floor()}%';
    final name = isMe ? t.challengesYou : m.displayName;
    return Semantics(
      button: true,
      label: [name, value, if (leader) t.challengesLeader, if (completed) t.challengesCompletedLabel].join(', '),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () => _showMember(c, m),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          child: SizedBox(
            width: 68.w,
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 56.w,
                      height: 56.w,
                      child: CircularProgressIndicator(
                        value: (m.percent / 100).clamp(0.0, 1.0),
                        strokeWidth: 3.5,
                        backgroundColor: p.line,
                        color: p.accent,
                      ),
                    ),
                    _Avatar(name: m.displayName, uid: m.uid, size: 44.w),
                    if (leader)
                      Positioned(
                        top: -15.w,
                        child: Icon(Iconsax.crown_1, size: 18.sp, color: p.accent),
                      ),
                    if (completed)
                      PositionedDirectional(
                        bottom: -2,
                        end: -2,
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                          child: Icon(Icons.check, size: 12.sp, color: p.bg),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: p.text)),
                    ),
                    _badgeIcons(p, m.uid),
                  ],
                ),
                Text(value,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.sp, color: p.sub)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _feedSliver(_Palette p, AppLocalizations t, Challenge c, Map<String, ChallengeParticipant> byUid) {
    return StreamBuilder<List<ChallengeFeedItem>>(
      stream: _feedStream,
      builder: (context, fs) {
        final items = fs.data;
        if (items == null) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: fs.hasError
                  ? Text(t.challengesErrorNetwork,
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp, color: p.sub))
                  : Center(child: CircularProgressIndicator(color: p.accent)),
            ),
          );
        }
        if (items.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Text(t.challengesFeedEmpty,
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp, height: 1.5, color: p.sub)),
            ),
          );
        }
        final hasMore = items.length >= _feedLimit;
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverList.builder(
            itemCount: items.length + (hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == items.length) {
                return Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _feedLimit += ChallengeService.feedPageSize;
                      _feedStream = _svc.feed(widget.challengeId, limit: _feedLimit);
                    }),
                    icon: Icon(Iconsax.arrow_down_1, size: 16.sp, color: p.accent),
                    label: Text(t.challengesLoadOlder, style: TextStyle(fontSize: 13.sp, color: p.accent)),
                  ),
                );
              }
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _feedTile(context, p, t, c, items[i], byUid),
              );
            },
          ),
        );
      },
    );
  }

  Widget _feedTile(BuildContext context, _Palette p, AppLocalizations t, Challenge c, ChallengeFeedItem item,
      Map<String, ChallengeParticipant> byUid) {
    final mine = item.uid == _uid;
    final member = byUid[item.uid];
    final name = member?.displayName ?? (item.name.isNotEmpty ? item.name : '…');
    final lang = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final time = DateUtils.isSameDay(item.createdAt, now)
        ? DateFormat.jm(lang).format(item.createdAt)
        : DateFormat.MMMd(lang).add_jm().format(item.createdAt);

    final Widget body;
    var align = CrossAxisAlignment.start;
    switch (item.kind) {
      case FeedKind.message:
        align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
        body = _bubble(p, item, name, time, mine);
      case FeedKind.joined:
        align = CrossAxisAlignment.center;
        body = _pill(p, Iconsax.user_add, t.challengesFeedJoined(name));
      case FeedKind.nudge:
        align = CrossAxisAlignment.center;
        final target = byUid[item.targetUid]?.displayName ?? '…';
        body = _pill(p, Iconsax.notification_bing,
            item.targetUid == _uid ? t.challengesFeedNudgeYou(name) : t.challengesFeedNudge(name, target));
      case FeedKind.progress:
        body = _progressCard(p, item, _progressText(c, item, name, t), name, time);
      case FeedKind.completed:
        body = _completedCard(p, t, item, name, now);
      case FeedKind.unknown:
        return const SizedBox.shrink();
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _itemActions(c, item),
      child: Column(
        crossAxisAlignment: align,
        children: [
          body,
          _reactionsRow(p, t, c, item, align),
        ],
      ),
    );
  }

  Widget _bubble(_Palette p, ChallengeFeedItem item, String name, String time, bool mine) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.74;
    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!mine)
            Padding(
              padding: EdgeInsetsDirectional.only(start: 4.w, bottom: 3.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(name,
                        style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: p.accent)),
                  ),
                  _badgeIcons(p, item.uid),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: mine ? p.accent.withValues(alpha: 0.2) : p.card,
              border: mine ? null : Border.all(color: p.line),
              borderRadius: BorderRadiusDirectional.only(
                topStart: Radius.circular(16.r),
                topEnd: Radius.circular(16.r),
                bottomStart: Radius.circular(mine ? 16.r : 4.r),
                bottomEnd: Radius.circular(mine ? 4.r : 16.r),
              ),
            ),
            child: Text(item.text, style: TextStyle(fontSize: 14.sp, height: 1.4, color: p.text)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Text(time, style: TextStyle(fontSize: 10.5.sp, color: p.sub)),
          ),
        ],
      ),
    );
    if (mine) return bubble;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 16.h),
          child: _Avatar(name: name, uid: item.uid, size: 28.w),
        ),
        SizedBox(width: 6.w),
        Flexible(child: bubble),
      ],
    );
  }

  Widget _pill(_Palette p, IconData icon, String text) => Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(color: p.line.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20.r)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.sp, color: p.sub),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp, color: p.sub)),
            ),
          ],
        ),
      );

  Widget _progressCard(_Palette p, ChallengeFeedItem item, String text, String name, String time) => Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: p.line),
        ),
        child: Row(
          children: [
            _Avatar(name: name, uid: item.uid, size: 32.w),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: p.text)),
                  SizedBox(height: 2.h),
                  Text(time, style: TextStyle(fontSize: 10.5.sp, color: p.sub)),
                ],
              ),
            ),
            if (item.percent != null) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text('${item.percent!.floor()}%',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: p.text)),
              ),
            ],
          ],
        ),
      );

  Widget _completedCard(_Palette p, AppLocalizations t, ChallengeFeedItem item, String name, DateTime now) {
    final card = Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.accent.withValues(alpha: 0.3), p.accent.withValues(alpha: 0.08)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: p.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: p.accent,
            child: Icon(Iconsax.cup, color: p.bg, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(t.challengesFeedCompleted(name),
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: p.text)),
          ),
        ],
      ),
    );
    // A gentle grow-in for a completion that just happened.
    final fresh = now.difference(item.createdAt).inSeconds.abs() < 30;
    if (!fresh || MediaQuery.disableAnimationsOf(context)) return card;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, v, child) =>
          Opacity(opacity: v.clamp(0.0, 1.0), child: Transform.scale(scale: 0.9 + 0.1 * v, child: child)),
      child: card,
    );
  }

  Widget _reactionsRow(_Palette p, AppLocalizations t, Challenge c, ChallengeFeedItem item, CrossAxisAlignment align) {
    final uid = _uid ?? '';
    final used = [
      for (final key in challengeReactionKeys)
        if (item.reactionCount(key) > 0) key
    ];
    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Wrap(
        alignment: switch (align) {
          CrossAxisAlignment.end => WrapAlignment.end,
          CrossAxisAlignment.center => WrapAlignment.center,
          _ => WrapAlignment.start,
        },
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6.w,
        runSpacing: 4.h,
        children: [
          for (final key in used)
            _reactionChip(
                p, t, key, item.reactionCount(key), item.reactedBy(uid, key), () => _toggleReaction(c, item, key)),
          Semantics(
            button: true,
            label: t.challengesReact,
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: () => _itemActions(c, item),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Icon(Iconsax.emoji_happy, size: 16.sp, color: p.sub.withValues(alpha: 0.7)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reactionChip(_Palette p, AppLocalizations t, String key, int count, bool mine, VoidCallback onTap,
      {bool large = false}) {
    final label = _reactionLabel(key, t);
    return Semantics(
      button: true,
      selected: mine,
      label: count > 0 ? '$label, $count' : label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: large ? 12.w : 8.w, vertical: large ? 8.h : 4.h),
          decoration: BoxDecoration(
            color: mine ? p.accent.withValues(alpha: 0.22) : p.card,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: mine ? p.accent.withValues(alpha: 0.6) : p.line),
          ),
          child: Text(count > 0 ? '$label $count' : label,
              style: TextStyle(fontSize: large ? 14.sp : 12.sp, fontWeight: FontWeight.w600, color: p.text)),
        ),
      ),
    );
  }

  Widget _composer(_Palette p, AppLocalizations t, Challenge c, DateTime now) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Material(
      color: p.card,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(6.w, 6.h, 6.w, 6.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: t.challengesNudge,
                onPressed: c.statusAt(now) == ChallengeStatus.active ? () => _openNudgeSheet(c) : null,
                icon: Icon(Iconsax.notification_bing, color: p.accent),
              ),
              Expanded(
                child: TextField(
                  controller: _message,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: ChallengeService.maxMessageLength,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(fontSize: 14.sp, color: p.text),
                  decoration: InputDecoration(
                    hintText: t.challengesMessageHint,
                    hintStyle: TextStyle(fontSize: 14.sp, color: p.sub),
                    isDense: true,
                    filled: true,
                    fillColor: p.bg,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.r), borderSide: BorderSide.none),
                  ),
                ),
              ),
              IconButton(
                tooltip: t.challengesSend,
                onPressed: _sending ? null : () => _send(c),
                icon: Transform.flip(flipX: rtl, child: Icon(Iconsax.send_1, color: p.accent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How many items a challenge's picker shows (Juz, Mushaf pages, ayahs).
int _itemCount(Challenge c) => switch (c.itemKind) {
      ChallengeItemKind.juz => 30,
      ChallengeItemKind.pages => 604,
      ChallengeItemKind.ayahs => quran.getVerseCount(c.surah ?? 1),
      ChallengeItemKind.none => 0,
    };

class _LogRequest {
  final int amount;
  final List<int> items;

  const _LogRequest({this.amount = 0, this.items = const []});
}

/// "Log progress": a number, or which Juz / pages / ayahs were done.
/// Ticked items stay ticked (progress only goes up).
class _LogSheet extends StatefulWidget {
  final Challenge challenge;
  final MyChallengeProgress mine;
  final int itemCount;

  const _LogSheet({required this.challenge, required this.mine, required this.itemCount});

  @override
  State<_LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends State<_LogSheet> {
  final _selected = <int>{};
  final _amount = TextEditingController();
  late final _from = TextEditingController();
  late final _to = TextEditingController();

  Challenge get c => widget.challenge;
  int get _remaining => max(0, c.target - widget.mine.progress);

  @override
  void initState() {
    super.initState();
    if (c.itemKind == ChallengeItemKind.pages) {
      var next = 1;
      while (next < 604 && widget.mine.items.contains(next)) {
        next++;
      }
      _from.text = '$next';
      _to.text = '${min(604, next + 19)}';
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  List<int> get _pageRange {
    final from = int.tryParse(_from.text) ?? 0;
    final to = int.tryParse(_to.text) ?? 0;
    if (from < 1 || to < from || to > 604) return const [];
    return [
      for (var i = from; i <= to; i++)
        if (!widget.mine.items.contains(i)) i
    ];
  }

  _LogRequest? get _request {
    switch (c.itemKind) {
      case ChallengeItemKind.none:
        final n = int.tryParse(_amount.text) ?? 0;
        return n > 0 ? _LogRequest(amount: min(n, _remaining)) : null;
      case ChallengeItemKind.pages:
        final pages = _pageRange;
        return pages.isEmpty ? null : _LogRequest(items: pages);
      case ChallengeItemKind.juz:
      case ChallengeItemKind.ayahs:
        return _selected.isEmpty ? null : _LogRequest(items: _selected.toList()..sort());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette(context);
    final request = _request;
    final kind = c.itemKind;
    final title = switch (kind) {
      ChallengeItemKind.juz => t.challengesPickJuz,
      ChallengeItemKind.pages => t.challengesPickPages,
      ChallengeItemKind.ayahs => t.challengesPickAyahs,
      ChallengeItemKind.none => t.challengesAmount,
    };
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(2.r)),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: p.text)),
                SizedBox(height: 4.h),
                Text(t.challengesProgressOf('${widget.mine.progress}', '${c.target}', challengeUnitLabel(c.unit, t)),
                    style: TextStyle(fontSize: 12.5.sp, color: p.sub)),
                SizedBox(height: 12.h),
                if (kind == ChallengeItemKind.none) _amountInput(p, t),
                if (kind == ChallengeItemKind.pages) _pagesInput(p, t),
                if (kind == ChallengeItemKind.juz || kind == ChallengeItemKind.ayahs)
                  Flexible(child: _grid(p, kind == ChallengeItemKind.juz ? 5 : 6)),
                SizedBox(height: 14.h),
                _primaryButton(p, t.challengesSave, request == null ? null : () => Navigator.pop(context, request)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountInput(_Palette p, AppLocalizations t) {
    final quick = c.type == ChallengeType.dhikr ? const [33, 100, 500, 1000] : const [1, 2, 5, 10];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _amount,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: p.text),
          decoration: _fieldDecoration(p, t.challengesTarget, suffix: challengeUnitLabel(c.unit, t))
              .copyWith(labelText: null, hintText: '0'),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final n in quick)
              ActionChip(
                label: Text('+$n', style: TextStyle(fontSize: 13.sp, color: p.text)),
                backgroundColor: p.bg,
                side: BorderSide(color: p.line),
                onPressed: () => setState(() => _amount.text = '${(int.tryParse(_amount.text) ?? 0) + n}'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _pagesInput(_Palette p, AppLocalizations t) {
    final count = _pageRange.length;
    Widget field(TextEditingController controller, String label) => Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
            onChanged: (_) => setState(() {}),
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: p.text),
            decoration: _fieldDecoration(p, label),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            field(_from, t.challengesFromPage),
            SizedBox(width: 10.w),
            field(_to, t.challengesToPage),
          ],
        ),
        SizedBox(height: 8.h),
        Text('+$count ${challengeUnitLabel(c.unit, t)}', style: TextStyle(fontSize: 13.sp, color: p.accent)),
      ],
    );
  }

  Widget _grid(_Palette p, int columns) {
    return GridView.builder(
      shrinkWrap: true,
      itemCount: widget.itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, i) {
        final n = i + 1;
        final done = widget.mine.items.contains(n);
        final selected = _selected.contains(n);
        // No more picks than the target allows.
        final full = !selected && _selected.length >= _remaining;
        return Semantics(
          button: true,
          selected: done || selected,
          child: InkWell(
            borderRadius: BorderRadius.circular(10.r),
            onTap: done || full ? null : () => setState(() => selected ? _selected.remove(n) : _selected.add(n)),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done
                    ? p.accent.withValues(alpha: 0.35)
                    : selected
                        ? p.accent
                        : p.bg,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: selected || done ? p.accent : p.line),
              ),
              child: done
                  ? Icon(Icons.check, size: 16.sp, color: p.text)
                  : Text('$n',
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: selected ? p.bg : (full ? p.sub.withValues(alpha: 0.5) : p.text))),
            ),
          ),
        );
      },
    );
  }
}
