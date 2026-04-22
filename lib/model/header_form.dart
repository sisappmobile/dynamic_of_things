// ignore_for_file: always_put_required_named_parameters_first, always_specify_types, cascade_invocations

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:collection/collection.dart";
import "package:dynamic_of_things/enumeration/dynamic_form_field_type.dart";
import "package:dynamic_of_things/helper/dml_assemblers.dart";
import "package:dynamic_of_things/helper/dynamic_form_texts.dart";
import "package:dynamic_of_things/helper/formats.dart";
import "package:dynamic_of_things/helper/offlines.dart";
import "package:flutter/material.dart";
import "package:sqflite/sqflite.dart";

class HeaderForm {
  late Category category;
  late Template template;
  List<DetailForm> detailForms = [];
  late Map<String, dynamic> data;
  late bool hasOnChangeEvent;
  List<PrintYourTemplate> printYourTemplates = [];
  List<ReportLayout> reportLayouts = [];

  String? dataId;

  HeaderForm();

  factory HeaderForm.fromJson(Map<String, dynamic> json) => HeaderForm()
    ..category = Category.fromJson(json["category"])
    ..template = Template.fromJson(json["template"])
    ..detailForms = json["detailForms"] != null ? List<DetailForm>.from(json["detailForms"].map((e) => DetailForm.fromJson(e))) : []
    ..data = json["data"]
    ..hasOnChangeEvent = json["hasOnChangeEvent"]
    ..printYourTemplates = json["printYourTemplates"] != null ? List<PrintYourTemplate>.from(json["printYourTemplates"].map((e) => PrintYourTemplate.fromJson(e))) : []
    ..reportLayouts = json["reportLayouts"] != null ? List<ReportLayout>.from(json["reportLayouts"].map((e) => ReportLayout.fromJson(e))) : [];

  Map<String, dynamic> toJson() => {
    "template": template.toJson(),
    "detailForms": List<dynamic>.from(detailForms.map((x) => x.toJson())),
    "hasOnChangeEvent": hasOnChangeEvent,
    "printYourTemplates": List<dynamic>.from(printYourTemplates.map((x) => x.toJson())),
    "reportLayouts": List<dynamic>.from(reportLayouts.map((x) => x.toJson())),
  };
}

class Menu {
  late String id;
  late String name;
  late int index;
  late String type;
  late String icon;

  Menu();

  factory Menu.fromJson(Map<String, dynamic> json) => Menu()
    ..id = json["id"] ?? ""
    ..name = json["name"] ?? ""
    ..index = json["index"] ?? 0
    ..type = json["type"] ?? ""
    ..icon = json["icon"] ?? "";

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "index": index,
    "type": type,
    "icon": icon,
  };
}

class Category {
  late String id;
  late String name;
  late int index;
  late Menu menu;

  Category();

  factory Category.fromJson(Map<String, dynamic> json) => Category()
    ..id = json["id"] ?? ""
    ..name = json["name"] ?? ""
    ..index = json["index"] ?? 0
    ..menu = Menu.fromJson(json["menu"]);

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "index": index,
    "menu": menu.toJson(),
  };
}

class Template {
  late String id;
  late String tableName;
  late String title;
  late String description;
  late bool journey;
  late bool recordLocationOnSubmit;
  late num? locationAccuracyInMeters;
  late num? locationAccuracyEfectiveDurationInSeconds;
  List<Action> actions = [];
  List<Section> sections = [];

  Template();

  factory Template.fromJson(Map<String, dynamic> json) => Template()
    ..id = json["id"] ?? ""
    ..tableName = json["tableName"] ?? ""
    ..title = json["title"] ?? ""
    ..description = json["description"] ?? ""
    ..journey = json["journey"] ?? false
    ..recordLocationOnSubmit = json["recordLocationOnSubmit"] ?? false
    ..locationAccuracyInMeters = json["locationAccuracyInMeters"]
    ..locationAccuracyEfectiveDurationInSeconds = json["locationAccuracyEfectiveDurationInSeconds"]
    ..actions = json["actions"] != null ? List<Action>.from(json["actions"].map((e) => Action.fromJson(e))) : []
    ..sections = json["sections"] != null ? List<Section>.from(json["sections"].map((e) => Section.fromJson(e))) : [];

