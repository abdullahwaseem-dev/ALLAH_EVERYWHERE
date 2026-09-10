import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/quran.dart' as Quran;
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/constraints/image_strings.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';


class SurahScreen extends StatefulWidget {
  final String surahName;
  final int surahId;

  SurahScreen({required this.surahName, required this.surahId});

  @override
  _SurahScreenState createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  int currentPage = 0;

  List<String> surahText = [];
  List<String> surahTranslationEn = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    loadSurahData();
  }

  void loadSurahData() {
    try {
      surahText.clear();
      surahTranslationEn.clear();

      for (int i = 1; i <= Quran.getVerseCount(widget.surahId); i++) {
        surahText.add(Quran.getVerse(widget.surahId, i));
        surahTranslationEn.add(Quran.getVerseTranslation(widget.surahId, i));
      }
      setState(() => _errorMessage = null);
    } catch (e) {
      VoidLogger.error('Error fetching Surah data', e);
      setState(() => _errorMessage = 'Could not load this Surah. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Background Image
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(VoidImages.details_background),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.only(top: 40.h, left: 16.w, right: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Icon(Icons.arrow_back, size: 24.w, color: Colors.white),
                            ),
                            Row(
                              children: [
                                Text(
                                  widget.surahName,
                                  style: TextStyle(
                                    fontSize: 23.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.more_vert, size: 24.w, color: Colors.white),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Container(
                          width: 190.w,
                          height: 1.h,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        SizedBox(height: 10.h),
                        Image.asset(
                          VoidImages.bismillah,
                          height: 30.h,
                          width: 150.w,
                        ),
                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  Expanded(
                    child: _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14.sp, color: Colors.white),
                              ),
                            ),
                          )
                        : ListView.builder(
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        int verseIndex = currentPage * 3 + index;

                        if (verseIndex < surahText.length) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    surahText[verseIndex],
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      color: VoidColors.black,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'NotoNaskhArabic',
                                    ),
                                  ),
                                ),
                                SizedBox(height: 35.h),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    surahTranslationEn[verseIndex],
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: VoidColors.black,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                              ],
                            ),
                          );
                        } else {
                          return Container();
                        }
                      },
                    ),
                  ),


                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: VoidColors.secondary),
                          onPressed: currentPage > 0
                              ? () {
                            setState(() {
                              currentPage--;
                            });
                          }
                              : null,
                          child: Text('Previous',style: TextStyle(color: VoidColors.black),),
                        ),
                        Text(
                          "Page ${currentPage + 1}",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: VoidColors.black,
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: VoidColors.secondary),
                          onPressed: currentPage < (surahText.length / 3).ceil() - 1
                              ? () {
                            setState(() {
                              currentPage++;
                            });
                          }
                              : null,
                          child: Text('Next',style: TextStyle(color: VoidColors.black),),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
