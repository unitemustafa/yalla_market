import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/order.dart';

enum OrdersDateFilter { today, week, month, custom }

class OrderPresentationData {
  const OrderPresentationData({
    required this.apiId,
    required this.status,
    required this.placedAt,
    required this.date,
    required this.orderId,
    required this.shippingDate,
    required this.itemCount,
    required this.total,
    required this.products,
    this.reviewStatus = '',
    this.paymentMethod = '',
    this.shippingCompany = '',
    this.deliveryType = '',
    this.deliveryPriceStatus = OrderDeliveryPriceStatus.fixed,
    this.deliveryPrice = '',
    this.isMultiMarket = false,
    this.marketCount = 1,
    this.marketSummary = '',
    this.marketSections = const [],
    this.multiMarketFeeRate = 0,
    this.multiMarketFee = 0,
  });

  final String apiId;
  final String status;
  final DateTime placedAt;
  final String date;
  final String orderId;
  final String shippingDate;
  final int itemCount;
  final String total;
  final List<OrderProductPresentationData> products;
  final String reviewStatus;
  final String paymentMethod;
  final String shippingCompany;
  final String deliveryType;
  final OrderDeliveryPriceStatus deliveryPriceStatus;
  final String deliveryPrice;
  final bool isMultiMarket;
  final int marketCount;
  final String marketSummary;
  final List<OrderMarketSectionData> marketSections;
  final double multiMarketFeeRate;
  final double multiMarketFee;

  Color get statusColor {
    return status == 'Delivered' ? AppColors.success : AppColors.warning;
  }
}

class OrderProductPresentationData {
  const OrderProductPresentationData({
    required this.title,
    required this.quantity,
    this.brand = '',
    this.total,
  });

  final String title;
  final int quantity;
  final String brand;
  final String? total;
}
