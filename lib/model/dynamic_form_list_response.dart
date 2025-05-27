// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

class ListResponse {
  final List<Action> actions;
  final List<Field> fields;
  final List<Map<String, dynamic>> data;

  String? name;

  ListResponse({
    this.name,
    required this.actions,
    required this.fields,
    required this.data,
  });

  factory ListResponse.fromJson(Map<String, dynamic> json) => ListResponse(
    actions: json["actions"] != null ? List<Action>.from(json["actions"].map((e) => Action.fromJson(e))) : [],
    fields: json["fields"] != null ? List<Field>.from(json["fields"].map((e) => Field.fromJson(e))) : [],
    data: json["data"] != null ? List<Map<String, dynamic>>.from(json["data"].map((e) => e)) : [],
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
