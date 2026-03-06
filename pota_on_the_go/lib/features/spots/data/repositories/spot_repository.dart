import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/spot_model.dart';
import '../../../../core/network/dio_client.dart';

final spotRepositoryProvider = Provider<SpotRepository>((ref) {
  return SpotRepository(DioClient().dio);
});

final currentSpotsProvider = FutureProvider.autoDispose<List<SpotModel>>((ref) async {
  final repo = ref.watch(spotRepositoryProvider);
  return repo.getRecentSpots();
});

class SpotRepository {
  final Dio _dio;

  SpotRepository(this._dio);

  Future<List<SpotModel>> getRecentSpots() async {
    try {
      final response = await _dio.get('spot/');
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> jsonList = response.data;
        return jsonList.map((json) => _fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch spots: \$e');
    }
  }

  SpotModel _fromJson(Map<String, dynamic> json) {
    return SpotModel()
      ..spotId = json['spotId'] ?? 0
      ..activator = json['activator'] ?? ''
      ..frequency = json['frequency']?.toString() ?? ''
      ..band = json['band'] ?? ''
      ..mode = json['mode'] ?? ''
      ..reference = json['reference'] ?? ''
      ..spotTime = DateTime.tryParse(json['spotTime'] ?? '') ?? DateTime.now();
  }
}
