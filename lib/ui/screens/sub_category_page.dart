import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/category.dart';

class SubCategoryPage extends StatelessWidget {
  final Category parentCategory;

  const SubCategoryPage({required this.parentCategory, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(parentCategory.name)),
      body: ListView.separated(
        // +1 for "View All" button at the top
        itemCount: parentCategory.children.length + 1,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          // A. "View All" Button (Always Index 0)
          if (index == 0) {
            return ListTile(
              tileColor: Colors.indigo.shade50,
              leading: const Icon(Icons.grid_view, color: Colors.indigo),
              title: Text(
                // "View All ${parentCategory.name}",
                "View All",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward, color: Colors.indigo),
              onTap: () {
                // ACTION: Go to Product List using the PARENT category
                // This passes the parent category filter to the product page
                context.push('/category/products', extra: parentCategory);
              },
            );
          }

          // B. Child Categories (Shift index by -1)
          final child = parentCategory.children[index - 1];
          final hasGrandChildren = child.children.isNotEmpty;

          return ListTile(
            title: Text(child.name),
            leading: Icon(
              hasGrandChildren ? Icons.folder_open : Icons.grass,
              color: hasGrandChildren ? Colors.grey[700] : Colors.green,
            ),
            trailing: hasGrandChildren
                ? const Icon(Icons.chevron_right, color: Colors.grey)
                : null,
            onTap: () {
              if (hasGrandChildren) {
                // RECURSION: Drill down deeper
                context.push('/category/sub', extra: child);
              } else {
                // Leaf Node: Go to Products List using THIS child category
                context.push('/category/products', extra: child);
              }
            },
          );
        },
      ),
    );
  }
}
