import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/presentation/widgets/app_refresh_indicator.dart';
import '../widgets/market_listing_sliver.dart';
import '../cubit/market_listing_cubit.dart';

class LatestStoresView extends StatefulWidget {
  const LatestStoresView({super.key, this.showPopularStores = false});
  final bool showPopularStores;
  @override
  State<LatestStoresView> createState() => _LatestStoresViewState();
}

class _LatestStoresViewState extends State<LatestStoresView> {
  final _controller = ScrollController();
  MarketListingCubit? _cubit;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB),
    body: SafeArea(
      child: AppRefreshIndicator(
        onRefresh: () async {
          await _cubit?.refresh();
        },
        child: CustomScrollView(
          controller: _controller,
          physics: AppRefreshIndicator.scrollPhysics,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              sliver: MarketListingSliver(
                title: widget.showPopularStores
                    ? 'Popular Stores'
                    : 'Latest Stores',
                popular: widget.showPopularStores,
                latest: !widget.showPopularStores,
                controller: _controller,
                onReady: (c) => _cubit = c,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
