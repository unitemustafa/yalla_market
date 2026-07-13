class AppNotification {
  const AppNotification({
    required this.id,
    required this.audience,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.orderId,
    this.offerId,
    this.productId,
    this.data = const {},
    this.isRead = false,
    this.isBlocking = false,
    this.isResolved = false,
  });

  final int id;
  final String audience;
  final String type;
  final String title;
  final String message;
  final int? orderId;
  final int? offerId;
  final int? productId;
  final Map<String, dynamic> data;
  final bool isRead;
  final bool isBlocking;
  final bool isResolved;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      audience: audience,
      type: type,
      title: title,
      message: message,
      orderId: orderId,
      offerId: offerId,
      productId: productId,
      data: data,
      isRead: isRead ?? this.isRead,
      isBlocking: isBlocking,
      isResolved: isResolved,
      createdAt: createdAt,
    );
  }
}
