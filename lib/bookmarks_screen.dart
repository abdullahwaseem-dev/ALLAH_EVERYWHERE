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
    }
  }

  void _open(Bookmark bookmark) {
    switch (bookmark.type) {
      case BookmarkType.surah:
        final parts = bookmark.refId.split('|');
        final surahId = int.tryParse(parts.first) ?? 1;
        Get.to(() => SurahScreen(surahName: bookmark.title, surahId: surahId));
        break;
      case BookmarkType.hadith:
        final parts = bookmark.refId.split('|');
        if (parts.length >= 2) {
          Get.to(() => HidthChaptersScreen(bookSlug: parts[0], bookNameInArabic: parts[1]));
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
          Get.to(() => Dua2Screen(category: category));
        } else {
          Get.to(() => DuaDetailScreen(
                dua: category.duas[duaIndex],
                index: duaIndex + 1,
                total: category.duas.length,
                categoryTitle: category.title,
              ));
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarks', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _bookmarks == null
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks!.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Text(
                      'No bookmarks yet. Tap the bookmark icon on a Surah, Hadith, or Dua to save it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    itemCount: _bookmarks!.length,
                    itemBuilder: (context, index) {
                      final bookmark = _bookmarks![index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4.h),
                        child: ListTile(
                          leading: Icon(_iconFor(bookmark.type), color: VoidColors.brown),
                          title: Text(bookmark.title, style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: bookmark.subtitle.isNotEmpty ? Text(bookmark.subtitle) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              await _service.remove(bookmark.id);
                              _load();
                            },
                          ),
                          onTap: () => _open(bookmark),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
