import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';

// -----------------------------------------------------------------------------
// 1. Filter Logic (Using Notifier instead of StateProvider)
// -----------------------------------------------------------------------------

class CategoryFilter {
  final String? search;
  CategoryFilter({this.search});

  // Helper to create a new instance with updated values
  CategoryFilter copyWith({String? search}) {
    return CategoryFilter(search: search);
  }
}

class CategoryFilterNotifier extends Notifier<CategoryFilter> {
  @override
  CategoryFilter build() {
    return CategoryFilter(); // Default state: empty search
  }

  // Method to update the search query
  void setSearch(String? query) {
    state = state.copyWith(search: query);
  }
}

final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, CategoryFilter>(
      CategoryFilterNotifier.new,
    );

// -----------------------------------------------------------------------------
// 2. Data Provider (Auto-refreshes when Filter changes)
// -----------------------------------------------------------------------------

final categoryTreeProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);

  // WATCH the filter. Any change to 'filter' triggers a re-fetch automatically.
  final filter = ref.watch(categoryFilterProvider);

  // LOGIC: If searching, switch to 'flat' view. Otherwise 'tree'.
  final viewMode = (filter.search != null && filter.search!.isNotEmpty)
      ? 'flat'
      : 'tree';

  return repository.getCategories(search: filter.search, view: viewMode);
});
