// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/enumeration/dynamic_form_field_type.dart";
import "package:dynamic_of_things/helper/formats.dart";
import "package:flutter/material.dart";

class HeaderForm {
  final Template template;
  final List<DetailForm> detailForms;
  final Map<String, dynamic> data;
  final bool hasOnChangeEvent;

  String? dataId;

  HeaderForm({
    required this.template,
    required this.detailForms,
    required this.data,
    required this.hasOnChangeEvent,
  });

  factory HeaderForm.fromJson(Map<String, dynamic> json) => HeaderForm(
    template: Template.fromJson(json["template"]),
    detailForms: json["detailForms"] != null ? List<DetailForm>.from(json["detailForms"].map((e) => DetailForm.fromJson(e))) : [],
    data: json["data"],
    hasOnChangeEvent: json["hasOnChangeEvent"],
  );
}

class Template {
  final String id;
  final String tableName;
  final String title;
  final String description;
  final List<Action> actions;
  final List<Resource> resources;
  final List<Section> sections;

  Template({
    required this.id,
    required this.tableName,
    required this.title,
    required this.description,
    required this.actions,
    required this.resources,
    required this.sections,
  });

  factory Template.fromJson(Map<String, dynamic> json) => Template(
    id: json["id"] ?? "",
    tableName: json["tableName"] ?? "",
    title: json["title"] ?? "",
    description: json["description"] ?? "",
    actions: json["actions"] != null ? List<Action>.from(json["actions"].map((e) => Action.fromJson(e))) : [],
    resources: json["resources"] != null ? List<Resource>.from(json["resources"].map((e) => Resource.fromJson(e))) : [],
    sections: json["sections"] != null ? List<Section>.from(json["sections"].map((e) => Section.fromJson(e))) : [],
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

class DetailForm with ChangeNotifier {
  final List<ListColumn> columns;
  final Template template;
  final Map<String, dynamic> constructor;
  final List<Map<String, dynamic>> data;
  final bool hasOnChangeEvent;

  DetailForm({
    required this.columns,
    required this.template,
    required this.constructor,
    required this.data,
    required this.hasOnChangeEvent,
  });

  factory DetailForm.fromJson(Map<String, dynamic> json) => DetailForm(
    columns: json["columns"] != null ? List<ListColumn>.from(json["columns"].map((e) => ListColumn.fromJson(e))) : [],
    template: Template.fromJson(json["template"]),
    constructor: json["template"],
    data: List<Map<String, dynamic>>.from(json["data"].map((e) => e as Map<String, dynamic>)),
    hasOnChangeEvent: json["hasOnChangeEvent"],
  );

  void addRow(Map<String, dynamic> row) {
    data.add(row);

    notifyListeners();
  }

  void deleteRow(int index) {
    data.removeAt(index);

    notifyListeners();
  }

  void updateRow(Map<String, dynamic> row, int index) {
    data[index] = row;

    notifyListeners();
  }
}

class SubDetailForm with ChangeNotifier {
  final List<ListColumn> columns;
  final Template template;
  final Map<String, dynamic> constructor;
  final List<Map<String, dynamic>> data;

  SubDetailForm({
    required this.columns,
    required this.template,
    required this.constructor,
    required this.data,
  });

  factory SubDetailForm.fromJson(Map<String, dynamic> json) => SubDetailForm(
    columns: json["columns"] != null ? List<ListColumn>.from(json["columns"].map((e) => ListColumn.fromJson(e))) : [],
    template: Template.fromJson(json["template"]),
    constructor: json["template"],
    data: List<Map<String, dynamic>>.from(json["data"].map((e) => e as Map<String, dynamic>)),
  );

  void addRow(Map<String, dynamic> row) {
    data.add(row);

    notifyListeners();
  }

  void deleteRow(int index) {
    data.removeAt(index);

    notifyListeners();
  }

  void updateRow(Map<String, dynamic> row, int index) {
    data[index] = row;

    notifyListeners();
  }
}

class ListColumn {
  final String name;
  final String type;
  final String description;
  final bool primaryKey;

  ListColumn({
    required this.name,
    required this.type,
    required this.description,
    required this.primaryKey,
  });

  factory ListColumn.fromJson(Map<String, dynamic> json) => ListColumn(
    name: json["name"] ?? "",
    type: json["type"] ?? "",
    description: json["description"] ?? "",
    primaryKey: json["primaryKey"] ?? false,
  );
}

class Resource {
  final String name;
  final String table;
  final List<String> fields;
  final List<ManualFilter> manualFilters;
  final List<AutoFilter> autoFilters;
  final List<DetailSetup> detailSetups;
  final List<LoadOnField> loadOnFields;

  Resource({
    required this.name,
    required this.table,
    required this.fields,
    required this.manualFilters,
    required this.autoFilters,
    required this.detailSetups,
    required this.loadOnFields,
  });

  factory Resource.fromJson(Map<String, dynamic> json) => Resource(
    name: json["name"] ?? "",
    table: json["table"] ?? "",
    fields: json["fields"] != null ? List<String>.from(json["fields"].map((e) => e)) : [],
    manualFilters: json["manualFilters"] != null ? List<ManualFilter>.from(json["manualFilters"].map((e) => ManualFilter.fromJson(e))) : [],
    autoFilters: json["autoFilters"] != null ? List<AutoFilter>.from(json["autoFilters"].map((e) => AutoFilter.fromJson(e))) : [],
    detailSetups: json["detailSetups"] != null ? List<DetailSetup>.from(json["detailSetups"].map((e) => DetailSetup.fromJson(e))) : [],
    loadOnFields: json["loadOnFields"] != null ? List<LoadOnField>.from(json["loadOnFields"].map((e) => LoadOnField.fromJson(e))) : [],
  );
}

class ManualFilter {
  final String key;
  final String value;
  final String operator;
  final String operation;

  ManualFilter({
    required this.key,
    required this.value,
    required this.operator,
    required this.operation,
  });

  factory ManualFilter.fromJson(Map<String, dynamic> json) => ManualFilter(
    key: json["key"] ?? "",
    value: json["value"] ?? "",
    operator: json["operator"] ?? "",
    operation: json["operation"] ?? "",
  );
}

class AutoFilter {
  final String key;
  final String value;
  final String operator;
  final String operation;

  AutoFilter({
    required this.key,
    required this.value,
    required this.operator,
    required this.operation,
  });

  factory AutoFilter.fromJson(Map<String, dynamic> json) => AutoFilter(
    key: json["key"] ?? "",
    value: json["value"] ?? "",
    operator: json["operator"] ?? "",
    operation: json["operation"] ?? "",
  );
}

class DetailSetup {
  final String srcKey;
  final String dstKey;

  DetailSetup({
    required this.srcKey,
    required this.dstKey,
  });

  factory DetailSetup.fromJson(Map<String, dynamic> json) => DetailSetup(
    srcKey: json["srcKey"] ?? "",
    dstKey: json["dstKey"] ?? "",
  );
}

class LoadOnField {
  final bool detail;
  final String source;
  final String target;

  LoadOnField({
    required this.detail,
    required this.source,
    required this.target,
  });

  factory LoadOnField.fromJson(Map<String, dynamic> json) => LoadOnField(
    detail: json["detail"] ?? false,
    source: json["source"] ?? "",
    target: json["target"] ?? "",
  );
}

class Section {
  final String title;
  final List<Field> fields;

  Section({
    required this.title,
    required this.fields,
  });

  factory Section.fromJson(Map<String, dynamic> json) => Section(
    title: json["title"] ?? "",
    fields: json["fields"] != null ? List<Field>.from(json["fields"].map((e) => Field.fromJson(e))) : [],
  );
}

class Field with ChangeNotifier {
  final String name;
  final String type;
  final String title;
  final String description;
  bool readOnly;
  final bool required;
  final bool multiple;
  final bool obscure;
  final bool hidden;
  final String defaultValue;
  final String enableAfter;
  final List<Validation> validations;
  final List<dynamic> data;
  final Link? link;

  Field({
    required this.name,
    required this.type,
    required this.title,
    required this.description,
    required this.readOnly,
    required this.required,
    required this.multiple,
    required this.obscure,
    required this.hidden,
    required this.defaultValue,
    required this.enableAfter,
    required this.validations,
    required this.data,
    required this.link,
  });

  factory Field.fromJson(Map<String, dynamic> json) => Field(
    name: json["name"] ?? "",
    type: json["type"] ?? "",
    title: json["title"] ?? "",
    description: json["description"] ?? "",
    readOnly: json["readOnly"] ?? false,
    required: json["required"] ?? false,
    multiple: json["multiple"] ?? false,
    obscure: json["obscure"] ?? false,
    hidden: json["hidden"] ?? false,
    defaultValue: json["defaultValue"] ?? "",
    enableAfter: json["enableAfter"] ?? "",
    validations: json["validations"] != null ? List<Validation>.from(json["validations"].map((e) => Validation.fromJson(e))) : [],
    data: json["data"] != null ? List<dynamic>.from(json["data"].map((e) => e)) : [],
    link: json["link"] != null ? Link.fromJson(json["link"]) : null,
  );

  dynamic getValue(Map<String, dynamic> data) {
    return data[name];
  }

  void setValue(Map<String, dynamic> data, dynamic value) {
    data[name] = value;

    notifyListeners();
  }

  void enable() {
    readOnly = false;

    notifyListeners();
  }

  String label(Map<String, dynamic> data) {
    dynamic value = data[name];

    if (value != null) {
      if (type == DynamicFormFieldType.NUMBER.name) {
        return Formats.tryParseNumber(value).currency();
      } else if (type == DynamicFormFieldType.DATE.name) {
        return Formats.date(value);
      } else if (type == DynamicFormFieldType.TIME.name) {
        return Formats.time(value);
      } else if (type == DynamicFormFieldType.DATE_TIME.name) {
        return Formats.dateTime(value);
      } else if (type == DynamicFormFieldType.DROPDOWN_DATA.name) {
        if (link != null) {
          if (data.containsKey(link!.target)) {
            String linkValue = data[link!.target];

            if (StringUtils.isNotNullOrEmpty(linkValue)) {
              return linkValue;
            }
          }
        }

        return value.toString();
      } else {
        return value.toString();
      }
    }

    return "";
  }
}

class Validation {
  final String type;
  final dynamic value;
  final String errorMessage;

  Validation({
    required this.type,
    required this.value,
    required this.errorMessage,
  });

  factory Validation.fromJson(Map<String, dynamic> json) => Validation(
    type: json["type"] ?? "",
    value: json["value"],
    errorMessage: json["errorMessage"] ?? "",
  );
}

class Link {
  final String source;
  final String target;
  final List<String> depends;

  Link({
    required this.source,
    required this.target,
    required this.depends,
  });

  factory Link.fromJson(Map<String, dynamic> json) => Link(
    source: json["source"] ?? "",
    target: json["target"] ?? "",
    depends: json["depends"] != null ? List<String>.from(json["depends"].map((e) => e)) : [],
  );
}
