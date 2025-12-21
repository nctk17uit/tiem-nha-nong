import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/models/product.dart';
import 'package:mobile/models/category.dart';
import 'package:mobile/controllers/cart_controller.dart';
import 'package:mobile/controllers/category_controller.dart';
import 'package:mobile/controllers/product_controller.dart';
import 'package:mobile/repositories/product_repository.dart';
import 'package:mobile/utils/elements_format.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final CarouselSliderController _salesCarouselController =
      CarouselSliderController();
  int _bannerIndex = 0;
  int _salesBannerIndex = 0;

  Category? _selectedCategory;
  List<Product> _products = [];
  bool _isLoading = false;
  bool _footerExpanded = false;

  static const int _maxHomeCategories = 7;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchProducts(String categoryId) async {
    if (_isLoading) return;
    if (mounted) setState(() => _isLoading = true);

    try {
      final products = await ref
          .read(productRepositoryProvider)
          .getProducts(categoryId: categoryId, limit: 10);
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _products = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addToCart(Product product) async {
    if (!product.isActive) return;

    // Show loading overlay
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // 1. Always fetch full data to ensure variants are present (for simple and variable)
      final fullProduct = await ref.read(
        productDetailProvider(product.id).future,
      );

      // 2. Safe Navigator pop
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }

      if (!mounted) return;

      // 3. Match ProductDetailPage Logic:
      // If it's a variable product, show the sheet.
      // If it's a simple product, add the first variant immediately.
      if (fullProduct.hasVariants && fullProduct.variants.isNotEmpty) {
        _showVariantBottomSheet(fullProduct);
      } else if (fullProduct.variants.isNotEmpty) {
        // Handle simple product logic by taking the first variant (activeVariant = variants.first)
        await _performAddToCart(fullProduct, fullProduct.variants.first);
      } else {
        throw Exception(
          "Sản phẩm hiện không khả dụng (thiếu dữ liệu phân loại)",
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showVariantBottomSheet(Product product) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Default selection logic: find first in-stock variant
    ProductVariant? selectedVariant;
    try {
      selectedVariant = product.variants.firstWhere(
        (v) => v.stockQuantity > 0 && v.isActive,
        orElse: () => product.variants.first,
      );
    } catch (_) {
      selectedVariant = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.thumbnailUrl ?? '',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image, size: 80),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: textTheme.titleMedium,
                              maxLines: 2,
                            ),
                            Text(
                              PriceFormatter.format(
                                selectedVariant?.price ?? product.price,
                              ),
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text("Chọn phân loại:", style: textTheme.labelLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.variants.map((variant) {
                      final isSelected = selectedVariant?.id == variant.id;
                      final bool isAvailable =
                          variant.stockQuantity > 0 && variant.isActive;

                      return ChoiceChip(
                        label: Text(variant.name),
                        selected: isSelected,
                        onSelected: !isAvailable
                            ? null
                            : (selected) {
                                setModalState(() => selectedVariant = variant);
                              },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: selectedVariant == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              _performAddToCart(product, selectedVariant!);
                            },
                      child: const Text("Thêm vào giỏ hàng"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _performAddToCart(
    Product product,
    ProductVariant variant,
  ) async {
    try {
      await ref
          .read(cartControllerProvider.notifier)
          .addToCart(product: product, variant: variant, quantity: 1);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm "${product.name}" vào giỏ'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final banners = [
      'assets/images/banner1.png',
      'assets/images/banner2.png',
      'assets/images/banner3.png',
    ];
    final categoriesAsync = ref.watch(categoryTreeProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(context),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (allCategories) {
          if (allCategories.isEmpty)
            return const Center(child: Text('No categories found'));

          if (_selectedCategory == null && allCategories.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _selectedCategory = allCategories.first);
                _fetchProducts(allCategories.first.id);
              }
            });
          }

          final displayCategories = allCategories
              .take(_maxHomeCategories)
              .toList();
          final hasMore = allCategories.length > _maxHomeCategories;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCarousel(banners, colorScheme),
                const SizedBox(height: 12),
                _buildCategoryStrip(
                  displayCategories,
                  hasMore,
                  colorScheme,
                  textTheme,
                ),
                const SizedBox(height: 12),
                _buildProductGrid(colorScheme, textTheme),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                  ), // Matches _buildProductGrid
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push('/category/products');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(Icons.storefront, color: colorScheme.primary),
                      label: Text(
                        "Xem tất cả sản phẩm",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // Sales banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Ưu đãi / Combo tiết kiệm',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 124,
                        child: Column(
                          children: [
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final salesViewportFraction =
                                      220 / MediaQuery.of(context).size.width;
                                  return CarouselSlider.builder(
                                    carouselController:
                                        _salesCarouselController,
                                    itemCount: 3,
                                    itemBuilder: (context, index, _) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Container(
                                          width: 220,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            color: Colors.grey[100],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: AspectRatio(
                                              aspectRatio: 16 / 9,
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Image.asset(
                                                    'assets/images/sales_banner${index + 1}.png',
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                  ),
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 220,
                                                    ),
                                                    color:
                                                        _salesBannerIndex ==
                                                            index
                                                        ? Colors.transparent
                                                        : Colors.black
                                                              .withOpacity(
                                                                0.38,
                                                              ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    options: CarouselOptions(
                                      height: double.infinity,
                                      viewportFraction: salesViewportFraction,
                                      autoPlay: true,
                                      enableInfiniteScroll: true,
                                      onPageChanged: (i, _) =>
                                          setState(() => _salesBannerIndex = i),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                3,
                                (i) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == _salesBannerIndex
                                        ? colorScheme.primary
                                        : Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Footer
                Container(
                  width: double.infinity,
                  color: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Toggle button to expand / collapse footer
                      IconButton(
                        onPressed: () =>
                            setState(() => _footerExpanded = !_footerExpanded),
                        icon: AnimatedRotation(
                          turns: _footerExpanded ? 0.0 : 0.5,
                          duration: const Duration(milliseconds: 220),
                          child: Icon(
                            Icons.keyboard_arrow_up,
                            color: colorScheme.onPrimary.withOpacity(0.7),
                            size: 20,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Vertical link list
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Chính sách đổi trả',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Liên hệ',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Zalo OA',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Hotline',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Social icons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    Icons.facebook,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    Icons.share,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    Icons.ondemand_video,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            Text(
                              '© ${DateTime.now().year} Tiem Nha Nong etc',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: colorScheme.onPrimary.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Privacy & terms',
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      color: colorScheme.onPrimary.withOpacity(
                                        0.7,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Security',
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      color: colorScheme.onPrimary.withOpacity(
                                        0.7,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        crossFadeState: _footerExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 220),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarousel(List<String> banners, ColorScheme colorScheme) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Column(
        children: [
          Expanded(
            child: CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: banners.length,
              itemBuilder: (context, index, _) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        banners[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        color: _bannerIndex == index
                            ? Colors.transparent
                            : Colors.black.withOpacity(0.38),
                      ),
                    ],
                  ),
                ),
              ),
              options: CarouselOptions(
                height: double.infinity,
                viewportFraction: 1.0,
                autoPlay: true,
                onPageChanged: (i, _) => setState(() => _bannerIndex = i),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              banners.length,
              (i) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _bannerIndex
                      ? colorScheme.primary
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStrip(
    List<Category> displayCategories,
    bool hasMore,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: 10),
      height: 130, // Fixed height to handle multi-line names
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: displayCategories.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (hasMore && index == displayCategories.length) {
            return _buildCategoryItem(
              null,
              "Xem tất cả",
              Icons.grid_view_rounded,
              colorScheme,
              textTheme,
            );
          }
          final cat = displayCategories[index];
          return _buildCategoryItem(
            cat,
            cat.name,
            Icons.grass,
            colorScheme,
            textTheme,
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(
    Category? cat,
    String name,
    IconData icon,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final selected = cat?.id == _selectedCategory?.id;
    return GestureDetector(
      onTap: () {
        if (cat == null)
          context.go('/category');
        else {
          setState(() => _selectedCategory = cat);
          _fetchProducts(cat.id);
        }
      },
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface,
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              color: selected ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 72,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedCategory?.name ?? 'Sản phẩm',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push(
                  '/category/products',
                  extra: _selectedCategory,
                ),
                child: const Text("Xem thêm"),
              ),
            ],
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) =>
                  _buildProductCard(_products[index], colorScheme, textTheme),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    Product p,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return GestureDetector(
      onTap: () => context.push('/product/${p.id}'),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Expanded(
              child: Image.network(
                p.thumbnailUrl ?? '',
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => const Icon(Icons.image),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    PriceFormatter.format(p.price),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _addToCart(p),
                      child: const Text("Thêm vào giỏ"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        "Trang Chủ",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
        Consumer(
          builder: (context, ref, _) {
            final count = ref.watch(cartControllerProvider).itemCount;
            return IconButton(
              icon: Badge(
                label: Text('$count'),
                isLabelVisible: count > 0,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              onPressed: () => context.push('/cart'),
            );
          },
        ),
      ],
    );
  }
}
