// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

class VersioningDynamicFormDataSchemaTriggerActionDetailItem {
  final String key;
  final String operation;
  final bool manualValue;
  final bool variable;
  final String variableName;
  final String value;

  VersioningDynamicFormDataSchemaTriggerActionDetailItem({
    required this.key,
    required this.operation,
    required this.manualValue,
    required this.variable,
    required this.variableName,
    required this.value,
  });

  factory VersioningDynamicFormDataSchemaTriggerActionDetailItem.fromJson(Map<String, dynamic> json) => VersioningDynamicFormDataSchemaTriggerActionDetailItem(
    key: json["key"] ?? "",
    operation: json["operation"] ?? "",
    manualValue: json["manualValue"] ?? false,
    variable: json["variable"] ?? false,
    variableName: json["variableName"] ?? "",
    value: json["value"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "key": key,
    "operation": operation,
    "manualValue": manualValue,
    "variable": variable,
    "variableName": variableName,
    "value": value,
  };
}
