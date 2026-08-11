import '../../domain/entities/order.dart';
import '../../domain/usecases/get_my_orders_usecase.dart';
import 'demo_orders.dart';

class DemoOrderHistorySupplement implements OrderHistorySupplement {
  const DemoOrderHistorySupplement();

  @override
  List<OrderData> fallbackOrders() {
    return DemoOrders.all.map(_mapOrder).toList(growable: false);
  }

  OrderData _mapOrder(DemoOrderData order) {
    final items = order.items
        .map(
          (item) => OrderItemData(
            id: '${order.orderId}-${item.title}',
            image: '',
            brand: item.brand,
            title: item.title,
            unitPrice: _money(item.total ?? '') / item.quantity,
            quantity: item.quantity,
          ),
        )
        .toList(growable: false);
    final placedAt = _date(order.date);

    return OrderData(
      id: order.orderId,
      orderNumber: order.orderId,
      status: order.status == 'Delivered'
          ? OrderStatus.delivered
          : OrderStatus.shipped,
      placedAt: placedAt,
      shippingAddress: const ShippingAddressData(
        fullName: '',
        phone: '',
        line1: '',
        city: '',
        state: '',
        country: '',
        postalCode: '',
      ),
      paymentMethod: 'cash',
      items: items,
      subtotal: _money(order.total),
      shippingFee: 0,
      deliveryType: OrderDeliveryType.delivery,
      taxTotal: 0,
      discountTotal: 0,
      total: _money(order.total),
      estimatedDeliveryAt: _date(order.shippingDate),
    );
  }

  double _money(String value) {
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
  }

  DateTime _date(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length != 3) return DateTime(2000);
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    return DateTime(
      int.tryParse(parts[2]) ?? 2000,
      months[parts[1]] ?? 1,
      int.tryParse(parts[0]) ?? 1,
    );
  }
}
