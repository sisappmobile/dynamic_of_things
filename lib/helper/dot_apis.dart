import "dart:io";

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dio/dio.dart";
import "package:dio/io.dart";
import "package:dynamic_of_things/helper/formats.dart";
import "package:dynamic_of_things/model/dynamic_form_list_response.dart";
import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";
import "package:dynamic_of_things/model/dynamic_form_resource_response.dart";
import "package:dynamic_of_things/model/dynamic_report_data.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:jiffy/jiffy.dart";

class DotApis {
  static DotApis? _instance;

  DotApis._internal();

  static DotApis getInstance() {
    _instance ??= DotApis._internal();

    return _instance!;
  }

  late Dio dio;

  void init(String baseUrl, Interceptor interceptor) async {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        contentType: Headers.jsonContentType,
      ),
    );

    dio.interceptors.add(interceptor);

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        request: true,
        requestHeader: true,
        responseHeader: true,
      ),
    );

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      HttpClient httpClient = HttpClient()..badCertificateCallback = (cert, host, port) => true;

      return httpClient;
    };
  }

  Future<DynamicFormMenuResponse?> dynamicFormMenu({String? customerId}) async {
    Map<String, String> headers = {};

    if (StringUtils.isNotNullOrEmpty(customerId)) {
      headers["sfa-customer-id"] = customerId!;
    }

    Response response = await dio.get(
      "v2/dynamic-forms/menus",
      options: Options(
        headers: headers,
      ),
    );

    if (response.statusCode == 200) {
      return DynamicFormMenuResponse.fromJson(response.data);
    }

    return null;
  }

  Future<ListResponse?> dynamicFormList({
    required String id,
    String? customerId,
  }) async {
    Map<String, String> headers = {};

    if (StringUtils.isNotNullOrEmpty(customerId)) {
      headers["sfa-customer-id"] = customerId!;
    }

    Response response = await dio.get(
      "v2/dynamic-forms/list",
      options: Options(
        headers: headers,
      ),
      queryParameters: {
        "id": id,
      },
    );

    if (response.statusCode == 200) {
      return ListResponse.fromJson(response.data);
    }

    return null;
  }

  Future<Response> dynamicFormCustomAction({
    required String actionId,
    required String formId,
    required String dataId,
    String? customerId,
  }) async {
    Map<String, String> headers = {};

    if (StringUtils.isNotNullOrEmpty(customerId)) {
      headers["sfa-customer-id"] = customerId!;
    }

    return await dio.get(
      "v2/dynamic-forms/custom-actions/$formId",
      options: Options(
        headers: headers,
      ),
      queryParameters: {
        "actionId": actionId,
        "dataId": dataId,
      },
    );
  }

  Future<HeaderForm?> dynamicFormCreate({
    required String formId,
    String? customerId,
  }) async {
    Map<String, String> headers = {};

    if (StringUtils.isNotNullOrEmpty(customerId)) {
      headers["sfa-customer-id"] = customerId!;
    }

    Response response = await dio.get(
      "v2/dynamic-forms/templates/$formId/create",
      options: Options(
        headers: headers,
      ),
    );

    if (response.statusCode == 200) {
      return HeaderForm.fromJson(response.data);
    }

    return null;
  }

  Future<HeaderForm?> dynamicFormView({
    required String formId,
    required String dataId,
    String? customerId,
  }) async {
    Map<String, String> headers = {};

    if (StringUtils.isNotNullOrEmpty(customerId)) {
      headers["sfa-customer-id"] = customerId!;
    }

    Response response = await dio.get(
      "v2/dynamic-forms/templates/$formId/view",
      options: Options(
        headers: headers,
      ),
      queryParameters: {
        "dataId": dataId,
      },
    );

    if (response.statusCode == 200) {
      return HeaderForm.fromJson(response.data);
    }

    return null;
  }

  Future<HeaderForm?> dynamicFormEdit({
    required String formId,
    required String dataId,
    String? customerId,
  }) async {
    Map<String, String> headers = {};

    if (StringUtils.isNotNullOrEmpty(customerId)) {
      headers["sfa-customer-id"] = customerId!;
    }

    Response response = await dio.get(
      "v2/dynamic-forms/templates/$formId/edit",
      options: Options(
        headers: headers,
      ),
      queryParameters: {
        "dataId": dataId,
      },
    );

    if (response.statusCode == 200) {
      return HeaderForm.fromJson(response.data);
    }

    return null;
  }

  Future<void> dynamicFormInsert({
    required String formId,
    required Map<String, dynamic> data,
    String? customerId,
  }) async {
    Map<String, String> headers = {};

    if (StringUtils.isNotNullOrEmpty(customerId)) {
      headers["sfa-customer-id"] = customerId!;
    }

    await dio.post(
      "v2/dynamic-forms/actions/$formId",
      options: Options(
        headers: headers,
      ),
      data: data,
    );
  }

  Future<void> dynamicFormUpdate({
    required String dataId,
    required String formId,
    required Map<String, dynamic> data,
    String? customerId,
  }) async {
    Map<String, String> headers = {};

    if (StringUtils.isNotNullOrEmpty(customerId)) {
      headers["sfa-customer-id"] = customerId!;
    }

    await dio.put(
      "v2/dynamic-forms/actions/$formId",
      options: Options(
        headers: headers,
      ),
      data: data,
      queryParameters: {
        "dataId": dataId,
      },
    );
  }

  Future<DynamicFormResourceResponse?> dynamicFormResource({
    required String formId,
    required String name,
    required Map<String, dynamic> data,
    String? customerId,
  }) async {
    Map<String, String> headers = {};

    if (StringUtils.isNotNullOrEmpty(customerId)) {
      headers["sfa-customer-id"] = customerId!;
    }

    Response response = await dio.post(
      "v2/dynamic-forms/resources/$formId",
      options: Options(
        headers: headers,
      ),
      queryParameters: {
        "name": name,
      },
      data: Formats.convert(Map<String, dynamic>.from(data)),
    );

    if (response.statusCode == 200) {
      return DynamicFormResourceResponse.fromJson(response.data);
    }

    return null;
  }

  Future<HeaderForm?> dynamicFormRefresh({
    required String formId,
    required Map<String, dynamic> data,
    String? customerId,
  }) async {
    Map<String, String> headers = {};

    if (StringUtils.isNotNullOrEmpty(customerId)) {
      headers["sfa-customer-id"] = customerId!;
    }

    Response response = await dio.post(
      "v2/dynamic-forms/templates/$formId/refresh",
      options: Options(
        headers: headers,
      ),
      data: Formats.convert(Map<String, dynamic>.from(data)),
    );

    if (response.statusCode == 200) {
      return HeaderForm.fromJson(response.data);
    }

    return null;
  }

  Future<Map<String, dynamic>?> dynamicFormSelect({
    required String formId,
    required String name,
    required dynamic value,
    String? customerId,
  }) async {
    Map<String, String> headers = {};

    if (StringUtils.isNotNullOrEmpty(customerId)) {
      headers["sfa-customer-id"] = customerId!;
    }

    Response response = await dio.post(
      "v2/dynamic-forms/templates/$formId/select",
      options: Options(
        headers: headers,
      ),
      queryParameters: {
        "name": name,
        "value": value,
      },
    );

    if (response.statusCode == 200) {
      return response.data;
    }

    return null;
  }

  Future<Response> dynamicFormFile({required String url}) async {
    Dio dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      HttpClient httpClient = HttpClient()..badCertificateCallback = (cert, host, port) => true;

      return httpClient;
    };

    return await dio.get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
  }

  Future<Response> dynamicReportTemplate({
    required String id,
  }) async {
    return await dio.get(
      "v2/dynamic-reports/$id/template",
    );
  }

  Future<Response> dynamicReportData({
    required String id,
    required DataRequest dataRequest,
  }) async {
    return await dio.post(
      "v2/dynamic-reports/$id",
      data: Formats.convert(dataRequest.toJson()),
    );
  }

  Future<Response> dynamicReportExport({
    required String id,
    required DataRequest dataRequest,
  }) async {
    return await dio.post(
      "v2/dynamic-reports/$id/export",
      options: Options(responseType: ResponseType.bytes),
      data: Formats.convert(dataRequest.toJson()),
    );
  }

  Future<Response> dynamicChartList() async {
    return await dio.get("v2/dynamic-charts");
  }

  Future<Response> dynamicChartDetail({
    required String id,
    required Jiffy begin,
    required Jiffy until,
  }) async {
    return await dio.get(
      "v2/dynamic-charts/$id",
      queryParameters: {
        "begin": begin.dateFormat(),
        "until": until.dateFormat(),
      },
    );
  }
}