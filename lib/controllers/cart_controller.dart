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

  // --- REMOVE ITEM ---
  Future<void> removeItem(CartItem item) async {
    final user = ref.read(authControllerProvider).value;
    // Optimistic Update: Remove from UI immediately for better UX
    final previousItems = state.items;
    state = CartState(
      items: state.items
          .where(
            (i) =>
                // If logged in, compare ID. If guest, compare Variant ID.
                user != null ? i.id != item.id : i.variantId != item.variantId,
          )
          .toList(),
      isLoading: true,
    );

    try {
      if (user != null) {
        // 1. Logged In: API (Use Server ID)
        if (item.id == null) throw "Server item missing ID";
        await ref.read(cartRepositoryProvider).removeItem(item.id!);

        // Refresh to ensure sync
        final newItems = await ref.read(cartRepositoryProvider).getCart();
        state = CartState(items: newItems, isLoading: false);
      } else {
        // 2. Guest: Local (Use Variant ID)
        // We already filtered the list locally above, just save it.
        await ref.read(cartStorageProvider).saveCart(state.items);
        state = CartState(items: state.items, isLoading: false);
      }
    } catch (e) {
      // Revert on error
      state = CartState(items: previousItems, isLoading: false);
      // Optional: Show error toast
    }
  }

  // --- UPDATE QUANTITY ---
  Future<void> updateQuantity(CartItem item, int newQuantity) async {
    final user = ref.read(authControllerProvider).value;

    // Validation
    if (newQuantity < 1) return;
    if (newQuantity > item.stockQuantity) {
      // Optional: Toast "Max stock reached"
      return;
    }

    // Set loading state (optional, or just handle silently)
    state = CartState(items: state.items, isLoading: true);

    try {
      if (user != null) {
        // 1. Logged In: API (Use Server ID)
        if (item.id == null) throw "Server item missing ID";
        await ref
            .read(cartRepositoryProvider)
            .updateQuantity(item.id!, newQuantity);

        final newItems = await ref.read(cartRepositoryProvider).getCart();
        state = CartState(items: newItems, isLoading: false);
      } else {
        // 2. Guest: Local (Use Variant ID)
        final currentItems = [...state.items];
        final index = currentItems.indexWhere(
          (i) => i.variantId == item.variantId,
        );

        if (index != -1) {
          // Use copyWith to update immutably
          currentItems[index] = item.copyWith(quantity: newQuantity);

          await ref.read(cartStorageProvider).saveCart(currentItems);
          state = CartState(items: currentItems, isLoading: false);
        }
      }
    } catch (e) {
      // Reload strictly to ensure data integrity
      _loadInitialCart();
    }
  }
}

final cartControllerProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);
