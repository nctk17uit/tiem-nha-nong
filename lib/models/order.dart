class OrderItem {
  final String name;
  final int quantity;
  final double price;
  final String? imageUrl;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] ?? 'Sản phẩm',
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity'].toString()) ?? 1,
      // Robust parsing for price
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl:
          json['image_url'], // Ensure backend returns this key if you did the JOIN
    );
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String paymentStatus; // 'PENDING', 'PAID', 'PAY_LATER'
  final String paymentMethod; // 'COD', 'ONLINE'
  final double totalAmount;
  final double discountAmount;
  final DateTime createdAt;
  final String? checkoutUrl; // For ONLINE payment redirect
  final List<OrderItem>? items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.totalAmount,
    required this.discountAmount,
    required this.createdAt,
    this.checkoutUrl,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['order_id'],

      // Handle order_number safely (backend might send int, we want String)
      orderNumber: json['order_number']?.toString() ?? '---',

      paymentStatus: json['payment_status'] ?? 'PENDING',
      paymentMethod: json['payment_method'] ?? 'UNKNOWN',

      // Robust parsing for decimal/numeric types
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      discountAmount:
          double.tryParse(json['discount_amount'].toString()) ?? 0.0,

      // Parse Date (Handle cases where it might be missing in older mocks)
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),

      checkoutUrl: json['checkout_url'],

      // Map items if they exist (for Detail view)
      items: json['items'] != null
          ? (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList()
          : null,
    );
  }
}
