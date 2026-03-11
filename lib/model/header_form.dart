// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/enumeration/dynamic_form_field_type.dart";
import "package:dynamic_of_things/helper/dynamic_form_texts.dart";
import "package:dynamic_of_things/helper/formats.dart";
import "package:flutter/material.dart";

class HeaderForm {
  final Category category;
  final Template template;
  final List<DetailForm> detailForms;
  Map<String, dynamic> data;
  final bool hasOnChangeEvent;

  String? dataId;

  HeaderForm({
    required this.category,
    required this.template,
    required this.detailForms,
    required this.data,
    required this.hasOnChangeEvent,
  });

  factory HeaderForm.fromJson(Map<String, dynamic> json) => HeaderForm(
    category: Category.fromJson(json["category"]),
    template: Template.fromJson(json["template"]),
    detailForms: json["detailForms"] != null ? List<DetailForm>.from(json["detailForms"].map((e) => DetailForm.fromJson(e))) : [],
    data: json["data"],
    hasOnChangeEvent: json["hasOnChangeEvent"],
  );

  Map<String, dynamic> toJson() => {
    "template": template.toJson(),
    "detailForms": List<dynamic>.from(detailForms.map((x) => x.toJson())),
    "hasOnChangeEvent": hasOnChangeEvent,
  };
}

class Menu {
  final String id;
  final String name;
  final int index;
  final String type;
  final String icon;

  Menu({
    required this.id,
    required this.name,
    required this.index,
    required this.type,
    required this.icon,
  });

  factory Menu.fromJson(Map<String, dynamic> json) => Menu(
    id: json["id"] ?? "",
    name: json["name"] ?? "",
    index: json["index"] ?? 0,
    type: json["type"] ?? "",
    icon: json["icon"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "index": index,
    "type": type,
    "icon": icon,
  };
}

class Category {
  final String id;
  final String name;
  final int index;
  final Menu menu;