  static Future<Template> loadTemplate(int mode, Map<String, dynamic> customFormView, List<Map<String, dynamic>> fields, {
    Transaction? transaction,
  }) async {
    Template template = Template();

    template.id = customFormView["id"].toString();
    template.tableName = customFormView["table_name"];
    template.title = customFormView["form_desc"];
    template.description = customFormView["form_desc"];
    template.journey = customFormView["f_journey"] == "Y";
    template.recordLocationOnSubmit = customFormView["f_record_location_on_submit"] == "Y";
    template.locationAccuracyInMeters = customFormView["location_accuracy_in_meters"];
    template.locationAccuracyEfectiveDurationInSeconds = customFormView["location_accuracy_effective_duration_in_seconds"];

    {
      List<Map<String, dynamic>> dtoList = await DMLAssemblers
          .create()
          .select("CAST(e.function_id AS TEXT) AS id")
          .select("e.resource_id AS resource_id")
          .select("e.function_name AS name")
          .from("c_group_access_sales_unit_custom_form a")
          .join("INNER JOIN c_group_access_sales_unit_custom_form_detail b ON b.group_id = a.id")
          .join("INNER JOIN c_sales_access_custom_form c ON c.group_id = a.id")
          .join("INNER JOIN c_sales_access_function_custom_form d ON d.access_id = c.id")
          .join("INNER JOIN c_custom_functions e ON e.resource_id = d.resource_id AND e.custom_id = c.custom_id")
          .equalTo("b.user_id", currentSalesUnitId)
          .and()
          .equalTo("c.custom_id", customFormView["id"])
          .all(transaction);

      for (Map<String, dynamic> hashDTO in dtoList) {
        template.actions.add(
          Action()
            ..id = hashDTO["id"]
            ..resourceId = hashDTO["resource_id"]
            ..name = hashDTO["name"],
        );
      }
    }

    {
      Map<String, List<Map<String, dynamic>>> sectionMap = groupBy(fields, (element) => (element["group_field_name"] ?? "") as String);

      for (MapEntry<String, List<Map<String, dynamic>>> mapEntry in sectionMap.entries) {
        Section section = Section();

        section.title = mapEntry.key;

        for (Map<String, dynamic> fieldCustomFormView in mapEntry.value) {
          if (fieldCustomFormView["f_link_value"] != "Y" || (fieldCustomFormView["f_link_value"] == "Y" && StringUtils.isNotNullOrEmpty(fieldCustomFormView["dst_link_field_value"]))) {
            if (customFormView["f_journey"] == "Y" && fieldCustomFormView["field_name"] == "customer_id") {
              continue;
            }

            if (fieldCustomFormView["f_pk"] != "Y" && !StringUtils.inList(fieldCustomFormView["field_name"], ["company_id", "bu_id", "salesunit_id"])) {
              String dataType = fieldCustomFormView["field_data_type"];

              Field field = Field();

              field.name = fieldCustomFormView["field_name"];
              field.title = fieldCustomFormView["field_caption"];

              if (mode == 0) {
                field.readOnly = fieldCustomFormView["f_readonly"] == "Y" || fieldCustomFormView["f_default_value"] == "Y";
              } else {
                field.readOnly = fieldCustomFormView["f_readonly"] == "Y";
              }

              field.required = fieldCustomFormView["f_mandatory"] == "Y" && fieldCustomFormView["f_default_value"] != "Y";
              field.hidden = fieldCustomFormView["f_hidden"] == "Y";
              field.defaultValue = fieldCustomFormView["default_value"] ?? "";
              field.hasScript = StringUtils.isNotNullOrEmpty(fieldCustomFormView["pseudo_code"]);
              field.linkUrl = fieldCustomFormView["f_is_link_url"] == "Y";

              if (fieldCustomFormView["enable_after_colum"] != null) {
                field.enableAfter = (await DMLAssemblers
                    .create()
                    .select("COALESCE(b.field_name, a.field_name) AS field_name")
                    .from("c_field_custom_form a")
                    .join("LEFT JOIN c_field_custom_form b ON b.dst_link_field_value = a.field_name")
                    .equalTo("a.custom_id", customFormView["id"])
                    .and()
                    .equalTo("a.column_id", fieldCustomFormView["enable_after_colum"])
                    .first(transaction))?["field_name"];
              }

              if (!StringUtils.inList(dataType, ["DATA", "MULTIDATA"])) {
                if (fieldCustomFormView["f_link_value"] == "Y") {
                  field.readOnly = true;
                }
              }

              if (dataType == "STRING") {
                if (fieldCustomFormView["f_text_area"] == "Y") {
                  field.type = "LONG_TEXT";
                } else {
                  field.type = "SHORT_TEXT";
                }
              } else if (dataType == "TEXT") {
                field.type = "LONG_TEXT";
              } else if (dataType == "PASSWORD") {
                field.type = "SHORT_TEXT";
                field.obscure = true;
              } else if (dataType == "NUMERIC") {
                field.type = "NUMBER";
              } else if (dataType == "EMAIL") {
                field.type = "EMAIL";
              } else if (dataType == "DATE") {
                field.type = "DATE";
              } else if (dataType == "DATETIME") {
                field.type = "DATE_TIME";
              } else if (dataType == "TIME") {
                field.type = "TIME";
              } else if (dataType == "CHECKBOX") {
                field.type = "CHECK";
              } else if (dataType == "FILE") {
                field.type = "FILE";
              } else if (dataType == "FOTO") {
                field.type = "FOTO";
              } else if (dataType == "VIDEO") {
                field.type = "VIDEO";
              } else if (dataType == "SIGNATURE") {
                field.type = "SIGNATURE";
              } else if (dataType == "UPLOAD_FOTO") {
                field.type = "UPLOAD_FOTO";
              } else if (dataType == "UPLOAD_VIDEO") {
                field.type = "UPLOAD_VIDEO";
              } else if (dataType == "UPLOAD_SIGNATURE") {
                field.type = "UPLOAD_SIGNATURE";
              } else if (dataType == "BARCODE") {
                field.type = "BARCODE";
              } else if (dataType == "QRCODE") {
                field.type = "QRCODE";
              } else if (dataType == "COMBOBOX") {
                field.type = "DROPDOWN";
                field.data = ((fieldCustomFormView["field_data_value"] ?? "") as String)
                    .split("\n")
                    .map((e) => e.replaceAll("\r", ""))
                    .toList();
              } else if (StringUtils.inList(dataType, ["DATA", "MULTIDATA"])) {
                field.type = "DROPDOWN_DATA";

                if (dataType == "MULTIDATA") {
                  field.multiple = true;
                }

                if (fieldCustomFormView["f_link_value"] == "Y") {
                  Link link = Link();

                  link.source = fieldCustomFormView["src_link_field_value"];
                  link.target = fieldCustomFormView["dst_link_field_value"];
                  link.depends = (await DMLAssemblers
                      .create()
                      .select("value")
                      .from("c_field_filter_from_field")
                      .equalTo("field_id", fieldCustomFormView["id"])
                      .all(transaction)).map((e) => e["value"] as String).toList();

                  field.link = link;
                }
              }

              if (fieldCustomFormView["field_data_length"] != null) {
                Validation validation = Validation();

                validation.type = "MAX_LENGTH";
                validation.value = fieldCustomFormView["field_data_length"];
                validation.errorMessage = "Jumlah karakter maksimal ${fieldCustomFormView["field_data_length"]}";

                field.validations.add(validation);
              }

              section.fields.add(field);
            }
          }
        }

        if (section.fields.isNotEmpty) {
          template.sections.add(section);
        }
      }
    }

    return template;
  }

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
    "sections": List<dynamic>.from(sections.map((x) => x.toJson())),
  };
}

