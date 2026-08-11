import 'package:flutter/material.dart';
import 'package:yalla_market/core/localization/app_translations.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/icons/app_icons.dart';

const double _actionHeight = 54;
const double _controlRadius = 18;
const double _wheelItemExtent = 44;
const double _wheelPickerHeight = 220;

class WheelDatePickerDialog extends StatefulWidget {
  const WheelDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<WheelDatePickerDialog> createState() => _WheelDatePickerDialogState();
}

class _WheelDatePickerDialogState extends State<WheelDatePickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;
  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _yearController;

  DateTime get _selectedDate =>
      DateTime(_selectedYear, _selectedMonth, _selectedDay);

  List<int> get _years => [
    for (int year = widget.firstDate.year; year <= widget.lastDate.year; year++)
      year,
  ];

  List<int> get _months {
    final start = _selectedYear == widget.firstDate.year
        ? widget.firstDate.month
        : 1;
    final end = _selectedYear == widget.lastDate.year
        ? widget.lastDate.month
        : 12;
    return [for (int month = start; month <= end; month++) month];
  }

  List<int> get _days {
    final monthDays = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    final start =
        _selectedYear == widget.firstDate.year &&
            _selectedMonth == widget.firstDate.month
        ? widget.firstDate.day
        : 1;
    final end =
        _selectedYear == widget.lastDate.year &&
            _selectedMonth == widget.lastDate.month
        ? widget.lastDate.day
        : monthDays;
    return [for (int day = start; day <= end; day++) day];
  }

  @override
  void initState() {
    super.initState();
    final initialDate = _normalize(widget.initialDate);
    _selectedYear = initialDate.year;
    _selectedMonth = initialDate.month;
    _selectedDay = initialDate.day;
    _dayController = FixedExtentScrollController(
      initialItem: _days.indexOf(_selectedDay),
    );
    _monthController = FixedExtentScrollController(
      initialItem: _months.indexOf(_selectedMonth),
    );
    _yearController = FixedExtentScrollController(
      initialItem: _years.indexOf(_selectedYear),
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkCardColor : Colors.white;
    final outlineColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);
    final surfaceColor = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : const Color(0xFFF7F8FB);
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: outlineColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.12),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: isDark ? 0.22 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        AppIcons.calendar,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 58),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.tr('Choose date'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_selectedDate),
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: mutedColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        fixedSize: const Size(44, 44),
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: _wheelPickerHeight,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: outlineColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SizedBox(
                    height: 42,
                    child: Row(
                      children: [
                        Expanded(child: _WheelLabel(context.tr('Day'))),
                        _WheelDivider(color: outlineColor),
                        Expanded(child: _WheelLabel(context.tr('Month'))),
                        _WheelDivider(color: outlineColor),
                        Expanded(child: _WheelLabel(context.tr('Year'))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _WheelPickerColumn(
                                values: _days,
                                controller: _dayController,
                                onChanged: _updateDay,
                                formatter: _twoDigits,
                              ),
                            ),
                            _WheelDivider(color: outlineColor),
                            Expanded(
                              child: _WheelPickerColumn(
                                values: _months,
                                controller: _monthController,
                                onChanged: _updateMonth,
                                formatter: _twoDigits,
                              ),
                            ),
                            _WheelDivider(color: outlineColor),
                            Expanded(
                              child: _WheelPickerColumn(
                                values: _years,
                                controller: _yearController,
                                onChanged: _updateYear,
                                formatter: (value) => '$value',
                              ),
                            ),
                          ],
                        ),
                        IgnorePointer(
                          child: Container(
                            height: _wheelItemExtent + 8,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(
                                alpha: isDark ? 0.18 : 0.08,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(_actionHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_controlRadius),
                      ),
                      side: BorderSide(color: outlineColor),
                    ),
                    child: Text(context.tr('Cancel')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _selectedDate),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(_actionHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_controlRadius),
                      ),
                    ),
                    child: Text(context.tr('Confirm')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateYear(int index) {
    setState(() {
      _selectedYear = _years[index];
      _selectedMonth = _clampValue(_selectedMonth, _months);
      _selectedDay = _clampValue(_selectedDay, _days);
    });
    _syncController(_monthController, _months.indexOf(_selectedMonth));
    _syncController(_dayController, _days.indexOf(_selectedDay));
  }

  void _updateMonth(int index) {
    setState(() {
      _selectedMonth = _months[index];
      _selectedDay = _clampValue(_selectedDay, _days);
    });
    _syncController(_dayController, _days.indexOf(_selectedDay));
  }

  void _updateDay(int index) => setState(() => _selectedDay = _days[index]);

  int _clampValue(int value, List<int> values) =>
      value.clamp(values.first, values.last);

  void _syncController(FixedExtentScrollController controller, int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients || index < 0) return;
      controller.jumpToItem(index);
    });
  }

  DateTime _normalize(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    final first = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
      widget.firstDate.day,
    );
    final last = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
      widget.lastDate.day,
    );
    if (date.isBefore(first)) return first;
    if (date.isAfter(last)) return last;
    return date;
  }

  String _formatDate(DateTime value) =>
      '${_twoDigits(value.day)}/${_twoDigits(value.month)}/${value.year}';

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _WheelLabel extends StatelessWidget {
  const _WheelLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WheelDivider extends StatelessWidget {
  const _WheelDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(width: 1, color: color);
}

class _WheelPickerColumn extends StatelessWidget {
  const _WheelPickerColumn({
    required this.values,
    required this.controller,
    required this.onChanged,
    required this.formatter,
  });

  final List<int> values;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onChanged;
  final String Function(int) formatter;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _wheelItemExtent,
      diameterRatio: 1.8,
      perspective: 0.002,
      squeeze: 0.96,
      useMagnifier: true,
      magnification: 1.08,
      overAndUnderCenterOpacity: 0.42,
      physics: const FixedExtentScrollPhysics(parent: BouncingScrollPhysics()),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: values.length,
        builder: (context, index) => Center(
          child: Text(
            formatter(values[index]),
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
