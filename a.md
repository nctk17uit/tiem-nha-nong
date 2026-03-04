# 6.3 - Mô tả màn và luồng (Screens & Workflows)

## 6.3.1 Splash Page — `lib/ui/screens/splash_page.dart` ✅
- Mục đích: Kiểm tra trạng thái đăng nhập (`AuthController`) và chuyển hướng đến `/home` nếu đã có user.
- Lưu ý: Router có `redirect` để tránh loop nếu user đã login.

```dart
// lib/ui/screens/splash_page.dart
ref.listen<AsyncValue<User?>>(authControllerProvider, (_, state) {
  if (!state.isLoading && !state.hasError) {
    context.go('/home');
  }
});

// Fallback
if (!authState.isLoading && !authState.hasError) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) context.go('/home');
  });
}
```

---

## 6.3.2 Authentication (Login / Register / Verify / Forgot / Reset) 🔐

### Login — `lib/ui/screens/login_page.dart`
- Mục đích: Đăng nhập bằng email/password.
- Inputs: `email`, `password`.
- Tương tác chính: `AuthController.login(email, password)`.
- On success: tokens saved -> cart merge -> redirect `/home` (AuthController.build sẽ return user).
- Error flows: show `SnackBar` với thông báo; support resend, go to `/forgot-password`.

```dart
// lib/ui/screens/login_page.dart
void _onLogin() async {
  await ref.read(authControllerProvider.notifier).login(_emailCtrl.text, _passCtrl.text);

  final state = ref.read(authControllerProvider);
  if (state.hasError && !state.isLoading) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${state.error}"), backgroundColor: Theme.of(context).colorScheme.error),
    );
  } else if (state.value != null) {
    final redirectPath = GoRouterState.of(context).extra as String?;
    if (redirectPath != null) context.replace(redirectPath);
    else if (context.canPop()) context.pop();
    else context.go('/home');
  }
}
```

#### Token save & cart merge (shared logic)
```dart
// lib/controllers/auth_controller.dart
Future<User> _handleAuthSuccess(Map<String, dynamic> data) async {
  final storage = ref.read(storageProvider);
  await storage.write(key: accessKey, value: data['accessToken']);
  await storage.write(key: refreshKey, value: data['refreshToken']);

  // Trigger Cart Merge
  final cartController = ref.read(cartControllerProvider.notifier);
  await cartController.mergeLocalCartToServer();

  return User.fromJson(data['user']);
}
```

### Register → Verify
```dart
// lib/ui/screens/register_page.dart
final success = await ref.read(authControllerProvider.notifier).register(name, email, pass);
if (success && mounted) {
  context.pushReplacement('/verify-code', extra: {'email': email, 'redirect': redirectPath});
}

// lib/ui/screens/verification_page.dart (try submit)
await ref.read(authControllerProvider.notifier).verifyCode(email, code);
// on success: context.replace(redirectPath ?? '/home');
```

### Forgot / Reset password
```dart
// lib/ui/screens/reset_password_page.dart
await ref.read(authControllerProvider.notifier).resetPassword(email: widget.email, code: code, newPassword: newPass);
// on success: context.go('/profile');
```

---

## 6.3.3 Home — `lib/ui/screens/home_page.dart` 🏠
- Mục đích: Banner carousel, danh mục, product grid, quick link "Xem tất cả".
- Tương tác chính: chọn category → tải sản phẩm (limit 10), bấm vào ảnh sản phẩm → push product detail.
- Thêm giỏ: Nếu có variants thì hiển thị bottom sheet chọn variant.

```dart
// lib/ui/screens/home_page.dart
Future<void> _addToCart(Product product) async {
  final fullProduct = await ref.read(productDetailProvider(product.id).future);

  if (fullProduct.hasVariants && fullProduct.variants.isNotEmpty) {
    _showVariantBottomSheet(fullProduct);
  } else {
    await _performAddToCart(fullProduct, fullProduct.variants.first);
  }
}

Future<void> _performAddToCart(Product product, ProductVariant variant) async {
  await ref.read(cartControllerProvider.notifier).addToCart(product: product, variant: variant, quantity: 1);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã thêm "${product.name}" vào giỏ')));
}
```

---

## 6.3.4 Category / Sub-category / Product List 🗂️
- Router: `/category`, `/category/sub`, `/category/products`.
- Flow: UI truyền `Category` object vào `state.extra` khi chuyển trang.

```dart
// lib/ui/screens/category_page.dart
// Drill Down: Pass the category object
context.push('/category/sub', extra: category);
// Leaf Node: Go to Products
context.push('/category/products', extra: category);

// lib/ui/screens/sub_category_page.dart
// "View All" uses parent category
context.push('/category/products', extra: parentCategory);

// lib/ui/screens/product_list_page.dart
// ProductListPage accepts optional Category via constructor
class ProductListPage extends ConsumerStatefulWidget {
  final Category? category;
}
```

---

