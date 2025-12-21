import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tawkto/flutter_tawk.dart';
import 'package:mobile/controllers/auth_controller.dart';

class SupportChatPage extends ConsumerWidget {
  const SupportChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authControllerProvider);
    final user = userState.value;
    final isGuest = user == null;

    if (userState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Access the current theme colors
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hỗ trợ khách hàng'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Tawk(
        directChatLink:
            'https://tawk.to/chat/694806f40b00e71980bdd252/1jd0lmbr2',
        visitor: TawkVisitor(
          name: isGuest ? 'Guest' : user.name,
          email: isGuest ? 'guest@example.com' : user.email,
        ),
        onLoad: () {
          debugPrint('Tawk.to loaded successfully');
        },
        placeholder: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
