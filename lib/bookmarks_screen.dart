import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/models/bookmark.dart';
import 'package:allah_everywhere/services/bookmark_service.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/surah.dart';
import 'package:allah_everywhere/hadith_chapters.dart';
import 'package:allah_everywhere/data/dua_data.dart';
import 'package:allah_everywhere/dua_2.dart';
import 'package:allah_everywhere/duadetail.dart';
import 'package:allah_everywhere/asma_ul_husna.dart';
import 'package:allah_everywhere/mushaf.dart';
import 'package:allah_everywhere/prophet_stories.dart';
import 'package:allah_everywhere/services/prophet_stories_service.dart';
import 'package:allah_everywhere/data/asma_ul_husna_data.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final BookmarkService _service = BookmarkService();
  List<Bookmark>? _bookmarks;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bookmarks = await _service.list();
    if (!mounted) return;
    setState(() => _bookmarks = bookmarks);
  }

  IconData _iconFor(BookmarkType type) {
    switch (type) {
      case BookmarkType.surah:
        return Icons.menu_book;
      case BookmarkType.hadith:
        return Icons.book;
      case BookmarkType.dua:
        return Icons.favorite;
      case BookmarkType.divineName:
        return Icons.auto_awesome;
      case BookmarkType.mushafPage:
        return Icons.auto_stories;
      case BookmarkType.prophetStory:
        return Icons.history_edu;
    }
  }

  Future<void> _delete(Bookmark bookmark) async {
    try {
      await _service.remove(bookmark.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove the bookmark. Please try again.')),
        );
      }
    }
    await _load();
  }

  /// Opens the bookmarked item, then reloads on return - the user may have
  /// un-bookmarked it there.
  Future<void> _open(Bookmark bookmark) async {
    await _openTarget(bookmark);
    if (mounted) await _load();
  }

  Future<void> _openTarget(Bookmark bookmark) async {
    switch (bookmark.type) {
      case BookmarkType.surah:
        final parts = bookmark.refId.split('|');
        final surahId = int.tryParse(parts.first) ?? 1;
        await Get.to(() => SurahScreen(surahName: bookmark.title, surahId: surahId));
        break;
      case BookmarkType.hadith:
        final parts = bookmark.refId.split('|');
        if (parts.length >= 2) {
          await Get.to(() => HidthChaptersScreen(bookSlug: parts[0], bookNameInArabic: parts[1]));
        }
        break;
      case BookmarkType.dua:
        final parts = bookmark.refId.split('|');
        if (parts.length < 2) return;
        final category = duaCategories.firstWhere(
          (c) => c.title == parts[0],
          orElse: () => duaCategories.first,
        );
        final duaIndex = category.duas.indexWhere((d) => d.title == parts[1]);
        if (duaIndex == -1) {
          await Get.to(() => Dua2Screen(category: category));
        } else {
          await Get.to(() => DuaDetailScreen(
                dua: category.duas[duaIndex],
                index: duaIndex + 1,
                total: category.duas.length,
                categoryTitle: category.title,
              ));
        }
        break;
      case BookmarkType.divineName:
        final number = int.tryParse(bookmark.refId);
        if (number == null || number < 1 || number > asmaUlHusna.length) return;
        await Get.to(() => AsmaUlHusnaDetailScreen(name: asmaUlHusna[number - 1]));
        break;
      case BookmarkType.mushafPage:
        final page = int.tryParse(bookmark.refId);
        if (page == null || page < 1 || page > 604) return;
        await Get.to(() => MushafScreen(initialPage: page));
        break;
      case BookmarkType.prophetStory:
        final parts = bookmark.refId.split('|');
        final prophets = await ProphetStoriesService().loadIndex();
        final index = prophets.indexWhere((p) => p.id == parts.first);
        if (index == -1) return;
        final chapter = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
        await Get.to(() => ProphetStoryReaderScreen(entry: prophets[index], initialChapter: chapter));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(t.bookmarksTitle, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: textColor)),
        centerTitle: true,
      ),
      body: ReadableWidth(child: _bookmarks == null
          ? Center(child: CircularProgressIndicator(color: accent))
          : _bookmarks!.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Text(
                      t.noBookmarksYet,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp, color: isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: accent,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    itemCount: _bookmarks!.length,
                    itemBuilder: (context, index) {
                      final bookmark = _bookmarks![index];
                      return Card(
                        color: cardColor,
                        margin: EdgeInsets.symmetric(vertical: 4.h),
                        child: ListTile(
                          leading: Icon(_iconFor(bookmark.type), color: accent),
                          title: Text(bookmark.title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                          subtitle: bookmark.subtitle.isNotEmpty
                              ? Text(bookmark.subtitle, style: TextStyle(color: isDark ? VoidColors.textDarkSecondary : null))
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _delete(bookmark),
                          ),
                          onTap: () => _open(bookmark),
                        ),
                      );
                    },
                  ),
                )),
    );
  }
}
