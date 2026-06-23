part of 'edit_profile_field_view.dart';

class _BirthDatePickerSheet extends StatefulWidget {
  const _BirthDatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_BirthDatePickerSheet> createState() => _BirthDatePickerSheetState();
}

class _BirthDatePickerSheetState extends State<_BirthDatePickerSheet> {
  static const double _wheelItemExtent = 44;
  static const double _wheelPickerHeight = 220;

  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;
  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _yearController;

  DateTime get _selectedDate =>
      DateTime(_selectedYear, _selectedMonth, _selectedDay);

  List<int> get _years => [
    for (var year = widget.firstDate.year; year <= widget.lastDate.year; year++)
      year,
  ];

  List<int> get _months {
    final startMonth = _selectedYear == widget.firstDate.year
        ? widget.firstDate.month
        : 1;
    final endMonth = _selectedYear == widget.lastDate.year
        ? widget.lastDate.month
        : 12;

    return [for (var month = startMonth; month <= endMonth; month++) month];
  }

  List<int> get _days {
    final monthDays = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    final startDay =
        _selectedYear == widget.firstDate.year &&
            _selectedMonth == widget.firstDate.month
        ? widget.firstDate.day
        : 1;
    final endDay =
        _selectedYear == widget.lastDate.year &&
            _selectedMonth == widget.lastDate.month
        ? widget.lastDate.day
        : monthDays;

    return [for (var day = startDay; day <= endDay; day++) day];
  }

  @override
  void initState() {
    super.initState();
    final initialDate = _clampDate(widget.initialDate);
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

  DateTime _clampDate(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
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

    if (normalized.isBefore(first)) return first;
    if (normalized.isAfter(last)) return last;
    return normalized;
  }

  String _label(BuildContext context, String english, String arabic) {
    return context.isArabicLanguage ? arabic : english;
  }

  String _digits(BuildContext context, int value) {
    final text = value.toString();
    if (!context.isArabicLanguage) return text;

    const arabicDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    return text.split('').map((digit) {
      final index = int.tryParse(digit);
      return index == null ? digit : arabicDigits[index];
    }).join();
  }

  String _monthName(BuildContext context, int month) {
    final months = context.isArabicLanguage
        ? const [
            'يناير',
            'فبراير',
            'مارس',
            'أبريل',
            'مايو',
            'يونيو',
            'يوليو',
            'أغسطس',
            'سبتمبر',
            'أكتوبر',
            'نوفمبر',
            'ديسمبر',
          ]
        : const [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];

    return months[month - 1];
  }

  String _weekdayName(BuildContext context, DateTime date) {
    final names = context.isArabicLanguage
        ? const [
            'الاثنين',
            'الثلاثاء',
            'الأربعاء',
            'الخميس',
            'الجمعة',
            'السبت',
            'الأحد',
          ]
        : const [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ];

    return names[date.weekday - 1];
  }

  String _selectedDateText(BuildContext context) {
    if (context.isArabicLanguage) {
      return '${_weekdayName(context, _selectedDate)}، '
          '${_digits(context, _selectedDate.day)} '
          '${_monthName(context, _selectedDate.month)} '
          '${_digits(context, _selectedDate.year)}';
    }

    return '${_weekdayName(context, _selectedDate)}, '
        '${_monthName(context, _selectedDate.month)} '
        '${_selectedDate.day}, ${_selectedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.darkCardColor : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final outlineColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);
    final wheelSurfaceColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : const Color(0xFFF7F8FB);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 520),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.14),
                blurRadius: 28,
                offset: const Offset(0, -12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: mutedColor.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _BirthDateHeader(
                  title: _label(
                    context,
                    'Select birth date',
                    'اختيار تاريخ الميلاد',
                  ),
                  dateText: _selectedDateText(context),
                  isDark: isDark,
                  onClose: () => Navigator.pop(context),
                ),
                const SizedBox(height: 14),
                Container(
                  height: _wheelPickerHeight,
                  decoration: BoxDecoration(
                    color: wheelSurfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: outlineColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 42,
                        child: Row(
                          children: [
                            Expanded(
                              child: _WheelColumnLabel(context.tr('Day')),
                            ),
                            _WheelDivider(color: outlineColor),
                            Expanded(
                              child: _WheelColumnLabel(context.tr('Month')),
                            ),
                            _WheelDivider(color: outlineColor),
                            Expanded(
                              child: _WheelColumnLabel(context.tr('Year')),
                            ),
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
                                    onSelectedItemChanged: _updateDay,
                                    formatter: (value) =>
                                        _digits(context, value),
                                    itemExtent: _wheelItemExtent,
                                  ),
                                ),
                                _WheelDivider(color: outlineColor),
                                Expanded(
                                  child: _WheelPickerColumn(
                                    values: _months,
                                    controller: _monthController,
                                    onSelectedItemChanged: _updateMonth,
                                    formatter: (value) =>
                                        _digits(context, value),
                                    itemExtent: _wheelItemExtent,
                                  ),
                                ),
                                _WheelDivider(color: outlineColor),
                                Expanded(
                                  child: _WheelPickerColumn(
                                    values: _years,
                                    controller: _yearController,
                                    onSelectedItemChanged: _updateYear,
                                    formatter: (value) =>
                                        _digits(context, value),
                                    itemExtent: _wheelItemExtent,
                                  ),
                                ),
                              ],
                            ),
                            _WheelSelectionFrame(isDark: isDark),
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
                          foregroundColor: textColor,
                          side: BorderSide(color: outlineColor),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          context.tr('Cancel'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, _selectedDate),
                        icon: const Icon(AppIcons.tick_circle, size: 18),
                        label: Text(
                          context.tr('Save'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  void _updateDay(int index) {
    setState(() => _selectedDay = _days[index]);
  }

  int _clampValue(int value, List<int> values) {
    if (value < values.first) return values.first;
    if (value > values.last) return values.last;
    return value;
  }

  void _syncController(FixedExtentScrollController controller, int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients || index < 0) return;
      controller.jumpToItem(index);
    });
  }
}

class _WheelColumnLabel extends StatelessWidget {
  const _WheelColumnLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Center(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: mutedColor,
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
  Widget build(BuildContext context) {
    return Container(width: 1, height: double.infinity, color: color);
  }
}

class _WheelSelectionFrame extends StatelessWidget {
  const _WheelSelectionFrame({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: _BirthDatePickerSheetState._wheelItemExtent + 8,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: isDark ? 0.34 : 0.20),
          ),
        ),
      ),
    );
  }
}

class _WheelPickerColumn extends StatelessWidget {
  const _WheelPickerColumn({
    required this.values,
    required this.controller,
    required this.onSelectedItemChanged,
    required this.formatter,
    required this.itemExtent,
  });

  final List<int> values;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onSelectedItemChanged;
  final String Function(int value) formatter;
  final double itemExtent;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemExtent,
      diameterRatio: 1.8,
      perspective: 0.002,
      squeeze: 0.96,
      useMagnifier: true,
      magnification: 1.08,
      overAndUnderCenterOpacity: 0.42,
      physics: const FixedExtentScrollPhysics(parent: BouncingScrollPhysics()),
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: values.length,
        builder: (context, index) {
          return Center(
            child: Text(
              formatter(values[index]),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          );
        },
      ),
    );
  }
}
