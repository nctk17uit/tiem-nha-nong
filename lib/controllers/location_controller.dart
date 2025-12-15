import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/models/location.dart';
import 'package:mobile/repositories/location_repository.dart';

// Cache the provinces list to avoid hitting API repeatedly
final provincesProvider = FutureProvider<List<Province>>((ref) async {
  final repo = ref.read(locationRepositoryProvider);
  return repo.getProvinces();
});

// Fetch wards based on selected province code
// Usage: ref.watch(wardsProvider(selectedProvinceCode))
final wardsProvider = FutureProvider.family<List<Ward>, int>((
  ref,
  provinceCode,
) async {
  final repo = ref.read(locationRepositoryProvider);
  return repo.getWards(provinceCode);
});
