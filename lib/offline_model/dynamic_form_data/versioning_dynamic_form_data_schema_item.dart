// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

import "package:dynamic_of_things/offline_model/dynamic_form_data/versioning_dynamic_form_data_schema_column_item.dart";
import "package:dynamic_of_things/offline_model/dynamic_form_data/versioning_dynamic_form_data_schema_trigger_item.dart";

class VersioningDynamicFormDataSchemaItem {
  final String id;
  final String name;
  final List<VersioningDynamicFormDataSchemaColumnItem> columns;
  final List<VersioningDynamicFormDataSchemaTriggerItem> triggers;

  VersioningDynamicFormDataSchemaItem({
    required this.id,
    required this.name,
    required this.columns,
    required this.triggers,
  });

  factory VersioningDynamicFormDataSchemaItem.fromJson(Map<String, dynamic> json) => VersioningDynamicFormDataSchemaItem(
    id: json["id"] ?? "",
    name: json["name"] ?? "",
    columns: json["columns"] != null ? List<VersioningDynamicFormDataSchemaColumnItem>.from(json["columns"].map((e) => VersioningDynamicFormDataSchemaColumnItem.fromJson(e))) : [],
    triggers: json["triggers"] != null ? List<VersioningDynamicFormDataSchemaTriggerItem>.from(json["triggers"].map((e) => VersioningDynamicFormDataSchemaTriggerItem.fromJson(e))) : [],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "columns": List<dynamic>.from(columns.map((x) => x.toJson())),
    "triggers": List<dynamic>.from(triggers.map((x) => x.toJson())),
  };
}
