import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, Response;
import 'package:batasph_mobile/config/config.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/services/auth_service.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio client;

  static const _startedAtKey = 'batasph.startedAt';

  static Duration? _elapsed(RequestOptions options) {
    final started = options.extra[_startedAtKey];
    return started is DateTime ? DateTime.now().difference(started) : null;
  }

  /// Binary and streamed payloads are summarised rather than dumped: an MP3
  /// from /tts/synthesize pretty-printed as a JSON int array would fill a log
  /// file on its own, and an SSE body is not readable until it is consumed.
  static Object? _loggableRequestBody(RequestOptions options) {
    final data = options.data;
    if (data is FormData) {
      final fields = data.fields.map((f) => '${f.key}=${f.value}').join(', ');
      final files = data.files
          .map((f) => '${f.key}=${f.value.filename} (${f.value.length} bytes)')
          .join(', ');
      return '<multipart fields: $fields | files: $files>';
    }
    return data;
  }

  static Object? _loggableResponseBody(Response response) {
    switch (response.requestOptions.responseType) {
      case ResponseType.stream:
        return '<stream>';
      case ResponseType.bytes:
        final data = response.data;
        return data is List<int> ? '<${data.length} bytes>' : data;
      case ResponseType.json:
      case ResponseType.plain:
        return response.data;
    }
  }

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
          options.extra[_startedAtKey] = DateTime.now();
          BatasphLogger.apiRequest(
            options.method,
            '${options.baseUrl}${options.path}',
            body: _loggableRequestBody(options),
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          BatasphLogger.apiResponse(
            response.requestOptions.method,
            '${response.requestOptions.baseUrl}${response.requestOptions.path}',
            statusCode: response.statusCode ?? 0,
            body: _loggableResponseBody(response),
            elapsed: _elapsed(response.requestOptions),
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
            elapsed: _elapsed(error.requestOptions),
          );
          handler.next(error);
        },
      ),
    );
  }
}
