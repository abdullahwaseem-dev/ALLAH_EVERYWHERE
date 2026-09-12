import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/controller/QuranController.dart';
import 'package:allah_everywhere/controller/HadithController.dart';
import 'package:allah_everywhere/data/dua_data.dart';
import 'package:allah_everywhere/surah.dart';
import 'package:allah_everywhere/hadith_chapters.dart';
import 'package:allah_everywhere/dua_2.dart';

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
    final surahs = _matchingSurahs;
    final books = _matchingBooks;
    final duas = _matchingDuas;
    final hasResults = surahs.isNotEmpty || books.isNotEmpty || duas.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(image: AssetImage(VoidImages.otherscreen_background), fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black, size: 24.sp),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            onChanged: (value) => setState(() => _query = value.trim()),
                            decoration: InputDecoration(
                              hintText: 'Search Surahs, Hadith books, Duas…',
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 16.sp),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(35.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.grey[200],
                              filled: true,
                              prefixIcon: Icon(Icons.search, color: Colors.black),
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
                            'Start typing to search',
                            style: TextStyle(fontSize: 16.sp, color: Colors.black54),
                          ),
                        )
                      : !hasResults
                          ? Center(
                              child: Text(
                                'No results for "$_query"',
                                style: TextStyle(fontSize: 16.sp, color: Colors.black54),
                              ),
                            )
                          : ListView(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              children: [
                                if (surahs.isNotEmpty) ...[
                                  _sectionHeader('Quran - Surahs'),
                                  ...surahs.map((surah) => _resultTile(
                                        title: surah['surahName'] as String,
                                        subtitle: surah['surahNameTranslation'] as String,
                                        onTap: () => Get.to(() => SurahScreen(
                                              surahName: surah['surahName'] as String,
                                              surahId: (surah['index'] as int) + 1,
                                            )),
                                      )),
                                ],
                                if (books.isNotEmpty) ...[
                                  _sectionHeader('Hadith Books'),
                                  ...books.map((book) => _resultTile(
                                        title: book['bookName'] as String,
                                        subtitle: 'by ${book['writerName']}',
                                        onTap: () => Get.to(() => HidthChaptersScreen(
                                              bookSlug: book['bookSlug'] as String,
                                              bookNameInArabic: book['bookName'] as String,
                                            )),
                                      )),
                                ],
                                if (duas.isNotEmpty) ...[
                                  _sectionHeader('Duas'),
                                  ...duas.map((entry) => _resultTile(
                                        title: entry.value.title,
                                        subtitle: entry.key.title,
                                        onTap: () => Get.to(() => Dua2Screen(category: entry.key)),
                                      )),
                                ],
                                SizedBox(height: 24.h),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: VoidColors.brown)),
    );
  }

  Widget _resultTile({required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12.sp)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
