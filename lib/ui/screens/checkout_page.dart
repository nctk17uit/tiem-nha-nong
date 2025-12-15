import 'package:flutter/material.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.payment, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Chức năng thanh toán đang phát triển'),
          ],
        ),
      ),
    );
  }
}
