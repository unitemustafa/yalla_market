class PartnerApplicationRequest {
  const PartnerApplicationRequest({
    required this.businessName,
    required this.contactFirstName,
    required this.contactLastName,
    required this.businessType,
    required this.branchesCount,
    required this.applicantRole,
    required this.hasTradeLicense,
    required this.email,
    required this.mobileNumber,
    required this.landline,
    required this.whatsappOptIn,
    required this.notes,
  });

  final String businessName;
  final String contactFirstName;
  final String contactLastName;
  final String businessType;
  final int branchesCount;
  final String applicantRole;
  final bool hasTradeLicense;
  final String email;
  final String mobileNumber;
  final String landline;
  final bool whatsappOptIn;
  final String notes;

  Map<String, Object?> toJson() {
    return {
      'business_name': businessName.trim(),
      'contact_first_name': contactFirstName.trim(),
      'contact_last_name': contactLastName.trim(),
      'business_type': businessType,
      'branches_count': branchesCount,
      'applicant_role': applicantRole,
      'has_trade_license': hasTradeLicense,
      'email': email.trim().toLowerCase(),
      'mobile_number': mobileNumber.trim(),
      'landline': landline.trim(),
      'whatsapp_opt_in': whatsappOptIn,
      'notes': notes.trim(),
    };
  }
}

class PartnerApplicationReceipt {
  const PartnerApplicationReceipt({
    required this.id,
    required this.businessName,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String businessName;
  final String status;
  final DateTime? createdAt;

  factory PartnerApplicationReceipt.fromJson(Map<String, dynamic> json) {
    return PartnerApplicationReceipt(
      id: json['id']?.toString() ?? '',
      businessName: json['business_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
