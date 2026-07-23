// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

import "package:dynamic_of_things/model/dynamic_form_list_response.dart" show FilterItem;

class Template {
  List<Action> actions = [];
  Map<String, String> forms = {};
  List<FilterItem> filters = [];

  Template();

  factory Template.fromJson(Map<String, dynamic> json) => Template()
    ..actions = json["actions"] != null ? List<Action>.from(json["actions"].map((e) => Action.fromJson(e))) : []
    ..forms = Map<String, String>.from(json["forms"])
    ..filters = json["filters"] != null ? List<FilterItem>.from(json["filters"].map((e) => FilterItem.fromJson(e))) : [];
}

class Action {
  late String id;
  late String resourceId;
  late String name;

  // See dynamic_form_list_response.dart's Action.filterOverrideId - same
  // meaning, same server-side parser (CustomFunctionScriptParser).
  String? filterOverrideId;
  String? filterOverrideOperator;

  Action();

  factory Action.fromJson(Map<String, dynamic> json) => Action()
    ..id = json["id"] ?? ""
    ..resourceId = json["resourceId"] ?? ""
    ..name = json["name"] ?? ""
    ..filterOverrideId = json["filterOverrideId"]
    ..filterOverrideOperator = json["filterOverrideOperator"];
}