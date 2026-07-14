import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/core/localization/app_translations.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/app_route_arguments.dart';

class PaymentSuccessView extends StatefulWidget {
  const PaymentSuccessView({super.key, this.args, this.feedbackPlayer});

  final PaymentSuccessRouteArgs? args;
  final Future<void> Function()? feedbackPlayer;

  @override
  State<PaymentSuccessView> createState() => _PaymentSuccessViewState();
}

class _PaymentSuccessViewState extends State<PaymentSuccessView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _sceneAnimation;
  late final Animation<double> _contentAnimation;
  bool _animationStarted = false;
  bool _feedbackPlayed = false;
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
    _sceneAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.68, curve: Curves.easeOutBack),
    );
    _contentAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.32, 1, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _feedbackPlayed) return;
      _feedbackPlayed = true;
      unawaited((widget.feedbackPlayer ?? _playSuccessFeedback)());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animationStarted) return;
    _animationStarted = true;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  Future<void> _playSuccessFeedback() async {
    final player = AudioPlayer();
    _audioPlayer = player;
    try {
      await player.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
          respectSilence: true,
          stayAwake: false,
        ).build(),
      );
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(
        DeviceFileSource(await _successChimeFilePath()),
        volume: 0.62,
      );
    } catch (_) {
      if (identical(_audioPlayer, player)) _audioPlayer = null;
      await player.dispose();
    }
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Haptic feedback is optional on unsupported devices.
    }
  }

  @override
  void dispose() {
    final audioPlayer = _audioPlayer;
    _audioPlayer = null;
    if (audioPlayer != null) unawaited(audioPlayer.dispose());
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkBackground : Colors.white;
    final mutedColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final orderArgs = widget.args;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 48).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PaymentSuccessAnimation(animation: _sceneAnimation),
                    const SizedBox(height: 24),
                    _SuccessReveal(
                      animation: _contentAnimation,
                      child: Text(
                        context.tr('Order Confirmed Successfully!'),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SuccessReveal(
                      animation: _contentAnimation,
                      child: Text(
                        context.tr('We will contact you soon.'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: mutedColor,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (orderArgs != null) ...[
                      const SizedBox(height: 18),
                      _SuccessReveal(
                        animation: _contentAnimation,
                        child: _SuccessOrderSummary(
                          args: orderArgs,
                          isDark: isDark,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    _SuccessReveal(
                      animation: _contentAnimation,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          child: Text(
                            context.tr('Continue Shopping'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

Uint8List? _cachedSuccessChime;
Future<String>? _cachedSuccessChimePath;

Future<String> _successChimeFilePath() {
  return _cachedSuccessChimePath ??= () async {
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}yalla_payment_success.wav',
    );
    final bytes = _successChimeBytes();
    if (!await file.exists() || await file.length() != bytes.length) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return file.path;
  }();
}

Uint8List _successChimeBytes() {
  final cached = _cachedSuccessChime;
  if (cached != null) return cached;

  const sampleRate = 22050;
  const durationSeconds = 0.56;
  final sampleCount = (sampleRate * durationSeconds).round();
  final audioLength = sampleCount * 2;
  final data = ByteData(44 + audioLength);

  void writeAscii(int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      data.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  writeAscii(0, 'RIFF');
  data.setUint32(4, 36 + audioLength, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  writeAscii(36, 'data');
  data.setUint32(40, audioLength, Endian.little);

  double tone(
    double time, {
    required double startsAt,
    required double duration,
    required double frequency,
  }) {
    final localTime = time - startsAt;
    if (localTime < 0 || localTime >= duration) return 0;
    final attack = (localTime / 0.025).clamp(0.0, 1.0);
    final release = (1 - (localTime / duration)).clamp(0.0, 1.0);
    final envelope = attack * math.pow(release, 1.7);
    return math.sin(2 * math.pi * frequency * localTime) * envelope;
  }

  for (var index = 0; index < sampleCount; index++) {
    final time = index / sampleRate;
    final sample =
        (0.34 * tone(time, startsAt: 0, duration: 0.23, frequency: 659.25)) +
        (0.18 * tone(time, startsAt: 0, duration: 0.23, frequency: 987.77)) +
        (0.36 * tone(time, startsAt: 0.15, duration: 0.41, frequency: 880)) +
        (0.18 * tone(time, startsAt: 0.15, duration: 0.41, frequency: 1318.51));
    final pcm = (sample.clamp(-1.0, 1.0) * 32767).round();
    data.setInt16(44 + (index * 2), pcm, Endian.little);
  }

  return _cachedSuccessChime = data.buffer.asUint8List();
}

class _PaymentSuccessAnimation extends StatelessWidget {
  const _PaymentSuccessAnimation({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr('Order confirmed'),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final value = animation.value;
          final opacity = value.clamp(0.0, 1.0);
          final scale = 0.72 + (0.28 * value);

          return SizedBox(
            key: const ValueKey('payment_success_animation'),
            width: 220,
            height: 210,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _SuccessParticle(
                  top: 24 - (10 * value),
                  left: 38 - (12 * value),
                  size: 13,
                  color: AppColors.warning,
                  opacity: opacity,
                ),
                _SuccessParticle(
                  top: 42 - (8 * value),
                  right: 28 - (12 * value),
                  size: 10,
                  color: AppColors.success,
                  opacity: opacity,
                ),
                _SuccessParticle(
                  bottom: 28 - (8 * value),
                  left: 28 - (10 * value),
                  size: 9,
                  color: AppColors.primary,
                  opacity: opacity,
                ),
                _SuccessParticle(
                  bottom: 18 - (12 * value),
                  right: 38 - (10 * value),
                  size: 14,
                  color: AppColors.warning,
                  opacity: opacity,
                ),
                Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 174,
                      height: 174,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6877FF), AppColors.primary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.34),
                            blurRadius: 34,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 68,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - value)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              context.tr('Order confirmed'),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SuccessParticle extends StatelessWidget {
  const _SuccessParticle({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size * 0.35),
          ),
        ),
      ),
    );
  }
}

class _SuccessReveal extends StatelessWidget {
  const _SuccessReveal({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.14),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _SuccessOrderSummary extends StatelessWidget {
  const _SuccessOrderSummary({required this.args, required this.isDark});

  final PaymentSuccessRouteArgs args;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final mutedColor = isDark ? Colors.white70 : Colors.black54;
    final marketText = args.marketSummary.trim().isNotEmpty
        ? args.marketSummary
        : context.tr(
            '${args.marketCount} market${args.marketCount == 1 ? '' : 's'}',
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _SuccessSummaryRow(label: 'Order', value: args.orderId),
          const SizedBox(height: 8),
          _SuccessSummaryRow(label: 'Status', value: args.status),
          if (args.reviewStatus.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _SuccessSummaryRow(label: 'Review', value: args.reviewStatus),
          ],
          const SizedBox(height: 8),
          _SuccessSummaryRow(label: 'Total', value: args.total),
          if (args.isMultiMarket || args.marketCount > 1) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(AppIcons.shop, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(marketText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SuccessSummaryRow extends StatelessWidget {
  const _SuccessSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          context.tr(label),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            context.tr(value),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
