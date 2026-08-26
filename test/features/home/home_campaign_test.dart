import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/features/home/domain/entities/home_campaign_data.dart';
import 'package:yalla_market/features/home/domain/entities/home_data.dart';
import 'package:yalla_market/features/home/presentation/home_campaign/home_campaign_host.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('parses the structured home campaign payload', () {
    final campaign = HomeCampaignData.fromJson(_payload());
    expect(campaign.id, '42');
    expect(campaign.teaser.text, 'عرض النهارده');
    expect(campaign.sheet.template, 'hero');
    expect(campaign.action.type, 'none');
    expect(campaign.teaser.backgroundColorValue, 0xFFFF5A00);
    expect(campaign.sheet.useThemeColors, isTrue);
    expect(campaign.behavior.rotationSeconds, 1800);
  });

  test('home payload exposes its campaign without changing existing lists', () {
    final home = HomeData.fromJson({
      'offers': <Object?>[],
      'market_classifications': <Object?>[],
      'products': <Object?>[],
      'home_campaign': _payload(),
    });
    expect(home.homeCampaign?.id, '42');
    expect(home.offers, isEmpty);
    expect(home.categories, isEmpty);
    expect(home.products, isEmpty);
  });

  testWidgets('opens the sheet and hides the teaser for the session', (
    tester,
  ) async {
    final campaign = HomeCampaignData.fromJson(_payload());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: HomeCampaignHost(campaign: campaign),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('عرض النهارده'), findsOneWidget);

    await tester.tap(find.text('عرض النهارده'));
    await tester.pumpAndSettle();
    expect(find.text('وفر في طلبك'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);

    await tester.tap(find.byTooltip('إغلاق'));
    await tester.pumpAndSettle();
    expect(find.text('عرض النهارده'), findsNothing);
  });

  testWidgets('campaign sheet follows the dark app theme', (tester) async {
    final payload = _payload()..['id'] = 43;
    final campaign = HomeCampaignData.fromJson(payload);
    const darkText = Color(0xFFE9EEF8);
    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            surface: Color(0xFF17191F),
            onSurface: darkText,
          ),
        ),
        home: Scaffold(
          bottomNavigationBar: HomeCampaignHost(campaign: campaign),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('عرض النهارده'));
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(find.text('وفر في طلبك'));
    expect(title.style?.color, darkText);
  });
}

Map<String, dynamic> _payload() => {
  'id': 42,
  'updated_at': '2026-08-25T10:00:00Z',
  'teaser': {
    'text': 'عرض النهارده',
    'background_color': '#FF5A00',
    'text_color': '#FFFFFF',
    'image_url': '',
  },
  'sheet': {
    'title': 'وفر في طلبك',
    'description': 'عرض مخصص ليك لفترة محدودة',
    'template': 'hero',
    'size': 'medium',
    'alignment': 'center',
    'use_theme_colors': true,
    'background_color': '#FFFFFF',
    'text_color': '#202124',
    'button_background_color': '#FF5A00',
    'button_text_color': '#FFFFFF',
  },
  'media': {'type': 'none', 'image_url': '', 'video_url': '', 'poster_url': ''},
  'action': {'type': 'none', 'label': '', 'value': '', 'target': null},
  'behavior': {
    'open_mode': 'tap_only',
    'dismiss_behavior': 'hide_session',
    'rotation_seconds': 1800,
  },
};