class Action {
  late String id;
  late String resourceId;
  late String name;

  Action();

  factory Action.fromJson(Map<String, dynamic> json) => Action()
    ..id = json["id"] ?? ""
    ..resourceId = json["resourceId"] ?? ""
    ..name = json["name"] ?? "";

  Map<String, dynamic> toJson() => {
    "id": id,
    "resourceId": resourceId,
    "name": name,
  };
}

class PrintYourTemplate {
  late String id;
  late String label;

  PrintYourTemplate();

  factory PrintYourTemplate.fromJson(Map<String, dynamic> json) => PrintYourTemplate()
    ..id = json["id"] ?? ""
    ..label = json["label"] ?? "";

  Map<String, dynamic> toJson() => {
    "id": id,
    "label": label,
  };
}

class ReportLayout {
  late String id;
  late String label;

  ReportLayout();

  factory ReportLayout.fromJson(Map<String, dynamic> json) => ReportLayout()
    ..id = json["id"] ?? ""
    ..label = json["label"] ?? "";

  Map<String, dynamic> toJson() => {
    "id": id,
    "label": label,
  };
}

class DetailForm with ChangeNotifier {
  late bool single;
  int? sectionIndex;
  List<ListColumn> columns = [];
  late Template template;
  late Map<String, dynamic> constructor;
  List<SubDetailForm> subDetailForms = [];
  late bool hasOnChangeEvent;

