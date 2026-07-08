// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

import "package:dynamic_of_things/helper/formats.dart";
import "package:jiffy/jiffy.dart";

class Item {
  final String id;
  final String title;
  final String description;
  final Jiffy begin;
  final Jiffy until;
  final String formId;
  final String formName;

  Item({
    required this.id,
    required this.title,
    required this.description,
    required this.begin,
    required this.until,
    required this.formId,
    required this.formName,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    id: json["id"] ?? "",
    title: json["title"] ?? "",
    description: json["description"] ?? "",
    begin: Formats.tryParseJiffy(json["begin"])!,
    until: Formats.tryParseJiffy(json["until"])!,
    formId: json["formId"] ?? "",
    formName: json["formName"] ?? "",
  );
}
