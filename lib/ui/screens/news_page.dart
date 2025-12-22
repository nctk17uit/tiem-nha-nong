import 'package:flutter/material.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  bool _isLoading = true;
  final List<Map<String, String>> _articles = List.generate(
    8,
    (i) => {
      'title': 'Tiêu đề bài viết số ${i + 1}',
      'excerpt': 'Title cho bài viết số ${i + 1}.',
      'image': 'https://picsum.photos/seed/news${i + 1}/400/200',
      'date': '21/12/2025',
      'author': 'Tác giả ${i + 1}',
    },
  );

  String _searchQuery = '';
  String _activeFilter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    // Simulate loading
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, String>> get _filteredArticles {
    final q = _searchQuery.toLowerCase().trim();
    final list = _articles.where((a) {
      final title = a['title']!.toLowerCase();
      final excerpt = a['excerpt']!.toLowerCase();
      final matchesQuery =
          q.isEmpty || title.contains(q) || excerpt.contains(q);
      final matchesFilter =
          _activeFilter == 'Tất cả' || a['title']!.contains(_activeFilter);
      return matchesQuery && matchesFilter;
    }).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Tin tức",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm tin tức...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 12,
                        ),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 12),
                    // Filters
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          const SizedBox(width: 4),
                          _buildFilterChip('Tất cả'),
                          _buildFilterChip('Khuyễn mãi'),
                          _buildFilterChip('Sự kiện'),
                          _buildFilterChip('Mẹo vặt'),
                          _buildFilterChip('Cập nhật'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Featured
                    if (_isLoading)
                      _featuredPlaceholder()
                    else
                      _featuredCard(context, _articles.first),
                    const SizedBox(height: 12),
                    const Text(
                      'Mới nhất',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Articles list
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (_isLoading) return _articlePlaceholder();

                final list = _filteredArticles;
                if (index >= list.length) return const SizedBox.shrink();
                final a = list[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Card(
                    clipBehavior: Clip.hardEdge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        // TODO: Navigate to news detail page when implemented
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Mở chi tiết bài viết (chưa triển khai)',
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 100,
                            child: Image.network(
                              a['image']!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a['title']!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    a['excerpt']!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        a['date']!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        a['author']!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }, childCount: _isLoading ? 6 : _filteredArticles.length),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                      // load more placeholder
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tải thêm (chưa triển khai)'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tải thêm'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featuredCard(BuildContext context, Map<String, String> article) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mở bài viết tiêu điểm (chưa triển khai)'),
        ),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 8,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(article['image']!, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.08),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article['excerpt']!,
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = label == _activeFilter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _activeFilter = label),
      ),
    );
  }

  Widget _featuredPlaceholder() {
    return AspectRatio(
      aspectRatio: 16 / 8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _articlePlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          height: 100,
          child: Row(
            children: [
              Container(width: 120, height: 100, color: Colors.grey.shade300),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 120,
                        color: Colors.grey.shade200,
                      ),
                      const Spacer(),
                      Container(
                        height: 12,
                        width: 80,
                        color: Colors.grey.shade200,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
