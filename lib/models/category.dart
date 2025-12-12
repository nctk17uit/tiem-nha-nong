class Category {
  final String id;
  final String name;
  final String path;
  final String? parentId;
  final List<Category> children;

  const Category({
    required this.id,
    required this.name,
    required this.path,
    this.parentId,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['category_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      path: json['path'] ?? '',
      parentId: json['parent_id'],
      // RECURSION: Automatically parse nested children list
      children:
          (json['children'] as List<dynamic>?)
              ?.map((e) => Category.fromJson(e))
              .toList() ??
          [],
    );
  }
}
