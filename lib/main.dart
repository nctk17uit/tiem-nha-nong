import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'ui/theme/material_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Initialize the MaterialTheme with a default TextTheme
    // (If we add GoogleFonts later, you pass GoogleFonts.poppinsTextTheme() here!)
    const materialTheme = MaterialTheme(TextTheme());

    return MaterialApp.router(
      routerConfig: router,
      title: 'Shop App',

      // Connect the Light Theme
      theme: materialTheme.light(),

      // Connect the Dark Theme
      darkTheme: materialTheme.dark(),

      // Auto-switch based on phone settings
      themeMode: ThemeMode.system,
    );
  }
}
