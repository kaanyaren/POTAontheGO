import 'package:dio/dio.dart';

class DioClient {
  // Singleton instance
  static DioClient? _instance;
  late final Dio _dio;

  // Private constructor
  DioClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.pota.app/',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptors removed: empty pass-through interceptors add overhead.
  }

  // Factory constructor for singleton
  factory DioClient() {
    _instance ??= DioClient._();
    return _instance!;
  }

  Dio get dio => _dio;
}