  DetailForm();

  factory DetailForm.fromJson(Map<String, dynamic> json) => DetailForm()
    ..single = json["single"]
    ..sectionIndex = json["sectionIndex"]
    ..columns = json["columns"] != null ? List<ListColumn>.from(json["columns"].map((e) => ListColumn.fromJson(e))) : []
    ..template = Template.fromJson(json["template"])
    ..constructor = json["template"]
    ..subDetailForms = json["subDetailForms"] != null ? List<SubDetailForm>.from(json["subDetailForms"].map((e) => SubDetailForm.fromJson(e))) : []
    ..hasOnChangeEvent = json["hasOnChangeEvent"];

  static Future<DetailForm> load({
    required int mode,
    required DetailCarrier detailCarrier,
    Transaction? transaction,
  }) async {
    DetailForm detailForm = DetailForm();

    detailForm.single = detailCarrier.customFormView["template_mode"] == "CARD";
    detailForm.template = await Template.loadTemplate(mode, detailCarrier.customFormView, detailCarrier.fields, transaction: transaction);
    detailForm.hasOnChangeEvent = detailCarrier.fields.any((element) => StringUtils.isNotNullOrEmpty(element["pseudo_code"]));

    if (!detailForm.single) {
      for (Map<String, dynamic> fieldCustomFormView in detailCarrier.fields) {
        if (fieldCustomFormView["field_name"] != "salesunit_id") {
          ListColumn listColumn = ListColumn();

          if (fieldCustomFormView["f_link_value"] == "Y") {
            listColumn.name = fieldCustomFormView["dst_link_field_value"] ?? "";
          } else {
            listColumn.name = fieldCustomFormView["field_name"];
          }

          listColumn.type = DynamicFormFieldType.convert(fieldCustomFormView["field_data_type"]).name;
          listColumn.description = fieldCustomFormView["field_caption"];
          listColumn.primaryKey = fieldCustomFormView["f_pk"] == "Y";

          detailForm.columns.add(listColumn);
        }
      }

      for (SubDetailCarrier subDetailCarrier in detailCarrier.subDetailCarriers) {
        detailForm.subDetailForms.add(await SubDetailForm.load(mode: mode, subDetailCarrier: subDetailCarrier));
      }
    }

    return detailForm;
  }

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
  List<ListColumn> columns = [];
  late Template template;
  late Map<String, dynamic> constructor;
  late bool hasOnChangeEvent;

  SubDetailForm();

