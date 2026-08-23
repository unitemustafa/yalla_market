class OtpDeliveryResult {
  const OtpDeliveryResult({
    this.sent = true,
    this.resendAfterSeconds,
    this.resendAvailableAt,
    this.registrationExpiresAt,
  });

  final bool sent;
  final int? resendAfterSeconds;
  final DateTime? resendAvailableAt;
  final DateTime? registrationExpiresAt;
}
