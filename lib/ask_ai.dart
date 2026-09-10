import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/controllers/ai_qa_controller.dart';
import 'package:allah_everywhere/services/ai_fatwa_service.dart';

/// Replaces the old Aalim (human scholar) flow: users ask an Islamic
/// question here and get an AI-generated answer instead of waiting for a
/// scholar to be available.
class AskAiScreen extends StatefulWidget {
  final String? initialCategory;

  const AskAiScreen({Key? key, this.initialCategory}) : super(key: key);

  @override
  State<AskAiScreen> createState() => _AskAiScreenState();
}

class _AskAiScreenState extends State<AskAiScreen> {
  final AiQaController controller = Get.put(AiQaController());
  final TextEditingController _questionController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _submit() {
    final question = _questionController.text;
    if (question.trim().isEmpty) return;
    controller.askQuestion(question, category: widget.initialCategory);
    _questionController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoidColors.secondary,
      appBar: AppBar(
        backgroundColor: VoidColors.brown,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: VoidColors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.initialCategory != null
              ? 'Ask AI • ${widget.initialCategory}'
              : 'Ask AI',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
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
                    'AI-generated guidance — always verify important rulings with a qualified scholar.',
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
                      'Ask any Islamic question below — an AI model will '
                      'research it and reply here.',
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
                    return _buildLoadingBubble();
                  }
                  final answer = controller
                      .history[index - (controller.isLoading.value ? 1 : 0)];
                  return _buildQaCard(answer);
                },
              );
            }),
          ),
          Obx(() => controller.errorMessage.value.isNotEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    controller.errorMessage.value,
                    style: TextStyle(color: Colors.red, fontSize: 12.sp),
                  ),
                )
              : const SizedBox.shrink()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          SizedBox(
            width: 16.w,
            height: 16.w,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8.w),
          Text('Researching your question…', style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildQaCard(AiAnswer answer) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6.r, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 16.sp, color: VoidColors.brown),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  answer.question,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.smart_toy_outlined, size: 16.sp, color: VoidColors.darkBlue),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  answer.answer,
                  style: TextStyle(fontSize: 13.sp, color: Colors.black87, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _questionController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Ask your question…',
                  filled: true,
                  fillColor: Colors.white,
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
                  icon: Icon(Icons.send, color: VoidColors.brown),
                  onPressed: controller.isLoading.value ? null : _submit,
                )),
          ],
        ),
      ),
    );
  }
}
