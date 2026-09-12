import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/controller/QuranController.dart';
import 'package:allah_everywhere/controller/HadithController.dart';
import 'package:allah_everywhere/data/dua_data.dart';
import 'package:allah_everywhere/surah.dart';
import 'package:allah_everywhere/hadith_chapters.dart';
import 'package:allah_everywhere/dua_2.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  late final QuranController _quranController;
  late final HadithController _hadithController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _quranController = Get.isRegistered<QuranController>() ? Get.find() : Get.put(QuranController());
    _hadithController = Get.isRegistered<HadithController>() ? Get.find() : Get.put(HadithController());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _matchingSurahs {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < _quranController.surahList.length; i++) {
      final surah = _quranController.surahList[i];
      if ((surah['surahName'] as String).toLowerCase().contains(q) ||
          (surah['surahNameTranslation'] as String).toLowerCase().contains(q)) {
        results.add({...surah, 'index': i});
      }
    }
    return results;
  }

  List<dynamic> get _matchingBooks {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return _hadithController.books.where((book) {
      return (book['bookName'] as String).toLowerCase().contains(q) ||
          (book['writerName'] as String).toLowerCase().contains(q);
    }).toList();
  }

  List<MapEntry<DuaCategory, DuaItem>> get _matchingDuas {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    final results = <MapEntry<DuaCategory, DuaItem>>[];
    for (final category in duaCategories) {
      for (final dua in category.duas) {
        if (dua.title.toLowerCase().contains(q) || category.title.toLowerCase().contains(q)) {
          results.add(MapEntry(category, dua));
        }
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final surahs = _matchingSurahs;
    final books = _matchingBooks;
    final duas = _matchingDuas;
    final hasResults = surahs.isNotEmpty || books.isNotEmpty || duas.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.black54;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_outlined, color: textColor, size: 24.sp),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        onChanged: (value) => setState(() => _query = value.trim()),
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: t.searchHint,
                          hintStyle: TextStyle(color: subColor, fontSize: 16.sp),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(35.0),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: cardColor,
                          filled: true,
                          prefixIcon: Icon(Icons.search, color: subColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: _query.isEmpty
                  ? Center(
                      child: Text(
                        t.startTypingToSearch,
                        style: TextStyle(fontSize: 16.sp, color: subColor),
                      ),
                    )
                  : !hasResults
                      ? Center(
                          child: Text(
                            t.noResultsFor(_query),
                            style: TextStyle(fontSize: 16.sp, color: subColor),
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          children: [
                            if (surahs.isNotEmpty) ...[
                              _sectionHeader(t.quran, accent),
                              ...surahs.map((surah) => _resultTile(
                                    title: surah['surahName'] as String,
                                    subtitle: surah['surahNameTranslation'] as String,
                                    onTap: () => Get.to(() => SurahScreen(
                                          surahName: surah['surahName'] as String,
                                          surahId: (surah['index'] as int) + 1,
                                        )),
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    subColor: subColor,
                                  )),
                            ],
                            if (books.isNotEmpty) ...[
                              _sectionHeader(t.hadith, accent),
                              ...books.map((book) => _resultTile(
                                    title: book['bookName'] as String,
                                    subtitle: 'by ${book['writerName']}',
                                    onTap: () => Get.to(() => HidthChaptersScreen(
                                          bookSlug: book['bookSlug'] as String,
                                          bookNameInArabic: book['bookName'] as String,
                                        )),
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    subColor: subColor,
                                  )),
                            ],
                            if (duas.isNotEmpty) ...[
                              _sectionHeader(t.dua, accent),
                              ...duas.map((entry) => _resultTile(
                                    title: entry.value.title,
                                    subtitle: entry.key.title,
                                    onTap: () => Get.to(() => Dua2Screen(category: entry.key)),
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    subColor: subColor,
                                  )),
                            ],
                            SizedBox(height: 24.h),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color accent) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: accent)),
    );
  }

  Widget _resultTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
    required Color subColor,
  }) {
    return Card(
      color: cardColor,
      margin: EdgeInsets.symmetric(vertical: 4.h),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: textColor)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12.sp, color: subColor)),
        trailing: Icon(Icons.chevron_right, color: subColor),
        onTap: onTap,
      ),
    );
  }
}
