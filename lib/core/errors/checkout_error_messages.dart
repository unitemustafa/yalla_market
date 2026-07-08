const checkoutRegionRequiredMessage = 'اختر منطقة التصفح قبل إتمام الطلب';
const checkoutAddressRequiredMessage = 'اختر عنوان توصيل مناسب قبل إتمام الطلب';
const checkoutPaymentRequiredMessage = 'اختر طريقة دفع صالحة قبل إتمام الطلب';
const checkoutItemsInvalidMessage = 'راجع منتجات السلة قبل إتمام الطلب';
const checkoutOffersInvalidMessage = 'راجع العروض في السلة قبل إتمام الطلب';
const checkoutOrderInvalidMessage =
    'تعذر إتمام الطلب. راجع بيانات الطلب وحاول مرة أخرى';

bool isCheckoutRegionRequiredMessage(String? message) {
  return message?.trim() == checkoutRegionRequiredMessage;
}
