import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../../core/database/isar_helper.dart';
import '../models/park_model.dart';

final parkLookupRepositoryProvider = Provider<ParkLookupRepository>((ref) {
  return ParkLookupRepository();
});

final parkNameProvider = FutureProvider.family<String?, String>((
  ref,
  reference,
) async {
  return ref.read(parkLookupRepositoryProvider).getParkName(reference);
});

class ParkLookupRepository {
  final Map<String, String> _cache = {};

  Future<String?> getParkName(String reference) async {
    final normalized = reference.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final cached = _cache[normalized];
    if (cached != null) {
      return cached;
    }

    // Use local Isar database instead of network call
    try {
      final park = await IsarHelper.isar.parkModels
          .filter()
          .referenceEqualTo(normalized)
          .findFirst();
      if (park != null) {
        _cache[normalized] = park.name;
        return park.name;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
