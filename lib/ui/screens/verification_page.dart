import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/controllers/auth_controller.dart';

class VerificationPage extends ConsumerStatefulWidget {
  // Update to accept Map or separate fields.
  // For simplicity with GoRouter 'extra', let's take the dynamic extra directly
  // or you can parse it in the router. Here I assume 'extra' is passed as a Map.
  final Map<String, dynamic> args;

  const VerificationPage({super.key, required this.args});

  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage>
    with TickerProviderStateMixin {
  // 6 Controllers for 6 digits
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _seconds = 30;
  Timer? _timer;

  // UI States
  bool _isVerified = false;
  bool _isLoading = false;
  late AnimationController _successAnimCtrl;

  @override
  void initState() {
    super.initState();
    _successAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 0) {
        t.cancel();
        if (mounted) setState(() {});
        return;
      }
      if (mounted) setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _timer?.cancel();
    _successAnimCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String v, int index) {
    if (v.isEmpty) return;

    final ch = v.substring(0, 1);
    _controllers[index].text = ch;

    if (index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }

    _trySubmitIfComplete();
  }

  Future<void> _trySubmitIfComplete() async {
    final code = _controllers.map((c) => c.text).join();

    if (code.length == 6 && !_controllers.any((c) => c.text.isEmpty)) {
      if (_isLoading || _isVerified) return;

      setState(() => _isLoading = true);

      // Extract Email from args
      final email = widget.args['email'] as String;

      try {
        // 1. Call Controller
        await ref.read(authControllerProvider.notifier).verifyCode(email, code);

        // 2. Success Animation
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isVerified = true;
          });
          _successAnimCtrl.forward();

          // 3. FORCE NAVIGATION TO REDIRECT PATH
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              // FIX 5: Retrieve Redirect Path from args
              final redirectPath = widget.args['redirect'] as String?;

              if (redirectPath != null) {
                context.replace(redirectPath); // Go to Checkout
              } else {
                context.go('/home'); // Default behavior
              }
            }
          });
        }
      } catch (e) {
        // 4. Error Handling
        if (mounted) {
          setState(() => _isLoading = false);

          for (var c in _controllers) c.clear();
          _focusNodes[0].requestFocus();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception:', '').trim()),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _resend() async {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    _startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mã xác thực đã được gửi lại')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Extract Email for display
    final email = widget.args['email'] as String;

    if (_isVerified) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _successAnimCtrl,
                curve: Curves.elasticOut,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Xác thực thành công!',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    fit: BoxFit.cover,
                    width: 72,
                    height: 72,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey[300]),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tiệm Nhà Nông',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),

              Text(
                'Xác thực tài khoản',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhập mã xác thực đã được gửi đến:\n$email',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 30),

              if (_isLoading)
                const CircularProgressIndicator()
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (i) => _buildPinBox(i, colorScheme, textTheme),
                  ),
                ),

              const SizedBox(height: 30),

              Text(
                _seconds > 0
                    ? 'Gửi lại trong: ${_seconds}s'
                    : 'Bạn có thể gửi lại mã',
                style: textTheme.bodyMedium?.copyWith(
                  color: _seconds > 0
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _seconds > 0 ? null : _resend,
                child: Text(
                  'Gửi lại',
                  style: textTheme.labelLarge?.copyWith(
                    color: _seconds > 0
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinBox(int index, ColorScheme colorScheme, TextTheme textTheme) {
    return SizedBox(
      width: 40,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          fillColor: colorScheme.surface,
          filled: true,
        ),
        onChanged: (v) => _onChanged(v, index),
      ),
    );
  }
}
