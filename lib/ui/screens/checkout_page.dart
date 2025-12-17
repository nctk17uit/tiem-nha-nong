import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mobile/controllers/checkout_controller.dart';
import 'package:mobile/controllers/cart_controller.dart';
import 'package:mobile/models/payment_method.dart';
import 'package:mobile/models/shipping_address.dart';
import 'package:mobile/utils/elements_format.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutControllerProvider);
    final cartState = ref.watch(cartControllerProvider);

    final grandTotal = cartState.total - checkoutState.discountAmount;

    return Scaffold(
      // 1. App Bar Title: "Thanh toán"
      appBar: AppBar(title: const Text('Thanh toán'), centerTitle: true),
      body: checkoutState.isLoading && checkoutState.availableMethods.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Shipping Address Section
                  _ShippingSection(
                    address: checkoutState.selectedAddress,
                    onTapChange: _onChangeAddress,
                  ),
                  const SizedBox(height: 24),

                  // 2. Payment Methods Section
                  Text(
                    'Phương thức thanh toán', // Payment Method
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (checkoutState.availableMethods.isEmpty)
                    const Text(
                      "Đang tải phương thức thanh toán...",
                    ), // Loading...
                  ...checkoutState.availableMethods.map(
                    (method) => _PaymentOptionTile(
                      method: method,
                      selectedId: checkoutState.selectedPayment?.id,
                      onChanged: (m) => ref
                          .read(checkoutControllerProvider.notifier)
                          .setPaymentMethod(m),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Coupon Section
                  _CouponSection(
                    controller: _couponController,
                    appliedCode: checkoutState.couponCode,
                    onApply: (code) => ref
                        .read(checkoutControllerProvider.notifier)
                        .applyCoupon(code),
                    onRemove: () => ref
                        .read(checkoutControllerProvider.notifier)
                        .removeCoupon(),
                    isLoading: checkoutState.isLoading,
                  ),
                  const SizedBox(height: 24),

                  // 4. Order Summary Section
                  _OrderSummary(
                    cartTotal: cartState.total,
                    discount: checkoutState.discountAmount,
                    grandTotal: grandTotal,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: checkoutState.isLoading
                  ? null
                  : () => _handlePlaceOrder(context, grandTotal),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: checkoutState.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Text(
                      // "Đặt hàng" = Place Order
                      'Đặt hàng • ${PriceFormatter.format(grandTotal)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // --- ACTIONS ---

  void _onChangeAddress() async {
    final selectedAddress = await context.push<ShippingAddress>(
      '/addresses?select=true',
    );

    if (selectedAddress != null) {
      ref.read(checkoutControllerProvider.notifier).setAddress(selectedAddress);
    }
  }

  Future<void> _handlePlaceOrder(BuildContext context, double total) async {
    try {
      final order = await ref
          .read(checkoutControllerProvider.notifier)
          .placeOrder();

      if (!context.mounted) return;

      if (order.paymentMethod == 'ONLINE' && order.checkoutUrl != null) {
        // ... (Keep existing Online payment logic) ...
        final url = Uri.parse(order.checkoutUrl!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw "Không thể mở trang thanh toán";
        }
      } else {
        // --- UPDATE HERE ---
        // Pass the short orderNumber instead of the long ID
        context.go('/order-confirmed/${order.orderNumber}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

// --- SUB-WIDGETS ---

class _ShippingSection extends StatelessWidget {
  final ShippingAddress? address;
  final VoidCallback onTapChange;

  const _ShippingSection({required this.address, required this.onTapChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Địa chỉ nhận hàng', // Shipping Address
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: onTapChange,
              // Add / Change
              child: Text(address == null ? 'Thêm' : 'Thay đổi'),
            ),
          ],
        ),
        if (address == null)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: const Center(
              // Please select an address...
              child: Text('Vui lòng chọn địa chỉ nhận hàng'),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${address!.fullName} | ${address!.phoneNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  address!.fullAddress,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final PaymentMethod method;
  final String? selectedId;
  final ValueChanged<PaymentMethod> onChanged;

  const _PaymentOptionTile({
    required this.method,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedId == method.id;

    return Opacity(
      opacity: method.isEnabled ? 1.0 : 0.5,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: RadioListTile<String>(
          value: method.id,
          groupValue: selectedId,
          onChanged: method.isEnabled ? (_) => onChanged(method) : null,
          title: Text(
            method.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(method.description),
          secondary: method.iconUrl != null
              ? Image.network(
                  method.iconUrl!,
                  width: 32,
                  errorBuilder: (_, __, ___) => const Icon(Icons.payment),
                )
              : const Icon(Icons.payment),
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _CouponSection extends StatelessWidget {
  final TextEditingController controller;
  final String? appliedCode;
  final Function(String) onApply;
  final VoidCallback onRemove;
  final bool isLoading;

  const _CouponSection({
    required this.controller,
    required this.appliedCode,
    required this.onApply,
    required this.onRemove,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (appliedCode != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đã áp dụng mã: $appliedCode', // Coupon applied
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.green),
              onPressed: onRemove,
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nhập mã giảm giá', // Enter coupon code
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: isLoading ? null : () => onApply(controller.text),
          child: const Text('Áp dụng'), // Apply
        ),
      ],
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final double cartTotal;
  final double discount;
  final double grandTotal;

  const _OrderSummary({
    required this.cartTotal,
    required this.discount,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tạm tính (Subtotal)
        _buildRow(context, 'Tạm tính', cartTotal),

        // Giảm giá (Discount)
        if (discount > 0)
          _buildRow(context, 'Giảm giá', -discount, color: Colors.green),

        const Divider(height: 24),

        // Tổng thanh toán (Total Payment)
        _buildRow(context, 'Tổng thanh toán', grandTotal, isBold: true),
      ],
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    double amount, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            PriceFormatter.format(amount),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
