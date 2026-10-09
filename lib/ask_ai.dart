import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/controllers/ai_qa_controller.dart';
import 'package:allah_everywhere/services/ai_fatwa_service.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';

/// Replaces the old Aalim (human scholar) flow: users ask an Islamic
/// question here and get an AI-generated answer instead of waiting for a
/// scholar to be available.
class AskAiScreen extends StatefulWidget {
  final String? initialCategory;

  /// Pre-filled into the input (e.g. "Explain Surah Al-Mulk, ayah 2") so the
  /// user can just press send. Not sent automatically.
  final String? initialQuestion;

  /// Opens the keyboard straight away. Always on when [initialQuestion] is set.
  final bool autofocus;

  const AskAiScreen({Key? key, this.initialCategory, this.initialQuestion, this.autofocus = false}) : super(key: key);

  @override
  State<AskAiScreen> createState() => _AskAiScreenState();
}

class _AskAiScreenState extends State<AskAiScreen> {
  final AiQaController controller = Get.put(AiQaController());
  late final TextEditingController _questionController = TextEditingController.fromValue(
    TextEditingValue(
      text: widget.initialQuestion ?? '',
      // Cursor at the end so the user can add to the pre-filled question.
      selection: TextSelection.collapsed(offset: widget.initialQuestion?.length ?? 0),
    ),
  );

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  String? _lastQuestion;

  Future<void> _submit() async {
    final question = _questionController.text;
    if (question.trim().isEmpty || controller.isLoading.value) return;
    HapticFeedback.lightImpact();
    _lastQuestion = question;
    _questionController.clear();
    FocusScope.of(context).unfocus();
    await controller.askQuestion(question, category: widget.initialCategory);
    // Give the question back on failure so the user doesn't retype it.
    if (mounted && controller.error.value != null && _questionController.text.isEmpty) {
      _questionController.text = question;
    }
  }

  void _retry() {
    final question = _lastQuestion;
    if (question == null || controller.isLoading.value) return;
    _questionController.clear();
    controller.askQuestion(question, category: widget.initialCategory);
  }

  String _errorText(AppLocalizations t, AiErrorKind kind) {
    switch (kind) {
      case AiErrorKind.offline:
        return t.aiErrorOffline;
      case AiErrorKind.busy:
        return t.aiErrorBusy;
      case AiErrorKind.noAnswer:
        return t.aiErrorNoAnswer;
      case AiErrorKind.unavailable:
        return t.aiErrorUnavailable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          widget.initialCategory != null
              ? '${t.askAi} • ${widget.initialCategory}'
              : t.askAi,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: textColor),
        ),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.history, color: textColor),
              tooltip: 'Recent conversations',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _buildHistoryDrawer(accent, textColor),
      body: ReadableWidth(child: Column(
        children: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(12.w),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18.sp, color: Colors.amber.shade800),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    t.askAiDisclaimer,
                    style: TextStyle(fontSize: 12.sp, color: Colors.brown.shade800),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.history.isEmpty && !controller.isLoading.value) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Text(
                      t.askAiEmptyState,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                reverse: true,
                itemCount: controller.history.length + (controller.isLoading.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (controller.isLoading.value && index == 0) {
                    return _buildLoadingBubble(accent);
                  }
                  final answer = controller
                      .history[index - (controller.isLoading.value ? 1 : 0)];
                  return _buildQaCard(answer, accent);
                },
              );
            }),
          ),
          Obx(() {
            final error = controller.error.value;
            if (error == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _errorText(t, error),
                      style: TextStyle(color: Colors.red, fontSize: 12.sp),
                    ),
                  ),
                  if (error != AiErrorKind.unavailable && _lastQuestion != null)
                    TextButton(
                      onPressed: _retry,
                      child: Text(t.retry, style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            );
          }),
          _buildInput(accent),
        ],
      )),
    );
  }

  Widget _buildLoadingBubble(Color accent) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          SizedBox(
            width: 16.w,
            height: 16.w,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent),
          ),
          SizedBox(width: 8.w),
          Text(AppLocalizations.of(context)!.researching, style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildQaCard(AiAnswer answer, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.06), blurRadius: 6.r, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 16.sp, color: accent),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  answer.question,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: textColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.smart_toy_outlined, size: 16.sp, color: accent),
              SizedBox(width: 6.w),
              Expanded(
                child: MarkdownBody(
                  data: answer.answer,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(fontSize: 13.sp, color: textColor, height: 1.4),
                    strong: TextStyle(fontSize: 13.sp, color: textColor, height: 1.4, fontWeight: FontWeight.bold),
                    em: TextStyle(fontSize: 13.sp, color: textColor, height: 1.4, fontStyle: FontStyle.italic),
                    listBullet: TextStyle(fontSize: 13.sp, color: textColor, height: 1.4),
                    h1: TextStyle(fontSize: 16.sp, color: textColor, fontWeight: FontWeight.bold),
                    h2: TextStyle(fontSize: 15.sp, color: textColor, fontWeight: FontWeight.bold),
                    h3: TextStyle(fontSize: 14.sp, color: textColor, fontWeight: FontWeight.bold),
                    blockquote: TextStyle(fontSize: 13.sp, color: textColor.withOpacity(0.8), height: 1.4),
                    blockquoteDecoration: BoxDecoration(
                      border: Border(left: BorderSide(color: accent, width: 3)),
                    ),
                    blockquotePadding: EdgeInsets.only(left: 10.w),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Groups the last 7 days of Q&A history by day so users can find an old
  /// conversation without scrolling through the entire chat.
  Widget _buildHistoryDrawer(Color accent, Color textColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? VoidColors.bgDark : VoidColors.bgLight;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;

    return Drawer(
      backgroundColor: bgColor,
      child: SafeArea(
        child: Obx(() {
          final cutoff = DateTime.now().subtract(const Duration(days: 7));
          final recent = controller.history.where((a) => a.createdAt.isAfter(cutoff)).toList();

          final groups = <String, List<AiAnswer>>{};
          for (final answer in recent) {
            final label = _dayLabel(answer.createdAt);
            groups.putIfAbsent(label, () => []).add(answer);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'Last 7 days',
                  style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
              Expanded(
                child: recent.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Text(
                            'No conversations in the last 7 days.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13.sp, color: subColor),
                          ),
                        ),
                      )
                    : ListView(
                        children: groups.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
                                child: Text(
                                  entry.key,
                                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: accent),
                                ),
                              ),
                              ...entry.value.map((answer) => ListTile(
                                    dense: true,
                                    title: Text(
                                      answer.question,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13.sp, color: textColor),
                                    ),
                                    subtitle: Text(
                                      DateFormat('h:mm a').format(answer.createdAt),
                                      style: TextStyle(fontSize: 11.sp, color: subColor),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showAnswerDetail(answer, accent, textColor);
                                    },
                                  )),
                            ],
                          );
                        }).toList(),
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(dt);
  }

  void _showAnswerDetail(AiAnswer answer, Color accent, Color textColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(16.w),
          child: _buildQaCard(answer, accent),
        ),
      ),
    );
  }

  Widget _buildInput(Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _questionController,
                autofocus: widget.autofocus || widget.initialQuestion != null,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                style: TextStyle(color: isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.askAiHint,
                  filled: true,
                  fillColor: isDark ? VoidColors.cardDark : VoidColors.cardLight,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Obx(() => IconButton(
                  icon: Icon(Icons.send, color: accent),
                  onPressed: controller.isLoading.value ? null : _submit,
                )),
          ],
        ),
      ),
    );
  }
}
