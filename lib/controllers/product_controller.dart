import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

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
    this.sortBy = 'newest', // Default sort
    this.priceMin,
    this.priceMax,
    this.inStockOnly = false,
  });

  ProductFilter copyWith({
    String? categoryId,
    String? search,
    String? sortBy,
    double? priceMin,
    double? priceMax,
    bool? inStockOnly,
  }) {
    return ProductFilter(
      categoryId: categoryId ?? this.categoryId,
      search: search ?? this.search,
      sortBy: sortBy ?? this.sortBy,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      inStockOnly: inStockOnly ?? this.inStockOnly,
    );
  }
}

class ProductFilterNotifier extends Notifier<ProductFilter> {
  @override
  ProductFilter build() => ProductFilter();

  void update(ProductFilter newFilter) => state = newFilter;
  void setCategory(String id) => state = state.copyWith(categoryId: id);
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
      products: [...existingState.products, ...newProducts],
      page: page,
      hasMore: newProducts.length >= limit,
      isLoadingMore: false,
    );
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasMore ||
        currentState.isLoadingMore)
      return;

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
final productDetailProvider = FutureProvider.family
    .autoDispose<Product, String>((ref, id) async {
      final repository = ref.read(productRepositoryProvider);
      return repository.getProductDetail(id);
    });