## 6.3.5 Product Detail — `lib/ui/screens/product_detail_page.dart` 🧾
- Show carousel, variant selector, quantity, add-to-cart bottom bar.
- Flow: chọn variant → kiểm tra stock → gọi `CartController.addToCart`.

```dart
// lib/ui/screens/product_detail_page.dart (bottom bar)
onPressed: () async {
  await ref.read(cartControllerProvider.notifier).addToCart(product: product, variant: activeVariant, quantity: _quantity);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã thêm \"$_quantity x ${product.name}\" vào giỏ hàng!")));
}
```

---

## 6.3.6 Cart — `lib/ui/screens/cart_page.dart` 🛒
- Hiển thị `CartItem`, tổng tiền, update quantity / remove (optimistic UI), Proceed to checkout.

```dart
// lib/ui/screens/cart_page.dart (checkout button)
onPressed: isEmpty ? null : () {
  if (isLoggedIn) context.push('/checkout');
  else context.push('/login', extra: '/checkout');
}
```

---

## 6.3.7 Checkout — `lib/ui/screens/checkout_page.dart` & `lib/controllers/checkout_controller.dart` 💳
- Chức năng: chọn địa chỉ (`AddressController`), chọn phương thức thanh toán, áp mã coupon, place order.
- `CheckoutController.placeOrder()` gọi `orderRepository.createOrder(...)`, sau success: `cartController.clearState()`.

```dart
// lib/controllers/checkout_controller.dart
Future<Order> placeOrder() async {
  if (state.selectedAddress == null) throw "Please select a shipping address";
  final order = await ref.read(orderRepositoryProvider).createOrder(...);

  // Success: Clear cart
  ref.read(cartControllerProvider.notifier).clearState();
  return order;
}

// lib/ui/screens/checkout_page.dart
final order = await ref.read(checkoutControllerProvider.notifier).placeOrder();
if (order.paymentMethod == 'ONLINE' && order.checkoutUrl != null) {
  await launchUrl(Uri.parse(order.checkoutUrl!));
} else {
  context.go('/order-confirmed/${order.orderNumber}');
}
```

### Payment result & deep-linking
Router handles payment callback and parses query params:
```dart
// lib/router/app_router.dart (payment route)
// Matches: /payment/success or /payment/cancel
path: '/payment/:status',
final orderCode = state.uri.queryParameters['orderCode'];
final payosCode = state.uri.queryParameters['payosCode'];
final isSuccess = status == 'success' && payosCode == '00';
return PaymentResultPage(isSuccess: isSuccess, orderCode: orderCode, ...);
```

---

## 6.3.8 Orders — `order_list_page.dart`, `order_detail_page.dart` ✅
- Danh sách đơn, xem chi tiết.

```dart
// lib/ui/screens/order_list_page.dart
onTap: () => context.push('/orders/${order.orderNumber}');

// lib/ui/screens/order_detail_page.dart
final order = ref.read(orderRepositoryProvider).getOrderDetails(id);
```

---

## 6.3.9 Profile — `profile_page.dart` 👤
- Quản lý user info và logout.

```dart
// lib/ui/screens/profile_page.dart (logout)
ref.read(authControllerProvider.notifier).logout();

// lib/controllers/auth_controller.dart
Future<void> logout() async {
  final storage = ref.read(storageProvider);
  await storage.deleteAll();
  state = const AsyncValue.data(null);
  ref.read(cartControllerProvider.notifier).clearState();
}
```

---

## 6.3.10 Support Chat — `support_chat_page.dart` 💬
```dart
// lib/ui/screens/support_chat_page.dart
Tawk(
  visitor: TawkVisitor(name: isGuest? 'Guest' : user.name, email: isGuest ? 'guest@example.com' : user.email),
)
```

---

## 6.3.11 News — `news_page.dart` 📰
- Simple list, search and filters.

```dart
// lib/ui/screens/news_page.dart
// Placeholder of articles and list; navigation to detail is a TODO
```

---

## 6.4 Luồng chính (Summaries) 🔁

**A) Luồng đăng nhập (với merge cart):**
1. UI gọi `authControllerProvider.notifier.login(email, password)` (`lib/ui/screens/login_page.dart`).
2. `AuthController._handleAuthSuccess` lưu tokens vào `storage` và gọi `CartController.mergeLocalCartToServer()` (`lib/controllers/auth_controller.dart`).
3. Router redirect về `/home` (via `AuthController.build()` when user exists and via splash/router redirect). 

**B) Thêm sản phẩm vào giỏ (Simple / Variable):**
- Simple product: lấy default variant → `CartController.addToCart(...)` (`lib/controllers/cart_controller.dart`).
- Variable product: hiển thị bottom sheet chọn variant → gọi `addToCart`.

**C) Thanh toán & tạo đơn:**
1. Checkout chọn address/payment/coupon → `CheckoutController.placeOrder()`.
2. On success: `cartController.clearState()` và `context.go('/order-confirmed/:id')`.
3. Hỗ trợ deep-link từ payment gateway → Router xử lý `/payment/:status` và query params.

---

