// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

class VersioningDynamicFormDataSchemaTriggerVariableItem {
  final String name;
  final String table;
  final String key;
  final String operation;
  final String value;

  VersioningDynamicFormDataSchemaTriggerVariableItem({
    required this.name,
    required this.table,
    required this.key,
    required this.operation,
    required this.value,
  });

  factory VersioningDynamicFormDataSchemaTriggerVariableItem.fromJson(Map<String, dynamic> json) => VersioningDynamicFormDataSchemaTriggerVariableItem(
    name: json["name"] ?? "",
    table: json["table"] ?? "",
    key: json["key"] ?? "",
    operation: json["operation"] ?? "",
    value: json["value"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "table": table,
    "key": key,
    "operation": operation,
    "value": value,
  };
}
