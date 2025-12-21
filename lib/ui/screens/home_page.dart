import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';

// Infrastructure Imports
import '../../models/product.dart';
import '../../models/category.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/category_controller.dart';
import '../../repositories/product_repository.dart';
import '../../utils/elements_format.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // --- UI State ---
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _bannerIndex = 0;

  Category? _selectedCategory;
  List<Product> _products = [];
  bool _isLoading = false;

  // CONSTANT: How many categories to show before the "View All" button
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
    // ... (Keep existing logic: check variants, call controller)
    ProductVariant? variantToAdd;
    if (product.hasVariants && product.variants.isNotEmpty) {
      context.push('/product/${product.id}');
      return;
    } else if (product.variants.isNotEmpty) {
      variantToAdd = product.variants.first;
    } else {
      return;
    }

    try {
      await ref
          .read(cartControllerProvider.notifier)
          .addToCart(product: product, variant: variantToAdd, quantity: 1);
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm "${product.name}" vào giỏ hàng'),
            backgroundColor: colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }



  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final banners = List.generate(3, (i) => 'assets/images/logo.jpg');
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

          // Initialize selection
          if (_selectedCategory == null && allCategories.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _selectedCategory = allCategories.first);
                _fetchProducts(allCategories.first.id);
              }
            });
          }

          // LOGIC: Limit the list for Home Page
          final displayCategories = allCategories
              .take(_maxHomeCategories)
              .toList();
          final hasMore = allCategories.length > _maxHomeCategories;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Banner
                SizedBox(
                  height: 200,
                  child: Column(
                    children: [
                      Expanded(
                        child: CarouselSlider.builder(
                          carouselController: _carouselController,
                          itemCount: banners.length,
                          itemBuilder: (context, index, realIdx) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  banners[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: colorScheme.surfaceContainerHighest,
                                  ),
                                ),
                              ),
                            );
                          },
                          options: CarouselOptions(
                            height: double.infinity,
                            viewportFraction: 1.0,
                            enableInfiniteScroll: true,
                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 7),
                            autoPlayAnimationDuration:
                                const Duration(milliseconds: 400),
                            enlargeCenterPage: false,
                            onPageChanged: (i, reason) {
                              setState(() => _bannerIndex = i);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(banners.length, (i) {
                          final isActive = i == _bannerIndex;
                          return GestureDetector(
                            onTap: () => _carouselController.animateToPage(i),
                            child: Container(
                              width: isActive ? 10 : 8,
                              height: isActive ? 10 : 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withOpacity(0.2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Categories (Quick Access Strip)
                Container(
                  color: colorScheme.surfaceContainerLow,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SizedBox(
                    height: 110,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      scrollDirection: Axis.horizontal,
                      // Add +1 item for "View All" if we have more categories
                      itemCount: displayCategories.length + (hasMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        // Render "View All" Button as the last item
                        if (hasMore && index == displayCategories.length) {
                          return GestureDetector(
                            onTap: () {
                              // Switch to Category Tab (Tab index 1 defined in AppRouter)
                              context.go('/category');
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
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.grid_view_rounded,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 72,
                                  child: Text(
                                    "Xem tất cả",
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Render Normal Category Item
                        final cat = displayCategories[index];
                        final selected = cat.id == _selectedCategory?.id;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            _fetchProducts(cat.id);
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.surface,
                                  border: selected
                                      ? Border.all(
                                          color: colorScheme.primary,
                                          width: 2,
                                        )
                                      : Border.all(
                                          color: colorScheme.outlineVariant,
                                          width: 1,
                                        ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: ClipOval(
                                    child: Container(
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      child: const Icon(
                                        Icons.grass,
                                      ), // Placeholder
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 72,
                                child: Text(
                                  cat.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 3. Products grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          // Optional: Another "View All" for the products themselves
                          TextButton(
                            onPressed: () {
                              if (_selectedCategory != null) {
                                context.push(
                                  '/category/products',
                                  extra: _selectedCategory,
                                );
                              }
                            },
                            child: Text("Xem thêm"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_products.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Text("Không tìm thấy sản phẩm nào."),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.68,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                              ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(
                              _products[index],
                              colorScheme,
                              textTheme,
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                      Center(
                        child: SizedBox(
                          width: double.infinity, // Make it full width
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Navigate to Product List WITHOUT passing a category
                              // This tells the page to load "All Products"
                              context.push('/category/products');
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: colorScheme.primary,
                              ), // Use Theme Color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(
                              Icons.storefront,
                              color: colorScheme.primary,
                            ),
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

                      const SizedBox(height: 12),

                      // Nguồn gốc & chứng nhận (image placeholders, replace with DB images later)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF41B93D), borderRadius: BorderRadius.circular(2))),
                                const SizedBox(width: 10),
                                Text('Nguồn gốc & chứng nhận', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 110,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: 4,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[100],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Ưu đãi
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(width: 4, height: 18, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2))),
                                const SizedBox(width: 10),
                                Text('Ưu đãi / Combo tiết kiệm', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 120,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: 3,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: 220,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[100],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    // ... (Keep existing AppBar code)
    return AppBar(
      title: Text("Trang Chủ", style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        Consumer(
          builder: (context, ref, child) {
            final count = ref.watch(cartControllerProvider).itemCount;
            return IconButton(
              icon: Badge(
                label: Text('$count'),
                isLabelVisible: count > 0,
                child: Icon(Icons.shopping_cart_outlined),
              ),
              onPressed: () => context.push('/cart'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(
    Product p,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // ... (Keep existing Product Card code)
    return GestureDetector(
      onTap: () => context.push('/product/${p.id}'),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: colorScheme.surfaceContainerHighest,
                width: double.infinity,
                child: Image.network(
                  p.thumbnailUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.image),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    PriceFormatter.format(p.price),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _addToCart(p),
                      child: Text("Thêm vào giỏ"),
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
}