> Files đã trích xuất: 
> - `lib/ui/screens/splash_page.dart`
> - `lib/ui/screens/login_page.dart`
> - `lib/controllers/auth_controller.dart`
> - `lib/controllers/cart_controller.dart`
> - `lib/ui/screens/home_page.dart`
> - `lib/router/app_router.dart`
> - `lib/ui/screens/product_detail_page.dart`
> - `lib/ui/screens/cart_page.dart`
> - `lib/controllers/checkout_controller.dart`
> - `lib/ui/screens/checkout_page.dart`
> - `lib/ui/screens/product_list_page.dart`
> - `lib/ui/screens/category_page.dart`
> - `lib/ui/screens/sub_category_page.dart`
> - `lib/ui/screens/register_page.dart`
> - `lib/ui/screens/verification_page.dart`
> - `lib/ui/screens/reset_password_page.dart`
> - `lib/ui/screens/order_list_page.dart`
> - `lib/ui/screens/order_detail_page.dart`
> - `lib/ui/screens/profile_page.dart`
> - `lib/ui/screens/support_chat_page.dart`
> - `lib/ui/screens/news_page.dart`

---

Nếu bạn muốn, tôi có thể:
- Thêm những đoạn code khác hoặc mở rộng giải thích từng controller repository,
- Tạo file `a.md` trong một thư mục docs cụ thể thay vì root,
- Hoàn thiện table of contents hoặc links nội bộ trong `a.md`.

---

*File `a.md` đã được tạo ở thư mục dự án.*

---

## 7. Hướng dẫn cài đặt & chạy ứng dụng (Installation & Run) 🔧

### 1) Yêu cầu trước (Prerequisites)
- **Flutter SDK** (phiên bản tương thích với project: Dart SDK >= **3.9.2**) — cài đặt theo: https://flutter.dev/docs/get-started/install
- **Android SDK / Android Studio** (để chạy emulator / build Android)
- **Java JDK 11** (nếu chưa có)
- **Xcode** (chỉ macOS) để build iOS
- **Windows**: nếu phát triển trên Windows, có thể build `windows` target (desktop)

Kiểm tra môi trường bằng:
```bash
flutter doctor -v
```

---

### 2) Clone & chuẩn bị code
1. Clone repository và chuyển vào thư mục project:
```bash
git clone <repo-url>
cd mobile
```
2. Cài dependencies:
```bash
flutter pub get
```
3. Tạo file `.env` (project sử dụng `flutter_dotenv`):
- Tệp `.env` nằm ở root và được thêm vào `assets` (xem `pubspec.yaml`).
- **Bắt buộc**: định nghĩa `APP_URL` (ví dụ `APP_URL=https://api.yourdomain.com`).

Ví dụ `.env`:
```
APP_URL=https://api.yourdomain.com
# OTHER_KEY=...
```
> ⚠️ Đừng commit `.env` chứa keys bí mật lên git; dùng `.env.example` nếu muốn chia sẻ cấu hình mẫu.

---

### 3) Chạy app trong development
- Liệt kê thiết bị/emulator:
```bash
flutter devices
```
- Chạy trên Android emulator hoặc device:
```bash
flutter run
# hoặc chỉ định device id
flutter run -d <device-id>
```
- Chạy trên Windows (desktop):
```bash
flutter run -d windows
```
- Chạy trên Web (nếu muốn):
```bash
flutter run -d chrome
```

---

### 4) Build release
- Android APK:
```bash
flutter build apk --release
```
- Android App Bundle (upload lên Play Console):
```bash
flutter build appbundle --release
```
- iOS (trên macOS):
```bash
flutter build ios --release
```
- Windows:
```bash
flutter build windows --release
```

**Signing (Android)**: project hiện dùng `debug` signing by default (xem `android/app/build.gradle.kts`). Để phát hành, tạo keystore và cấu hình `signingConfigs` & `gradle.properties` theo hướng dẫn chính thức: https://flutter.dev/docs/deployment/android

---

### 5) Chạy kiểm thử & kiểm tra mã
- Chạy unit/widget tests:
```bash
flutter test
```
- Phân tích tĩnh / linter:
```bash
flutter analyze
```
- Tạo launcher icons (nếu cần):
```bash
flutter pub run flutter_launcher_icons:main
```

---

### 6) Một số lưu ý & Troubleshooting
- Lỗi `dotenv.env['APP_URL']!` -> đảm bảo `.env` tồn tại và `APP_URL` đã được khai báo.
- Nếu gặp lỗi build Android, chạy `flutter doctor --android-licenses` và chấp nhận các license.
- Network / timeout: xem `lib/services/networking.dart` (connect/receive timeout được đặt 10s).
- Nếu gặp lỗi token/401: `AuthController` xử lý refresh token; nhưng nếu refresh fail, storage sẽ được clear và user trở về trạng thái guest.

---

Nếu bạn muốn, tôi có thể thêm:
- Một file `.env.example` trong repo,
- Hướng dẫn chi tiết ký APK (keystore + gradle config),
- Tập lệnh CI (GitHub Actions) để build và phát hành tự động.
