// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

class Template {
  final List<Action> actions;
  final Map<String, String> forms;

  Template({
    required this.actions,
    required this.forms,
  });

  factory Template.fromJson(Map<String, dynamic> json) => Template(
    actions: json["actions"] != null ? List<Action>.from(json["actions"].map((e) => Action.fromJson(e))) : [],
    forms: Map<String, String>.from(json["forms"]),
  );
}

class Action {
  final String id;
  final String resourceId;
  final String name;

  Action({
    required this.id,
    required this.resourceId,
    required this.name,
  });

  factory Action.fromJson(Map<String, dynamic> json) => Action(
    id: json["id"] ?? "",
    resourceId: json["resourceId"] ?? "",
    name: json["name"] ?? "",
  );
}
