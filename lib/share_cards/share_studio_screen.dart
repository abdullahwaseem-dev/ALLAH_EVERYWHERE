import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/controllers/language_controller.dart';
import 'package:allah_everywhere/services/app_share_service.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

import 'mood_data.dart';
import 'share_backgrounds.dart';
import 'share_card.dart';
import 'share_content.dart';
import 'share_strings.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';

enum _KindFilter { all, quran, hadith }

/// "Share a Reminder": the user picks how they feel, gets matching Quran
/// ayat and Hadith, dresses one up on a background, and shares it as an
/// image to WhatsApp Status, Instagram, or anywhere else.
///
/// Pass [initialContent] to open with a specific ayah/hadith (e.g. from the
/// Hadith reader) instead of a mood's content.
class ShareStudioScreen extends StatefulWidget {
  final ShareContent? initialContent;

  const ShareStudioScreen({super.key, this.initialContent});

  @override
  State<ShareStudioScreen> createState() => _ShareStudioScreenState();
}

class _ShareStudioScreenState extends State<ShareStudioScreen> {
  final _captureKey = GlobalKey();
  final _random = math.Random();

  late String _lang;
  late ShareStrings _s;

  Mood? _mood;

  /// True while showing [ShareStudioScreen.initialContent] rather than a
  /// mood's list; picking a mood switches to that mood's content.
  bool _fromInitial = false;
  _KindFilter _filter = _KindFilter.all;
  List<ShareContent> _items = [];
  int _index = 0;

  ShareFormat _format = ShareFormat.story;
  bool _darkBackgrounds = false;
  ShareBackground _background = shareBackgrounds.first;
  bool _showArabic = true;
  bool _showTranslation = true;
  bool _sharing = false;

  ShareIdentity _identity = const ShareIdentity(name: AppLinks.appName);

  @override
  void initState() {
    super.initState();
    _lang = Get.isRegistered<LanguageController>()
        ? Get.find<LanguageController>().locale.value.languageCode
        : 'en';
    _s = ShareStrings(_lang);
    if (widget.initialContent != null) {
      _items = [widget.initialContent!];
      _fromInitial = true;
    } else {
      _selectMood(moods.first);
    }
    _loadIdentity();
  }

