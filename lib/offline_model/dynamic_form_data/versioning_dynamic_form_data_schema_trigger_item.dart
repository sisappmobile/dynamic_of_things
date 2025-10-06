// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

import "package:dynamic_of_things/offline_model/dynamic_form_data/versioning_dynamic_form_data_schema_trigger_action_item.dart";
import "package:dynamic_of_things/offline_model/dynamic_form_data/versioning_dynamic_form_data_schema_trigger_variable_item.dart";

class VersioningDynamicFormDataSchemaTriggerItem {
  final String name;
  final String state;
  final String operation;
  final List<VersioningDynamicFormDataSchemaTriggerVariableItem> variables;
  final List<VersioningDynamicFormDataSchemaTriggerActionItem> actions;

  VersioningDynamicFormDataSchemaTriggerItem({
    required this.name,
    required this.state,
    required this.operation,
    required this.variables,
    required this.actions,
  });

  factory VersioningDynamicFormDataSchemaTriggerItem.fromJson(Map<String, dynamic> json) => VersioningDynamicFormDataSchemaTriggerItem(
    name: json["name"] ?? "",
    state: json["state"] ?? "",
    operation: json["operation"] ?? "",
    variables: json["variables"] != null ? List<VersioningDynamicFormDataSchemaTriggerVariableItem>.from(json["variables"].map((e) => VersioningDynamicFormDataSchemaTriggerVariableItem.fromJson(e))) : [],
    actions: json["actions"] != null ? List<VersioningDynamicFormDataSchemaTriggerActionItem>.from(json["actions"].map((e) => VersioningDynamicFormDataSchemaTriggerActionItem.fromJson(e))) : [],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "state": state,
    "operation": operation,
    "variables": List<dynamic>.from(variables.map((x) => x.toJson())),
    "actions": List<dynamic>.from(actions.map((x) => x.toJson())),
  };
}
