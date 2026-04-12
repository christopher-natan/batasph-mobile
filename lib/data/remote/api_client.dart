import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/config/config.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/services/auth_service.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio client;

  ApiClient._() {
    client = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        headers: {
          'Content-Type': 'application/json',
          if (AppConfig.apiKey.isNotEmpty) 'x-api-key': AppConfig.apiKey,
        },
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = AuthService.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers['x-guest-session-id'] =
                MySharedPref.getGuestSessionId();
          }
          BatasphLogger.apiRequest(
            options.method,
            '${options.baseUrl}${options.path}',
            body: options.data,
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          BatasphLogger.apiResponse(
            response.requestOptions.method,
            '${response.requestOptions.baseUrl}${response.requestOptions.path}',
            statusCode: response.statusCode ?? 0,
            body: response.data,
          );
          handler.next(response);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              Get.isRegistered<AuthService>()) {
            await Get.find<AuthService>().handleUnauthorized();
          }
          BatasphLogger.apiError(
            error.requestOptions.method,
            '${error.requestOptions.baseUrl}${error.requestOptions.path}',
            error:
                '${error.message} [${error.response?.statusCode}] ${error.response?.data}',
          );
          handler.next(error);
        },
      ),
    );
  }
}
