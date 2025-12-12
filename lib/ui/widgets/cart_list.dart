import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: Icons.collections,
          ),
          SlidableAction(
            onPressed: (context) => onRemoveItem(item),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          children: [
            // 1. PRODUCT IMAGE (With Placeholder Logic)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!, width: 1),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100], // Background color for placeholder
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _buildImage(item.thumbnailUrl),
              ),
            ),
            const SizedBox(width: 12),

            // 2. Product Info
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
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
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
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.variantName,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        PriceFormatter.format(item.price),
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQtyBtn(
                              icon: Icons.remove,
                              onTap: () =>
                                  onUpdateQuantity(item, item.quantity - 1),
                            ),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey[400]!,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item.quantity.toString(),
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _buildQtyBtn(
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

  /// Helper to safely build the image or the placeholder
  Widget _buildImage(String? url) {
    // 1. If URL is null or empty, return Placeholder immediately
    if (url == null || url.isEmpty) {
      return _buildPlaceholder();
    }

    // 2. Try to load image
    return Image.network(
      url,
      fit: BoxFit.cover,
      // 3. If loading fails (404, no internet), return Placeholder
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder();
      },
    );
  }

  /// The reusable Placeholder widget (Grey Icon)
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined, // Better icon for missing images
          color: Colors.grey[400],
          size: 24,
        ),
      ),
    );
  }

  Widget _buildQtyBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: Colors.grey[700]),
      ),
    );
  }
}
