import '../../../../core/domain/data_page.dart';
import 'order.dart';

class OrderHistoryPage extends DataPage<OrderData> {
  const OrderHistoryPage({
    required super.items,
    required super.count,
    required super.hasMore,
    required this.deliveredCount,
  });
  final int deliveredCount;
}
