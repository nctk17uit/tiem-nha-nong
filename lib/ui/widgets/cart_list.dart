import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:mobile/models/cart.dart';
import 'package:mobile/utils/elements_format.dart';

class CartList extends StatelessWidget {
  final List<CartItem> cartItems;
  final Function(CartItem) onRemoveItem;
  final Function(CartItem, int) onUpdateQuantity;

  const CartList({
    super.key,
    required this.cartItems,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        return _buildProductCard(context, cartItems[index]);
      },
      separatorBuilder: (context, index) => const SizedBox(height: 8),
    );
  }

  Widget _buildProductCard(BuildContext context, CartItem item) {
    // 1. Access Theme Data
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Slidable(
      key: ValueKey(item.id ?? item.variantId),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Xem sản phẩm tương tự của ${item.productName}',
                  ),
                ),
              );
            },
            // Keep Orange for "Similar" as it's likely a specific action color,
            // or use colorScheme.tertiary if you have it defined.
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: Icons.collections,
          ),
          SlidableAction(
            onPressed: (context) => onRemoveItem(item),
            // Use semantic Error color for delete
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            icon: Icons.delete,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Use Surface color (White in light mode, Dark Grey in dark mode)
          color: colorScheme.surface,
          // Use Outline Variant for subtle borders
          border: Border.all(color: colorScheme.outlineVariant, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 1. PRODUCT IMAGE
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant, width: 1),
                borderRadius: BorderRadius.circular(8),
                // Use a slightly darker surface for placeholder background
                color: colorScheme.surfaceContainerHighest,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _buildImage(context, item.thumbnailUrl),
              ),
            ),
            const SizedBox(width: 12),

            // 2. PRODUCT INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          // Use standard text styles
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          // TODO: Handle edit action
                        },
                        child: Text(
                          'Sửa',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            // Use Primary color (usually Blue/Green) for actions
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.variantName,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        PriceFormatter.format(item.price),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQtyBtn(
                              context,
                              icon: Icons.remove,
                              onTap: () =>
                                  onUpdateQuantity(item, item.quantity - 1),
                            ),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: colorScheme.outline,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item.quantity.toString(),
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _buildQtyBtn(
                              context,
                              icon: Icons.add,
                              onTap: () =>
                                  onUpdateQuantity(item, item.quantity + 1),
                            ),
                          ],
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

  Widget _buildImage(BuildContext context, String? url) {
    if (url == null || url.isEmpty) {
      return _buildPlaceholder(context);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder(context);
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildQtyBtn(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: colorScheme.onSurface, // Adapts to dark mode
        ),
      ),
    );
  }
}
