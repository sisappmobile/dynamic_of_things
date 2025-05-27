// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

import "package:dynamic_of_things/helper/formats.dart";
import "package:flutter/material.dart";

class Template {
  final String id;
  final String title;
  final bool pivotable;
  final List<Field> fields;
  final List<Filter> filters;

  Template({
    required this.id,
    required this.title,
    required this.pivotable,
    required this.fields,
    required this.filters,
  });

  factory Template.fromJson(Map<String, dynamic> json) => Template(
    id: json["id"] ?? "",
    title: json["title"] ?? "",
    pivotable: Formats.tryParseBool(json["pivotable"]),
    fields: json["fields"] != null ? List<Field>.from(json["fields"].map((e) => Field.fromJson(e))) : [],
    filters: json["filters"] != null ? List<Filter>.from(json["filters"].map((e) => Filter.fromJson(e))) : [],
  );
}

class Field {
  final String id;
  final String name;
  final String caption;
  final String type;
  final String formatting;
  final bool summarize;

  Field({
    required this.id,
    required this.name,
    required this.caption,
    required this.type,
    required this.formatting,
    required this.summarize,
  });

  factory Field.fromJson(Map<String, dynamic> json) => Field(
    id: json["id"] ?? "",
    name: json["name"] ?? "",
    caption: json["caption"] ?? "",
    type: json["type"] ?? "",
    formatting: json["formatting"] ?? "",
    summarize: Formats.tryParseBool(json["summarize"]),
  );
}

class Filter {
  final String id;
  final String name;
  final String caption;
  final String type;
  final String operator;
  final String defaultValue;

  dynamic value;
  TextEditingController? controller;

  Filter({
    required this.id,
    required this.name,
    required this.caption,
    required this.type,
    required this.operator,
    required this.defaultValue,
  });

  factory Filter.fromJson(Map<String, dynamic> json) => Filter(
    id: json["id"] ?? "",
    name: json["name"] ?? "",
    caption: json["caption"] ?? "",
    type: json["type"] ?? "",
    operator: json["operator"] ?? "",
    defaultValue: json["defaultValue"] ?? "",
  );
}