  Category({
    required this.id,
    required this.name,
    required this.index,
    required this.menu,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json["id"] ?? "",
    name: json["name"] ?? "",
    index: json["index"] ?? 0,
    menu: Menu.fromJson(json["menu"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "index": index,
    "menu": menu.toJson(),
  };
}

class Template {
  final String id;
  final String tableName;
  final String title;
  final String description;
  final bool journey;
  final bool recordLocationOnSubmit;
  final num? locationAccuracyInMeters;
  final num? locationAccuracyEfectiveDurationInSeconds;
  final List<Action> actions;
  final List<ListColumn> columns;
  final List<Resource> resources;
  final List<Section> sections;

  Template({
    required this.id,
    required this.tableName,
    required this.title,
    required this.description,
    required this.journey,
    required this.recordLocationOnSubmit,
    required this.locationAccuracyInMeters,
    required this.locationAccuracyEfectiveDurationInSeconds,
    required this.actions,
    required this.columns,
    required this.resources,
    required this.sections,
  });

  factory Template.fromJson(Map<String, dynamic> json) => Template(
    id: json["id"] ?? "",
    tableName: json["tableName"] ?? "",
    title: json["title"] ?? "",
    description: json["description"] ?? "",
    journey: json["journey"] ?? false,
    recordLocationOnSubmit: json["recordLocationOnSubmit"] ?? false,
    locationAccuracyInMeters: json["locationAccuracyInMeters"],
    locationAccuracyEfectiveDurationInSeconds: json["locationAccuracyEfectiveDurationInSeconds"],
    actions: json["actions"] != null ? List<Action>.from(json["actions"].map((e) => Action.fromJson(e))) : [],
    columns: json["columns"] != null ? List<ListColumn>.from(json["columns"].map((e) => ListColumn.fromJson(e))) : [],
    resources: json["resources"] != null ? List<Resource>.from(json["resources"].map((e) => Resource.fromJson(e))) : [],
    sections: json["sections"] != null ? List<Section>.from(json["sections"].map((e) => Section.fromJson(e))) : [],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "tableName": tableName,
    "title": title,
    "description": description,
    "journey": journey,
    "recordLocationOnSubmit": recordLocationOnSubmit,
    "locationAccuracyInMeters": locationAccuracyInMeters,
    "locationAccuracyEfectiveDurationInSeconds": locationAccuracyEfectiveDurationInSeconds,
    "actions": List<dynamic>.from(actions.map((x) => x.toJson())),
    "resources": List<dynamic>.from(resources.map((x) => x.toJson())),
    "sections": List<dynamic>.from(sections.map((x) => x.toJson())),
  };
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

  Map<String, dynamic> toJson() => {
    "id": id,
    "resourceId": resourceId,
    "name": name,
  };
}

class DetailForm with ChangeNotifier {
  final bool single;
  final int? sectionIndex;
  final List<ListColumn> columns;
  final Template template;
  final Map<String, dynamic> constructor;
  final List<SubDetailForm> subDetailForms;
  final bool hasOnChangeEvent;

  DetailForm({
    required this.single,
    required this.sectionIndex,
    required this.columns,
    required this.template,
    required this.constructor,
    required this.subDetailForms,
    required this.hasOnChangeEvent,
  });

  factory DetailForm.fromJson(Map<String, dynamic> json) => DetailForm(
    single: json["single"],
    sectionIndex: json["sectionIndex"],
    columns: json["columns"] != null ? List<ListColumn>.from(json["columns"].map((e) => ListColumn.fromJson(e))) : [],
    template: Template.fromJson(json["template"]),
    constructor: json["template"],
    subDetailForms: json["subDetailForms"] != null ? List<SubDetailForm>.from(json["subDetailForms"].map((e) => SubDetailForm.fromJson(e))) : [],
    hasOnChangeEvent: json["hasOnChangeEvent"],
  );

  Map<String, dynamic> toJson() => {
    "single": single,
    "columns": List<dynamic>.from(columns.map((x) => x.toJson())),
    "template": template.toJson(),
    "subDetailForms": List<dynamic>.from(subDetailForms.map((x) => x.toJson())),
    "hasOnChangeEvent": hasOnChangeEvent,
  };

  dynamic getData(HeaderForm headerForm) {
    if (single) {
      headerForm.data[template.tableName] = Map<String, dynamic>.from(headerForm.data[template.tableName] ?? {});
    } else {
      headerForm.data[template.tableName] = List<Map<String, dynamic>>.from(headerForm.data[template.tableName] ?? []);
    }

    return headerForm.data[template.tableName];
  }

  Map<String, dynamic> getRow(HeaderForm headerForm, int index) {
    return Map<String, dynamic>.from(getData(headerForm)[index]);
  }

  void addRow(HeaderForm headerForm, Map<String, dynamic> row) {
    getData(headerForm).add(row);

    notifyListeners();
  }

  void deleteRow(HeaderForm headerForm, int index) {
    getData(headerForm).removeAt(index);

    notifyListeners();
  }

  void updateRow(HeaderForm headerForm, Map<String, dynamic> row, int index) {
    getData(headerForm)[index] = row;

    notifyListeners();
  }
}

class SubDetailForm with ChangeNotifier {
  final List<ListColumn> columns;
  final Template template;
  final Map<String, dynamic> constructor;
  final bool hasOnChangeEvent;

  SubDetailForm({
    required this.columns,
    required this.template,
    required this.constructor,
    required this.hasOnChangeEvent,
  });

  factory SubDetailForm.fromJson(Map<String, dynamic> json) => SubDetailForm(
    columns: json["columns"] != null ? List<ListColumn>.from(json["columns"].map((e) => ListColumn.fromJson(e))) : [],
    template: Template.fromJson(json["template"]),
    constructor: json["template"],
    hasOnChangeEvent: json["hasOnChangeEvent"],
  );

  Map<String, dynamic> toJson() => {
    "columns": List<dynamic>.from(columns.map((x) => x.toJson())),
    "template": template.toJson(),
    "hasOnChangeEvent": hasOnChangeEvent,
  };

  List<Map<String, dynamic>> getRows(Map<String, dynamic> detailData) {
    detailData[template.tableName] = List<Map<String, dynamic>>.from(detailData[template.tableName] ?? []);

    return detailData[template.tableName];
  }

  Map<String, dynamic> getRow(Map<String, dynamic> detailData, int index) {
    return Map<String, dynamic>.from(getRows(detailData)[index]);
  }

  void addRow(Map<String, dynamic> detailData, Map<String, dynamic> row) {
    getRows(detailData).add(row);

    notifyListeners();
  }

  void deleteRow(Map<String, dynamic> detailData, int index) {
    getRows(detailData).removeAt(index);

    notifyListeners();
  }

  void updateRow(Map<String, dynamic> detailData, Map<String, dynamic> row, int index) {
    getRows(detailData)[index] = row;

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

  Map<String, dynamic> toJson() => {
    "name": name,
    "type": type,
    "description": description,
    "primaryKey": primaryKey,
  };
}

class Resource {
  final String name;
  final String key;
  final String table;
  final List<String> fields;
  final List<ManualFilter> manualFilters;
  final List<AutoFilter> autoFilters;
  final List<DetailSetup> detailSetups;
  final List<LoadOnField> loadOnFields;

  Resource({
    required this.name,
    required this.key,
    required this.table,
    required this.fields,
    required this.manualFilters,
    required this.autoFilters,
    required this.detailSetups,
    required this.loadOnFields,
  });

  factory Resource.fromJson(Map<String, dynamic> json) => Resource(
    name: json["name"] ?? "",
    key: json["key"] ?? "",
    table: json["table"] ?? "",
    fields: json["fields"] != null ? List<String>.from(json["fields"].map((e) => e)) : [],
    manualFilters: json["manualFilters"] != null ? List<ManualFilter>.from(json["manualFilters"].map((e) => ManualFilter.fromJson(e))) : [],
    autoFilters: json["autoFilters"] != null ? List<AutoFilter>.from(json["autoFilters"].map((e) => AutoFilter.fromJson(e))) : [],
    detailSetups: json["detailSetups"] != null ? List<DetailSetup>.from(json["detailSetups"].map((e) => DetailSetup.fromJson(e))) : [],
    loadOnFields: json["loadOnFields"] != null ? List<LoadOnField>.from(json["loadOnFields"].map((e) => LoadOnField.fromJson(e))) : [],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "key": key,
    "table": table,
    "fields": fields,
    "manualFilters": List<dynamic>.from(manualFilters.map((x) => x.toJson())),
    "autoFilters": List<dynamic>.from(autoFilters.map((x) => x.toJson())),
    "detailSetups": List<dynamic>.from(detailSetups.map((x) => x.toJson())),
    "loadOnFields": List<dynamic>.from(loadOnFields.map((x) => x.toJson())),
  };
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

  Map<String, dynamic> toJson() => {
    "key": key,
    "value": value,
    "operator": operator,
    "operation": operation,
  };
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

  Map<String, dynamic> toJson() => {
    "key": key,
    "value": value,
    "operator": operator,
    "operation": operation,
  };
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

  Map<String, dynamic> toJson() => {
    "srcKey": srcKey,
    "dstKey": dstKey,
  };
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

  Map<String, dynamic> toJson() => {
    "detail": detail,
    "source": source,
    "target": target,
  };
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

  Map<String, dynamic> toJson() => {
    "title": title,
    "fields": List<dynamic>.from(fields.map((x) => x.toJson())),
  };
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
  final bool hasScript;
  final bool linkUrl;
  final String defaultValue;
  final String enableAfter;
  final List<Validation> validations;
  final List<dynamic> data;
  final Link? link;

  bool forceRefresh = false;

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
    required this.hasScript,
    required this.linkUrl,
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
    hasScript: json["hasScript"] ?? false,
    linkUrl: json["linkUrl"] ?? false,
    defaultValue: json["defaultValue"] ?? "",
    enableAfter: json["enableAfter"] ?? "",
    validations: json["validations"] != null ? List<Validation>.from(json["validations"].map((e) => Validation.fromJson(e))) : [],
    data: json["data"] != null ? List<dynamic>.from(json["data"].map((e) => e)) : [],
    link: json["link"] != null ? Link.fromJson(json["link"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "type": type,
    "title": title,
    "description": description,
    "readOnly": readOnly,
    "required": required,
    "multiple": multiple,
    "obscure": obscure,
    "hidden": hidden,
    "hasScript": hasScript,
    "linkUrl": linkUrl,
    "defaultValue": defaultValue,
    "enableAfter": enableAfter,
    "validations": List<dynamic>.from(validations.map((x) => x.toJson())),
    "data": data,
    "link": link?.toJson(),
  };

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
              return DynamicFormTexts.resolve(linkValue);
            }
          }
        }

        return DynamicFormTexts.resolve(value);
      } else {
        return DynamicFormTexts.resolve(value);
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

  Map<String, dynamic> toJson() => {
    "type": type,
    "value": value,
    "errorMessage": errorMessage,
  };
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

  Map<String, dynamic> toJson() => {
    "source": source,
    "target": target,
    "depends": depends,
  };
}
