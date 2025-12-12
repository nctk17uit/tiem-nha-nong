import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../models/product.dart'; // Need Product/Variant models for adding
import '../repositories/cart_repository.dart';
import '../services/cart_storage.dart';
import 'auth_controller.dart'; // To check login state

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
    // Initial Load
    _loadInitialCart();
    return CartState(isLoading: true);
  }

  Future<void> _loadInitialCart() async {
    final user = ref.read(authControllerProvider).value;
    List<CartItem> items = [];

    try {
      if (user != null) {
        // Logged In: Load from API
        items = await ref.read(cartRepositoryProvider).getCart();
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
  Future<void> addToCart({
    required Product product,
    required ProductVariant variant,
    int quantity = 1,
  }) async {
    final user = ref.read(authControllerProvider).value;
    state = CartState(items: state.items, isLoading: true);

    try {
      if (user != null) {
        // 1. Logged In: Call API
        await ref.read(cartRepositoryProvider).addToCart(variant.id, quantity);
        // Refresh cart from server to get correct IDs and totals
        final newItems = await ref.read(cartRepositoryProvider).getCart();
        state = CartState(items: newItems, isLoading: false);
      } else {
        // 2. Guest: Local Logic
        // Check local duplicate
        final currentItems = [...state.items];
        final index = currentItems.indexWhere((i) => i.variantId == variant.id);

        if (index != -1) {
          // Update existing
          final existing = currentItems[index];
          final newQty = existing.quantity + quantity;
          // Validate Stock (Optimistic)
          if (newQty > variant.stock) throw "Not enough stock";

          currentItems[index] = CartItem(
            variantId: variant.id,
            productId: product.id,
            productName: product.name,
            variantName: variant.name,
            thumbnailUrl: product.thumbnailUrl, // Or specific variant image
            price: variant.price,
            quantity: newQty,
            stockQuantity: variant.stock,
          );
        } else {
          // Add new
          if (quantity > variant.stock) throw "Not enough stock";

          currentItems.add(
            CartItem(
              variantId: variant.id,
              productId: product.id,
              productName: product.name,
              variantName: variant.name,
              thumbnailUrl: product.thumbnailUrl,
              price: variant.price,
              quantity: quantity,
              stockQuantity: variant.stock,
            ),
          );
        }

        // Save to Storage
        await ref.read(cartStorageProvider).saveCart(currentItems);
        state = CartState(items: currentItems, isLoading: false);
      }
    } catch (e) {
      state = CartState(items: state.items, isLoading: false);
      rethrow; // Let UI handle error toast
    }
  }

  // --- MERGE (Called after Login) ---
  Future<List<CartMergeNotification>> mergeLocalCartToServer() async {
    try {
      state = CartState(items: state.items, isLoading: true);

      // 1. Get Local Items
      final localItems = await ref.read(cartStorageProvider).loadCart();
      if (localItems.isEmpty) {
        // Nothing to merge, just fetch server cart
        await _loadInitialCart();
        return [];
      }

      // 2. Call API Merge
      final notifications = await ref
          .read(cartRepositoryProvider)
          .mergeCart(localItems);

      // 3. Clear Local Storage
      await ref.read(cartStorageProvider).clearCart();

      // 4. Refresh State from Server
      await _loadInitialCart();

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
        if (item.id == null) throw "ID missing";
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
        if (item.id == null) throw "ID missing";
        await ref
            .read(cartRepositoryProvider)
            .updateQuantity(item.id!, newQuantity);

        // Optional: You can fetch the cart again "silently" to ensure price totals are correct from server
        // without triggering a loading spinner.
        // final serverItems = await ref.read(cartRepositoryProvider).getCart();
        // state = CartState(items: serverItems, isLoading: false);
      } else {
        // 4b. Guest: Save to Storage
        await ref.read(cartStorageProvider).saveCart(optimisticItems);
      }
    } catch (e) {
      // 5. REVERT on failure
      state = CartState(items: previousItems, isLoading: false);
      // Optional: Show Toast "Update failed"
    }
  }
}

final cartControllerProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);
