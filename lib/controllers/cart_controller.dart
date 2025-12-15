import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/models/cart.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/repositories/cart_repository.dart';
import 'package:mobile/services/cart_storage.dart';
import 'auth_controller.dart';
import 'package:flutter/foundation.dart';

class CartState {
  final List<CartItem> items;
  final bool isLoading;

  CartState({this.items = const [], this.isLoading = false});

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

class CartController extends Notifier<CartState> {
  @override
  CartState build() {
    // 1. Return initial state immediately
    // 2. Fire the async method strictly as a side effect
    Future(() => _loadInitialCart());

    return CartState(isLoading: true);
  }

  Future<void> _loadInitialCart() async {
    if (kDebugMode) {
      print("DEBUG: _loadInitialCart STARTED");
    }
    final user = ref.read(authControllerProvider).value;
    List<CartItem> items = [];

    try {
      if (user != null) {
        // Logged In: Load from API
        // 1. LOGGED IN: Try to fetch from API with a 5-second timeout
        // If server is down, this throws an error after 5 seconds instead of waiting forever.
        items = await ref
            .read(cartRepositoryProvider)
            .getCart()
            .timeout(const Duration(seconds: 5));
      } else {
        // Guest: Load from Local Storage
        items = await ref.read(cartStorageProvider).loadCart();
      }
      state = CartState(items: items, isLoading: false);
    } catch (e) {
      state = CartState(items: [], isLoading: false);
    }
  }

  // --- ADD ITEM ---
  // --- ADD ITEM ---
  Future<void> addToCart({
    required Product product,
    required ProductVariant variant,
    int quantity = 1,
  }) async {
    final user = ref.read(authControllerProvider).value;

    // --- 1. PRE-VALIDATION (Check limit before doing anything) ---
    // Find if this item is already in the cart (Works for both Guest & User state)
    final existingItemIndex = state.items.indexWhere(
      (item) => item.variantId == variant.id,
    );

    int currentQtyInCart = 0;
    if (existingItemIndex != -1) {
      currentQtyInCart = state.items[existingItemIndex].quantity;
    }

    // Check if adding this quantity exceeds stock
    if (currentQtyInCart + quantity > variant.stockQuantity) {
      if (currentQtyInCart >= variant.stockQuantity) {
        // Case A: Cart already has 2, Stock is 2. User tries to add more.
        throw "Bạn đã đạt giới hạn số lượng mua cho sản phẩm này!";
      } else {
        // Case B: Cart has 1, Stock is 2. User tries to add 2 more.
        final availableToAdd = variant.stockQuantity - currentQtyInCart;
        throw "Chỉ có thể thêm tối đa $availableToAdd sản phẩm nữa vào giỏ!";
      }
    }

    // If validation passes, proceed with loading state
    state = CartState(items: state.items, isLoading: true);

    try {
      if (user != null) {
        // --- LOGGED IN PATH ---
        await ref.read(cartRepositoryProvider).addToCart(variant.id, quantity);

        final newItems = await ref.read(cartRepositoryProvider).getCart();
        state = CartState(items: newItems, isLoading: false);
      } else {
        // --- GUEST PATH ---
        final currentItems = [...state.items];

        if (existingItemIndex != -1) {
          // Update existing
          final existing = currentItems[existingItemIndex];
          final newQty = existing.quantity + quantity;

          // We already validated stock above, but double-check ensures safety
          if (newQty > variant.stockQuantity)
            throw "Số lượng sản phẩm trong kho không đủ";

          currentItems[existingItemIndex] = existing.copyWith(
            quantity: newQty,
            stockQuantity: variant.stockQuantity,
          );
        } else {
          // Add new
          if (quantity > variant.stockQuantity)
            throw "Số lượng sản phẩm trong kho không đủ";

          currentItems.add(
            CartItem(
              variantId: variant.id,
              productId: product.id,
              productName: product.name,
              variantName: variant.name,
              thumbnailUrl: product.thumbnailUrl,
              price: variant.price,
              quantity: quantity,
              stockQuantity: variant.stockQuantity,
            ),
          );
        }

        await ref.read(cartStorageProvider).saveCart(currentItems);
        state = CartState(items: currentItems, isLoading: false);
      }
    } catch (e) {
      state = CartState(items: state.items, isLoading: false);

      // --- HANDLE SERVER 409 (Race Condition) ---
      // This only triggers if the UI thought there was stock, but the
      // Server says "No, someone else just bought it".
      if (e.toString().contains("409")) {
        throw "Rất tiếc, sản phẩm này vừa hết hàng!";
      }

      rethrow;
    }
  }

