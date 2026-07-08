// ignore_for_file: always_specify_types

import "package:dynamic_of_things/helper/formats.dart";

class DataRequest {
  final int size;
  final int index;
  final String? sortField;
  final String? sortDirection;
  final Map<String, Object> filters;

  DataRequest({
    required this.size,
    required this.index,
    required this.sortField,
    required this.sortDirection,
    required this.filters,
  });

  Map<String, dynamic> toJson() => {
    "size": size,
    "index": index,
    "sortField": sortField,
    "sortDirection": sortDirection,
    "filters": filters,
  };
}

class DataResponse {
  final int size;
  final List<Map<String, dynamic>> rows;

  DataResponse({
    required this.size,
    required this.rows,
  });

  factory DataResponse.fromJson(Map<String, dynamic> json) => DataResponse(
    size: Formats.tryParseNumber(json["size"]).toInt(),
    rows: json["rows"] != null ? List<Map<String, dynamic>>.from(json["rows"].map((e) => e)) : [],
  );
}
