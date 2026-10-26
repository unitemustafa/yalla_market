import '../../../../core/domain/favorite_page.dart';
import '../../../../core/network/favorite_page_decoder.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../store/domain/entities/product_data.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';

class WishlistRemoteRepositoryImpl
    implements WishlistRepository, PagedWishlistRepository {
  WishlistRemoteRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;
  final List<WishlistItem> _items = [];
  final Set<String> _favoriteIds = {};
  String? _user;
  int _generation = 0;
  int _activate(String userKey) {
    if (_user != userKey) {
      _user = userKey;
      _generation++;
      _items.clear();
      _favoriteIds.clear();
    }
    return _generation;
  }

  @override
  Future<ApiResult<FavoritePage<WishlistItem>>> getPage(
    String userKey, {
    int page = 1,
  }) {
    final generation = _activate(userKey);
    return _guard(() async {
      final payload = await _apiClient.get<Map<String, dynamic>>(
        '/catalog/products/likes/',
        queryParameters: {
          'page': page,
          'page_size': 30,
          if (page == 1) 'include_ids': 'true',
        },
      );
      final data = decodeFavoritePage(
        payload,
        _itemFromProductJson,
        requireIds: page == 1,
      );
      if (generation == _generation) {
        if (page == 1) {
          _items.clear();
          _favoriteIds
            ..clear()
            ..addAll(data.favoriteIds!);
        }
        for (final item in data.items) {
          _upsertItem(item);
        }
      }
      return data;
    });
  }

  @override
  Future<ApiResult<List<WishlistItem>>> getItems(String userKey) {
    final generation = _activate(userKey);
    return _guard(() async {
      final payload = await _apiClient.get<Object?>('/catalog/products/likes/');
      final items = _itemsFromPayload(payload);
      if (generation != _generation) return items;
      _replaceItems(items);
      _favoriteIds
        ..clear()
        ..addAll(items.map((item) => item.productId));
      return List.unmodifiable(_items);
    });
  }

  @override
  Future<ApiResult<List<WishlistItem>>> toggleItem(
    String userKey,
    WishlistItem item,
  ) {
    final generation = _activate(userKey);
    return _guard(() async {
      final productId = item.productId.trim();
      if (productId.isEmpty) {
        return List.unmodifiable(_items);
      }

      final isLiked = _favoriteIds.contains(productId);
      final payload = isLiked
          ? await _apiClient.delete<Object?>(
              '/catalog/products/$productId/unlike/',
            )
          : await _apiClient.post<Object?>(
              '/catalog/products/$productId/like/',
            );
      if (generation != _generation) return const <WishlistItem>[];
      final liked = _likedFromPayload(payload);

      if (liked ?? !isLiked) {
        _favoriteIds.add(productId);
        _upsertItem(item);
      } else {
        _favoriteIds.remove(productId);
        _removeItem(productId);
      }

      return List.unmodifiable(_items);
    });
  }

  List<WishlistItem> _itemsFromPayload(Object? payload) {
    final rawItems = payload is Map<String, dynamic>
        ? payload['results'] ??
              payload['items'] ??
              payload['products'] ??
              payload['likes']
        : payload;
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(_itemFromProductJson)
        .toList(growable: false);
  }

  WishlistItem _itemFromProductJson(Map<String, dynamic> json) {
    final product = ProductData.fromJson(json);
    return WishlistItem(
      productId: product.id,
      image: product.image,
      title: product.title,
      brand: product.brand,
      price: product.defaultVariantPrice ?? product.price,
      oldPrice: product.oldPrice,
      discount: product.discount,
    );
  }

  bool? _likedFromPayload(Object? payload) {
    if (payload is! Map<String, dynamic>) return null;
    final liked = payload['liked'];
    return liked is bool ? liked : null;
  }

  void _replaceItems(List<WishlistItem> items) {
    _items
      ..clear()
      ..addAll(items.where((item) => item.productId.trim().isNotEmpty));
  }

  void _upsertItem(WishlistItem item) {
    final productId = item.productId.trim();
    if (productId.isEmpty) return;

    _removeItem(productId);
    _items.add(item);
  }

  void _removeItem(String productId) {
    _items.removeWhere((entry) => entry.productId == productId);
  }

  Future<ApiResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return ApiResult.success(await action());
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not update wishlist.'),
      );
    }
  }
}
