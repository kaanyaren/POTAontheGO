import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/callsign_profile_model.dart';

final callsignRepositoryProvider = Provider<CallsignRepository>((ref) {
  return CallsignRepository(DioClient().dio);
});

class CallsignRepository {
  CallsignRepository(this._dio);

  final Dio _dio;

  Future<CallsignProfileModel> getCallsignProfile(String rawCallsign) async {
    final callsign = rawCallsign.trim().toUpperCase();
    if (callsign.isEmpty) {
      throw Exception('Geçerli bir çağrı işareti girilmedi.');
    }

    final candidates = _buildCandidates(callsign);
    DioException? lastDioError;

    for (final candidate in candidates) {
      try {
        final response = await _dio.get(
          'stats/user/${Uri.encodeComponent(candidate)}',
          options: Options(receiveTimeout: const Duration(seconds: 8)),
        );

        final payload = response.data;
        if (response.statusCode == 200 && payload is Map<String, dynamic>) {
          return CallsignProfileModel.fromJson(payload);
        }
      } on DioException catch (error) {
        lastDioError = error;
        final statusCode = error.response?.statusCode;

        // Portable/suffix callsigns may not exist directly in stats/user.
        // In that case we try the next normalized candidate.
        if (statusCode == 403 || statusCode == 404) {
          continue;
        }

        throw Exception(
          'Çağrı işareti bilgisi alınamadı: ${error.message ?? 'Ağ hatası'}',
        );
      }
    }

    if (lastDioError?.response?.statusCode == 403 ||
        lastDioError?.response?.statusCode == 404) {
      throw Exception('Bu çağrı işareti için POTA profili bulunamadı.');
    }

    throw Exception('Çağrı işareti bilgisi alınamadı.');
  }

  List<String> _buildCandidates(String callsign) {
    final candidates = <String>{callsign};

    final slashIndex = callsign.indexOf('/');
    if (slashIndex > 0) {
      candidates.add(callsign.substring(0, slashIndex));
    }

    final dashIndex = callsign.indexOf('-');
    if (dashIndex > 0) {
      candidates.add(callsign.substring(0, dashIndex));
    }

    return candidates.toList(growable: false);
  }
}
