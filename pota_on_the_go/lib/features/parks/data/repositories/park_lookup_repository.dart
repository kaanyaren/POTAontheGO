import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../../core/database/isar_helper.dart';
import '../../../../core/network/dio_client.dart';
import '../models/park_model.dart';

final parkLookupRepositoryProvider = Provider<ParkLookupRepository>((ref) {
  return ParkLookupRepository(DioClient().dio);
});

final parkNameProvider = FutureProvider.family<String?, String>((
  ref,
  reference,
) async {
  return ref.read(parkLookupRepositoryProvider).getParkName(reference);
});

class ParkLookupRepository {
  ParkLookupRepository(this._dio);

  final Dio _dio;
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

  String? _extractName(dynamic data) {
    if (data is Map<String, dynamic>) {
      final direct =
          data['name'] ??
          data['parkName'] ??
          data['title'] ??
          data['displayName'];
      if (direct is String && direct.trim().isNotEmpty) {
        return direct.trim();
      }

      final nested = data['park'];
      if (nested is Map<String, dynamic>) {
        return _extractName(nested);
      }
      return null;
    }

    if (data is List && data.isNotEmpty) {
      return _extractName(data.first);
    }

    return null;
  }
}
