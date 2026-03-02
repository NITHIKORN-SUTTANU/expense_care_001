import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _beforeDay(DateTime a, DateTime b) =>
    DateTime(a.year, a.month, a.day)
        .isBefore(DateTime(b.year, b.month, b.day));

bool _afterDay(DateTime a, DateTime b) =>
    DateTime(a.year, a.month, a.day)
        .isAfter(DateTime(b.year, b.month, b.day));

// ── Public API ────────────────────────────────────────────────────────────────

/// Shows a custom single-date picker bottom sheet.
/// If [withTime] is true, a time scroll-wheel is shown below the calendar.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  bool withTime = false,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => _SingleDateSheet(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      withTime: withTime,
    ),
  );
}

/// Shows a custom date-range picker bottom sheet.
Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialRange,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => _DateRangeSheet(
      initialRange: initialRange,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

// ── Single Date Sheet ─────────────────────────────────────────────────────────

class _SingleDateSheet extends StatefulWidget {
  const _SingleDateSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.withTime,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool withTime;

  @override
  State<_SingleDateSheet> createState() => _SingleDateSheetState();
}

class _SingleDateSheetState extends State<_SingleDateSheet> {
  late DateTime _selected;
  late DateTime _display;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _display = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  bool get _canPrev => _display
      .isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));

  bool get _canNext => _display
      .isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final onBg = isDark ? AppColors.darkOnBackground : AppColors.onBackground;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheetTop)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DragHandle(color: borderColor),
            _SheetTitle(
              title: widget.withTime ? 'Date & Time' : 'Select Date',
              onBg: onBg,
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _CalendarGrid(
                      display: _display,
                      selectedDate: _selected,
                      firstDate: widget.firstDate,
                      lastDate: widget.lastDate,
                      canPrev: _canPrev,
                      canNext: _canNext,
                      onPrev: () => setState(() => _display =
                          DateTime(_display.year, _display.month - 1)),
                      onNext: () => setState(() => _display =
                          DateTime(_display.year, _display.month + 1)),
                      onDisplayChanged: (d) => setState(() => _display = d),
                      onDayTap: (day) => setState(() => _selected = DateTime(
                          day.year,
                          day.month,
                          day.day,
                          _selected.hour,
                          _selected.minute)),
                      isDark: isDark,
                    ),
                    if (widget.withTime) ...[
                      Divider(height: 1, color: borderColor),
                      _TimeGrid(
                        initialTime: _selected,
                        isDark: isDark,
                        onChanged: (dt) => setState(() => _selected = DateTime(
                            _selected.year,
                            _selected.month,
                            _selected.day,
                            dt.hour,
                            dt.minute)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _ConfirmBar(
              borderColor: borderColor,
              onConfirm: () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date Range Sheet ──────────────────────────────────────────────────────────

class _DateRangeSheet extends StatefulWidget {
  const _DateRangeSheet({
    required this.initialRange,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTimeRange? initialRange;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_DateRangeSheet> createState() => _DateRangeSheetState();
}

class _DateRangeSheetState extends State<_DateRangeSheet> {
  DateTime? _start;
  DateTime? _end;
  late DateTime _display;

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start;
    _end = widget.initialRange?.end;
    final anchor = _start ?? DateTime.now();
    _display = DateTime(anchor.year, anchor.month);
  }

  bool get _canPrev => _display
      .isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));

  bool get _canNext => _display
      .isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));

  void _onDayTap(DateTime day) {
    setState(() {
      if (_start == null || _end != null) {
        _start = day;
        _end = null;
      } else if (_sameDay(day, _start!)) {
        _end = day;
      } else if (_beforeDay(day, _start!)) {
        _end = _start;
        _start = day;
      } else {
        _end = day;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final onBg = isDark ? AppColors.darkOnBackground : AppColors.onBackground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheetTop)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DragHandle(color: borderColor),
            _SheetTitle(title: 'Select Date Range', onBg: onBg),

            // FROM / TO chips
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _DateChip(
                      label: 'FROM',
                      date: _start,
                      active: _start == null,
                      primary: primary,
                      onBg: onBg,
                      muted: muted,
                      isDark: isDark,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 14, color: muted),
                  ),
                  Expanded(
                    child: _DateChip(
                      label: 'TO',
                      date: _end,
                      active: _start != null && _end == null,
                      primary: primary,
                      onBg: onBg,
                      muted: muted,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: borderColor),

            Flexible(
              child: SingleChildScrollView(
                child: _CalendarGrid(
                  display: _display,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  rangeStart: _start,
                  rangeEnd: _end,
                  canPrev: _canPrev,
                  canNext: _canNext,
                  onPrev: () => setState(() =>
                      _display = DateTime(_display.year, _display.month - 1)),
                  onNext: () => setState(() =>
                      _display = DateTime(_display.year, _display.month + 1)),
                  onDisplayChanged: (d) => setState(() => _display = d),
                  onDayTap: _onDayTap,
                  isDark: isDark,
                ),
              ),
            ),

            _ConfirmBar(
              borderColor: borderColor,
              onConfirm: (_start != null && _end != null)
                  ? () => Navigator.of(context)
                      .pop(DateTimeRange(start: _start!, end: _end!))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Calendar Grid ─────────────────────────────────────────────────────────────

class _CalendarGrid extends StatefulWidget {
  const _CalendarGrid({
    required this.display,
    this.selectedDate,
    this.rangeStart,
    this.rangeEnd,
    required this.firstDate,
    required this.lastDate,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
    required this.onDisplayChanged,
    required this.onDayTap,
    required this.isDark,
  });

  final DateTime display;
  final DateTime? selectedDate;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDisplayChanged;
  final ValueChanged<DateTime> onDayTap;
  final bool isDark;

  @override
  State<_CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<_CalendarGrid> {
  bool _showYearPicker = false;
  final ScrollController _yearScrollCtrl = ScrollController();

  static const _weekLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  void dispose() {
    _yearScrollCtrl.dispose();
    super.dispose();
  }

  void _toggleYearPicker() {
    final opening = !_showYearPicker;
    setState(() => _showYearPicker = opening);
    if (opening) {
      // Scroll to current year row after the grid renders
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_yearScrollCtrl.hasClients) return;
        final firstYear = widget.firstDate.year;
        final rowIndex =
            ((widget.display.year - firstYear) / 4).floor();
        const rowH = 48.0; // approx row height incl. spacing
        _yearScrollCtrl.jumpTo(max(0.0, (rowIndex - 1) * rowH));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.isDark ? AppColors.darkPrimary : AppColors.primary;
    final onBg =
        widget.isDark ? AppColors.darkOnBackground : AppColors.onBackground;
    final muted = widget.isDark ? AppColors.darkMuted : AppColors.muted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Column(
        children: [
          // ── Header row ────────────────────────────────────────────────
          Row(
            children: [
              // Prev button (hidden in year-picker mode)
              AnimatedOpacity(
                opacity: _showYearPicker ? 0 : 1,
                duration: const Duration(milliseconds: 150),
                child: IgnorePointer(
                  ignoring: _showYearPicker,
                  child: _NavBtn(
                    icon: Icons.chevron_left_rounded,
                    enabled: widget.canPrev,
                    color: widget.canPrev
                        ? onBg
                        : muted.withValues(alpha: 0.35),
                    onTap: widget.onPrev,
                  ),
                ),
              ),

              // Month / Year label — tappable to toggle year picker
              Expanded(
                child: GestureDetector(
                  onTap: _toggleYearPicker,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showYearPicker
                            ? '${widget.display.year}'
                            : DateFormat('MMMM yyyy').format(widget.display),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: onBg,
                        ),
                      ),
                      const SizedBox(width: 3),
                      AnimatedRotation(
                        turns: _showYearPicker ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: onBg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Next button (hidden in year-picker mode)
              AnimatedOpacity(
                opacity: _showYearPicker ? 0 : 1,
                duration: const Duration(milliseconds: 150),
                child: IgnorePointer(
                  ignoring: _showYearPicker,
                  child: _NavBtn(
                    icon: Icons.chevron_right_rounded,
                    enabled: widget.canNext,
                    color: widget.canNext
                        ? onBg
                        : muted.withValues(alpha: 0.35),
                    onTap: widget.onNext,
                  ),
                ),
              ),
            ],
          ),

          // ── Year picker grid OR calendar ───────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _showYearPicker
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildYearGrid(primary, onBg, muted),
            secondChild: _buildDayGrid(primary, onBg, muted),
          ),
        ],
      ),
    );
  }

  // ── Year grid ──────────────────────────────────────────────────────────────

  Widget _buildYearGrid(Color primary, Color onBg, Color muted) {
    final firstYear = widget.firstDate.year;
    final lastYear = widget.lastDate.year;
    final count = lastYear - firstYear + 1;

    return SizedBox(
      height: 240,
      child: GridView.builder(
        controller: _yearScrollCtrl,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 2.2,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: count,
        itemBuilder: (_, i) {
          final year = firstYear + i;
          final isSelected = year == widget.display.year;
          return GestureDetector(
            onTap: () {
              widget.onDisplayChanged(
                  DateTime(year, widget.display.month));
              setState(() => _showYearPicker = false);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSelected ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              alignment: Alignment.center,
              child: Text(
                '$year',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? Colors.white : onBg,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Day grid ───────────────────────────────────────────────────────────────

  Widget _buildDayGrid(Color primary, Color onBg, Color muted) {
    final daysInMonth =
        DateTime(widget.display.year, widget.display.month + 1, 0).day;
    final startOffset =
        (DateTime(widget.display.year, widget.display.month, 1).weekday - 1) %
            7;
    final rows = ((startOffset + daysInMonth) / 7).ceil();
    final hasRange = widget.rangeStart != null &&
        widget.rangeEnd != null &&
        !_sameDay(widget.rangeStart!, widget.rangeEnd!);

    return Column(
      children: [
        const SizedBox(height: 4),

        // Weekday labels
        Row(
          children: _weekLabels
              .map((l) => Expanded(
                    child: Text(
                      l,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: muted,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ))
              .toList(),
        ),

        const SizedBox(height: 4),

        // Day rows
        for (int r = 0; r < rows; r++)
          Row(
            children: List.generate(7, (c) {
              final idx = r * 7 + c;
              final dayNum = idx - startOffset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 40));
              }
              final day = DateTime(
                  widget.display.year, widget.display.month, dayNum);
              final disabled = _beforeDay(day, widget.firstDate) ||
                  _afterDay(day, widget.lastDate);
              final isToday = _sameDay(day, DateTime.now());
              final isSel = widget.selectedDate != null &&
                  _sameDay(day, widget.selectedDate!);
              final isStart = widget.rangeStart != null &&
                  _sameDay(day, widget.rangeStart!);
              final isEnd =
                  widget.rangeEnd != null && _sameDay(day, widget.rangeEnd!);
              final inRange = hasRange &&
                  _afterDay(day, widget.rangeStart!) &&
                  _beforeDay(day, widget.rangeEnd!);

              return Expanded(
                child: GestureDetector(
                  onTap: disabled ? null : () => widget.onDayTap(day),
                  child: _DayCell(
                    dayNum: dayNum,
                    isSelected: isSel,
                    isToday: isToday,
                    isDisabled: disabled,
                    isRangeStart: isStart && hasRange,
                    isRangeEnd: isEnd && hasRange,
                    inRange: inRange,
                    primary: primary,
                    onBg: onBg,
                    muted: muted,
                  ),
                ),
              );
            }),
          ),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Day Cell ──────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayNum,
    required this.isSelected,
    required this.isToday,
    required this.isDisabled,
    required this.isRangeStart,
    required this.isRangeEnd,
    required this.inRange,
    required this.primary,
    required this.onBg,
    required this.muted,
  });

  final int dayNum;
  final bool isSelected, isToday, isDisabled;
  final bool isRangeStart, isRangeEnd, inRange;
  final Color primary, onBg, muted;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = isSelected || isRangeStart || isRangeEnd;
    final bandColor = primary.withValues(alpha: 0.12);

    final Color textColor;
    if (isDisabled) {
      textColor = muted.withValues(alpha: 0.3);
    } else if (isHighlighted) {
      textColor = Colors.white;
    } else if (isToday || inRange) {
      textColor = primary;
    } else {
      textColor = onBg;
    }

    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Range band split into left/right halves for endpoint half-caps
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 32,
                    color: (inRange || isRangeEnd)
                        ? bandColor
                        : Colors.transparent,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 32,
                    color: (inRange || isRangeStart)
                        ? bandColor
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),

          // Today ring (when not highlighted)
          if (isToday && !isHighlighted)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: primary.withValues(alpha: 0.55), width: 1.5),
              ),
            ),

          // Filled circle for selected / range endpoints
          if (isHighlighted)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
            ),

          // Day number
          Text(
            '$dayNum',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: (isHighlighted || isToday || inRange)
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Time Grid ─────────────────────────────────────────────────────────────────

class _TimeGrid extends StatefulWidget {
  const _TimeGrid({
    required this.initialTime,
    required this.isDark,
    required this.onChanged,
  });

  final DateTime initialTime;
  final bool isDark;
  final ValueChanged<DateTime> onChanged;

  @override
  State<_TimeGrid> createState() => _TimeGridState();
}

class _TimeGridState extends State<_TimeGrid> {
  late int _hour12; // 1–12
  late int _minute; // 0, 5, 10 … 55
  late bool _isPm;

  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minCtrl;

  static const _hours = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  static const _minutes = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];
  static const _itemExtent = 44.0;
  static const _wheelHeight = _itemExtent * 3; // 3 visible items

  @override
  void initState() {
    super.initState();
    final h = widget.initialTime.hour;
    _isPm = h >= 12;
    _hour12 = h % 12 == 0 ? 12 : h % 12;
    _minute = ((widget.initialTime.minute / 5).round() * 5) % 60;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minCtrl = FixedExtentScrollController(initialItem: _minute ~/ 5);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    final h24 = _isPm ? _hour12 % 12 + 12 : _hour12 % 12;
    widget.onChanged(DateTime(
      widget.initialTime.year,
      widget.initialTime.month,
      widget.initialTime.day,
      h24,
      _minute,
    ));
  }

  Widget _buildWheel({
    required List<int> values,
    required FixedExtentScrollController ctrl,
    required int selected,
    required String Function(int) format,
    required Color primary,
    required Color onBg,
    required Color muted,
    required Color bg,
    required ValueChanged<int> onIndexChanged,
  }) {
    return SizedBox(
      width: 72,
      height: _wheelHeight,
      child: Stack(
        children: [
          // Center selection highlight band (middle of 3 items)
          Positioned(
            top: _itemExtent * 1,
            left: 4,
            right: 4,
            child: Container(
              height: _itemExtent,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
            ),
          ),

          // Wheel
          ListWheelScrollView(
            controller: ctrl,
            itemExtent: _itemExtent,
            physics: const FixedExtentScrollPhysics(),
            perspective: 0.003,
            diameterRatio: 1.8,
            onSelectedItemChanged: onIndexChanged,
            children: values.map((v) {
              final isSel = v == selected;
              return Center(
                child: Text(
                  format(v),
                  style: GoogleFonts.poppins(
                    fontSize: isSel ? 20 : 15,
                    fontWeight:
                        isSel ? FontWeight.w700 : FontWeight.w400,
                    color: isSel ? primary : muted,
                  ),
                ),
              );
            }).toList(),
          ),

          // Top fade overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: _itemExtent * 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bg, bg.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),

          // Bottom fade overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: _itemExtent * 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [bg, bg.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.isDark ? AppColors.darkPrimary : AppColors.primary;
    final onBg =
        widget.isDark ? AppColors.darkOnBackground : AppColors.onBackground;
    final muted = widget.isDark ? AppColors.darkMuted : AppColors.muted;
    final divColor =
        widget.isDark ? AppColors.darkDivider : AppColors.divider;
    final bg =
        widget.isDark ? AppColors.darkSurface : AppColors.surface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label + AM/PM toggle ─────────────────────────────────────
          Row(
            children: [
              Text('Time', style: AppTextStyles.labelLarge(color: onBg)),
              const Spacer(),
              Container(
                height: 32,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color:
                      widget.isDark ? AppColors.darkBackground : AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.chip + 2),
                  border: Border.all(color: divColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AmPmOption(
                      label: 'AM',
                      selected: !_isPm,
                      primary: primary,
                      muted: muted,
                      onTap: () {
                        setState(() => _isPm = false);
                        _notify();
                      },
                    ),
                    const SizedBox(width: 2),
                    _AmPmOption(
                      label: 'PM',
                      selected: _isPm,
                      primary: primary,
                      muted: muted,
                      onTap: () {
                        setState(() => _isPm = true);
                        _notify();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Drum-roll wheels ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hour wheel
              _buildWheel(
                values: _hours,
                ctrl: _hourCtrl,
                selected: _hour12,
                format: (v) => '$v',
                primary: primary,
                onBg: onBg,
                muted: muted,
                bg: bg,
                onIndexChanged: (i) {
                  setState(() => _hour12 = _hours[i]);
                  _notify();
                },
              ),

              // Colon separator centered in the wheel height
              SizedBox(
                height: _wheelHeight,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      ':',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: onBg,
                      ),
                    ),
                  ),
                ),
              ),

              // Minute wheel
              _buildWheel(
                values: _minutes,
                ctrl: _minCtrl,
                selected: _minute,
                format: (v) => v.toString().padLeft(2, '0'),
                primary: primary,
                onBg: onBg,
                muted: muted,
                bg: bg,
                onIndexChanged: (i) {
                  setState(() => _minute = _minutes[i]);
                  _notify();
                },
              ),
            ],
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _AmPmOption extends StatelessWidget {
  const _AmPmOption({
    required this.label,
    required this.selected,
    required this.primary,
    required this.muted,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color primary, muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 38,
          height: 26,
          decoration: BoxDecoration(
            color: selected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : muted,
            ),
          ),
        ),
      );
}


// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
      );
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title, required this.onBg});
  final String title;
  final Color onBg;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: AppTextStyles.titleLarge(color: onBg)),
        ),
      );
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.enabled,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: color),
        ),
      );
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.date,
    required this.active,
    required this.primary,
    required this.onBg,
    required this.muted,
    required this.isDark,
  });

  final String label;
  final DateTime? date;
  final bool active;
  final Color primary, onBg, muted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final filled = date != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: filled
            ? primary.withValues(alpha: 0.08)
            : active
                ? primary.withValues(alpha: 0.04)
                : Colors.transparent,
        border: Border.all(
          color: (filled || active)
              ? primary.withValues(alpha: 0.6)
              : borderColor,
          width: (filled || active) ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.chip + 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: (filled || active) ? primary : muted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date != null ? DateFormat('MMM d, y').format(date!) : '—',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: filled ? onBg : muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.borderColor, required this.onConfirm});
  final Color borderColor;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, color: borderColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onConfirm,
                child: const Text('Confirm'),
              ),
            ),
          ),
        ],
      );
}
