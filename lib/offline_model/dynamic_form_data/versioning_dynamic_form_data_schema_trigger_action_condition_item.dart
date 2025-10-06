// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

class VersioningDynamicFormDataSchemaTriggerActionConditionItem {
  final bool manualKey;
  final String key;
  final String operation;
  final bool manualValue;
  final bool variable;
  final String variableName;
  final String value;
  final String operand;

  VersioningDynamicFormDataSchemaTriggerActionConditionItem({
    required this.manualKey,
    required this.key,
    required this.operation,
    required this.manualValue,
    required this.variable,
    required this.variableName,
    required this.value,
    required this.operand,
  });

  factory VersioningDynamicFormDataSchemaTriggerActionConditionItem.fromJson(Map<String, dynamic> json) => VersioningDynamicFormDataSchemaTriggerActionConditionItem(
    manualKey: json["manualKey"] ?? false,
    key: json["key"] ?? "",
    operation: json["operation"] ?? "",
    manualValue: json["manualValue"] ?? false,
    variable: json["variable"] ?? false,
    variableName: json["variableName"] ?? "",
    value: json["value"] ?? "",
    operand: json["operand"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "manualKey": manualKey,
    "key": key,
    "operation": operation,
    "manualValue": manualValue,
    "variable": variable,
    "variableName": variableName,
    "value": value,
    "operand": operand,
  };
}
