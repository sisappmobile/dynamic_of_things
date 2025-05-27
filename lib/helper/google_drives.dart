// ignore_for_file: always_specify_types, use_build_context_synchronously, always_put_required_named_parameters_first, cascade_invocations

import "package:googleapis/drive/v3.dart" as drive;
import "package:googleapis_auth/auth_io.dart";
import "package:http/http.dart" as http;
import "package:http/io_client.dart";

class GoogleHttpClient extends IOClient {
  final Map<String, String> _headers;

  GoogleHttpClient(this._headers) : super();

  @override
  Future<IOStreamedResponse> send(http.BaseRequest request) {
    return super.send(request..headers.addAll(_headers));
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) {
    return super.head(url, headers: (headers ?? {})..addAll(_headers));
  }
}

class GoogleDrives {
  static GoogleDrives? _instance;

  GoogleDrives._internal();

  static Future<GoogleDrives> getInstance() async {
    _instance ??= GoogleDrives._internal();

    return _instance!;
  }

  late Map<String, dynamic> credentialJson;

  void init(Map<String, dynamic> credentialJson) async {
    this.credentialJson = credentialJson;
  }

  Future<String?> upload({
    required List<int> bytes,
  }) async {
    if (bytes.isNotEmpty) {
      ServiceAccountCredentials serviceAccountCredentials = ServiceAccountCredentials.fromJson(credentialJson);

      List<String> scopes = [
        drive.DriveApi.driveFileScope,
        drive.DriveApi.driveScope,
        drive.DriveApi.driveAppdataScope,
      ];

      http.Client client = http.Client();

      AccessCredentials accessCredentials = await obtainAccessCredentialsViaServiceAccount(serviceAccountCredentials, scopes, client);

      client.close();

      GoogleHttpClient googleHttpClient = GoogleHttpClient({
        "Authorization" : "${accessCredentials.accessToken.type} ${accessCredentials.accessToken.data}",
      });

      drive.DriveApi driveApi = drive.DriveApi(googleHttpClient);

      drive.File file = drive.File();

      file.name = DateTime.now().millisecondsSinceEpoch.toString();
      file.parents = ["1--2oT24oRgP1jDSD2k2VIwzN8nQTL6mm"];

      file = await driveApi.files.create(
        file,
        uploadMedia: drive.Media(Stream.value(bytes), bytes.length),
      );

      return file.id!;
    } else {
      return null;
    }
  }

  Future<List<int>> download({
    required String id,
  }) async {
    ServiceAccountCredentials serviceAccountCredentials = ServiceAccountCredentials.fromJson(credentialJson);

    List<String> scopes = [
      drive.DriveApi.driveFileScope,
      drive.DriveApi.driveScope,
      drive.DriveApi.driveAppdataScope,
    ];

    http.Client client = http.Client();

    AccessCredentials accessCredentials = await obtainAccessCredentialsViaServiceAccount(serviceAccountCredentials, scopes, client);

    client.close();

    GoogleHttpClient googleHttpClient = GoogleHttpClient({
      "Authorization" : "${accessCredentials.accessToken.type} ${accessCredentials.accessToken.data}",
    });

    drive.DriveApi driveApi = drive.DriveApi(googleHttpClient);

    drive.Media media = await driveApi.files.get(id, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

    List<int> results = [];

    await for (List<int> result in media.stream) {
      results.insertAll(results.length, result);
    }

    return results;
  }
}
