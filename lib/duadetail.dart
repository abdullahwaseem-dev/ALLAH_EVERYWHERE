import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:allah_everywhere/models/bookmark.dart';
import 'package:allah_everywhere/services/bookmark_service.dart';
import 'data/dua_data.dart';

class DuaDetailScreen extends StatefulWidget {
  final DuaItem dua;
  final int index;
  final int total;
  final String categoryTitle;

  const DuaDetailScreen({
    Key? key,
    required this.dua,
    required this.index,
    required this.total,
    this.categoryTitle = '',
  }) : super(key: key);

  @override
  State<DuaDetailScreen> createState() => _DuaDetailScreenState();
}

class _DuaDetailScreenState extends State<DuaDetailScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  bool _isBookmarked = false;

  String get _refId => '${widget.categoryTitle}|${widget.dua.title}';

  @override
  void initState() {
    super.initState();
    if (widget.categoryTitle.isNotEmpty) _loadBookmarkState();
  }

  Future<void> _loadBookmarkState() async {
    final bookmarked = await _bookmarkService.isBookmarked(BookmarkType.dua, _refId);
    if (mounted) setState(() => _isBookmarked = bookmarked);
  }

  Future<void> _toggleBookmark() async {
    await _bookmarkService.toggle(BookmarkType.dua, _refId, widget.dua.title, widget.categoryTitle);
    if (mounted) setState(() => _isBookmarked = !_isBookmarked);
  }

  @override
  Widget build(BuildContext context) {
    final dua = widget.dua;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.black87;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        toolbarHeight: 60.h,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          dua.title,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: textColor),
        ),
        centerTitle: true,
        actions: [
          if (widget.categoryTitle.isNotEmpty)
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                color: accent,
              ),
              onPressed: _toggleBookmark,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 110.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${widget.index}/${widget.total}', style: TextStyle(fontSize: 14.sp, color: textColor)),
                SizedBox(width: 8.w),
                Expanded(
                  child: LinearProgressIndicator(
                    value: widget.total == 0 ? 0 : widget.index / widget.total,
                    backgroundColor: textColor.withOpacity(0.12),
                    color: accent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Text(
              dua.title,
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w700, color: textColor),
            ),
            SizedBox(height: 20.h),
            Text(
              dua.arabic,
              textAlign: TextAlign.start,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w400, color: textColor, height: 1.5),
            ),
            SizedBox(height: 20.h),
            Text(
              dua.transliteration,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400, color: subColor, height: 1.5),
            ),
            SizedBox(height: 20.h),
            Text(
              dua.translation,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400, color: subColor, height: 1.5),
            ),
            SizedBox(height: 30.h),
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.book, color: accent, size: 18.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      dua.reference,
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: accent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
