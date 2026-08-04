// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

import "package:base/base.dart";
import "package:flutter/material.dart";
import "package:jiffy/jiffy.dart";

class ListResponse {
  final bool createUsingScanQr;
  final List<Action> actions;
  final List<Field> fields;
  final List<FilterItem> filters;
  final List<Map<String, dynamic>> data;

  String? name;

  ListResponse({
    this.name,
    required this.createUsingScanQr,
    required this.actions,
    required this.fields,
    required this.filters,
    required this.data,
  });

  factory ListResponse.fromJson(Map<String, dynamic> json) => ListResponse(
    createUsingScanQr: json["createUsingScanQr"] ?? false,
    actions: json["actions"] != null ? List<Action>.from(json["actions"].map((e) => Action.fromJson(e))) : [],
    fields: json["fields"] != null ? List<Field>.from(json["fields"].map((e) => Field.fromJson(e))) : [],
    filters: json["filters"] != null ? List<FilterItem>.from(json["filters"].map((e) => FilterItem.fromJson(e))) : [],
    data: json["data"] != null ? List<Map<String, dynamic>>.from(json["data"].map((e) => e)) : [],
  );
}

// Client-facing metadata for one c_custom_filter_field row, shared by the
// dynamic-forms list page and the dynamic-schedule page. `value`/`controller`
// are local UI-bound state (mirroring dynamic_report_template.dart's Filter
// class), not part of the server payload.
class FilterItem {
  final String id;
  final String caption;
  final String type;
  final String operator;
  final String? lovType;
  final String? defaultValue;

  dynamic value;
  TextEditingController? controller;

  // The DATE filter's input widget stores the picked date as a `Jiffy`
  // instance in `value` (so the picker can be reopened against it directly)
  // - but that's never valid to hand to jsonEncode() when building the
  // `filters`/`filterOperators` request map, which crashes with
  // "Converting object to an encodable object failed: Instance of 'Jiffy'".
  // Both the online (DynamicFormService.list()) and offline (Offlines.list())
  // filter-application code expect a plain ISO "yyyy-MM-dd" string for a
  // supplied DATE value, matching how dates are already stored everywhere
  // else in this app (DynamicForms.encodeValue et al) - so this is the one
  // place callers should read a filter's value from when sending it
  // anywhere, instead of the raw `value` field.
  dynamic get apiValue {
    if (type == "DATE" && value is Jiffy) {
      return (value as Jiffy).dateFormat();
    }

    return value;
  }

  FilterItem({
    required this.id,
    required this.caption,
    required this.type,
    required this.operator,
    required this.lovType,
    required this.defaultValue,
  });

  factory FilterItem.fromJson(Map<String, dynamic> json) => FilterItem(
    id: json["id"] ?? "",
    caption: json["caption"] ?? "",
    type: json["type"] ?? "",
    operator: json["operator"] ?? "",
    lovType: json["lovType"],
    defaultValue: json["defaultValue"],
  );
}

class Action {
  final String id;
  final String resourceId;
  final String name;
  final bool showOutside;

  // Set only for the narrow subset of custom functions whose script_before
  // just toggles a hidden filter's operator (e.g. "Expired Event"/"Ongoing
  // Event" on the EVENT form) - see CustomFunctionScriptParser server-side.
  // Non-null here means this action is a list-level filter toggle, not a
  // row-scoped action, and should be rendered as a toolbar button instead
  // of appearing in the per-row action menu.
  final String? filterOverrideId;
  final String? filterOverrideOperator;

  Action({
    required this.id,
    required this.resourceId,
    required this.name,
    this.showOutside = false,
    this.filterOverrideId,
    this.filterOverrideOperator,
  });

  factory Action.fromJson(Map<String, dynamic> json) => Action(
    id: json["id"] ?? "",
    resourceId: json["resourceId"] ?? "",
    name: json["name"] ?? "",
    showOutside: json["showOutside"] ?? false,
    filterOverrideId: json["filterOverrideId"],
    filterOverrideOperator: json["filterOverrideOperator"],
  );
}

class Field {
  final String name;
  final String type;
  final String description;
  final bool primaryKey;

  Field({
    required this.name,
    required this.type,
    required this.description,
    required this.primaryKey,
  });

  factory Field.fromJson(Map<String, dynamic> json) => Field(
    name: json["name"] ?? "",
    type: json["type"] ?? "",
    description: json["description"] ?? "",
    primaryKey: json["primaryKey"] ?? false,
  );
}
