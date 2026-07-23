import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';

class AboutAppView extends StatefulWidget {
  const AboutAppView({super.key});

  @override
  State<AboutAppView> createState() => _AboutAppViewState();
}

class _AboutAppViewState extends State<AboutAppView> {
  String _versionLabel = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _versionLabel = '${info.version} (${info.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  children: [
                    const PageTopBar(
                      title: 'About Yalla Market',
                      subtitle: 'Everything you need to know about the app',
                    ),
                    const SizedBox(height: 18),
                    _AboutHero(isDark: isDark),
                    const SizedBox(height: 18),
                    _AboutMenuCard(
                      isDark: isDark,
                      children: [
                        _AboutMenuTile(
                          icon: AppIcons.message_text,
                          title: 'Frequently asked questions',
                          accentColor: AppColors.primary,
                          onTap: () => _showInformationSheet(
                            title: 'Frequently asked questions',
                            icon: AppIcons.message_text,
                            sections: const [
                              _InfoSection(
                                title: 'How do I place an order?',
                                body:
                                    'Choose your market and products, add the delivery address, then confirm your order from the cart.',
                              ),
                              _InfoSection(
                                title: 'How can I track my order?',
                                body:
                                    'Open My Orders from the account page to see the latest order status and delivery updates.',
                              ),
                              _InfoSection(
                                title: 'How do I contact support?',
                                body:
                                    'Use the WhatsApp button on the account page for direct assistance.',
                              ),
                            ],
                          ),
                        ),
                        _AboutDivider(isDark: isDark),
                        _AboutMenuTile(
                          icon: AppIcons.security_safe,
                          title: 'Privacy policy',
                          accentColor: AppColors.success,
                          onTap: () => _showInformationSheet(
                            title: 'Privacy policy',
                            icon: AppIcons.security_safe,
                            sections: const [
                              _InfoSection(
                                title: 'Your information',
                                body:
                                    'We use your account and delivery information only to provide, secure, and improve Yalla Market services.',
                              ),
                              _InfoSection(
                                title: 'Data protection',
                                body:
                                    'We apply security controls to protect your information and never sell your personal data.',
                              ),
                            ],
                          ),
                        ),
                        _AboutDivider(isDark: isDark),
                        _AboutMenuTile(
                          icon: AppIcons.document_text,
                          title: 'Terms of use',
                          accentColor: AppColors.warning,
                          onTap: () => _showInformationSheet(
                            title: 'Terms of use',
                            icon: AppIcons.document_text,
                            sections: const [
                              _InfoSection(
                                title: 'Using Yalla Market',
                                body:
                                    'Use accurate account and delivery details and keep your password private.',
                              ),
                              _InfoSection(
                                title: 'Orders and availability',
                                body:
                                    'Product availability, prices, and delivery times can change before an order is confirmed.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _AboutMenuCard(
                      isDark: isDark,
                      children: [
                        _AboutMenuTile(
                          customIcon: const FaIcon(
                            FontAwesomeIcons.facebookF,
                            size: 18,
                          ),
                          title: 'Facebook',
                          accentColor: const Color(0xFF1877F2),
                          onTap: () => _openSocial(
                            Uri.https('www.facebook.com', '/yallamarket'),
                          ),
                        ),
                        _AboutDivider(isDark: isDark),
                        _AboutMenuTile(
                          customIcon: const FaIcon(
                            FontAwesomeIcons.xTwitter,
                            size: 18,
                          ),
                          title: 'X',
                          accentColor: isDark ? Colors.white : Colors.black,
                          onTap: () =>
                              _openSocial(Uri.https('x.com', '/yallamarket')),
                        ),
                        _AboutDivider(isDark: isDark),
                        _AboutMenuTile(
                          customIcon: const FaIcon(
                            FontAwesomeIcons.instagram,
                            size: 19,
                          ),
                          title: 'Instagram',
                          accentColor: const Color(0xFFE1306C),
                          onTap: () => _openSocial(
                            Uri.https('www.instagram.com', '/yallamarket'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardColor : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Text(
                _versionLabel.isEmpty
                    ? context.tr('Loading version...')
                    : '${context.tr('Version')} $_versionLabel',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSocial(Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched || !mounted) return;
    } catch (_) {
      if (!mounted) return;
    }

    CustomSnackBar.showError(
      context: context,
      title: 'Could not open link',
      message: 'Please try again.',
    );
  }

  void _showInformationSheet({
    required String title,
    required IconData icon,
    required List<_InfoSection> sections,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: isDark ? AppColors.darkCardColor : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          minChildSize: 0.42,
          maxChildSize: 0.90,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(height: 14),
                Text(
                  context.tr(title),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                for (final section in sections) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF7F8FB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(section.title),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          context.tr(section.body),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                height: 1.55,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _AboutHero extends StatelessWidget {
  const _AboutHero({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              AppIcons.shopping_bag,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('Simple shopping from trusted local markets.'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutMenuCard extends StatelessWidget {
  const _AboutMenuCard({required this.isDark, required this.children});

  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _AboutMenuTile extends StatelessWidget {
  const _AboutMenuTile({
    this.icon,
    this.customIcon,
    required this.title,
    required this.accentColor,
    required this.onTap,
  }) : assert(icon != null || customIcon != null);

  final IconData? icon;
  final Widget? customIcon;
  final String title;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: IconTheme(
                  data: IconThemeData(color: accentColor),
                  child: Center(
                    child:
                        customIcon ?? Icon(icon, color: accentColor, size: 21),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr(title),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                isRtl ? AppIcons.arrow_left_2 : AppIcons.arrow_right_3,
                size: 18,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutDivider extends StatelessWidget {
  const _AboutDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64,
      color: isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.black.withValues(alpha: 0.06),
    );
  }
}

class _InfoSection {
  const _InfoSection({required this.title, required this.body});

  final String title;
  final String body;
}
