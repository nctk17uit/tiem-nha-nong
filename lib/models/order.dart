class Order {
  final String id;
  final String paymentStatus; // 'PENDING', 'PAID', 'PAY_LATER'
  final String paymentMethod; // 'COD', 'ONLINE'
  final double totalAmount;
  final String? checkoutUrl; // For ONLINE payment redirect

  Order({
    required this.id,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.totalAmount,
    this.checkoutUrl,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['order_id'],
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'],
      // Robust parsing for decimal/numeric types
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      checkoutUrl: json['checkout_url'],
    );
  }
}
