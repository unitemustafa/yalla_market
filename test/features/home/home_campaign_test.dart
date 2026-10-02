import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/features/home/domain/entities/home_campaign_data.dart';
import 'package:yalla_market/features/home/domain/entities/home_data.dart';
import 'package:yalla_market/features/home/presentation/home_campaign/home_campaign_host.dart';
import 'package:yalla_market/features/home/presentation/home_campaign/home_campaign_preferences.dart';
import 'package:yalla_market/core/presentation/media/app_video.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/presentation/widgets/images/app_image.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('parses multiple campaign images and keeps legacy image support', () {
    final payload = _payload();
    (payload['media'] as Map<String, dynamic>)['image_urls'] = [
      'https://example.com/one.png',
      'https://example.com/two.png',
    ];
    final campaign = HomeCampaignData.fromJson(payload);
    expect(campaign.media.availableImageUrls, hasLength(2));
    expect(campaign.behavior.rotationSeconds, 1800);

    (payload['media'] as Map<String, dynamic>).remove('image_urls');
    expect(HomeCampaignData.fromJson(payload).media.availableImageUrls, [
      'https://example.com/legacy.png',
    ]);
  });

  test('selects one image per session and advances the saved index', () async {
    const identity = 'campaign_image_test';
    const urls = ['one', 'two'];
    expect(
      await HomeCampaignPreferences.imageForSession(identity, urls),
      'one',
    );
    expect(
      await HomeCampaignPreferences.imageForSession(identity, urls),
      'one',
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('home_campaign.image_index.$identity'), 0);

    const nextLaunchIdentity = 'campaign_next_launch_test';
    await preferences.setInt(
      'home_campaign.image_index.$nextLaunchIdentity',
      0,
    );
    expect(
      await HomeCampaignPreferences.imageForSession(nextLaunchIdentity, urls),
      'two',
    );
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

  testWidgets(
    'unavailable campaign video uses a static fallback without an endless loader',
    (tester) async {
      final payload = _payload()..['id'] = 49;
      (payload['media'] as Map<String, dynamic>)['type'] = 'video';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: HomeCampaignHost(
              campaign: HomeCampaignData.fromJson(payload),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppVideo), findsOneWidget);
      expect(
        tester.widget<AppVideo>(find.byType(AppVideo)).fit,
        BoxFit.contain,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AppImage && widget.source == AppAssets.defaultOffer,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('automatically opens a centered dialog and leaves no bar', (
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
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Campaign title'), findsOneWidget);
    expect(find.text('Campaign teaser'), findsNothing);
    final center = tester.getCenter(find.byType(Dialog));
    expect(
      (center.dy - tester.getSize(find.byType(Scaffold)).height / 2).abs(),
      lessThan(80),
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Campaign teaser'), findsNothing);
  });

  testWidgets('text-only campaign dialog fits its content', (tester) async {
    final campaign = HomeCampaignData.fromJson(_payload()..['id'] = 44);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: HomeCampaignHost(campaign: campaign),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final surface = find.byKey(const ValueKey('home_campaign_surface'));
    expect(tester.getSize(surface).height, lessThan(250));
    final descriptionBottom = tester
        .getBottomLeft(find.text('Campaign description'))
        .dy;
    final surfaceBottom = tester.getBottomLeft(surface).dy;
    expect(surfaceBottom - descriptionBottom, lessThan(35));
  });

  testWidgets('long campaign content scrolls within the height limit', (
    tester,
  ) async {
    final payload = _payload()..['id'] = 45;
    (payload['sheet'] as Map<String, dynamic>)['description'] =
        'Long campaign description. ' * 120;
    payload['action'] = {
      'type': 'copy_text',
      'label': 'Copy code',
      'value': 'SAVE',
      'target': null,
    };
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: HomeCampaignHost(
            campaign: HomeCampaignData.fromJson(payload),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final surface = find.byKey(const ValueKey('home_campaign_surface'));
    expect(tester.getSize(surface).height, lessThanOrEqualTo(350));
    await tester.ensureVisible(find.text('Copy code'));
    await tester.pumpAndSettle();
    expect(find.text('Copy code'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Copy code')).dy,
      greaterThan(tester.getTopLeft(surface).dy),
    );
    expect(
      tester.getBottomLeft(find.text('Copy code')).dy,
      lessThan(tester.getBottomLeft(surface).dy),
    );
  });

  testWidgets('centered campaign follows the dark app theme', (tester) async {
    final payload = _payload()..['id'] = 43;
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
          bottomNavigationBar: HomeCampaignHost(
            campaign: HomeCampaignData.fromJson(payload),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final title = tester.widget<Text>(find.text('Campaign title'));
    expect(title.style?.color, darkText);
  });
}

Map<String, dynamic> _payload() => {
  'id': 42,
  'updated_at': '2026-08-25T10:00:00Z',
  'teaser': {
    'text': 'Campaign teaser',
    'background_color': '#FF5A00',
    'text_color': '#FFFFFF',
    'image_url': '',
  },
  'sheet': {
    'title': 'Campaign title',
    'description': 'Campaign description',
    'template': 'hero',
    'size': 'medium',
    'alignment': 'center',
    'use_theme_colors': true,
    'background_color': '#FFFFFF',
    'text_color': '#202124',
    'button_background_color': '#FF5A00',
    'button_text_color': '#FFFFFF',
  },
  'media': <String, dynamic>{
    'type': 'none',
    'image_url': 'https://example.com/legacy.png',
    'video_url': '',
    'poster_url': '',
  },
  'action': {'type': 'none', 'label': '', 'value': '', 'target': null},
  'behavior': {
    'open_mode': 'tap_only',
    'dismiss_behavior': 'collapse_only',
    'rotation_seconds': 1800,
  },
};
