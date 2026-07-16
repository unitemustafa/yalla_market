part of 'promo_slider.dart';

class _PromoOfferCard extends StatelessWidget {
  const _PromoOfferCard({required this.offer, required this.onTap});

  final _PromoOfferData offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = Colors.white;
    final bodyColor = Colors.white.withValues(alpha: 0.82);
    final endsAt = offer.endsAt;

    return Material(
      color: isDark ? AppColors.darkCardColor : Colors.white,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: AppImage(
                source: offer.image,
                fallbackType: AppImagePlaceholderType.offer,
                fit: BoxFit.cover,
                cacheWidth: 720,
                cacheHeight: 316,
                filterQuality: FilterQuality.low,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      Colors.black.withValues(alpha: 0.56),
                      Colors.black.withValues(alpha: 0.24),
                      Colors.black.withValues(alpha: 0.66),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.045),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  children: [
                    Row(
                      textDirection: TextDirection.ltr,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 116),
                              child: _OfferOverlayBadge(offer: offer),
                            ),
                          ),
                        ),
                        if (endsAt != null) ...[
                          Flexible(
                            fit: FlexFit.loose,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _OfferCountdownChip(
                                endsAt: endsAt,
                                color: offer.color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Align(
                      alignment: AlignmentDirectional.bottomStart,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 270),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              offer.title(context),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: titleColor,
                                    fontSize: 21,
                                    height: 1.08,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            _OfferDescriptionTicker(
                              text: offer.outsideDescription(context),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: bodyColor,
                                    fontSize: 12,
                                    height: 1.35,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferOverlayBadge extends StatelessWidget {
  const _OfferOverlayBadge({required this.offer});

  final _PromoOfferData offer;

  @override
  Widget build(BuildContext context) {
    final discountRate = offer.hasExternalLink
        ? null
        : offer.discountRate(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: offer.color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(offer.icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              discountRate == null
                  ? offer.badge(context)
                  : '${offer.badge(context)} - $discountRate',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferDescriptionTicker extends StatefulWidget {
  const _OfferDescriptionTicker({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  State<_OfferDescriptionTicker> createState() =>
      _OfferDescriptionTickerState();
}

class _OfferDescriptionTickerState extends State<_OfferDescriptionTicker> {
  final ScrollController _controller = ScrollController();
  Timer? _delayTimer;
  Completer<bool>? _delayCompleter;
  int _runId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restartTicker());
  }

  @override
  void didUpdateWidget(covariant _OfferDescriptionTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restartTicker());
    }
  }

  @override
  void dispose() {
    _runId++;
    _cancelDelay();
    _controller.dispose();
    super.dispose();
  }

  void _restartTicker() {
    if (!mounted) return;
    _runId++;
    _cancelDelay();
    if (_controller.hasClients) {
      _controller.jumpTo(0);
    }
    unawaited(_runTicker(_runId));
  }

  Future<void> _runTicker(int runId) async {
    if (!await _wait(const Duration(milliseconds: 800))) return;
    while (mounted && _controller.hasClients && runId == _runId) {
      final maxExtent = _controller.position.maxScrollExtent;
      if (maxExtent <= 1) return;

      final forwardMs = (maxExtent * 38).clamp(1400, 5200).round();
      await _controller.animateTo(
        maxExtent,
        duration: Duration(milliseconds: forwardMs),
        curve: Curves.linear,
      );
      if (!await _wait(const Duration(milliseconds: 650))) return;
      if (!mounted || !_controller.hasClients || runId != _runId) return;

      await _controller.animateTo(
        0,
        duration: const Duration(milliseconds: 850),
        curve: Curves.easeOut,
      );
      if (!await _wait(const Duration(milliseconds: 900))) return;
    }
  }

  Future<bool> _wait(Duration duration) {
    _cancelDelay();
    final completer = Completer<bool>();
    _delayCompleter = completer;
    _delayTimer = Timer(duration, () {
      _delayTimer = null;
      if (identical(_delayCompleter, completer)) {
        _delayCompleter = null;
      }
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    });
    return completer.future;
  }

  void _cancelDelay() {
    _delayTimer?.cancel();
    _delayTimer = null;

    final completer = _delayCompleter;
    _delayCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Text(
          widget.text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: widget.style,
        ),
      ),
    );
  }
}

class _OfferCountdownChip extends StatefulWidget {
  const _OfferCountdownChip({required this.endsAt, required this.color});

  final DateTime endsAt;
  final Color color;

  @override
  State<_OfferCountdownChip> createState() => _OfferCountdownChipState();
}

class _OfferCountdownChipState extends State<_OfferCountdownChip> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.endsAt.difference(_now);
    final duration = remaining.isNegative ? Duration.zero : remaining;

    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.color.withValues(alpha: 0.24)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: _CountdownUnits(
          duration: duration,
          color: widget.color,
          numberColor: AppColors.lightTextPrimary,
          isCompact: true,
          isSingleLine: true,
        ),
      ),
    );
  }
}

