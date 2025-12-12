import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// import 'package:mobile/models/cart.dart';
import 'package:mobile/utils/elements_format.dart';
import 'package:mobile/controllers/cart_controller.dart';
import 'package:mobile/ui/widgets/cart_list.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. WATCH STATE
    // This returns your custom 'CartState' object (which contains items & isLoading)
    final cartState = ref.watch(cartControllerProvider);
    final cartItems = cartState.items;

    // 3. CALCULATE TOTAL
    final double totalPrice = cartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        toolbarHeight: 56,
        title: Text(
          'Giỏ hàng - ${cartItems.length}',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),

      // 4. MAIN CONTENT
      // Prioritize Loading -> Empty -> List
      body: cartState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? _buildEmptyState(context)
          : CartList(
              cartItems: cartItems,
              // ACTION: Pass the *whole item* so the controller can check
              // if it needs to use 'id' (Server) or 'variantId' (Guest)
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[400]!, width: 4),
            ),
            child: Icon(
              Icons.sentiment_very_dissatisfied,
              size: 50,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Giỏ hàng đang trống',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mua sắm thêm để\nkhông bỏ lỡ những ưu đãi của Tiệm Nhà Nông!!!',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Mua sắm ngay',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
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
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              PriceFormatter.format(totalPrice),
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEmpty
                    ? Colors.grey[400]
                    : Colors.orange[700],
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
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
