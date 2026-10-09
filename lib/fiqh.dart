import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'ask_ai.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';
import 'package:allah_everywhere/widgets/pressable_tile.dart';
import 'package:allah_everywhere/widgets/ask_ai_fab.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';

class FiqhScreen extends StatefulWidget {
  @override
  State<FiqhScreen> createState() => _FiqhScreenState();
}

class _FiqhScreenState extends State<FiqhScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const List<String> _topics = [
    'Purification (Taharah)',
    'Salah',
    'Zakat',
    'Sawm (Fasting)',
    'Hajj',
    'Nikah (Marriage)',
    'Halal & Haram',
    'Business Transactions',
  ];

  List<String> get _filteredTopics => _query.isEmpty
      ? _topics
      : _topics.where((t) => t.toLowerCase().contains(_query.toLowerCase())).toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;
    final headerGradient = isDark
        ? [VoidColors.cardDark, VoidColors.oliveDeep]
        : [VoidColors.oliveDeep, VoidColors.dustyRose];

    return AskAiFabHost(
      category: 'Fiqh',
      child: Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      body: ReadableWidth(child: Column(
        children: [
          Stack(
            children: [
              ClipPath(
                clipper: CustomAppBarClipper(),
                child: Container(
                  height: 120.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: headerGradient,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Text(
                      'FIQH',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 42.h,
                left: 16.w,
                child: VoidBackButton(onPressed: () => Navigator.pop(context), color: Colors.white),
              ),
            ],
          ),

          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: subColor),
                  hintText: 'Search For Fiqh',
                  hintStyle: TextStyle(fontSize: 14.sp, color: subColor),
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tap a topic to ask AI about it',
                style: TextStyle(fontSize: 13.sp, color: subColor),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 110.h),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 1.1,
              ),
              itemCount: _filteredTopics.length,
              itemBuilder: (context, index) {
                final topic = _filteredTopics[index];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: PressableTile(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16.r),
                    semanticLabel: topic,
                    onTap: () => Get.to(() => AskAiScreen(initialCategory: topic)),
                    child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.smart_toy_outlined, size: 32.sp, color: accent),
                        SizedBox(height: 10.h),
                        Text(
                          topic,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: textColor),
                        ),
                      ],
                    ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      )),
    ));
  }
}

// Custom Clipper for the curved AppBar
class CustomAppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50); // Starting from the left-bottom
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 50); // Curve
    path.lineTo(size.width, 0); // Top-right corner
    path.close(); // Close the path
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
