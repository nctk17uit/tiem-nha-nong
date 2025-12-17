import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentResultScreen extends StatelessWidget {
  final bool isSuccess;
  final String? orderCode;
  final String? payosMessage;

  const PaymentResultScreen({
    super.key,
    required this.isSuccess,
    this.orderCode,
    this.payosMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kết quả thanh toán")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              isSuccess ? "Thanh toán thành công!" : "Thanh toán thất bại",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (orderCode != null) ...[
              const SizedBox(height: 10),
              Text("Mã đơn hàng: $orderCode"),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Clear stack and go home
                context.go('/');
              },
              child: const Text("Về trang chủ"),
            ),
          ],
        ),
      ),
    );
  }
}
