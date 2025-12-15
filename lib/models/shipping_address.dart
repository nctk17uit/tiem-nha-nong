class ShippingAddress {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String streetAddress;
  final int provinceCode;
  final int wardCode;
  final bool isDefault;

  // Display fields (populated by backend JOINs in GET requests)
  final String? provinceName;
  final String? wardName;

  ShippingAddress({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.streetAddress,
    required this.provinceCode,
    required this.wardCode,
    required this.isDefault,
    this.provinceName,
    this.wardName,
  });

  // Factory to convert JSON from Backend (snake_case) to Dart Object
  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      id: json['address_id'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      streetAddress: json['street_address'],
      provinceCode: json['province_code'],
      wardCode: json['ward_code'],
      isDefault: json['is_default'] ?? false,
      provinceName: json['province_name'],
      wardName: json['ward_name'],
    );
  }

  // Convert to JSON for sending to Backend (Create/Update)
  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone_number': phoneNumber,
      'street_address': streetAddress,
      'province_code': provinceCode,
      'ward_code': wardCode,
      'is_default': isDefault,
    };
  }

  // Helper for "Full Address String" in UI
  String get fullAddress {
    final parts = [
      streetAddress,
      wardName,
      provinceName,
    ].where((p) => p != null && p.isNotEmpty).join(', ');
    return parts;
  }

  ShippingAddress copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? streetAddress,
    int? provinceCode,
    int? wardCode,
    bool? isDefault,
    String? provinceName,
    String? wardName,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      streetAddress: streetAddress ?? this.streetAddress,
      provinceCode: provinceCode ?? this.provinceCode,
      wardCode: wardCode ?? this.wardCode,
      isDefault: isDefault ?? this.isDefault,
      provinceName: provinceName ?? this.provinceName,
      wardName: wardName ?? this.wardName,
    );
  }
}