  // --- MERGE (Called after Login) ---
  Future<List<CartMergeNotification>> mergeLocalCartToServer() async {
    try {
      state = CartState(items: state.items, isLoading: true);

      // 1. Get Local Items
      final localItems = await ref.read(cartStorageProvider).loadCart();

      if (localItems.isEmpty) {
        // Don't call _loadInitialCart(). The AuthProvider isn't updated yet!
        // Call the repository directly to fetch the server cart.
        final serverItems = await ref.read(cartRepositoryProvider).getCart();
        state = CartState(items: serverItems, isLoading: false);
        return [];
      }

      // 2. Call API Merge
      final notifications = await ref
          .read(cartRepositoryProvider)
          .mergeCart(localItems);

      // 3. Clear Local Storage
      await ref.read(cartStorageProvider).clearCart();

      // Again, call repository directly to get the final merged list.
      final finalItems = await ref.read(cartRepositoryProvider).getCart();
      state = CartState(items: finalItems, isLoading: false);

      return notifications;
    } catch (e) {
      state = CartState(items: state.items, isLoading: false);
      rethrow;
    }
  }

  // --- CLEAR (Logout) ---
  void clearState() {
    state = CartState(items: []);
  }

  // --- OPTIMISTIC REMOVE ITEM ---
  Future<void> removeItem(CartItem item) async {
    final user = ref.read(authControllerProvider).value;

    // 1. SNAPSHOT
    final previousItems = state.items;

    // 2. OPTIMISTIC UPDATE: Remove item immediately
    final optimisticItems = state.items.where((i) {
      return user != null ? i.id != item.id : i.variantId != item.variantId;
    }).toList();

    state = CartState(items: optimisticItems, isLoading: false);

    try {
      if (user != null) {
        if (item.id == null) throw "Không tìm thấy ID sản phẩm";
        await ref.read(cartRepositoryProvider).removeItem(item.id!);
      } else {
        await ref.read(cartStorageProvider).saveCart(optimisticItems);
      }
    } catch (e) {
      // 3. REVERT on failure
      state = CartState(items: previousItems, isLoading: false);
    }
  }

  // --- OPTIMISTIC UPDATE QUANTITY ---
  Future<void> updateQuantity(CartItem item, int newQuantity) async {
    final user = ref.read(authControllerProvider).value;

    // 1. Validation
    if (newQuantity < 1) return;
    if (newQuantity > item.stockQuantity) return; // Optional toast here

    // 2. SNAPSHOT: Save previous list in case we need to revert
    final previousItems = state.items;

    // 3. OPTIMISTIC UPDATE: Update the UI *immediately* without loading spinner
    // We create a new list where the specific item has the new quantity
    final optimisticItems = state.items.map((i) {
      // Identify item (by Server ID if logged in, or Variant ID if guest)
      final isTarget = user != null
          ? i.id == item.id
          : i.variantId == item.variantId;

      return isTarget ? i.copyWith(quantity: newQuantity) : i;
    }).toList();

    // Update state NOW (isLoading stays false!)
    state = CartState(items: optimisticItems, isLoading: false);

    try {
      if (user != null) {
        // 4a. Logged In: Sync with API
        if (item.id == null) throw "Không tìm thấy ID sản phẩm";
        await ref
            .read(cartRepositoryProvider)
            .updateQuantity(item.id!, newQuantity);
      } else {
        // 4b. Guest: Save to Storage
        await ref.read(cartStorageProvider).saveCart(optimisticItems);
      }
    } catch (e) {
      // 5. REVERT on failure
      state = CartState(items: previousItems, isLoading: false);
    }
  }
}

final cartControllerProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);
