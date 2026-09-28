import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routing/app_route_arguments.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../domain/entities/home_campaign_data.dart';
import 'home_campaign_preferences.dart';
import 'home_campaign_sheet.dart';

class HomeCampaignHost extends StatefulWidget {
  const HomeCampaignHost({
    super.key,
    required this.campaign,
    this.onRotationDue,
  });
  final HomeCampaignData campaign;
  final Future<void> Function()? onRotationDue;

  @override
  State<HomeCampaignHost> createState() => _HomeCampaignHostState();
}

class _HomeCampaignHostState extends State<HomeCampaignHost> {
  bool _sheetOpen = false;
  String _selectedImageUrl = '';
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _prepare();
    _scheduleRotation();
  }

  @override
  void didUpdateWidget(covariant HomeCampaignHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campaign.storageIdentity != widget.campaign.storageIdentity) {
      _prepare();
      _scheduleRotation();
    }
  }

  void _scheduleRotation() {
    _rotationTimer?.cancel();
    final seconds = widget.campaign.behavior.rotationSeconds
        .clamp(60, 86400)
        .toInt();
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final delaySeconds = seconds - (nowSeconds % seconds);
    _rotationTimer = Timer(Duration(seconds: delaySeconds), () async {
      await widget.onRotationDue?.call();
      if (mounted) _scheduleRotation();
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  Future<void> _prepare() async {
    final identity = widget.campaign.storageIdentity;
    final imageUrl = await HomeCampaignPreferences.imageForSession(
      identity,
      widget.campaign.media.availableImageUrls,
    );
    if (!mounted || identity != widget.campaign.storageIdentity) return;
    _selectedImageUrl = imageUrl;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoOpen());
  }

  Future<void> _maybeAutoOpen() async {
    if (!mounted || _sheetOpen) return;
    final campaign = widget.campaign;
    final identity = campaign.storageIdentity;
    if (HomeCampaignPreferences.openedInSession(identity)) return;
    HomeCampaignPreferences.markOpenedInSession(identity);
    await _open();
  }

  Future<void> _open() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    final result = await showHomeCampaignSheet(
      context,
      widget.campaign,
      imageUrl: _selectedImageUrl,
    );
    _sheetOpen = false;
    if (!mounted) return;
    if (result == HomeCampaignSheetResult.acted) {
      await _performAction();
      return;
    }
  }

  Future<void> _performAction() async {
    final action = widget.campaign.action;
    final target = action.target;
    final id = target?['id']?.toString() ?? '';
    switch (action.type) {
      case 'offer':
        if (id.isEmpty) return;
        await Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.navigationMenu,
          (_) => false,
          arguments: NavigationMenuRouteArgs(focusOfferId: id),
        );
        return;
      case 'product':
        if (id.isEmpty) return;
        await Navigator.pushNamed(
          context,
          AppRoutes.productDetail,
          arguments: ProductDetailRouteArgs(
            productId: id,
            image: target?['image']?.toString() ?? '',
            title: target?['name']?.toString() ?? '',
            brand: target?['market_name']?.toString() ?? '',
            price: target?['price']?.toString() ?? '',
            discount: _discountText(target?['discount']),
            initialVariantId: target?['variant_id']?.toString(),
          ),
        );
        return;
      case 'market':
        if (id.isEmpty) return;
        await Navigator.pushNamed(
          context,
          AppRoutes.brandProducts,
          arguments: BrandProductsRouteArgs(
            brand: target?['name']?.toString() ?? '',
            logo: target?['image']?.toString() ?? '',
            productCount: '0',
            marketId: id,
          ),
        );
        return;
      case 'product_category':
        if (id.isEmpty) return;
        await Navigator.pushNamed(
          context,
          AppRoutes.productCategoryCampaign,
          arguments: ProductCategoryCampaignRouteArgs(
            categoryId: id,
            categoryName: target?['name']?.toString() ?? '',
          ),
        );
        return;
      case 'external_url':
        final uri = Uri.tryParse(action.value);
        if (uri == null ||
            uri.scheme != 'https' ||
            !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (mounted) {
            CustomSnackBar.showError(
              context: context,
              title: 'تعذر فتح الرابط',
              message: 'الرابط الخارجي غير صالح أو غير متاح.',
            );
          }
        }
        return;
      case 'copy_text':
        if (action.value.isEmpty) return;
        await Clipboard.setData(ClipboardData(text: action.value));
        if (mounted) {
          CustomSnackBar.showSuccess(
            context: context,
            title: 'تم النسخ',
            message: 'تم نسخ النص بنجاح.',
          );
        }
        return;
      default:
        return;
    }
  }

  String? _discountText(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == '0' || text == '0.00') return null;
    return text.endsWith('%') ? text : '$text%';
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
