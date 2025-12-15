import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/controllers/auth_controller.dart';
import 'package:mobile/ui/screens/cart_page.dart';
import 'package:mobile/ui/screens/login_page.dart';
import 'package:mobile/ui/screens/register_page.dart';
import 'package:mobile/ui/screens/verification_page.dart';
import 'package:mobile/ui/screens/forgot_password_page.dart';
import 'package:mobile/ui/screens/reset_password_page.dart';
import 'package:mobile/ui/screens/update_info_page.dart';
import 'package:mobile/ui/screens/change_password_page.dart';
import 'package:mobile/ui/screens/address_list_page.dart';
import 'package:mobile/ui/screens/add_edit_address_page.dart';
import 'package:mobile/ui/screens/checkout_page.dart';
import 'package:mobile/ui/screens/splash_page.dart';
import 'package:mobile/ui/screens/home_page.dart';
import 'package:mobile/ui/screens/profile_page.dart';
import 'package:mobile/ui/screens/category_page.dart';
import 'package:mobile/ui/screens/sub_category_page.dart';
import 'package:mobile/ui/screens/product_list_page.dart';
import 'package:mobile/ui/screens/product_detail_page.dart';
import 'package:mobile/ui/widgets/app_navigation_bar.dart';
import 'package:mobile/models/category.dart';
import 'package:mobile/models/shipping_address.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // 1. Protect Splash Loop
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
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/verify-code',
        builder: (context, state) {
          // Cast the extra object to Map
          final args = state.extra as Map<String, dynamic>;
          return VerificationPage(args: args);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          // Retrieve email passed from ForgotPasswordPage
          final email = state.extra as String?;
          return ResetPasswordPage(email: email ?? '');
        },
      ),
      GoRoute(
        path: '/profile/update-info',
        builder: (context, state) => const UpdateInfoPage(),
      ),
      GoRoute(
        path: '/profile/change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const AddressListPage(),
      ),
      GoRoute(
        path: '/addresses/form',
        builder: (context, state) {
          // Retrieve the address object if passed (for Edit mode)
          final address = state.extra as ShippingAddress?;
          return AddEditAddressPage(address: address);
        },
      ),

      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      // --- MAIN APP SHELL (Bottom Nav) ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          // Tab 1: Home
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
                  GoRoute(
                    path: 'sub',
                    builder: (context, state) {
                      final category = state.extra as Category;
                      return SubCategoryPage(parentCategory: category);
                    },
                  ),
                  GoRoute(
                    path: 'products',
                    builder: (context, state) {
                      final category = state.extra as Category?;
                      return ProductListPage(category: category);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Tab 3: Cart
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const CartPage(),
              ),
            ],
          ),
          // Tab 4: Profile
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
      // Global Detail Route (pushes over tabs)
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailPage(productId: id);
        },
      ),
      GoRoute(
        path: '/pushed-cart',
        builder: (context, state) => const CartPage(),
      ),
    ],
  );
});
