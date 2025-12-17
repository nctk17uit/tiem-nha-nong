import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentResultPage extends StatefulWidget {
  final bool isSuccess;
  final String? orderCode;
  final String? message;

  const PaymentResultPage({
    super.key,
    required this.isSuccess,
    this.orderCode,
    this.message,
  });

  @override
  State<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends State<PaymentResultPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _handleAutoRedirect();
  }

  void _handleAutoRedirect() {
    // Only redirect automatically if payment is successful and we have an order code
    if (widget.isSuccess && widget.orderCode != null) {
      _timer = Timer(const Duration(seconds: 1), () {
        // Check mounted to ensure the widget is still on screen
        if (mounted) {
          _goToConfirmation();
        }
      });
    }
  }

  void _goToConfirmation() {
    // Cancel timer if the user clicks the button manually before 3s
    _timer?.cancel();
    context.go('/order-confirmed/${widget.orderCode}');
  }

  @override
  void dispose() {
    _timer?.cancel(); // Always clean up timers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Icon
              Icon(
                widget.isSuccess ? Icons.check_circle : Icons.cancel,
                size: 80,
                color: widget.isSuccess ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 24),

              // 2. Title
              Text(
                widget.isSuccess
                    ? 'Thanh toán thành công!'
                    : 'Thanh toán thất bại',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.isSuccess ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 3. Status Message
              if (widget.isSuccess)
                Text(
                  'Đang chuyển đến trang xác nhận...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),

              // 4. Error Message (if failed)
              if (!widget.isSuccess && widget.message != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Lỗi: ${widget.message}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 40),

              // 5. Buttons
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (widget.isSuccess) {
                      _goToConfirmation();
                    } else {
                      context.go('/'); // Go home on failure
                    }
                  },
                  child: Text(
                    widget.isSuccess ? 'Xem ngay (Không chờ)' : 'Về trang chủ',
                  ),
                ),
              ),

              if (!widget.isSuccess) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      context.go('/cart');
                    },
                    child: const Text('Thử lại'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
