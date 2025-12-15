import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/controllers/cart_controller.dart';
import 'package:mobile/controllers/product_controller.dart';
import 'package:mobile/models/product.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailPage({required this.productId, super.key});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  int _currentImageIndex = 0;
  String? _selectedVariantId;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final asyncProduct = ref.watch(productDetailProvider(widget.productId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: colorScheme.surface.withOpacity(0.7),
            child: BackButton(color: colorScheme.onSurface),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundColor: colorScheme.surface.withOpacity(0.7),
              child: Consumer(
                builder: (context, ref, child) {
                  final cartState = ref.watch(cartControllerProvider);
                  final itemCount = cartState.items.length;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shopping_cart_outlined,
                          color: colorScheme.onSurface,
                        ),
                        onPressed: () {
                          context.push('/pushed-cart');
                        },
                      ),
                      if (itemCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$itemCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: asyncProduct.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (product) {
          // Determine Active Variant:
          // 1. If user selected one, use it.
          // 2. If not, find the FIRST AVAILABLE (Stock > 0).
          // 3. If all OOS, default to the first one.
          ProductVariant? activeVariant;
          if (product.variants.isNotEmpty) {
            if (!product.hasVariants) {
              activeVariant = product.variants.first;
            } else {
              activeVariant = product.variants.firstWhere(
                (v) => v.id == _selectedVariantId,
                orElse: () => product.variants.firstWhere(
                  // Try to find first in-stock item
                  (v) => v.stockQuantity > 0 && v.isActive,
                  // If EVERYTHING is OOS, just show the first item
                  orElse: () => product.variants.first,
                ),
              );
            }
          }
          final displayPrice = activeVariant?.price ?? product.price;

          // Check if the current selection is available
          final int currentStock = activeVariant?.stockQuantity ?? 0;
          final bool isAvailable =
              currentStock > 0 && (activeVariant?.isActive ?? true);

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCarousel(product, colorScheme),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITLE
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),

                      // PRICE
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            NumberFormat.currency(
                              locale: 'vi_VN',
                              symbol: 'đ',
                            ).format(displayPrice),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Stock Status Text
                          Text(
                            isAvailable ? "Kho: $currentStock" : "Hết hàng",
                            style: TextStyle(
                              color: isAvailable ? Colors.grey : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // VARIANT SELECTOR
                      if (product.hasVariants &&
                          product.variants.isNotEmpty) ...[
                        Text(
                          "Chọn phân loại:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildVariantSelector(
                          product,
                          colorScheme,
                          activeVariant?.id, // Pass the calculated ID here
                        ),
                        const SizedBox(height: 24),
                      ],

                      const Divider(),
                      _buildDescription(product.description, colorScheme),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(context, asyncProduct.value),
    );
  }

  Widget _buildBottomBar(BuildContext context, Product? product) {
    if (product == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    // 1. Match Body Logic for default variant
    ProductVariant? activeVariant;
    if (product.variants.isNotEmpty) {
      if (!product.hasVariants) {
        activeVariant = product.variants.first;
      } else {
        activeVariant = product.variants.firstWhere(
          (v) => v.id == _selectedVariantId,
          orElse: () => product.variants.firstWhere(
            (v) => v.stockQuantity > 0 && v.isActive,
            orElse: () => product.variants.first,
          ),
        );
      }
    }

    // 2. Logic: Is it buyable?
    final int maxStock = activeVariant?.stockQuantity ?? 0;
    final bool isActive = activeVariant?.isActive ?? true;
    final bool isOutOfStock = maxStock <= 0 || !isActive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // --- Quantity Selector ---
            Opacity(
              opacity: isOutOfStock ? 0.5 : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: (!isOutOfStock && _quantity > 1)
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove),
                      iconSize: 20,
                      color: colorScheme.onSurface,
                    ),
                    Text(
                      '$_quantity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      onPressed: (!isOutOfStock && _quantity < maxStock)
                          ? () => setState(() => _quantity++)
                          : null,
                      icon: const Icon(Icons.add),
                      iconSize: 20,
                      color: (!isOutOfStock && _quantity < maxStock)
                          ? colorScheme.onSurface
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // --- Add to Cart Button ---
            Expanded(
              child: FilledButton.icon(
                onPressed: isOutOfStock
                    ? null
                    : () async {
                        if (activeVariant == null) return;
                        try {
                          await ref
                              .read(cartControllerProvider.notifier)
                              .addToCart(
                                product: product,
                                variant: activeVariant,
                                quantity: _quantity,
                              );

                          if (context.mounted) {
                            // Clear previous Snackbars first
                            ScaffoldMessenger.of(context).clearSnackBars();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Đã thêm \"$_quantity x ${product.name}\" vào giỏ hàng!",
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior
                                    .floating, // Optional: Makes it look nicer
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            // Clear previous Snackbars first
                            ScaffoldMessenger.of(context).clearSnackBars();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                icon: isOutOfStock
                    ? const Icon(Icons.remove_shopping_cart, size: 20)
                    : const Icon(Icons.shopping_cart_outlined),
                label: Text(isOutOfStock ? "Hết hàng" : "Thêm vào giỏ"),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel(Product product, ColorScheme colorScheme) {
    if (product.images.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: product.images.length,
          options: CarouselOptions(
            height: 350,
            viewportFraction: 1.0,
            enableInfiniteScroll: false,
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
                if (product.hasVariants) {
                  final imageVariantId = product.images[index].variantId;
                  if (imageVariantId != null) {
                    _selectedVariantId = imageVariantId;
                    _quantity = 1;
                  }
                }
              });
            },
          ),
          itemBuilder: (context, index, realIndex) {
            return Image.network(
              product.images[index].url,
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(
                  Icons.broken_image,
                  size: 50,
                  color: colorScheme.outline,
                ),
              ),
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: product.images.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentImageIndex == entry.key ? 20.0 : 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 4.0,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(4),
                color: _currentImageIndex == entry.key
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVariantSelector(
    Product product,
    ColorScheme colorScheme,
    String? activeVariantId,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: product.variants.map((variant) {
        final isSelected = activeVariantId == variant.id;

        // Check for Stock
        final bool isAvailable = variant.stockQuantity > 0 && variant.isActive;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedVariantId = variant.id;
              _quantity = 1;
            });
            final imageIndex = product.images.indexWhere(
              (img) => img.variantId == variant.id,
            );
            if (imageIndex != -1) {
              _carouselController.animateToPage(imageIndex);
            }
          },
          child: Opacity(
            opacity: isAvailable ? 1.0 : 0.5,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    variant.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      decoration: isAvailable
                          ? TextDecoration.none
                          : TextDecoration.lineThrough,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                  if (!isAvailable) ...[
                    const SizedBox(width: 4),
                    Text(
                      "(Hết)",
                      style: TextStyle(fontSize: 10, color: colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDescription(
    List<DescriptionBlock> blocks,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) {
        switch (block.type) {
          case 'heading':
            return Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
              child: Text(
                block.content,
                style: TextStyle(
                  fontSize: block.level == 1 ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            );
          case 'paragraph':
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                block.content,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: colorScheme.onSurface,
                ),
              ),
            );
          case 'list_item':
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "• ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      block.content,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          case 'divider':
            return const Divider(height: 32);
          default:
            return const SizedBox.shrink();
        }
      }).toList(),
    );
  }
}
