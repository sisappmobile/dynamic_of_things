// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

import "package:dynamic_of_things/helper/formats.dart";
import "package:flutter/material.dart";

class Template {
  late String id;
  late String title;
  late bool pivotable;
  List<Field> fields = [];
  List<Filter> filters = [];

  Template();

  factory Template.fromJson(Map<String, dynamic> json) => Template()
    ..id = json["id"] ?? ""
    ..title = json["title"] ?? ""
    ..pivotable = Formats.tryParseBool(json["pivotable"])
    ..fields = json["fields"] != null ? List<Field>.from(json["fields"].map((e) => Field.fromJson(e))) : []
    ..filters = json["filters"] != null ? List<Filter>.from(json["filters"].map((e) => Filter.fromJson(e))) : [];
}

class Field {
  late String id;
  late String name;
  late String caption;
  late String type;
  late String formatting;
  late bool summarize;

  Field();

  factory Field.fromJson(Map<String, dynamic> json) => Field()
    ..id = json["id"] ?? ""
    ..name = json["name"] ?? ""
    ..caption = json["caption"] ?? ""
    ..type = json["type"] ?? ""
    ..formatting = json["formatting"] ?? ""
    ..summarize = Formats.tryParseBool(json["summarize"]);
}

class Filter {
  late String id;
  late String name;
  late String caption;
  late String type;
  late String operator;
  late String defaultValue;

  dynamic value;
  TextEditingController? controller;

  Filter();

  factory Filter.fromJson(Map<String, dynamic> json) => Filter()
    ..id = json["id"] ?? ""
    ..name = json["name"] ?? ""
    ..caption = json["caption"] ?? ""
    ..type = json["type"] ?? ""
    ..operator = json["operator"] ?? ""
    ..defaultValue = json["defaultValue"] ?? "";
}