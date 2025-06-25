// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

import "package:dynamic_of_things/helper/formats.dart";
import "package:jiffy/jiffy.dart";

class ScheduleResponse {
  final List<Action> actions;
  final List<Item> items;

  ScheduleResponse({
    required this.actions,
    required this.items,
  });

  factory ScheduleResponse.fromJson(Map<String, dynamic> json) => ScheduleResponse(
    actions: json["actions"] != null ? List<Action>.from(json["actions"].map((e) => Action.fromJson(e))) : [],
    items: json["items"] != null ? List<Item>.from(json["items"].map((e) => Item.fromJson(e))) : [],
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

class Item {
  final String id;
  final String title;
  final String description;
  final Jiffy begin;
  final Jiffy until;

  Item({
    required this.id,
    required this.title,
    required this.description,
    required this.begin,
    required this.until,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    id: json["id"] ?? "",
    title: json["title"] ?? "",
    description: json["description"] ?? "",
    begin: Formats.tryParseJiffy(json["begin"])!,
    until: Formats.tryParseJiffy(json["until"])!,
  );
}
