import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/controllers/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // 1. CHANGE: Remove initial text values
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onLogin() async {
    // 1. Trigger Login
    await ref
        .read(authControllerProvider.notifier)
        .login(_emailCtrl.text, _passCtrl.text);

    // 2. Check Result
    final state = ref.read(authControllerProvider);

    if (state.hasError && !state.isLoading) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${state.error}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } else if (state.value != null) {
      // 3. Success: Check for Redirect Intent
      if (mounted) {
        // Retrieve the 'extra' data passed from GoRouter
        final redirectPath = GoRouterState.of(context).extra as String?;

        if (redirectPath != null) {
          // Case A: Came from Cart -> Go to Checkout (Replace Login in stack)
          context.replace(redirectPath);
        } else {
          // Case B: Came from Profile -> Go back to Profile
          if (context.canPop()) {
            context.pop();
          } else {
            // Fallback if no history exists
            context.go('/home');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final primaryColor = colorScheme.primary;

    // FIX 2: Capture the extra parameter at the start of build so we can forward it
    final redirectPath = GoRouterState.of(context).extra as String?;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // --- LOGO ---
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
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.image,
                      color: colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tiệm Nhà Nông',
                style: textTheme.headlineSmall?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),

              // --- EMAIL INPUT ---
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration(
                  label: 'Email',
                  hintText: 'user@example.com', // Added Hint
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(height: 12),

              // --- PASSWORD INPUT ---
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: _buildInputDecoration(
                  label: 'Mật khẩu',
                  hintText: '••••••••', // Added Hint
                  colorScheme: colorScheme,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    context.push('/forgot-password');
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text(
                    'Quên mật khẩu?',
                    style: textTheme.bodyMedium?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- LOGIN BUTTON ---
              SizedBox(
                width: double.infinity,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _onLogin,
                        child: Text(
                          'Đăng nhập',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Chưa có tài khoản? ',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // FIX 3: Forward the redirect path to Register Page
                      // context.push('/register', extra: redirectPath);

                      // FIX: Use pushReplacement instead of push
                      // This removes 'Login' from the stack and puts 'Register' in its place.
                      context.pushReplacement('/register', extra: redirectPath);
                    },
                    child: Text(
                      'Đăng ký ngay',
                      style: textTheme.bodyMedium?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // 2. CHANGE: Added hintText parameter
  InputDecoration _buildInputDecoration({
    required String label,
    required ColorScheme colorScheme,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelText: label,
      hintText: hintText, // Applied here
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surface,
    );
  }
}
