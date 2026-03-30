import 'package:flutter/material.dart';

/// A vertical wheel-style time picker with two columns: Hours and Minutes.
/// Uses [ListWheelScrollView] for the iOS-style spinning selector look.
class TimePickerWheel extends StatefulWidget {
  const TimePickerWheel({
    super.key,
    required this.enabled,
    required this.onTimeChanged,
    this.initialHour = 8,
    this.initialMinute = 0,
    this.minHour = 0,
    this.maxHour = 23,
  });

  final bool enabled;
  final void Function(int hour, int minute) onTimeChanged;
  final int initialHour;
  final int initialMinute;
  final int minHour;
  final int maxHour;

  @override
  State<TimePickerWheel> createState() => _TimePickerWheelState();
}

class _TimePickerWheelState extends State<TimePickerWheel> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialHour;
    _selectedMinute = widget.initialMinute;
    
    // Adjust initial item to handle minHour offset
    _hourController = FixedExtentScrollController(initialItem: _selectedHour - widget.minHour);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        widget.enabled ? theme.colorScheme.onSurface : Colors.grey.shade400;
    final highlightColor = widget.enabled
        ? theme.colorScheme.primary.withAlpha(25)
        : Colors.grey.shade100;

    final hourCount = widget.maxHour - widget.minHour + 1;

    return SizedBox(
      height: 180,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Hours column ─────────────────────────────────────────
          _WheelColumn(
            label: 'HH',
            itemCount: hourCount,
            controller: _hourController,
            enabled: widget.enabled,
            textColor: textColor,
            highlightColor: highlightColor,
            formatter: (i) => (i + widget.minHour).toString().padLeft(2, '0'),
            onChanged: (i) {
              _selectedHour = i + widget.minHour;
              widget.onTimeChanged(_selectedHour, _selectedMinute);
            },
          ),

          // ── Colon separator ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),

          // ── Minutes column ──────────────────────────────────────
          _WheelColumn(
            label: 'MM',
            itemCount: 60,
            controller: _minuteController,
            enabled: widget.enabled,
            textColor: textColor,
            highlightColor: highlightColor,
            formatter: (i) => i.toString().padLeft(2, '0'),
            onChanged: (i) {
              _selectedMinute = i;
              widget.onTimeChanged(_selectedHour, _selectedMinute);
            },
          ),
        ],
      ),
    );
  }
}

// ── Reusable wheel column ───────────────────────────────────────────────────

class _WheelColumn extends StatelessWidget {
  const _WheelColumn({
    required this.label,
    required this.itemCount,
    required this.controller,
    required this.enabled,
    required this.textColor,
    required this.highlightColor,
    required this.formatter,
    required this.onChanged,
  });

  final String label;
  final int itemCount;
  final FixedExtentScrollController controller;
  final bool enabled;
  final Color textColor;
  final Color highlightColor;
  final String Function(int) formatter;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Column label
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor.withAlpha(150),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),

        // Wheel
        Expanded(
          child: SizedBox(
            width: 72,
            child: Stack(
              children: [
                // Highlight band behind the selected item
                Center(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: enabled
                            ? Colors.grey.shade300
                            : Colors.grey.shade200,
                      ),
                    ),
                  ),
                ),

                // Scroll wheel
                ListWheelScrollView.useDelegate(
                  controller: controller,
                  itemExtent: 44,
                  diameterRatio: 1.4,
                  perspective: 0.003,
                  physics: enabled
                      ? const FixedExtentScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  onSelectedItemChanged: enabled ? onChanged : null,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: itemCount,
                    builder: (context, index) {
                      return Center(
                        child: Text(
                          formatter(index),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
