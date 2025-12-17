import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/controllers/product_controller.dart';
import 'package:mobile/models/category.dart';
import 'package:mobile/models/product.dart';

class ProductListPage extends ConsumerStatefulWidget {
  final Category? category; // Passed from Drill-Down Navigation
  const ProductListPage({this.category, super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 1. Initialize Filter with Category ID (if passed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.category != null) {
        ref
            .read(productFilterProvider.notifier)
            .setCategory(widget.category!.id);
      }
    });

    // 2. Setup Infinite Scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(productListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(productListProvider);
    final colorScheme = Theme.of(
      context,
    ).colorScheme; // Access current theme colors

    // Logic to determine Page Title
    final title = widget.category?.name ?? "Tất cả sản phẩm";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // FIX: Wrap BackButton in a semi-transparent circle
        leading: Padding(
          padding: const EdgeInsets.all(
            8.0,
          ), // Add padding to make circle smaller
          child: CircleAvatar(
            // Dynamic background: White in Light Mode, Dark Grey in Dark Mode
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surface.withOpacity(0.8),
            // Dynamic icon color: Black in Light Mode, White in Dark Mode
            child: BackButton(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ),
      endDrawer: const _FilterDrawer(),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (state) {
          // --- EMPTY STATE HANDLING (THEMED) ---
          if (state.products.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        // Dynamic background color
                        color: colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        // Dynamic icon color
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "No Products Found",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        widget.category != null
                            ? "We couldn't find any products in '${widget.category!.name}'."
                            : "Try adjusting your search or filters.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action Button
                    OutlinedButton.icon(
                      onPressed: () {
                        if (widget.category != null) {
                          context.pop();
                        } else {
                          Scaffold.of(context).openEndDrawer();
                        }
                      },
                      icon: Icon(
                        widget.category != null ? Icons.arrow_back : Icons.tune,
                      ),
                      label: Text(
                        widget.category != null ? "Go Back" : "Change Filters",
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // --- PRODUCT GRID ---
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
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(productFilterProvider);
    final notifier = ref.read(productFilterProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      width: 300,
      backgroundColor: colorScheme.surface, // Standard drawer background
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Filter Products",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Sort By
                  Text(
                    "Sort By",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  DropdownButton<String>(
                    value: filter.sortBy,
                    isExpanded: true,
                    dropdownColor: colorScheme
                        .surfaceContainer, // Fix dropdown bg in dark mode
                    style: TextStyle(color: colorScheme.onSurface),
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text("Newest")),
                      DropdownMenuItem(
                        value: 'price_asc',
                        child: Text("Price: Low to High"),
                      ),
                      DropdownMenuItem(
                        value: 'price_desc',
                        child: Text("Price: High to Low"),
                      ),
                      DropdownMenuItem(
                        value: 'rating_desc',
                        child: Text("Rating: Best"),
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
                      "In Stock Only",
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
                    "Price Range",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: const InputDecoration(
                            labelText: "Min",
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (val) {
                            notifier.update(
                              filter.copyWith(priceMin: double.tryParse(val)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: const InputDecoration(
                            labelText: "Max",
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (val) {
                            notifier.update(
                              filter.copyWith(priceMax: double.tryParse(val)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Press Enter on keyboard to apply price",
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Apply Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const SizedBox(
                  width: double.infinity,
                  child: Center(child: Text("Done")),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
