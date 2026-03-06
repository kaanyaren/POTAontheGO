import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activation_model.dart';
import '../../../../core/network/dio_client.dart';

final activationRepositoryProvider = Provider<ActivationRepository>((ref) {
  return ActivationRepository(DioClient().dio);
});

final parkActivationsProvider = FutureProvider.family<List<ActivationModel>, String>((ref, reference) async {
  final repo = ref.watch(activationRepositoryProvider);
  return repo.getParkActivations(reference);
});

class ActivationRepository {
  final Dio _dio;

  ActivationRepository(this._dio);

  Future<List<ActivationModel>> getParkActivations(String reference, {int count = 10}) async {
    try {
      final response = await _dio.get('park/activations/\$reference', queryParameters: {
        'count': count,
      });
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> jsonList = response.data;
        return jsonList.map((json) => ActivationModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch park activations: \$e');
    }
  }
}
