// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

class VersioningDynamicFormDataSchemaColumnItem {
  final String name;
  final String description;
  final String type;
  bool primaryKey;

  VersioningDynamicFormDataSchemaColumnItem({
    required this.name,
    required this.description,
    required this.type,
    required this.primaryKey,
  });

  factory VersioningDynamicFormDataSchemaColumnItem.fromJson(Map<String, dynamic> json) => VersioningDynamicFormDataSchemaColumnItem(
    name: json["name"] ?? "",
    description: json["description"] ?? "",
    type: json["type"] ?? "",
    primaryKey: json["primaryKey"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "description": description,
    "type": type,
    "primaryKey": primaryKey,
  };
}
