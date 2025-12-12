import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/controllers/auth_controller.dart';
import 'package:mobile/models/user.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    // Redirect listener (Standard)
    ref.listen<AsyncValue<User?>>(authControllerProvider, (_, state) {
      if (!state.isLoading && !state.hasError) {
        context.go('/home');
      }
    });

    // Safety Net: If loaded too fast, go now.
    if (!authState.isLoading && !authState.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
