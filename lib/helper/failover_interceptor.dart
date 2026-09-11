import "package:dio/dio.dart";

/// Retries a request against [alternativeBaseUrlProvider] when it fails to
/// reach [dio]'s current base URL because the server is unreachable
/// (connection/timeout errors, not application-level HTTP error responses).
///
/// On a successful retry, [dio]'s base URL is switched to the alternative
/// for subsequent requests and [onFailover] is invoked so the caller can
/// persist the switch (e.g. to shared preferences).
class FailoverInterceptor extends Interceptor {
  FailoverInterceptor({
    required this.dio,
    required this.alternativeBaseUrlProvider,
    this.onFailover,
  });

  final Dio dio;
  final String? Function() alternativeBaseUrlProvider;
  final void Function(String newBaseUrl)? onFailover;

  static const String _attemptedKey = "__dotFailoverAttempted";

  bool _isServerUnreachable(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        return false;
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final String? alternativeBaseUrl = alternativeBaseUrlProvider();
    final String currentBaseUrl = err.requestOptions.baseUrl.isNotEmpty
        ? err.requestOptions.baseUrl
        : dio.options.baseUrl;

    if (alternativeBaseUrl == null ||
        alternativeBaseUrl.isEmpty ||
        alternativeBaseUrl == currentBaseUrl ||
        !_isServerUnreachable(err) ||
        err.requestOptions.extra[_attemptedKey] == true) {
      return handler.next(err);
    }

    try {
      final RequestOptions retryOptions = err.requestOptions;
      retryOptions.extra[_attemptedKey] = true;
      retryOptions.baseUrl = alternativeBaseUrl;

      final Response<dynamic> response = await dio.fetch(retryOptions);

      dio.options.baseUrl = alternativeBaseUrl;
      onFailover?.call(alternativeBaseUrl);

      return handler.resolve(response);
    } catch (_) {
      return handler.next(err);
    }
  }
}