  factory SubDetailForm.fromJson(Map<String, dynamic> json) => SubDetailForm()
    ..columns = json["columns"] != null ? List<ListColumn>.from(json["columns"].map((e) => ListColumn.fromJson(e))) : []
    ..template = Template.fromJson(json["template"])
    ..constructor = json["template"]
    ..hasOnChangeEvent = json["hasOnChangeEvent"];

  static Future<SubDetailForm> load({
    required int mode,
    required SubDetailCarrier subDetailCarrier,
    Transaction? transaction,
  }) async {
    SubDetailForm subDetailForm = SubDetailForm();

    subDetailForm.template = await Template.loadTemplate(mode, subDetailCarrier.customFormView, subDetailCarrier.fields, transaction: transaction);
    subDetailForm.hasOnChangeEvent = subDetailCarrier.fields.any((element) => StringUtils.isNotNullOrEmpty(element["pseudo_code"]));

    for (Map<String, dynamic> fieldCustomFormView in subDetailCarrier.fields) {
      if (fieldCustomFormView["field_name"] != "salesunit_id") {
        ListColumn listColumn = ListColumn();

        if (fieldCustomFormView["f_link_value"] == "Y") {
          listColumn.name = fieldCustomFormView["dst_field_value"];
        } else {
          listColumn.name = fieldCustomFormView["field_name"];
        }

        listColumn.type = DynamicFormFieldType.convert(fieldCustomFormView["field_data_type"]).name;
        listColumn.description = fieldCustomFormView["field_caption"];
        listColumn.primaryKey = fieldCustomFormView["f_pk"] == "Y";

        subDetailForm.columns.add(listColumn);
      }
    }

    return subDetailForm;
  }

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
  late String name;
  late String type;
  late String description;
  late bool primaryKey;

  ListColumn();

  factory ListColumn.fromJson(Map<String, dynamic> json) => ListColumn()
    ..name = json["name"] ?? ""
    ..type = json["type"] ?? ""
    ..description = json["description"] ?? ""
    ..primaryKey = json["primaryKey"] ?? false;

  Map<String, dynamic> toJson() => {
    "name": name,
    "type": type,
    "description": description,
    "primaryKey": primaryKey,
  };
}

class Resource {
  late String name;
  late String key;
  late String table;
  List<String> fields = [];
  List<ManualFilter> manualFilters = [];
  List<AutoFilter> autoFilters = [];
  List<DetailSetup> detailSetups = [];
  List<LoadOnField> loadOnFields = [];

  Resource();

  factory Resource.fromJson(Map<String, dynamic> json) => Resource()
    ..name = json["name"] ?? ""
    ..key = json["key"] ?? ""
    ..table = json["table"] ?? ""
    ..fields = json["fields"] != null ? List<String>.from(json["fields"].map((e) => e)) : []
    ..manualFilters = json["manualFilters"] != null ? List<ManualFilter>.from(json["manualFilters"].map((e) => ManualFilter.fromJson(e))) : []
    ..autoFilters = json["autoFilters"] != null ? List<AutoFilter>.from(json["autoFilters"].map((e) => AutoFilter.fromJson(e))) : []
    ..detailSetups = json["detailSetups"] != null ? List<DetailSetup>.from(json["detailSetups"].map((e) => DetailSetup.fromJson(e))) : []
    ..loadOnFields = json["loadOnFields"] != null ? List<LoadOnField>.from(json["loadOnFields"].map((e) => LoadOnField.fromJson(e))) : [];

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
  late String key;
  late String value;
  late String operator;
  late String operation;

  ManualFilter();

  factory ManualFilter.fromJson(Map<String, dynamic> json) => ManualFilter()
    ..key = json["key"] ?? ""
    ..value = json["value"] ?? ""
    ..operator = json["operator"] ?? ""
    ..operation = json["operation"] ?? "";

  Map<String, dynamic> toJson() => {
    "key": key,
    "value": value,
    "operator": operator,
    "operation": operation,
  };
}

class AutoFilter {
  late String key;
  late String value;
  late String operator;
  late String operation;

  AutoFilter();

