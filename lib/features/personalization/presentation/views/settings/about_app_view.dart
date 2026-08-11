import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/legal/legal_urls.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../widgets/about_app_widgets.dart';

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
                    AboutHero(isDark: isDark),
                    const SizedBox(height: 18),
                    AboutMenuCard(
                      isDark: isDark,
                      children: [
                        AboutMenuTile(
                          icon: AppIcons.message_text,
                          title: 'Frequently asked questions',
                          accentColor: AppColors.primary,
                          onTap: () => _showInformationSheet(
                            title: 'Frequently asked questions',
                            icon: AppIcons.message_text,
                            collapsible: true,
                            sections: const [
                              AboutInfoSection(
                                title: 'How do I place an order?',
                                body:
                                    'Choose your market and products, add the delivery address, then confirm your order from the cart.',
                              ),
                              AboutInfoSection(
                                title: 'How can I track my order?',
                                body:
                                    'Open My Orders from the account page to see the latest order status and delivery updates.',
                              ),
                              AboutInfoSection(
                                title: 'How do I contact support?',
                                body:
                                    'Use the WhatsApp button on the account page for direct assistance.',
                              ),
                            ],
                          ),
                        ),
                        AboutDivider(isDark: isDark),
                        AboutMenuTile(
                          icon: AppIcons.security_safe,
                          title: 'Privacy policy',
                          accentColor: AppColors.success,
                          onTap: () => _openLegalPage(
                            LegalUrls.privacy,
                            title: 'Privacy policy',
                            icon: AppIcons.security_safe,
                            sections: const [
                              AboutInfoSection(
                                title: 'Your information',
                                body:
                                    'We use your account and delivery information only to provide, secure, and improve Yalla Market services.',
                              ),
                              AboutInfoSection(
                                title: 'Data protection',
                                body:
                                    'We apply security controls to protect your information and never sell your personal data.',
                              ),
                            ],
                          ),
                        ),
                        AboutDivider(isDark: isDark),
                        AboutMenuTile(
                          icon: AppIcons.document_text,
                          title: 'Terms of use',
                          accentColor: AppColors.warning,
                          onTap: () => _openLegalPage(
                            LegalUrls.terms,
                            title: 'Terms of use',
                            icon: AppIcons.document_text,
                            sections: const [
                              AboutInfoSection(
                                title: 'Using Yalla Market',
                                body:
                                    'Use accurate account and delivery details and keep your password private.',
                              ),
                              AboutInfoSection(
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
                    AboutMenuCard(
                      isDark: isDark,
                      children: [
                        AboutMenuTile(
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
                        AboutDivider(isDark: isDark),
                        AboutMenuTile(
                          customIcon: const FaIcon(
                            FontAwesomeIcons.xTwitter,
                            size: 18,
                          ),
                          title: 'X',
                          accentColor: isDark ? Colors.white : Colors.black,
                          onTap: () =>
                              _openSocial(Uri.https('x.com', '/yallamarket')),
                        ),
                        AboutDivider(isDark: isDark),
                        AboutMenuTile(
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

  Future<void> _openLegalPage(
    Uri? uri, {
    required String title,
    required IconData icon,
    required List<AboutInfoSection> sections,
  }) async {
    if (uri != null) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {
        // Keep the in-app summary available when no browser can open.
      }
    }
    if (!mounted) return;
    _showInformationSheet(title: title, icon: icon, sections: sections);
  }

  void _showInformationSheet({
    required String title,
    required IconData icon,
    required List<AboutInfoSection> sections,
    bool collapsible = false,
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
                  if (collapsible)
                    AboutExpandableInfoCard(section: section, isDark: isDark)
                  else
                    AboutInfoCard(section: section, isDark: isDark),
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
