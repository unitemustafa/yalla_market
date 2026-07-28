part of 'promo_slider.dart';

class _PromoOfferCard extends StatelessWidget {
  const _PromoOfferCard({required this.offer, required this.onTap});

  final _PromoOfferData offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final endsAt = offer.endsAt;
    final actionLabel = offer.hasExternalLink
        ? offer.action(context).trim()
        : (context.isArabicLanguage ? 'اشتري الآن' : 'Buy now');

    return Material(
      color: isDark ? AppColors.darkCardColor : Colors.white,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('promo_offer_card'),
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: AppImage(
                key: const ValueKey('promo_offer_background'),
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
                key: const ValueKey('promo_offer_image_scrim'),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      Colors.black.withValues(alpha: 0.30),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.44),
                    ],
                    stops: const [0, 0.48, 1],
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final contentWidth = (constraints.maxWidth * 0.46)
                        .clamp(142.0, 174.0)
                        .toDouble();

                    return Stack(
                      children: [
                        Positioned(
                          left: 10,
                          top: 8,
                          bottom: 8,
                          width: contentWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 142,
                                  ),
                                  child: _OfferOverlayBadge(offer: offer),
                                ),
                              ),
                              const Spacer(),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _OfferBuyButton(
                                  onTap: onTap,
                                  label: actionLabel.isEmpty
                                      ? (context.isArabicLanguage
                                            ? 'فتح الإعلان'
                                            : 'Open ad')
                                      : actionLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (endsAt != null)
                          Positioned(
                            right: 10,
                            bottom: 8,
                            child: _OfferCountdownChip(
                              endsAt: endsAt,
                              color: offer.color,
                            ),
                          ),
                      ],
                    );
                  },
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
          Icon(offer.icon, color: Colors.white, size: 10),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              discountRate == null
                  ? offer.badge(context)
                  : '${offer.badge(context)} - $discountRate',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontSize: AppFontSizes.micro,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferBuyButton extends StatelessWidget {
  const _OfferBuyButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('promo_offer_buy_button'),
      width: 112,
      height: 28,
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontSize: AppFontSizes.small,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
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
      key: const ValueKey('promo_offer_countdown'),
      constraints: const BoxConstraints(maxWidth: 108),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
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
                fontSize: isCompact
                    ? AppFontSizes.caption
                    : AppFontSizes.bodyLarge,
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
                fontSize: isCompact ? AppFontSizes.micro : AppFontSizes.caption,
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
