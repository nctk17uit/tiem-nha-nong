class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final bool isEnabled;
  final double? balance; // Specific for 'PAY_LATER' to show user credit

  PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.isEnabled,
    this.balance,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconUrl: json['icon_url'],
      isEnabled: json['is_enabled'] ?? false,
      balance: json['balance'] != null
          ? (json['balance'] as num).toDouble()
          : null,
    );
  }
}
