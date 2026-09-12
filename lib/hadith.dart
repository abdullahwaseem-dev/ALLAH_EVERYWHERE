import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'controller/HadithController.dart';
import 'hadith_chapters.dart';

class HadithScreen extends StatelessWidget {
  final HadithController _controller = Get.put(HadithController());

  final Map<String, String> bookNamesInUrdu = {
    'Sahih Bukhari': 'صحیح بخاری',
    'Sahih Muslim': 'صحیح مسلم',
    'Jami\' Al-Tirmidhi': 'جامع ترمذی',
    'Sunan Abu Dawood': 'سنن ابوداؤد',
    'Sunan Ibn-e-Majah': 'سنن ابن ماجہ',
    'Sunan An-Nasa`i': 'سنن نسائی',
    'Mishkat Al-Masabih': 'مشکوٰۃ المصابیح',
    'Musnad Ahmad': 'مسند احمد بن حنبل',
    'Al-Silsila Sahiha': 'السلسلہ الصحیحہ',
  };

  final RxBool isSurahActive = false.obs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined, color: textColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Hadith',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [VoidColors.cardDark, VoidColors.oliveDeep]
                        : [VoidColors.oliveDeep, VoidColors.dustyRose],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Obx(() {
                  final hasLastRead = _controller.lastReadBookSlug.isNotEmpty;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last Read', style: TextStyle(fontSize: 12.sp, color: Colors.white70)),
                      SizedBox(height: 4.h),
                      Text(
                        hasLastRead ? _controller.lastReadBookName.value : 'Start Reading',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text('Chapters (Abwab, أبواب)', style: TextStyle(fontSize: 12.sp, color: Colors.white70)),
                      SizedBox(height: 8.h),
                      ElevatedButton(
                        onPressed: hasLastRead
                            ? () {
                                Get.to(HidthChaptersScreen(
                                  bookSlug: _controller.lastReadBookSlug.value,
                                  bookNameInArabic: _controller.lastReadBookName.value,
                                ));
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Continue', style: TextStyle(fontSize: 12.sp, color: Colors.white)),
                            Icon(Icons.arrow_forward, size: 14.sp, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
              SizedBox(height: 16.h),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: TextField(
                  onChanged: (query) => _controller.searchBooks(query),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: subColor),
                    hintText: 'Search For Hadith Book',
                    hintStyle: TextStyle(fontSize: 14.sp, color: subColor),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Obx(() {
                if (_controller.isLoading.value) {
                  return Center(child: CircularProgressIndicator(color: accent));
                }

                if (_controller.errorMessage.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _controller.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16.sp, color: Colors.red),
                        ),
                        SizedBox(height: 8.h),
                        TextButton(
                          onPressed: _controller.fetchBooks,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _controller.filteredBooks.length,
                  itemBuilder: (context, index) {
                    final book = _controller.filteredBooks[index];
                    String bookNameInUrdu = bookNamesInUrdu[book['bookName']] ?? '';

                    return GestureDetector(
                      onTap: () {
                        _controller.updateLastReadBook(book['bookSlug'], book['bookName']);
                        Get.to(HidthChaptersScreen(
                          bookSlug: book['bookSlug'],
                          bookNameInArabic: book['bookName'],
                        ));
                      },
                      child: buildSurahTile(
                        book['id'].toString(),
                        book['bookName'],
                        book['writerName'],
                        book['chapters_count']?.toString(),
                        bookNameInUrdu,
                        isDark,
                        accent,
                        textColor,
                        subColor,
                      ),
                    );
                  },
                );
              }),
              SizedBox(height: 110.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSurahTile(
    String? id,
    String? bookName,
    String? writerName,
    String? chaptersCount,
    String? bookNameInUrdu,
    bool isDark,
    Color accent,
    Color textColor,
    Color subColor,
  ) {
    String safeId = id ?? "N/A";
    String safeBookName = bookName ?? "Unknown Book";
    String safeWriterName = writerName ?? "Unknown Writer";
    String safeChaptersCount = chaptersCount ?? "0";
    String safeBookNameInUrdu = bookNameInUrdu ?? '';

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: accent.withOpacity(isDark ? 0.25 : 0.14),
                child: Text(
                  safeId,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: accent),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            safeBookName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            safeBookNameInUrdu,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontFamily: 'Noto Nastaliq Urdu',
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text('Writer: $safeWriterName', style: TextStyle(fontSize: 12.sp, color: subColor)),
                    Text('Chapters: $safeChaptersCount', style: TextStyle(fontSize: 12.sp, color: subColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
          thickness: 1.h,
          color: textColor.withOpacity(0.08),
          height: 16.h,
        ),
      ],
    );
  }
}
