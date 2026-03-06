import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/dio_client.dart';
import '../models/hf_conditions_model.dart';

final hfConditionsRepositoryProvider = Provider<HfConditionsRepository>((ref) {
  return HfConditionsRepository(DioClient().dio);
});

final hfConditionsProvider = FutureProvider<HfConditionsSnapshot>((ref) async {
  final repo = ref.watch(hfConditionsRepositoryProvider);
  return repo.getHfConditions();
});

class HfConditionsRepository {
  HfConditionsRepository(this._dio);

  static const _endpoint = 'https://www.hamqsl.com/solarxml.php';
  static const _cacheTtl = Duration(minutes: 10);
  static const _cacheXmlKey = 'hf_conditions_cache_xml';
  static const _cacheUpdatedAtKey = 'hf_conditions_cache_updated_at';
  static SharedPreferences? _prefs;

  final Dio _dio;
  DateTime? _lastSuccessfulFetchAt;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<HfConditionsSnapshot> getHfConditions({
    bool forceRefresh = false,
  }) async {
    final cachedXmlPayload = await _getCachedXmlPayload();
    final cachedSnapshot = _tryParseSnapshot(cachedXmlPayload);
    _lastSuccessfulFetchAt ??= await _getLastCacheTimestamp();

    final hasFreshCache =
        !forceRefresh &&
        cachedSnapshot != null &&
        _lastSuccessfulFetchAt != null &&
        DateTime.now().difference(_lastSuccessfulFetchAt!) < _cacheTtl;

    if (hasFreshCache) {
      return cachedSnapshot;
    }

    try {
      final response = await _dio.get<String>(
        _endpoint,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 12),
          headers: {'Accept': 'application/xml,text/xml;q=0.9,*/*;q=0.8'},
        ),
      );

      final payload = response.data?.trim();
      final freshSnapshot = _tryParseSnapshot(payload);

      if (response.statusCode == 200 && freshSnapshot != null) {
        await _saveCache(payload!);
        _lastSuccessfulFetchAt = DateTime.now();
        return freshSnapshot;
      }

      if (cachedSnapshot != null) {
        return cachedSnapshot;
      }

      throw Exception('HF conditions payload is empty.');
    } on DioException catch (error) {
      if (cachedSnapshot != null) {
        return cachedSnapshot;
      }
      throw Exception('HF conditions could not be fetched: ${error.message}');
    } catch (error) {
      if (cachedSnapshot != null) {
        return cachedSnapshot;
      }
      throw Exception('HF conditions could not be parsed: $error');
    }
  }

  HfConditionsSnapshot? _tryParseSnapshot(String? xmlPayload) {
    final payload = xmlPayload?.trim();
    if (payload == null || payload.isEmpty) {
      return null;
    }

    try {
      return HfConditionsSnapshot.fromXml(payload);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getCachedXmlPayload() async {
    final preferences = await _preferences;
    final payload = preferences.getString(_cacheXmlKey);
    if (payload == null || payload.isEmpty) {
      return null;
    }
    return payload;
  }

  Future<void> _saveCache(String xmlPayload) async {
    final preferences = await _preferences;
    await preferences.setString(_cacheXmlKey, xmlPayload);
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
}
