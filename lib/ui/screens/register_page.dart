import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/controllers/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  // 1. Controllers for Name, Email, Password
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onRegister() async {
    // 2. Validation: Require Name, Email, and Password
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    // 3. Call Controller with (Name, Email, Password)
    final success = await ref
        .read(authControllerProvider.notifier)
        .register(name, email, pass);

    // 4. Navigate on Success using GoRouter
    if (success && mounted) {
      // Pass the email to the Verify page so the user doesn't have to re-type it
      context.push('/verify-code', extra: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final primaryColor = colorScheme.primary;

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
              const SizedBox(height: 18),

              // --- NAME INPUT ---
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _buildInputDecoration(
                  label: 'Họ và tên', // Updated Label
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(height: 12),

              // --- EMAIL INPUT ---
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration(
                  label: 'Email',
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

              const SizedBox(height: 24),

              // --- REGISTER BUTTON ---
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
                        onPressed: _onRegister,
                        child: Text(
                          'Tạo tài khoản',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  // Consistent Input Style
  InputDecoration _buildInputDecoration({
    required String label,
    required ColorScheme colorScheme,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelText: label,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),

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
