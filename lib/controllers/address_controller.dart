import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/models/shipping_address.dart';
import 'package:mobile/repositories/address_repository.dart';

class AddressController extends AsyncNotifier<List<ShippingAddress>> {
  @override
  FutureOr<List<ShippingAddress>> build() async {
    return _fetchAddresses();
  }

  Future<List<ShippingAddress>> _fetchAddresses() {
    return ref.read(addressRepositoryProvider).getAddresses();
  }

  /// Create a new address and refresh the list
  Future<void> addAddress(ShippingAddress address) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(addressRepositoryProvider);
      await repo.createAddress(address);

      // Refresh to get updated list (handling 'isDefault' logic from backend)
      ref.invalidateSelf();
      await future;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update an existing address and refresh the list
  Future<void> updateAddress(String id, ShippingAddress address) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(addressRepositoryProvider);
      await repo.updateAddress(id, address);

      ref.invalidateSelf();
      await future;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Delete an address
  Future<void> deleteAddress(String id) async {
    // Optimistic update: Remove immediately from UI
    final previousState = state.value;
    if (previousState != null) {
      state = AsyncValue.data(
        previousState.where((addr) => addr.id != id).toList(),
      );
    }

    try {
      final repo = ref.read(addressRepositoryProvider);
      await repo.deleteAddress(id);
    } catch (e, st) {
      // Revert on failure
      state = AsyncValue.error(e, st);
      // If we had previous data, restore it?
      // Simpler to just invalidate and re-fetch to ensure consistency
      ref.invalidateSelf();
      rethrow;
    }
  }

  /// Set a specific address as default
  Future<void> setDefault(ShippingAddress address) async {
    // 1. Create a copy with isDefault = true
    final updatedAddress = address.copyWith(isDefault: true);

    // 2. Call the existing update method
    // This will trigger the backend logic to unset the old default and set this one
    await updateAddress(updatedAddress.id, updatedAddress);
  }
}

final addressControllerProvider =
    AsyncNotifierProvider<AddressController, List<ShippingAddress>>(
      AddressController.new,
    );
