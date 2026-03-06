import 'package:dio/dio.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
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

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Log request or add tokens if needed later
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log or manipulate response
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Centralized error handling
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
