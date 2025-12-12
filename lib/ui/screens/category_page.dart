import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/category_controller.dart';
import '../../models/category.dart';

class CategoryPage extends ConsumerStatefulWidget {
  const CategoryPage({super.key});

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  // Debounce search to avoid spamming API
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // NEW SYNTAX:
      // Call the method on the Notifier class
      ref
          .read(categoryFilterProvider.notifier)
          .setSearch(query.isEmpty ? null : query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncCategories = ref.watch(categoryTreeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Categories"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search categories...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
      body: asyncCategories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: TextButton(
            onPressed: () => ref.refresh(categoryTreeProvider),
            child: const Text("Retry"),
          ),
        ),
        data: (categories) {
          if (categories.isEmpty)
            return const Center(child: Text("No results"));

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(categoryTreeProvider),
            child: ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final category = categories[index];
                final hasChildren = category.children.isNotEmpty;

                return ListTile(
                  title: Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: hasChildren
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  leading: Icon(
                    hasChildren ? Icons.folder_open : Icons.grass,
                    color: hasChildren ? Colors.indigo : Colors.green,
                  ),
                  trailing: hasChildren
                      ? const Icon(Icons.chevron_right, color: Colors.grey)
                      : null,
                  onTap: () {
                    if (hasChildren) {
                      // Drill Down: Pass the category object
                      context.push('/category/sub', extra: category);
                    } else {
                      // Go to Products
                      context.push('/category/products', extra: category);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
