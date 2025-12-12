import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/controllers/auth_controller.dart';
import 'package:mobile/models/user.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController(text: 'test@test.com');
  final _pass = TextEditingController(text: 'password');

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(authControllerProvider, (_, state) {
      if (state.hasError && !state.isLoading) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("${state.error}")));
        }
      } else if (state.value != null) {
        // Success: Close the login page
        if (context.mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/profile');
          }
        }
      }
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("Sign In")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 32),
            isLoading
                ? const CircularProgressIndicator()
                : FilledButton(
                    onPressed: () {
                      ref
                          .read(authControllerProvider.notifier)
                          .login(_email.text, _pass.text);
                    },
                    child: const SizedBox(
                      width: double.infinity,
                      child: Center(child: Text("Login")),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
