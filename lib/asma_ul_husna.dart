import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:allah_everywhere/controllers/language_controller.dart';
import 'package:allah_everywhere/data/asma_ul_husna_data.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/models/bookmark.dart';
import 'package:allah_everywhere/services/bookmark_service.dart';
import 'package:allah_everywhere/share_cards/share_content.dart';
import 'package:allah_everywhere/share_cards/share_studio_screen.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/theme/scripture_text.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';
import 'package:allah_everywhere/widgets/pressable_tile.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

String _languageCode() => Get.isRegistered<LanguageController>()
    ? Get.find<LanguageController>().locale.value.languageCode
    : 'en';

/// Meanings in Urdu are set in Nastaliq, like every other Urdu text.
TextStyle _meaningStyle(String languageCode, double fontSize, Color color, {FontWeight? fontWeight}) {
  return languageCode == 'ur'
      ? ScriptureText.urdu(fontSize: fontSize, color: color, fontWeight: fontWeight)
      : TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight, height: 1.35);
}

/// Strips harakat so an Arabic search matches with or without tashkeel.
String _stripTashkeel(String s) => s.replaceAll(RegExp('[ؐ-ًؚ-ٰٟۖ-ۭ]'), '');

/// Asma-ul-Husna: all 99 Names in a searchable grid.
class AsmaUlHusnaScreen extends StatefulWidget {
  const AsmaUlHusnaScreen({super.key});

  @override
  State<AsmaUlHusnaScreen> createState() => _AsmaUlHusnaScreenState();
}

