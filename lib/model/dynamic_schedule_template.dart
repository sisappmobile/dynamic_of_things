// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

class Template {
  List<Action> actions = [];
  Map<String, String> forms = {};

  Template();

  factory Template.fromJson(Map<String, dynamic> json) => Template()
    ..actions = json["actions"] != null ? List<Action>.from(json["actions"].map((e) => Action.fromJson(e))) : []
    ..forms = Map<String, String>.from(json["forms"]);
}

class Action {
  late String id;
  late String resourceId;
  late String name;

  Action();

  factory Action.fromJson(Map<String, dynamic> json) => Action()
    ..id = json["id"] ?? ""
    ..resourceId = json["resourceId"] ?? ""
    ..name = json["name"] ?? "";
}