class _CountdownUnits extends StatelessWidget {
  const _CountdownUnits({
    required this.duration,
    required this.color,
    required this.numberColor,
    this.isCompact = false,
    this.isSingleLine = false,
  });

  final Duration duration;
  final Color color;
  final Color numberColor;
  final bool isCompact;
  final bool isSingleLine;

  @override
  Widget build(BuildContext context) {
    final totalSeconds = duration.inSeconds;
    const secondsPerDay = 24 * 60 * 60;
    final days = totalSeconds ~/ secondsPerDay;
    final hours = (totalSeconds % secondsPerDay) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final units = [
      _CountdownUnitData(
        value: days.toString(),
        label: _useArabicCopy(context) ? 'يوم' : 'day',
      ),
      _CountdownUnitData(
        value: hours.toString().padLeft(2, '0'),
        label: _useArabicCopy(context) ? 'ساعة' : 'hr',
      ),
      _CountdownUnitData(
        value: minutes.toString().padLeft(2, '0'),
        label: _useArabicCopy(context) ? 'دقيقة' : 'min',
      ),
      _CountdownUnitData(
        value: seconds.toString().padLeft(2, '0'),
        label: _useArabicCopy(context) ? 'ثانية' : 'sec',
      ),
    ];

    if (isSingleLine) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < units.length; index++) ...[
              _CountdownUnitCell(
                data: units[index],
                color: color,
                numberColor: numberColor,
                isCompact: true,
              ),
              if (index != units.length - 1) const SizedBox(width: 3),
            ],
          ],
        ),
      );
    }

    if (isCompact) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CountdownUnitCell(
                  data: units[0],
                  color: color,
                  numberColor: numberColor,
                  isCompact: true,
                ),
                const SizedBox(width: 4),
                _CountdownUnitCell(
                  data: units[1],
                  color: color,
                  numberColor: numberColor,
                  isCompact: true,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CountdownUnitCell(
                  data: units[2],
                  color: color,
                  numberColor: numberColor,
                  isCompact: true,
                ),
                const SizedBox(width: 4),
                _CountdownUnitCell(
                  data: units[3],
                  color: color,
                  numberColor: numberColor,
                  isCompact: true,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < units.length; index++) ...[
            _CountdownUnitCell(
              data: units[index],
              color: color,
              numberColor: numberColor,
              isCompact: false,
            ),
            if (index != units.length - 1) const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }
}

class _CountdownUnitData {
  const _CountdownUnitData({required this.value, required this.label});

  final String value;
  final String label;
}

class _CountdownUnitCell extends StatelessWidget {
  const _CountdownUnitCell({
    required this.data,
    required this.color,
    required this.numberColor,
    required this.isCompact,
  });

  final _CountdownUnitData data;
  final Color color;
  final Color numberColor;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final width = isCompact ? 29.0 : 44.0;

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 3 : 5,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              data.value,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: numberColor,
                fontSize: isCompact ? 10 : 14,
                height: 1,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          SizedBox(height: isCompact ? 2 : 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              data.label,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: isCompact ? 7 : 10,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
