import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../controllers/cart_controller.dart'; // Import Cart Controller
import '../../controllers/product_controller.dart';
import '../../models/product.dart';

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
  String? _selectedVariantId; // Only used if hasVariants == true

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
      ),
      body: asyncProduct.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (product) {
          // --- LOGIC: DETERMINE ACTIVE VARIANT ---
          ProductVariant? activeVariant;

          if (product.variants.isNotEmpty) {
            if (!product.hasVariants) {
              // CASE 1: Single Product -> Always use the first (default) variant
              activeVariant = product.variants.first;
            } else {
              // CASE 2: Multi Variant -> Use selection OR default to first
              activeVariant = product.variants.firstWhere(
                (v) => v.id == _selectedVariantId,
                orElse: () => product.variants.first,
              );
            }
          }

          final displayPrice = activeVariant?.price ?? product.price;

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
                          activeVariant?.id,
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

  // --- WIDGET BUILDERS ---

  Widget _buildBottomBar(BuildContext context, Product? product) {
    if (product == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

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
        child: FilledButton.icon(
          onPressed: () async {
            // 1. Resolve Variant
            ProductVariant? targetVariant;

            if (product.variants.isNotEmpty) {
              if (!product.hasVariants) {
                targetVariant = product.variants.first;
              } else {
                final selectedId =
                    _selectedVariantId ?? product.variants.first.id;
                targetVariant = product.variants.firstWhere(
                  (v) => v.id == selectedId,
                );
              }
            }

            if (targetVariant == null) return;

            // 2. Add to Cart (Call Controller)
            try {
              await ref
                  .read(cartControllerProvider.notifier)
                  .addToCart(
                    product: product,
                    variant: targetVariant,
                    quantity: 1,
                  );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Added ${product.name} to cart"),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()), // e.g. "Not enough stock"
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.shopping_cart_outlined),
          label: const Text("Thêm vào giỏ hàng"),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
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

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedVariantId = variant.id;
            });
            final imageIndex = product.images.indexWhere(
              (img) => img.variantId == variant.id,
            );
            if (imageIndex != -1) {
              _carouselController.animateToPage(imageIndex);
            }
          },
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
            child: Text(
              variant.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
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
