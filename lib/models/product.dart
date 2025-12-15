// -----------------------------------------------------------------------------
// 1. Description Block (Rich Text)
// -----------------------------------------------------------------------------
class DescriptionBlock {
  final String type;
  final String content;
  final int level;

  DescriptionBlock({required this.type, this.content = '', this.level = 0});

  factory DescriptionBlock.fromJson(Map<String, dynamic> json) {
    return DescriptionBlock(
      type: json['type'] ?? 'paragraph',
      content: json['content'] ?? '',
      level: json['level'] ?? 0,
    );
  }
}

// -----------------------------------------------------------------------------
// 2. Product Image (For Carousel)
// -----------------------------------------------------------------------------
class ProductImage {
  final String id;
  final String url;
  final bool isThumbnail;
  final String? variantId;

  ProductImage({
    required this.id,
    required this.url,
    required this.isThumbnail,
    this.variantId,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['image_id'] ?? '',
      url: json['image_url'] ?? '',
      isThumbnail: json['is_thumbnail'] ?? false,
      variantId: json['variant_id'],
    );
  }
}

// -----------------------------------------------------------------------------
// 3. Product Variant (For Size/Color Selection)
// -----------------------------------------------------------------------------
class ProductVariant {
  final String id;
  final String name;
  final String sku;
  final double price;

  // --- UPDATED FIELDS ---
  final int stockQuantity; // Renamed from 'stock' to match frontend usage
  final bool isActive; // Added to handle unavailable items

  ProductVariant({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.stockQuantity,
    required this.isActive,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['variant_id'] ?? '',
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',

      // FIX: Robust parsing for Price
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,

      // FIX: Robust parsing for Stock (Handle String vs Int)
      // Backend key is 'stock_quantity' based on your SQL
      stockQuantity:
          int.tryParse(json['stock_quantity']?.toString() ?? '0') ?? 0,

      // FIX: Added isActive parsing
      isActive: json['is_active'] ?? true,
    );
  }
}

// -----------------------------------------------------------------------------
// 4. Main Product Model
// -----------------------------------------------------------------------------
class Product {
  final String id;
  final String name;
  final double price;
  final int stock; // Top-level stock (optional if variants exist)
  final String? thumbnailUrl;
  final bool hasVariants;
  final bool isActive;
  final double avgRating;
  final int reviewCount;
  final List<DescriptionBlock> description;

  // NEW FIELDS for Detail Page
  final List<ProductImage> images;
  final List<ProductVariant> variants;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.thumbnailUrl,
    required this.hasVariants,
    required this.isActive,
    required this.avgRating,
    required this.reviewCount,
    required this.description,
    this.images = const [],
    this.variants = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // 1. Parse Description
    List<DescriptionBlock> parsedDesc = [];
    final rawDesc = json['description'];
    if (rawDesc is List) {
      parsedDesc = rawDesc.map((e) => DescriptionBlock.fromJson(e)).toList();
    } else if (rawDesc is Map<String, dynamic> && rawDesc.containsKey('text')) {
      parsedDesc.add(
        DescriptionBlock(type: 'paragraph', content: rawDesc['text']),
      );
    }

    // 2. Parse Images
    List<ProductImage> parsedImages = [];
    if (json['images'] != null) {
      parsedImages = (json['images'] as List)
          .map((e) => ProductImage.fromJson(e))
          .toList();
    }

    // 3. Parse Variants
    List<ProductVariant> parsedVariants = [];
    if (json['variants'] != null) {
      parsedVariants = (json['variants'] as List)
          .map((e) => ProductVariant.fromJson(e))
          .toList();
    }

    // --- Smart Thumbnail Logic ---
    String? finalThumbnail = json['thumbnail_url'] ?? json['thumbnail'];

    // If direct keys are missing, look inside the 'images' list
    if (finalThumbnail == null && parsedImages.isNotEmpty) {
      // Try to find one marked as 'isThumbnail'
      final thumbObj = parsedImages.firstWhere(
        (img) => img.isThumbnail,
        orElse: () => parsedImages.first,
      );
      finalThumbnail = thumbObj.url;
    }

    return Product(
      id: json['product_id'] ?? '',
      name: json['name'] ?? 'Unknown',

      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,

      // Top level stock parsing
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,

      thumbnailUrl: finalThumbnail,
      hasVariants: json['has_variants'] ?? false,
      isActive: json['is_active'] ?? true,

      avgRating: double.tryParse(json['avg_rating']?.toString() ?? '0') ?? 0.0,
      reviewCount: json['review_count'] ?? 0,

      description: parsedDesc,
      images: parsedImages,
      variants: parsedVariants,
    );
  }
}
