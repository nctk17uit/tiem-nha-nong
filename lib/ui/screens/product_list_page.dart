import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/controllers/product_controller.dart';
import 'package:mobile/models/category.dart';
import 'package:mobile/models/product.dart';
import 'dart:async';

class ProductListPage extends ConsumerStatefulWidget {
  final Category? category;
  const ProductListPage({this.category, super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Logic Fix: Reset existing filters (like search) before applying
      // the new category context.
      ref.read(productFilterProvider.notifier).reset();

      if (widget.category != null) {
        ref
            .read(productFilterProvider.notifier)
            .setCategory(widget.category!.id);
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(productListProvider.notifier).loadMore();
      }
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Matches the fixed setCategory/setSearch methods
      ref
          .read(productFilterProvider.notifier)
          .setSearch(query.isEmpty ? null : query);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(productListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category?.name ?? "Tất cả sản phẩm"),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Tìm kiếm sản phẩm...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      endDrawer: const _FilterDrawer(),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err'),
              ElevatedButton(
                onPressed: () => ref.refresh(productListProvider),
                child: const Text("Thử lại"),
              ),
            ],
          ),
        ),
        data: (state) {
          if (state.products.isEmpty) {
            return _buildEmptyState(context, colorScheme);
          }

          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: state.products.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.products.length) {
                return const Center(child: CircularProgressIndicator());
              }
              return _ProductGridItem(product: state.products[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "Không tìm thấy sản phẩm",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text("Hãy thử điều chỉnh bộ lọc hoặc từ khóa tìm kiếm."),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                });
                // Triggers reset logic in controller
                ref.read(productFilterProvider.notifier).reset();
                // Optionally restore the current category if applicable
                if (widget.category != null) {
                  ref
                      .read(productFilterProvider.notifier)
                      .setCategory(widget.category!.id);
                }
              },
              child: const Text("Xóa tất cả bộ lọc"),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Helper: Product Card Item (THEMED) ---
class _ProductGridItem extends StatelessWidget {
  final Product product;
  const _ProductGridItem({required this.product});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        context.push('/product/${product.id}');
      },
      child: Card(
        elevation: 0, // Flat style for modern look (or keep 2)
        color: colorScheme.surfaceContainerLow, // Subtle card background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image
            Expanded(
              child: product.thumbnailUrl != null
                  ? Image.network(
                      product.thumbnailUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: colorScheme.surfaceContainerHighest),
                    )
                  : Container(
                      color: colorScheme
                          .surfaceContainerHighest, // Dynamic placeholder
                      child: Center(
                        child: Icon(
                          Icons.image,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
            // 2. Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currencyFormat.format(product.price),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      // Uses Primary color (Indigo in Light, Lighter Purple in Dark)
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        product.avgRating.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        " (${product.reviewCount})",
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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

// --- Helper: Filter Drawer (THEMED) ---
class _FilterDrawer extends ConsumerStatefulWidget {
  const _FilterDrawer();

  @override
  ConsumerState<_FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends ConsumerState<_FilterDrawer> {
  late TextEditingController _minPriceCtrl;
  late TextEditingController _maxPriceCtrl;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current state values from the provider
    final currentFilter = ref.read(productFilterProvider);
    _minPriceCtrl = TextEditingController(
      text: currentFilter.priceMin?.toStringAsFixed(0) ?? '',
    );
    _maxPriceCtrl = TextEditingController(
      text: currentFilter.priceMax?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  void _resetFilters() {
    // Reset the provider state
    ref.read(productFilterProvider.notifier).reset();

    // Clear the local text controllers immediately
    _minPriceCtrl.clear();
    _maxPriceCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(productFilterProvider);
    final notifier = ref.read(productFilterProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      width: 300,
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Bộ lọc",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Added a clear filter button at the top
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text("Xóa tất cả"),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Sort By
                  Text(
                    "Sắp xếp theo",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  DropdownButton<String>(
                    value: filter.sortBy,
                    isExpanded: true,
                    dropdownColor: colorScheme.surfaceContainer,
                    style: TextStyle(color: colorScheme.onSurface),
                    items: const [
                      DropdownMenuItem(
                        value: 'newest',
                        child: Text("Mới nhất"),
                      ),
                      DropdownMenuItem(
                        value: 'price_asc',
                        child: Text("Giá: Thấp đến Cao"),
                      ),
                      DropdownMenuItem(
                        value: 'price_desc',
                        child: Text("Giá: Cao đến Thấp"),
                      ),
                      DropdownMenuItem(
                        value: 'rating_desc',
                        child: Text("Đánh giá tốt nhất"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        notifier.update(filter.copyWith(sortBy: val));
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // 2. In Stock Only
                  SwitchListTile(
                    title: Text(
                      "Chỉ còn hàng",
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    contentPadding: EdgeInsets.zero,
                    value: filter.inStockOnly,
                    onChanged: (val) {
                      notifier.update(filter.copyWith(inStockOnly: val));
                    },
                  ),
                  const SizedBox(height: 24),

                  // 3. Price Range
                  Text(
                    "Khoảng giá (đ)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: const InputDecoration(
                            labelText: "Tối thiểu",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          ),
                          onChanged: (val) {
                            // Update provider state as user types or on submit
                            notifier.update(
                              filter.copyWith(priceMin: double.tryParse(val)),
                            );
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("-"),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: const InputDecoration(
                            labelText: "Tối đa",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          ),
                          onChanged: (val) {
                            notifier.update(
                              filter.copyWith(priceMax: double.tryParse(val)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Action Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const SizedBox(
                  width: double.infinity,
                  child: Center(child: Text("Áp dụng")),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