class _AsmaUlHusnaScreenState extends State<AsmaUlHusnaScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DivineName> _filtered(String languageCode) {
    final q = foldForSearch(_query.trim());
    if (q.isEmpty) return asmaUlHusna;
    final arabicQuery = _stripTashkeel(_query.trim());
    return asmaUlHusna.where((name) {
      return foldForSearch(name.transliteration).contains(q) ||
          foldForSearch(name.meaning).contains(q) ||
          foldForSearch(divineNameMeaning(name, languageCode)).contains(q) ||
          _stripTashkeel(name.arabic).contains(arabicQuery) ||
          name.number.toString() == q;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;
    final names = _filtered(languageCode);
    // Room for the Arabic, transliteration and a 2-line meaning at the
    // largest supported text size (1.3x).
    final tileExtent = MediaQuery.textScalerOf(context).scale(150.h) + 16.h;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(t.asmaUlHusnaTitle,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19.sp, color: textColor)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: ReadableWidth(
        maxWidth: 1000,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      textInputAction: TextInputAction.search,
                      style: TextStyle(fontSize: 14.sp, color: textColor),
                      decoration: InputDecoration(
                        hintText: t.asmaSearchHint,
                        hintStyle: TextStyle(fontSize: 14.sp, color: subColor),
                        prefixIcon: Icon(Iconsax.search_normal_1, color: accent, size: 18.sp),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(Icons.close, color: subColor, size: 18.sp),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                        filled: true,
                        fillColor: cardColor,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      t.asmaSourceNote(asmaUlHusnaReference, asmaUlHusnaCountReference),
                      style: TextStyle(fontSize: 11.sp, height: 1.4, color: subColor),
                    ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            ),
            if (names.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Text(t.asmaNoResults,
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: subColor)),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, navBarClearance(context) + 24.h),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWideLayout(context) ? 4 : 2,
                    mainAxisSpacing: 12.h,
                    crossAxisSpacing: 12.w,
                    mainAxisExtent: tileExtent,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _NameCard(
                      name: names[index],
                      languageCode: languageCode,
                      isDark: isDark,
                      accent: accent,
                      textColor: textColor,
                      subColor: subColor,
                      cardColor: cardColor,
                    ),
                    childCount: names.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  final DivineName name;
  final String languageCode;
  final bool isDark;
  final Color accent;
  final Color textColor;
  final Color subColor;
  final Color cardColor;

  const _NameCard({
    required this.name,
    required this.languageCode,
    required this.isDark,
    required this.accent,
    required this.textColor,
    required this.subColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final meaning = divineNameMeaning(name, languageCode);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: PressableTile(
        color: cardColor,
        borderRadius: BorderRadius.circular(18.r),
        semanticLabel: '${name.number}. ${name.transliteration}, $meaning',
        onTap: () => Get.to(() => AsmaUlHusnaDetailScreen(name: name)),
        child: Container(
          padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.topStart,
                child: _NumberBadge(number: name.number, accent: accent, size: 24.r),
              ),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      name.arabic,
                      textDirection: TextDirection.rtl,
                      style: ScriptureText.arabic(fontSize: 28.sp, color: textColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              Text(
                name.transliteration,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: accent),
              ),
              SizedBox(height: 2.h),
              Text(
                meaning,
                maxLines: languageCode == 'ur' ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: _meaningStyle(languageCode, 11.5.sp, subColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int number;
  final Color accent;
  final double size;

  const _NumberBadge({required this.number, required this.accent, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), shape: BoxShape.circle),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Text('$number', style: TextStyle(fontWeight: FontWeight.w700, color: accent)),
        ),
      ),
    );
  }
}

/// One Name in full: Arabic, meaning, explanation, and Bookmark / Share /
/// Copy actions.
class AsmaUlHusnaDetailScreen extends StatefulWidget {
  final DivineName name;

  const AsmaUlHusnaDetailScreen({super.key, required this.name});

  @override
  State<AsmaUlHusnaDetailScreen> createState() => _AsmaUlHusnaDetailScreenState();
}

class _AsmaUlHusnaDetailScreenState extends State<AsmaUlHusnaDetailScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  bool _isBookmarked = false;

  String get _refId => '${widget.name.number}';

  @override
  void initState() {
    super.initState();
    _loadBookmarkState();
  }

  Future<void> _loadBookmarkState() async {
    final bookmarked = await _bookmarkService.isBookmarked(BookmarkType.divineName, _refId);
    if (mounted) setState(() => _isBookmarked = bookmarked);
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.lightImpact();
    final name = widget.name;
    try {
      final bookmarked = await _bookmarkService.toggle(
          BookmarkType.divineName, _refId, name.transliteration, '${name.arabic} · ${name.meaning}');
      if (mounted) setState(() => _isBookmarked = bookmarked);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.bookmarkUpdateFailed)));
      }
    }
  }

  Future<void> _copy(String meaning) async {
    final name = widget.name;
    await Clipboard.setData(ClipboardData(
      text: '${name.arabic}\n${name.transliteration} - $meaning\n($asmaUlHusnaReference)',
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.copied)));
    }
  }

  void _share() {
    Get.to(() => ShareStudioScreen(initialContent: ShareContent.fromDivineName(widget.name, _languageCode())));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final name = widget.name;
    final languageCode = Localizations.localeOf(context).languageCode;
    final meaning = divineNameMeaning(name, languageCode);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade700;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(name.transliteration,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: textColor)),
        centerTitle: true,
      ),
      body: ReadableWidth(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, navBarClearance(context) + 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [VoidColors.cardDark, VoidColors.oliveDeep]
                        : [VoidColors.oliveDeep, VoidColors.dustyRose],
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Column(
                  children: [
                    _NumberBadge(number: name.number, accent: VoidColors.goldDark, size: 34.r),
                    SizedBox(height: 8.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        name.arabic,
                        textDirection: TextDirection.rtl,
                        style: ScriptureText.arabic(fontSize: 52.sp, color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      name.transliteration,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: VoidColors.goldDark),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      meaning,
                      textAlign: TextAlign.center,
                      style: _meaningStyle(languageCode, 15.sp, Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: _isBookmarked ? Iconsax.archive_tick : Iconsax.archive_add,
                      label: _isBookmarked ? t.bookmarked : t.bookmark,
                      onTap: _toggleBookmark,
                      accent: accent,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _ActionButton(
                      icon: Iconsax.share,
                      label: t.share,
                      onTap: _share,
                      accent: accent,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _ActionButton(
                      icon: Iconsax.copy,
                      label: t.copy,
                      onTap: () => _copy(meaning),
                      accent: accent,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Text(t.asmaAboutName, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: textColor)),
              SizedBox(height: 8.h),
              Text(name.explanation, style: TextStyle(fontSize: 14.sp, height: 1.5, color: subColor)),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.book_1, color: accent, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        asmaUlHusnaReference,
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: accent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accent;
  final Color cardColor;
  final Color textColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accent,
    required this.cardColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return PressableTile(
      color: cardColor,
      borderRadius: BorderRadius.circular(14.r),
      semanticLabel: label,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 22.sp),
            SizedBox(height: 6.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
