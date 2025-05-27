// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

import "package:dynamic_of_things/helper/formats.dart";

class DynamicFormMenuResponse {
  final List<DynamicFormCategoryItem> categories;

  DynamicFormMenuResponse({
    required this.categories,
  });

  factory DynamicFormMenuResponse.fromJson(Map<String, dynamic> json) => DynamicFormMenuResponse(
    categories: json["categories"] != null ? List<DynamicFormCategoryItem>.from(json["categories"].map((e) => DynamicFormCategoryItem.fromJson(e))) : [],
  );
}

class DynamicFormCategoryItem {
  final String id;
  final String name;
  final num index;
  final List<DynamicFormMenuItem> menus;

  DynamicFormCategoryItem({
    required this.id,
    required this.name,
    required this.index,
    required this.menus,
  });

  factory DynamicFormCategoryItem.fromJson(Map<String, dynamic> json) => DynamicFormCategoryItem(
    id: json["id"] ?? "",
    name: json["name"] ?? "",
    index: Formats.tryParseNumber(json["index"]),
    menus: json["menus"] != null ? List<DynamicFormMenuItem>.from(json["menus"].map((e) => DynamicFormMenuItem.fromJson(e))) : [],
  );
}

class DynamicFormMenuItem {
  final String id;
  final String name;
  final num index;
  final String type;

  DynamicFormMenuItem({
    required this.id,
    required this.name,
    required this.index,
    required this.type,
  });

  factory DynamicFormMenuItem.fromJson(Map<String, dynamic> json) => DynamicFormMenuItem(
    id: json["id"] ?? "",
    name: json["name"] ?? "",
    index: Formats.tryParseNumber(json["index"]),
    type: json["type"] ?? "",
  );
}