  factory AutoFilter.fromJson(Map<String, dynamic> json) => AutoFilter()
    ..key = json["key"] ?? ""
    ..value = json["value"] ?? ""
    ..operator = json["operator"] ?? ""
    ..operation = json["operation"] ?? "";

  Map<String, dynamic> toJson() => {
    "key": key,
    "value": value,
    "operator": operator,
    "operation": operation,
  };
}

class DetailSetup {
  late String srcKey;
  late String dstKey;

  DetailSetup();

  factory DetailSetup.fromJson(Map<String, dynamic> json) => DetailSetup()
    ..srcKey = json["srcKey"] ?? ""
    ..dstKey = json["dstKey"] ?? "";

  Map<String, dynamic> toJson() => {
    "srcKey": srcKey,
    "dstKey": dstKey,
  };
}

class LoadOnField {
  late bool detail;
  late String source;
  late String target;

  LoadOnField();

  factory LoadOnField.fromJson(Map<String, dynamic> json) => LoadOnField()
    ..detail = json["detail"] ?? false
    ..source = json["source"] ?? ""
    ..target = json["target"] ?? "";

  Map<String, dynamic> toJson() => {
    "detail": detail,
    "source": source,
    "target": target,
  };
}

class Section {
  late String title;
  List<Field> fields = [];

  Section();

  factory Section.fromJson(Map<String, dynamic> json) => Section()
    ..title = json["title"] ?? ""
    ..fields = json["fields"] != null ? List<Field>.from(json["fields"].map((e) => Field.fromJson(e))) : [];

  Map<String, dynamic> toJson() => {
    "title": title,
    "fields": List<dynamic>.from(fields.map((x) => x.toJson())),
  };
}

class Field with ChangeNotifier {
  late String name;
  late String type;
  late String title;
  late String description;
  late bool readOnly;
  late bool required;
  late bool multiple;
  late bool obscure;
  late bool hidden;
  late bool hasScript;
  late bool linkUrl;
  late String defaultValue;
  String? enableAfter;
  List<Validation> validations = [];
  List<dynamic> data = [];
  late Link? link;

  bool forceRefresh = false;

  Field();

  factory Field.fromJson(Map<String, dynamic> json) => Field()
    ..name = json["name"] ?? ""
    ..type = json["type"] ?? ""
    ..title = json["title"] ?? ""
    ..description = json["description"] ?? ""
    ..readOnly = json["readOnly"] ?? false
    ..required = json["required"] ?? false
    ..multiple = json["multiple"] ?? false
    ..obscure = json["obscure"] ?? false
    ..hidden = json["hidden"] ?? false
    ..hasScript = json["hasScript"] ?? false
    ..linkUrl = json["linkUrl"] ?? false
    ..defaultValue = json["defaultValue"] ?? ""
    ..enableAfter = json["enableAfter"]
    ..validations = json["validations"] != null ? List<Validation>.from(json["validations"].map((e) => Validation.fromJson(e))) : []
    ..data = json["data"] != null ? List<dynamic>.from(json["data"].map((e) => e)) : []
    ..link = json["link"] != null ? Link.fromJson(json["link"]) : null;

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
  late String type;
  late dynamic value;
  late String errorMessage;

  Validation();

  factory Validation.fromJson(Map<String, dynamic> json) => Validation()
    ..type = json["type"] ?? ""
    ..value = json["value"]
    ..errorMessage = json["errorMessage"] ?? "";

  Map<String, dynamic> toJson() => {
    "type": type,
    "value": value,
    "errorMessage": errorMessage,
  };
}

class Link {
  late String source;
  late String target;
  List<String> depends = [];

  Link();

  factory Link.fromJson(Map<String, dynamic> json) => Link()
    ..source = json["source"] ?? ""
    ..target = json["target"] ?? ""
    ..depends = json["depends"] != null ? List<String>.from(json["depends"].map((e) => e)) : [];

  Map<String, dynamic> toJson() => {
    "source": source,
    "target": target,
    "depends": depends,
  };
}
