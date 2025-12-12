import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Remove Google Fonts as we now use Theme TextStyles
// import 'package:google_fonts/google_fonts.dart';

import 'package:mobile/utils/elements_format.dart';
import 'package:mobile/controllers/cart_controller.dart';
import 'package:mobile/ui/widgets/cart_list.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. THEME DATA
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // 2. WATCH STATE
    final cartState = ref.watch(cartControllerProvider);
    final cartItems = cartState.items;

    // 3. CALCULATE TOTAL
    final double totalPrice = cartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        // Use Primary Color from Theme (usually the Green brand color)
        backgroundColor: colorScheme.primary,
        elevation: 0,
        toolbarHeight: 56,
        // Ensure Back Button is readable on Primary color
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        title: Text(
          'Giỏ hàng - ${cartItems.length}',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
      ),

      // 4. MAIN CONTENT
      body: cartState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? _buildEmptyState(context)
          : CartList(
              cartItems: cartItems,
              onRemoveItem: (item) {
                ref.read(cartControllerProvider.notifier).removeItem(item);
              },
              onUpdateQuantity: (item, qty) {
                if (qty > 0) {
                  ref
                      .read(cartControllerProvider.notifier)
                      .updateQuantity(item, qty);
                }
              },
            ),

      bottomNavigationBar: _buildBottomBar(
        context,
        cartItems.isEmpty,
        totalPrice,
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outline, width: 4),
            ),
            child: Icon(
              Icons.sentiment_very_dissatisfied,
              size: 50,
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Giỏ hàng đang trống',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mua sắm thêm để\nkhông bỏ lỡ những ưu đãi của Tiệm Nhà Nông!!!',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              // Use Primary color for the main Call-To-Action
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Mua sắm ngay',
              style: textTheme.labelLarge?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    bool isEmpty,
    double totalPrice,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              PriceFormatter.format(totalPrice),
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                // Active color = Primary.
                // Disabled color is handled automatically by Flutter when onPressed is null.
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: isEmpty
                  ? null
                  : () {
                      // TODO: Navigate to Payment/Checkout Screen
                      // Navigator.pushNamed(context, '/checkout');
                    },
              child: Text(
                'Mua hàng',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
