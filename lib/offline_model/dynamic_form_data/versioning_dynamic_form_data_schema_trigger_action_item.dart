// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

import "package:dynamic_of_things/offline_model/dynamic_form_data/versioning_dynamic_form_data_schema_trigger_action_condition_item.dart";
import "package:dynamic_of_things/offline_model/dynamic_form_data/versioning_dynamic_form_data_schema_trigger_action_detail_item.dart";

class VersioningDynamicFormDataSchemaTriggerActionItem {
  final int sequence;
  final String name;
  final String function;
  final String table;
  final List<VersioningDynamicFormDataSchemaTriggerActionDetailItem> details;
  final List<VersioningDynamicFormDataSchemaTriggerActionConditionItem> conditions;

  VersioningDynamicFormDataSchemaTriggerActionItem({
    required this.sequence,
    required this.name,
    required this.function,
    required this.table,
    required this.details,
    required this.conditions,
  });

  factory VersioningDynamicFormDataSchemaTriggerActionItem.fromJson(Map<String, dynamic> json) => VersioningDynamicFormDataSchemaTriggerActionItem(
    sequence: json["sequence"] ?? 0,
    name: json["name"] ?? "",
    function: json["function"] ?? "",
    table: json["table"] ?? "",
    details: json["details"] != null ? List<VersioningDynamicFormDataSchemaTriggerActionDetailItem>.from(json["details"].map((e) => VersioningDynamicFormDataSchemaTriggerActionDetailItem.fromJson(e))) : [],
    conditions: json["conditions"] != null ? List<VersioningDynamicFormDataSchemaTriggerActionConditionItem>.from(json["conditions"].map((e) => VersioningDynamicFormDataSchemaTriggerActionConditionItem.fromJson(e))) : [],
  );

  Map<String, dynamic> toJson() => {
    "sequence": sequence,
    "name": name,
    "function": function,
    "table": table,
    "details": List<dynamic>.from(details.map((x) => x.toJson())),
    "conditions": List<dynamic>.from(conditions.map((x) => x.toJson())),
  };
}
