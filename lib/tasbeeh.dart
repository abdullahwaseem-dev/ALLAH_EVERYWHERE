import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/services/tasbeeh_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const List<int> _targetOptions = [33, 99, 100];

class TasbeehScreen extends StatefulWidget {
  @override
  _TasbeehScreenState createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> with SingleTickerProviderStateMixin {
  static const _countKey = 'tasbeeh_session_count';
  static const _lapKey = 'tasbeeh_session_laps';
  static const _targetKey = 'tasbeeh_target';

  final TasbeehService _service = TasbeehService();
  int tasbeehCount = 0;
  int lapCount = 0;
  int target = 33;
  int _unsyncedTaps = 0;
  Color beadColor = VoidColors.brown;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    tasbeehCount = VoidStorage().readData<int>(_countKey) ?? 0;
    lapCount = VoidStorage().readData<int>(_lapKey) ?? 0;
    target = VoidStorage().readData<int>(_targetKey) ?? 33;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.08,
    );
  }

  @override
  void dispose() {
    _syncPendingTaps();
    _pulseController.dispose();
    super.dispose();
  }

  void _syncPendingTaps() {
    if (_unsyncedTaps > 0) {
      _service.addToLifetimeTotal(_unsyncedTaps);
      _unsyncedTaps = 0;
    }
  }

  void _increment() {
    HapticFeedback.lightImpact();
    _pulseController.forward(from: 0).then((_) => _pulseController.reverse());
    setState(() {
      tasbeehCount++;
      _unsyncedTaps++;
      if (tasbeehCount % target == 0) {
        lapCount++;
        HapticFeedback.mediumImpact();
        _syncPendingTaps();
      }
    });
    VoidStorage().saveData(_countKey, tasbeehCount);
    VoidStorage().saveData(_lapKey, lapCount);
  }

  void resetTasbeeh() {
    _syncPendingTaps();
    setState(() {
      tasbeehCount = 0;
      lapCount = 0;
    });
    VoidStorage().saveData(_countKey, 0);
    VoidStorage().saveData(_lapKey, 0);
  }

  void _setTarget(int value) {
    setState(() => target = value);
    VoidStorage().saveData(_targetKey, value);
  }

  void _pickCustomTarget() async {
    final controller = TextEditingController();
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. 500'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (value != null && value > 0) _setTarget(value);
  }

  void changeBeadColor(Color color) {
    setState(() => beadColor = color);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (tasbeehCount % target) / target;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : VoidColors.black;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : VoidColors.secondary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Text(
                'Tasbeeh',
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8.w,
              children: [
                ..._targetOptions.map((t) => ChoiceChip(
                      label: Text('$t'),
                      selected: target == t,
                      onSelected: (_) => _setTarget(t),
                    )),
                ChoiceChip(
                  label: Text(_targetOptions.contains(target) ? 'Custom' : 'Custom ($target)'),
                  selected: !_targetOptions.contains(target),
                  onSelected: (_) => _pickCustomTarget(),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _increment,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) => Transform.scale(
                      scale: 1 + _pulseController.value,
                      child: child,
                    ),
                    child: Container(
                      width: 220.w,
                      height: 220.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardColor,
                        boxShadow: [
                          BoxShadow(color: beadColor.withOpacity(0.3), blurRadius: 24, spreadRadius: 4),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 220.w,
                            height: 220.w,
                            child: CircularProgressIndicator(
                              value: progress == 0 && tasbeehCount > 0 ? 1 : progress,
                              strokeWidth: 8,
                              backgroundColor: beadColor.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation(beadColor),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$tasbeehCount',
                                style: TextStyle(
                                  fontSize: 56.sp,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                '${tasbeehCount % target} / $target',
                                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Text(
              'Tap the circle to count. Laps completed: $lapCount',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 12.h),
            TextButton.icon(
              onPressed: resetTasbeeh,
              icon: const Icon(Icons.refresh, color: Colors.red),
              label: Text('Reset', style: TextStyle(color: Colors.red, fontSize: 14.sp)),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ColorDot(color: VoidColors.brown, onTap: () => changeBeadColor(VoidColors.brown)),
                  _ColorDot(color: Colors.green, onTap: () => changeBeadColor(Colors.green)),
                  _ColorDot(color: Colors.red, onTap: () => changeBeadColor(Colors.red)),
                  _ColorDot(color: Colors.purple, onTap: () => changeBeadColor(Colors.purple)),
                  _ColorDot(color: Colors.orange, onTap: () => changeBeadColor(Colors.orange)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _ColorDot({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
