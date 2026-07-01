import 'package:dio/dio.dart';

import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../store/domain/entities/product_data.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';

class WishlistRemoteRepositoryImpl implements WishlistRepository {
  WishlistRemoteRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;
  final List<WishlistItem> _items = [];

  @override
  Future<ApiResult<List<WishlistItem>>> getItems(String userKey) {
    return _guard(() async {
      final payload = await _apiClient.get<Object?>('/catalog/products/likes/');
      final items = _itemsFromPayload(payload);
      _replaceItems(items);
      return List.unmodifiable(_items);
    });
  }

  @override
  Future<ApiResult<List<WishlistItem>>> toggleItem(
    String userKey,
    WishlistItem item,
  ) {
    return _guard(() async {
      final productId = item.productId.trim();
      if (productId.isEmpty) {
        return List.unmodifiable(_items);
      }

      final isLiked = _items.any((entry) => entry.productId == productId);
      final payload = isLiked
          ? await _apiClient.delete<Object?>(
              '/catalog/products/$productId/unlike/',
            )
          : await _apiClient.post<Object?>(
              '/catalog/products/$productId/like/',
            );
      final liked = _likedFromPayload(payload);

      if (liked ?? !isLiked) {
        _upsertItem(item);
      } else {
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
      productId: product.id ?? json['id']?.toString() ?? '',
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
