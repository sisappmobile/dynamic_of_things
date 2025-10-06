// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

import "package:dynamic_of_things/offline_model/dynamic_form_data/versioning_dynamic_form_data_schema_item.dart";

class VersioningDynamicFormDataResponse {
  final VersioningDynamicFormDataSchemaItem schema;
  final List<Map<String, dynamic>> data;

  VersioningDynamicFormDataResponse({
    required this.schema,
    required this.data,
  });

  factory VersioningDynamicFormDataResponse.fromJson(Map<String, dynamic> json) => VersioningDynamicFormDataResponse(
    schema: VersioningDynamicFormDataSchemaItem.fromJson(json["schema"]),
    data: json["data"] != null ? List<Map<String, dynamic>>.from(json["data"].map((e) => e)) : [],
  );
}
