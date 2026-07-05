class OtpDeliveryResult {
  const OtpDeliveryResult({
    this.sent = true,
    this.resendAfterSeconds,
    this.resendAvailableAt,
  });

  final bool sent;
  final int? resendAfterSeconds;
  final DateTime? resendAvailableAt;
}
