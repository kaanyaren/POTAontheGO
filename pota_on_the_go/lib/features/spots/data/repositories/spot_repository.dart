import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/radio_utils.dart';
import '../../../../core/network/dio_client.dart';
import '../models/spot_model.dart';

final spotRepositoryProvider = Provider<SpotRepository>((ref) {
  return SpotRepository(DioClient().dio);
});

final currentSpotsProvider = FutureProvider<List<SpotModel>>((ref) async {
  final repo = ref.watch(spotRepositoryProvider);
  return repo.getRecentSpots();
});

class SpotRepository {
  SpotRepository(this._dio);

  static const _cacheTtl = Duration(minutes: 3);
  static const _cacheKey = 'spots_cache_json';
  static const _cacheUpdatedAtKey = 'spots_cache_updated_at';
  static SharedPreferences? _prefs;
  final Dio _dio;
  DateTime? _lastSuccessfulFetchAt;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<List<SpotModel>> getRecentSpots({bool forceRefresh = false}) async {
    final cachedSpots = await _getCachedSpots();
    _lastSuccessfulFetchAt ??= await _getLastCacheTimestamp();
    final hasFreshCache =
        !forceRefresh &&
        cachedSpots.isNotEmpty &&
        _lastSuccessfulFetchAt != null &&
        DateTime.now().difference(_lastSuccessfulFetchAt!) < _cacheTtl;

    if (hasFreshCache) {
      return cachedSpots;
    }

    try {
      final response = await _dio.get(
        'spot/',
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );

      if (response.statusCode == 200 && response.data != null) {
        final jsonList = response.data as List<dynamic>;
        final spots = jsonList
            .map((json) => _fromJson(json as Map<String, dynamic>))
            .toList(growable: false);
        await _saveSpotsToCache(spots);
        _lastSuccessfulFetchAt = DateTime.now();
        return spots;
      }

      return cachedSpots;
    } on DioException catch (error) {
      if (cachedSpots.isNotEmpty) {
        return cachedSpots;
      }
      throw Exception('Failed to fetch spots: ${error.message}');
    } catch (error) {
      if (cachedSpots.isNotEmpty) {
        return cachedSpots;
      }
      throw Exception('Failed to fetch spots: $error');
    }
  }

  Future<List<SpotModel>> _getCachedSpots() async {
    final preferences = await _preferences;
    final rawJson = preferences.getString(_cacheKey);
    if (rawJson == null || rawJson.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawJson) as List<dynamic>;
    final spots = decoded
        .map((item) => _fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    spots.sort((a, b) => b.spotTime.compareTo(a.spotTime));
    return spots;
  }

  Future<void> _saveSpotsToCache(List<SpotModel> spots) async {
    final preferences = await _preferences;
    final encoded = jsonEncode(
      spots
          .map(
            (spot) => {
              'spotId': spot.spotId,
              'activator': spot.activator,
              'frequency': spot.frequency,
              'band': resolveBandLabel(
                rawBand: spot.band,
                frequency: spot.frequency,
              ),
              'mode': spot.mode,
              'reference': spot.reference,
              'spotTime': spot.spotTime.toIso8601String(),
            },
          )
          .toList(growable: false),
    );

    await preferences.setString(_cacheKey, encoded);
    await preferences.setInt(
      _cacheUpdatedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<DateTime?> _getLastCacheTimestamp() async {
    final preferences = await _preferences;
    final timestamp = preferences.getInt(_cacheUpdatedAtKey);
    if (timestamp == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  SpotModel _fromJson(Map<String, dynamic> json) {
    return SpotModel()
      ..spotId = json['spotId'] ?? 0
      ..activator = json['activator'] ?? ''
      ..frequency = json['frequency']?.toString() ?? ''
      ..band = resolveBandLabel(
        rawBand: json['band']?.toString() ?? '',
        frequency: json['frequency']?.toString() ?? '',
      )
      ..mode = json['mode'] ?? ''
      ..reference = json['reference'] ?? ''
      ..spotTime = DateTime.tryParse(json['spotTime'] ?? '') ?? DateTime.now();
  }
}
