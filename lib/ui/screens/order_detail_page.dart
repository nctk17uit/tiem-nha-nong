import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/models/order.dart';
import 'package:mobile/repositories/order_repository.dart';
import 'package:mobile/utils/elements_format.dart';

// Provider family to fetch specific order
final orderDetailsProvider = FutureProvider.family.autoDispose<Order, String>((
  ref,
  id,
) async {
  return ref.read(orderRepositoryProvider).getOrderDetails(id);
});

class OrderDetailPage extends ConsumerWidget {
  final String orderId; // Can be UUID or Number
  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết đơn #$orderId')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (order) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trạng thái: ${order.paymentStatus}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            'Ngày đặt: ${order.createdAt.toString().split('.')[0]}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Product List
                const Text(
                  'Sản phẩm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...?order.items?.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        // Image placeholder
                        Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[200],
                          child: item.imageUrl != null
                              ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                              : const Icon(Icons.image, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'x${item.quantity}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(PriceFormatter.format(item.price * item.quantity)),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 32),

                // 3. Totals
                Column(
                  children: [
                    // Subtotal (Tạm tính) = Final Total + Discount Saved
                    _buildSummaryRow(
                      'Tạm tính',
                      PriceFormatter.format(
                        order.totalAmount + order.discountAmount,
                      ),
                    ),

                    // Only show the Discount row if there was actually a discount
                    if (order.discountAmount > 0)
                      _buildSummaryRow(
                        'Giảm giá',
                        '-${PriceFormatter.format(order.discountAmount)}',
                        valueColor: Colors.green,
                      ),

                    const Divider(height: 24),

                    // Final Total (Tổng cộng)
                    _buildSummaryRow(
                      'Tổng cộng',
                      PriceFormatter.format(order.totalAmount),
                      isBold: true,
                      fontSize: 18,
                      valueColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 16,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
