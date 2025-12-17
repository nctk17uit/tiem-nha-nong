import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/repositories/product_repository.dart';

// --- 1. FILTER STATE ---
class ProductFilter {
  final String? categoryId;
  final String? search;
  final String sortBy;
  final double? priceMin;
  final double? priceMax;
  final bool inStockOnly;

  ProductFilter({
    this.categoryId,
    this.search,
    this.sortBy = 'newest',
    this.priceMin,
    this.priceMax,
    this.inStockOnly = false,
  });

  // Helper to quickly check if any filter besides category is active
  bool get hasActiveFilters =>
      search != null ||
      priceMin != null ||
      priceMax != null ||
      inStockOnly ||
      sortBy != 'newest';

  // FIX: Using a pattern that allows explicitly passing null to clear filters
  ProductFilter copyWith({
    Object? categoryId = _sentinel,
    Object? search = _sentinel,
    String? sortBy,
    Object? priceMin = _sentinel,
    Object? priceMax = _sentinel,
    bool? inStockOnly,
  }) {
    return ProductFilter(
      categoryId: categoryId == _sentinel ? this.categoryId : (categoryId as String?),
      search: search == _sentinel ? this.search : (search as String?),
      sortBy: sortBy ?? this.sortBy,
      priceMin: priceMin == _sentinel ? this.priceMin : (priceMin as double?),
      priceMax: priceMax == _sentinel ? this.priceMax : (priceMax as double?),
      inStockOnly: inStockOnly ?? this.inStockOnly,
    );
  }

  static const _sentinel = Object();
}

class ProductFilterNotifier extends Notifier<ProductFilter> {
  @override
  ProductFilter build() => ProductFilter();

  void update(ProductFilter newFilter) => state = newFilter;

  // Logic to allow explicitly clearing search or category by passing null
  void setCategory(String? id) => state = state.copyWith(categoryId: id);

  // Implement the setSearch method for your ProductListPage search bar
  void setSearch(String? query) => state = state.copyWith(search: query);

  // IMPLEMENTED: Resets the state to default ProductFilter values
  void reset() {
    state = ProductFilter();
  }
}

final productFilterProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilter>(
  ProductFilterNotifier.new,
);

// --- 2. PAGINATION STATE ---
class ProductPaginationState {
  final List<Product> products;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const ProductPaginationState({
    this.products = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  ProductPaginationState copyWith({
    List<Product>? products,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ProductPaginationState(
      products: products ?? this.products,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// --- 3. LIST CONTROLLER ---
class ProductListController extends AsyncNotifier<ProductPaginationState> {
  @override
  Future<ProductPaginationState> build() async {
    // Watch filter: Reset list when filter changes
    final filter = ref.watch(productFilterProvider);
    return _fetchProducts(
      page: 1,
      filter: filter,
      existingState: const ProductPaginationState(),
    );
  }

  Future<ProductPaginationState> _fetchProducts({
    required int page,
    required ProductFilter filter,
    required ProductPaginationState existingState,
  }) async {
    final repository = ref.read(productRepositoryProvider);
    const limit = 10; // Match your API default or preference

    final newProducts = await repository.getProducts(
      page: page,
      limit: limit,
      categoryId: filter.categoryId,
      search: filter.search,
      sortBy: filter.sortBy,
      priceMin: filter.priceMin,
      priceMax: filter.priceMax,
      inStock: filter.inStockOnly,
    );

    return existingState.copyWith(
      products: page == 1 ? newProducts : [...existingState.products, ...newProducts],
      page: page,
      hasMore: newProducts.length >= limit,
      isLoadingMore: false,
    );
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    final filter = ref.read(productFilterProvider);
    state = await AsyncValue.guard(() async {
      return _fetchProducts(
        page: currentState.page + 1,
        filter: filter,
        existingState: currentState,
      );
    });
  }
}

final productListProvider =
    AsyncNotifierProvider<ProductListController, ProductPaginationState>(
  ProductListController.new,
);

// Family Provider: Fetches details for a specific Product ID
final productDetailProvider =
    FutureProvider.family.autoDispose<Product, String>((ref, id) async {
  final repository = ref.read(productRepositoryProvider);
  return repository.getProductDetail(id);
});
