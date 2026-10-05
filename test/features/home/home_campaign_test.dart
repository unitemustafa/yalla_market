import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/features/home/domain/entities/home_campaign_data.dart';
import 'package:yalla_market/features/home/domain/entities/home_data.dart';
import 'package:yalla_market/features/home/presentation/home_campaign/home_campaign_host.dart';
import 'package:yalla_market/features/home/presentation/home_campaign/home_campaign_preferences.dart';
import 'package:yalla_market/features/home/presentation/home_campaign/home_campaign_sheet.dart';
import 'package:yalla_market/core/presentation/media/app_video.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/presentation/widgets/images/app_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Cairo')
      ..addFont(rootBundle.load('assets/fonts/Cairo.ttf'));
    await font.load();
  });
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

  for (final width in [320.0, 360.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'compact campaign overlays close and fits Arabic title at $width/$brightness',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          const title = 'انسخ الكود واستخدمه';
          final payload = _payload();
          payload['sheet'] = <String, dynamic>{
            ...payload['sheet'] as Map<String, dynamic>,
            'title': title,
            'description': 'اضغط الزر لنسخ الكود فورًا.',
          };
          payload['media'] = {
            'type': 'image',
            'image_url': AppAssets.defaultOffer,
          };
          payload['action'] = {
            'type': 'copy_text',
            'label': 'انسخ الكود',
            'value': 'SAVE',
          };
          HomeCampaignSheetResult? result;
          await _openCampaign(
            tester,
            payload,
            brightness: brightness,
            onResult: (value) => result = value,
          );

          final mediaRect = tester.getRect(
            find.byKey(const ValueKey('campaign_image_viewport')),
          );
          final close = find.byTooltip('إغلاق');
          final closeRect = tester.getRect(close);
          expect(mediaRect.contains(closeRect.topLeft), isTrue);
          expect(mediaRect.contains(closeRect.bottomRight), isTrue);
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(title),
          );
          final titleBoxes = paragraph.getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: title.length),
          );
          expect(titleBoxes, isNotEmpty);
          expect(titleBoxes.map((box) => box.top).toSet(), hasLength(1));
          expect(
            tester
                .getSize(find.byKey(const ValueKey('home_campaign_surface')))
                .height,
            lessThan(360),
          );
          await tester.tap(close);
          await tester.pumpAndSettle();
          expect(result, HomeCampaignSheetResult.dismissed);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final template in ['hero', 'split', 'media_focus']) {
    testWidgets(
      '$template wraps arbitrary campaign text without shrinking or truncating',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        const title =
            'اكتشف أحدث المنتجات والعروض المتاحة لفترة محدودة واستمتع بتجربة تسوق جديدة مع توصيل سريع لحد باب البيت';
        const description =
            'اختار المنتجات اللي محتاجها من المحلات القريبة منك واستفيد من عروضنا الجديدة في كل مرة تطلب فيها.';
        final payload = _payload();
        payload['sheet'] = <String, dynamic>{
          ...payload['sheet'] as Map<String, dynamic>,
          'template': template,
          'title': title,
          'description': description,
        };
        payload['media'] = {
          'type': 'image',
          'image_url': AppAssets.defaultOffer,
        };
        payload['action'] = {'type': 'offer', 'label': 'شوف العروض الجديدة'};
        await _openCampaign(tester, payload);

        final titleWidget = tester.widget<Text>(find.text(title));
        expect(titleWidget.style?.fontSize, 18);
        expect(titleWidget.maxLines, isNull);
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(title),
        );
        final boxes = paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: title.length),
        );
        expect(
          boxes.map((box) => box.top).toSet().length,
          greaterThanOrEqualTo(3),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(find.text(description), findsOneWidget);
        final action = find.byType(FilledButton);
        final surface = tester.getRect(
          find.byKey(const ValueKey('home_campaign_surface')),
        );
        expect(
          tester.getRect(action).bottom,
          lessThanOrEqualTo(surface.bottom),
        );
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scenario in [
    (width: 320.0, textScale: 1.0),
    (width: 360.0, textScale: 1.0),
    (width: 800.0, textScale: 1.5),
    (width: 800.0, textScale: 1.0),
  ]) {
    testWidgets(
      'legacy split uses Hero at width ${scenario.width} and text scale ${scenario.textScale}',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(scenario.width, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final payload = _payload();
        payload['sheet'] = <String, dynamic>{
          ...payload['sheet'] as Map<String, dynamic>,
          'template': 'split',
          'size': 'large',
          'title': 'انسخ الكود واستخدمه',
          'description': 'اضغط الزر لنسخ الكود فورًا.',
        };
        (payload['media'] as Map<String, dynamic>).addAll({
          'type': 'image',
          'image_url': AppAssets.defaultOffer,
        });
        payload['action'] = {
          'type': 'copy_text',
          'label': 'انسخ الكود',
          'value': 'SAVE',
        };
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'Cairo'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scenario.textScale)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              ),
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showHomeCampaignSheet(
                    context,
                    HomeCampaignData.fromJson(payload),
                  ),
                  child: const Text('Open campaign'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open campaign'));
        await tester.pumpAndSettle();

        final title = find.text('انسخ الكود واستخدمه');
        final media = find.byKey(const ValueKey('campaign_image_viewport'));
        expect(
          tester.getTopLeft(title).dy,
          greaterThanOrEqualTo(tester.getBottomLeft(media).dy),
        );
        expect(tester.getSize(title).width, greaterThan(240));
        await tester.ensureVisible(find.text('انسخ الكود'));
        await tester.tap(find.text('انسخ الكود'));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final template in ['hero', 'split', 'media_focus']) {
    for (final size in ['medium', 'large', 'near_full']) {
      for (final mediaType in ['image', 'video', 'none', 'empty_image']) {
        testWidgets('$template/$size/$mediaType fits enlarged long content', (
          tester,
        ) async {
          const viewport = Size(360, 800);
          await tester.binding.setSurfaceSize(viewport);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          const title = 'انسخ الكود واستخدمه للحصول على خصم على طلبك القادم';
          const label = 'انسخ كود الخصم واستخدمه عند إتمام طلبك القادم';
          final payload = _payload();
          payload['sheet'] = <String, dynamic>{
            ...payload['sheet'] as Map<String, dynamic>,
            'template': template,
            'size': size,
            'alignment': 'start',
            'title': title,
            'description': 'تفاصيل الحملة والعرض المتاح لجميع العملاء. ' * 20,
            'use_theme_colors': false,
          };
          payload['media'] = <String, dynamic>{
            'type': mediaType == 'empty_image' ? 'image' : mediaType,
            'image_url': mediaType == 'empty_image'
                ? ''
                : AppAssets.defaultOffer,
            'video_url': '',
          };
          payload['action'] = <String, dynamic>{
            'type': mediaType == 'none' ? 'none' : 'copy_text',
            'label': label,
            'value': 'SAVE',
          };
          HomeCampaignSheetResult? result;
          await _openCampaign(
            tester,
            payload,
            textScale: 1.8,
            onResult: (value) => result = value,
          );

          final surface = find.byKey(const ValueKey('home_campaign_surface'));
          expect(
            tester.getSize(surface).height,
            lessThanOrEqualTo(viewport.height * 0.58),
          );
          expect(
            tester.widget<Text>(find.text(title)).textAlign,
            TextAlign.center,
          );
          expect(
            tester.widget<Text>(find.text(title)).style?.color,
            const Color(0xFF202124),
          );
          if (mediaType == 'none' || mediaType == 'empty_image') {
            expect(find.byType(AspectRatio), findsNothing);
          } else {
            final media = find.byKey(
              ValueKey(
                mediaType == 'video'
                    ? 'campaign_video_viewport'
                    : 'campaign_image_viewport',
              ),
            );
            expect(
              tester.getTopLeft(find.text(title)).dy,
              greaterThanOrEqualTo(tester.getBottomLeft(media).dy),
            );
          }
          if (mediaType == 'none') {
            expect(find.byType(FilledButton), findsNothing);
            await tester.tap(find.byIcon(Icons.close_rounded));
            await tester.pumpAndSettle();
            expect(result, HomeCampaignSheetResult.dismissed);
          } else {
            final buttonBeforeScroll = tester.getRect(
              find.byType(FilledButton),
            );
            final surfaceRect = tester.getRect(surface);
            expect(
              buttonBeforeScroll.top,
              greaterThanOrEqualTo(surfaceRect.top),
            );
            expect(
              buttonBeforeScroll.bottom,
              lessThanOrEqualTo(surfaceRect.bottom),
            );
            await tester.ensureVisible(find.byType(FilledButton));
            await tester.pumpAndSettle();
            final buttonRect = tester.getRect(find.byType(FilledButton));
            final labelRect = tester.getRect(find.text(label));
            expect(labelRect.top, greaterThanOrEqualTo(buttonRect.top));
            expect(labelRect.bottom, lessThanOrEqualTo(buttonRect.bottom));
            final paragraph = tester.renderObject<RenderParagraph>(
              find.text(label),
            );
            for (final box in paragraph.getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: label.length),
            )) {
              expect(
                paragraph.localToGlobal(Offset(0, box.bottom)).dy,
                lessThanOrEqualTo(buttonRect.bottom),
              );
            }
            await tester.tap(find.byType(FilledButton));
            await tester.pumpAndSettle();
            expect(result, HomeCampaignSheetResult.acted);
          }
          expect(find.byType(Dialog), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final mediaType in ['none', 'empty_image']) {
    testWidgets('wide split with $mediaType gives text the full width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final payload = _payload();
      (payload['sheet'] as Map<String, dynamic>)['template'] = 'split';
      payload['media'] = <String, dynamic>{
        'type': mediaType == 'empty_image' ? 'image' : 'none',
        'image_url': '',
      };
      await _openCampaign(tester, payload);
      final surface = find.byKey(const ValueKey('home_campaign_surface'));
      expect(
        tester.getSize(find.text('Campaign title')).width,
        closeTo(tester.getSize(surface).width - 36, 1),
      );
      expect(find.byType(AspectRatio), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final template in ['hero', 'split', 'media_focus']) {
    for (final size in ['medium', 'large', 'near_full']) {
      testWidgets('$template/$size keeps the action reachable in landscape', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(800, 360));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final payload = _payload();
        payload['sheet'] = <String, dynamic>{
          ...payload['sheet'] as Map<String, dynamic>,
          'template': template,
          'size': size,
          'description': 'تفاصيل العرض الطويلة متاحة بالتمرير. ' * 30,
        };
        payload['media'] = <String, dynamic>{'type': 'video', 'video_url': ''};
        payload['action'] = <String, dynamic>{
          'type': 'copy_text',
          'label': 'انسخ الكود واستخدمه',
          'value': 'SAVE',
        };
        HomeCampaignSheetResult? result;
        await _openCampaign(
          tester,
          payload,
          textScale: 2,
          onResult: (value) => result = value,
        );
        await tester.ensureVisible(find.byType(FilledButton));
        await tester.pumpAndSettle();
        final surface = tester.getRect(
          find.byKey(const ValueKey('home_campaign_surface')),
        );
        final button = tester.getRect(find.byType(FilledButton));
        expect(button.top, greaterThanOrEqualTo(surface.top));
        expect(button.bottom, lessThanOrEqualTo(surface.bottom));
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(result, HomeCampaignSheetResult.acted);
        expect(find.byType(Dialog), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Future<void> _openCampaign(
  WidgetTester tester,
  Map<String, dynamic> payload, {
  double textScale = 1,
  Brightness brightness = Brightness.light,
  ValueChanged<HomeCampaignSheetResult?>? onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: 'Cairo', brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await showHomeCampaignSheet(
                context,
                HomeCampaignData.fromJson(payload),
              );
              onResult?.call(result);
            },
            child: const Text('Open campaign'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open campaign'));
  await tester.pumpAndSettle();
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
