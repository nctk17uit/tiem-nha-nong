import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/controllers/auth_controller.dart';
import 'package:mobile/ui/screens/login_page.dart';
import 'package:mobile/ui/screens/splash_page.dart';
import 'package:mobile/ui/screens/home_page.dart';
import 'package:mobile/ui/screens/profile_page.dart';
import 'package:mobile/ui/screens/simple_page.dart';
import 'package:mobile/ui/widgets/app_navigation_bar.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Minimal Redirect: Only protect the splash screen looping
      if (state.matchedLocation == '/splash') {
        final user = ref.read(authControllerProvider).value;
        if (user != null) {
          return '/home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/category',
                builder: (context, state) =>
                    const SimplePage(title: "Category"),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const SimplePage(title: "Cart"),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

