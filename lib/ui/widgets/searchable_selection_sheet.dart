import 'package:flutter/material.dart';

class SearchableSelectionSheet<T> extends StatefulWidget {
  final List<T> items;
  final String title;
  final String Function(T) itemLabel;

  const SearchableSelectionSheet({
    super.key,
    required this.items,
    required this.title,
    required this.itemLabel,
  });

  @override
  State<SearchableSelectionSheet<T>> createState() =>
      _SearchableSelectionSheetState<T>();
}

class _SearchableSelectionSheetState<T>
    extends State<SearchableSelectionSheet<T>> {
  late List<T> _filteredItems;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          return widget
              .itemLabel(item)
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height * 0.75, // Take up 75% of screen
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Handle Bar for Dragging
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: _filter,
            ),
          ),
          const SizedBox(height: 12),

          // List
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(child: Text('Không tìm thấy kết quả'))
                : ListView.separated(
                    itemCount: _filteredItems.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return ListTile(
                        title: Text(widget.itemLabel(item)),
                        onTap: () {
                          Navigator.pop(context, item); // Return selected item
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
