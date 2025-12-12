import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/controllers/auth_controller.dart';
import 'package:mobile/ui/screens/cart_page.dart';
import 'package:mobile/ui/screens/login_page.dart';
import 'package:mobile/ui/screens/splash_page.dart';
import 'package:mobile/ui/screens/home_page.dart';
import 'package:mobile/ui/screens/profile_page.dart';
import 'package:mobile/ui/screens/simple_page.dart';
import 'package:mobile/ui/screens/category_page.dart';
import 'package:mobile/ui/screens/sub_category_page.dart';
import 'package:mobile/ui/screens/product_list_page.dart';
import 'package:mobile/ui/screens/product_detail_page.dart';
import 'package:mobile/ui/widgets/app_navigation_bar.dart';
import 'package:mobile/models/category.dart';

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
          // Tab 2: Category
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/category',
                builder: (context, state) => const CategoryPage(),
                routes: [
                  // The Sub-Route for drill-down
                  // Access via: context.push('/category/sub', extra: categoryObj);
                  GoRoute(
                    path: 'sub', // Resulting path: /category/sub
                    builder: (context, state) {
                      // Pass the object via 'extra' to avoid re-fetching
                      final category = state.extra as Category;
                      return SubCategoryPage(parentCategory: category);
                    },
                  ),

                  // Path becomes: /category/products
                  GoRoute(
                    path: 'products',
                    builder: (context, state) {
                      // We expect a Category object to be passed via 'extra'
                      // It can be null (e.g., if we just want to show all products)
                      final category = state.extra as Category?;
                      return ProductListPage(category: category);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const CartPage(),
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
      GoRoute(
        // Path uses a parameter :id
        path: '/product/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailPage(productId: id);
        },
      ),
    ],
  );
});