  /// Uses the same sources as the Profile screen: the Firestore profile
  /// first, then the Firebase Auth account. Guests keep the app identity.
  Future<void> _loadIdentity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String? name = user.displayName?.trim();
    String? photoUrl = user.photoURL;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));
      final data = doc.data() ?? const <String, dynamic>{};
      final docName = (data['name'] as String?)?.trim();
      if (docName != null && docName.isNotEmpty) name = docName;
      final docPic = data['profilePicture'] as String?;
      if (docPic != null && docPic.isNotEmpty) photoUrl = docPic;
    } catch (_) {
      // Offline or slow: fall back to the auth profile.
    }

    ImageProvider? photo;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      final provider = NetworkImage(photoUrl);
      // Resolve it now: an image still loading when the card is captured
      // would export as a blank circle. On failure the app logo is used.
      try {
        if (mounted) await precacheImage(provider, context).timeout(const Duration(seconds: 8));
        photo = provider;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _identity = ShareIdentity(
        name: (name != null && name.isNotEmpty) ? name : (user.email ?? AppLinks.appName),
        photo: photo,
      );
    });
  }

  void _selectMood(Mood mood) {
    _mood = mood;
    _fromInitial = false;
    _rebuildItems();
  }

  void _rebuildItems() {
    final mood = _mood;
    if (mood == null) return;
    final ayat = _filter == _KindFilter.hadith
        ? <ShareContent>[]
        : mood.ayat.map((r) => ShareContent.fromQuran(r, _lang)).toList();
    final hadith = _filter == _KindFilter.quran
        ? <ShareContent>[]
        : mood.hadith.map((h) => ShareContent.fromHadith(h, _lang)).toList();
    // Alternate ayah / hadith so "Another" moves between both.
    final merged = <ShareContent>[];
    for (int i = 0; i < math.max(ayat.length, hadith.length); i++) {
      if (i < ayat.length) merged.add(ayat[i]);
      if (i < hadith.length) merged.add(hadith[i]);
    }
    _items = merged;
    _index = merged.isEmpty ? 0 : _random.nextInt(merged.length);
  }

  void _next() {
    if (_items.length < 2) return;
    setState(() => _index = (_index + 1) % _items.length);
  }

  Future<void> _share(BuildContext buttonContext) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      // Let the button's pressed state paint before the (synchronous-ish)
      // rasterisation work starts.
      await Future<void>.delayed(const Duration(milliseconds: 16));
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Card not laid out');
      final image = await boundary.toImage(pixelRatio: 1080 / _format.logicalSize.width);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) throw StateError('PNG encoding failed');
      if (!buttonContext.mounted) return;
      // Image only: the store badges are already on the card, and adding
      // text makes some targets (Instagram, WhatsApp Status) drop the image
      // or treat the share as a document.
      final ok = await AppShareService.shareImage(buttonContext, bytes.buffer.asUint8List());
      if (!ok && mounted) _snack(_s.shareFailed);
    } catch (e) {
      VoidLogger.error('Failed to build share image', e);
      if (mounted) _snack(_s.shareFailed);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;
    final content = _items.isEmpty ? null : _items[_index.clamp(0, _items.length - 1)];

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(_s.title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18.sp)),
        centerTitle: true,
      ),
      body: ReadableWidth(child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 40.h),
          children: [
            _label(_s.feeling, textColor),
            SizedBox(height: 8.h),
            SizedBox(
              height: 38.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: moods.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (_, i) {
                  final mood = moods[i];
                  final selected = !_fromInitial && _mood?.id == mood.id;
                  return ChoiceChip(
                    label: Text('${mood.emoji}  ${mood.labelFor(_lang)}'),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectMood(mood)),
                    selectedColor: accent,
                    backgroundColor: cardColor,
                    labelStyle: TextStyle(fontSize: 12.5.sp, color: selected ? Colors.white : textColor),
                    showCheckmark: false,
                    side: BorderSide(color: accent.withValues(alpha: 0.35)),
                  );
                },
              ),
            ),
            if (_mood != null) ...[
              SizedBox(height: 10.h),
              _segmented<_KindFilter>(
                value: _filter,
                options: {_KindFilter.all: _s.all, _KindFilter.quran: _s.quran, _KindFilter.hadith: _s.hadith},
                onChanged: (v) => setState(() {
                  _filter = v;
                  _rebuildItems();
                }),
                accent: accent,
                textColor: textColor,
                cardColor: cardColor,
              ),
            ],
            SizedBox(height: 14.h),
            if (content != null) _preview(content, accent, subColor),
            SizedBox(height: 10.h),
            if (_items.length > 1)
              Center(
                child: TextButton.icon(
                  onPressed: _next,
                  icon: Icon(Icons.autorenew, color: accent),
                  label: Text('${_s.another}  (${_index + 1}/${_items.length})',
                      style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
                ),
              ),
            SizedBox(height: 6.h),
            _label(_s.format, textColor),
            SizedBox(height: 8.h),
            _segmented<ShareFormat>(
              value: _format,
              options: {ShareFormat.story: _s.story, ShareFormat.post: _s.post, ShareFormat.square: _s.square},
              onChanged: (v) => setState(() => _format = v),
              accent: accent,
              textColor: textColor,
              cardColor: cardColor,
            ),
            SizedBox(height: 4.h),
            Text(
              switch (_format) {
                ShareFormat.story => _s.storyHint,
                ShareFormat.post => _s.postHint,
                ShareFormat.square => _s.squareHint,
              },
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5.sp, color: subColor),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(child: _label(_s.background, textColor)),
                _segmented<bool>(
                  value: _darkBackgrounds,
                  options: {false: _s.light, true: _s.dark},
                  onChanged: (v) => setState(() => _darkBackgrounds = v),
                  accent: accent,
                  textColor: textColor,
                  cardColor: cardColor,
                  compact: true,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            _backgroundPicker(accent),
            SizedBox(height: 16.h),
            _label(_s.show, textColor),
            SizedBox(height: 4.h),
            Row(
              children: [
                Expanded(
                  // At least one of the two stays on, so the card is never empty.
                  child: _toggle(
                    _s.arabic,
                    _showArabic,
                    content == null || content.translation.isEmpty
                        ? null
                        : (v) => setState(() {
                              _showArabic = v;
                              if (!v) _showTranslation = true;
                            }),
                    accent,
                    textColor,
                  ),
                ),
                Expanded(
                  child: _toggle(
                    _s.translation,
                    _showTranslation && content != null && content.translation.isNotEmpty,
                    content == null || content.translation.isEmpty
                        ? null
                        : (v) => setState(() {
                              _showTranslation = v;
                              if (!v) _showArabic = true;
                            }),
                    accent,
                    textColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Builder(
              builder: (buttonContext) => SizedBox(
                height: 50.h,
                child: ElevatedButton.icon(
                  onPressed: content == null || _sharing ? null : () => _share(buttonContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 0,
                  ),
                  icon: _sharing
                      ? SizedBox(width: 18.w, height: 18.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.ios_share),
                  label: Text(_s.share, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(_s.shareTip, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5.sp, color: subColor)),
          ],
        ),
      )),
    );
  }

  Widget _preview(ShareContent content, Color accent, Color subColor) {
    final size = _format.logicalSize;
    final maxHeight = 0.58.sh;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: AspectRatio(
          aspectRatio: size.width / size.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.r),
            child: FittedBox(
              child: RepaintBoundary(
                key: _captureKey,
                child: ShareCard(
                  content: content,
                  background: _background,
                  format: _format,
                  identity: _identity,
                  showArabic: _showArabic || !_showTranslation || content.translation.isEmpty,
                  showTranslation: _showTranslation,
                  downloadLabel: _s.download,
                  kindLabel: switch (content.kind) {
                    ShareContentKind.quran => _s.quran,
                    ShareContentKind.hadith => _s.hadith,
                    ShareContentKind.divineName => _s.divineName,
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _backgroundPicker(Color accent) {
    final options = shareBackgrounds.where((b) => b.isDark == _darkBackgrounds).toList();
    return SizedBox(
      height: 92.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (_, i) {
          final bg = options[i];
          final selected = bg.id == _background.id;
          return GestureDetector(
            onTap: () => setState(() => _background = bg),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 52.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: selected ? accent : Colors.transparent, width: 2.5),
              ),
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9.r),
                // Painted at card scale then shrunk, so thumbnails show the
                // same motif density as the real card.
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(width: 180, height: 320, child: ShareBackgroundView(background: bg)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text, Color color) {
    return Text(text, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: color));
  }

  Widget _toggle(String label, bool value, ValueChanged<bool>? onChanged, Color accent, Color textColor) {
    return Row(
      children: [
        Switch.adaptive(value: value, onChanged: onChanged, activeTrackColor: accent),
        SizedBox(width: 4.w),
        Flexible(child: Text(label, style: TextStyle(fontSize: 13.sp, color: textColor))),
      ],
    );
  }

  Widget _segmented<T>({
    required T value,
    required Map<T, String> options,
    required ValueChanged<T> onChanged,
    required Color accent,
    required Color textColor,
    required Color cardColor,
    bool compact = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12.r)),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          for (final entry in options.entries)
            _maybeExpanded(
              !compact,
              GestureDetector(
                onTap: () => onChanged(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: entry.key == value ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: Text(
                    entry.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: entry.key == value ? Colors.white : textColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _maybeExpanded(bool expand, Widget child) => expand ? Expanded(child: child) : child;
}
