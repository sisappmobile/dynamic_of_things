import "package:dio/dio.dart";

import "package:dynamic_of_things/helper/dio_platform_adapter_stub.dart"
    if (dart.library.io) "package:dynamic_of_things/helper/dio_platform_adapter_io.dart"
    as dio_platform_adapter;

void configureBadCertificateBypass(Dio dio) {
  dio_platform_adapter.configureBadCertificateBypass(dio);
}
