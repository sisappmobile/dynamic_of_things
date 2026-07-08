import "dart:io";

import "package:dio/dio.dart";
import "package:dio/io.dart";

void configureNativeBadCertificateBypass(Dio dio) {
  final HttpClientAdapter adapter = dio.httpClientAdapter;

  if (adapter is! IOHttpClientAdapter) {
    return;
  }

  adapter.createHttpClient = () {
    return HttpClient()..badCertificateCallback = (cert, host, port) => true;
  };
}
