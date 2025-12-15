class CartItem {
  final String? id; // Null for local guest items
  final String variantId;
  final String productId;
  final String productName;
  final String variantName;
  final String? thumbnailUrl;
  final double price;
  final int quantity;
  final int stockQuantity;
  final bool isActive;

  const CartItem({
    this.id,
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    this.thumbnailUrl,
    required this.price,
    required this.quantity,
    required this.stockQuantity,
    this.isActive = true,
  });

  // Convert from API JSON (Server Cart)
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['cart_item_id'],
      variantId: json['variant_id'],
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? 'Unknown',
      variantName: json['variant_name'] ?? '',
      thumbnailUrl: json['thumbnail'],

      // --- FIX: Robust Parsing for API ---
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,

      quantity: json['quantity'] ?? 1,
      stockQuantity: json['stock_quantity'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  // Convert from Local Storage JSON (Guest Cart)
  factory CartItem.fromLocalJson(Map<String, dynamic> json) {
    return CartItem(
      id: null,
      variantId: json['variantId'],
      productId: json['productId'],
      productName: json['productName'],

      variantName: json['variantName'],
      // 1. Try 'thumbnailUrl' (standard local save format)
      // 2. Fallback to 'thumbnail' (format from Product API)
      thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnail'],

      // Robust Parsing for Local Storage
      // This prevents the crash if local storage saved price as "3000.00"
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,

      quantity: json['quantity'] ?? 1,
      stockQuantity: json['stockQuantity'] ?? 99,
      isActive: true,
    );
  }

  // To Save Locally
  Map<String, dynamic> toJson() {
    return {
      'variantId': variantId,
      'productId': productId,
      'productName': productName,
      'variantName': variantName,
      'thumbnailUrl': thumbnailUrl,
      'price': price,
      'quantity': quantity,
      'stockQuantity': stockQuantity,
    };
  }

  CartItem copyWith({
    String? id,
    String? variantId,
    String? productId,
    String? productName,
    String? variantName,
    String? thumbnailUrl,
    double? price,
    int? quantity,
    int? stockQuantity,
    bool? isActive,
  }) {
    return CartItem(
      id: id ?? this.id,
      variantId: variantId ?? this.variantId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      variantName: variantName ?? this.variantName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper for UI
  double get subtotal => price * quantity;
}

class CartMergeNotification {
  final String type; // 'REMOVED' or 'ADJUSTED'
  final String message;

  CartMergeNotification({required this.type, required this.message});

  factory CartMergeNotification.fromJson(Map<String, dynamic> json) {
    return CartMergeNotification(type: json['type'], message: json['message']);
  }
}
