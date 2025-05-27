import "dart:io";
import "dart:typed_data";

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/enumeration/dynamic_form_field_type.dart";
import "package:dynamic_of_things/helper/custom_attachments.dart";
import "package:dynamic_of_things/helper/formats.dart";
import "package:dynamic_of_things/helper/google_drives.dart";
import "package:dynamic_of_things/model/attachment.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:flutter/material.dart";
import "package:video_thumbnail/video_thumbnail.dart";

class DynamicForms {
  static String spell({
    required String type,
    required dynamic value,
  }) {
    if (value != null) {
      if (type == DynamicFormFieldType.DATE.name) {
        DateTime? dateTime;

        if (value is String) {
          dateTime = DateTime.tryParse(value);
        } else if (value is DateTime) {
          dateTime = value;
        }

        return Formats.date(dateTime);
      } else if (type == DynamicFormFieldType.TIME.name) {
        TimeOfDay? timeOfDay;

        if (value is String) {
          timeOfDay = Formats.parseTime(value);
        } else if (value is TimeOfDay) {
          timeOfDay = value;
        }

        return Formats.time(timeOfDay);
      } else if (type == DynamicFormFieldType.DATE_TIME.name) {
        DateTime? dateTime;

        if (value is String) {
          dateTime = DateTime.tryParse(value);
        } else if (value is DateTime) {
          dateTime = value;
        }

        return Formats.dateTime(dateTime);
      } else if (StringUtils.inList(type, [DynamicFormFieldType.NUMBER.name, DynamicFormFieldType.NUMERIC.name])) {
        num numValue = 0;

        if (value is String) {
          numValue = Formats.tryParseNumber(value);
        } else if (value is num) {
          numValue = value;
        }

        return numValue.currency();
      } else {
        return value.toString();
      }
    }

    return "";
  }

  static String dataType(String value) {
    if (StringUtils.equalsIgnoreCase(value, "STRING")) {
      return DynamicFormFieldType.SHORT_TEXT.name;
    } else if (StringUtils.equalsIgnoreCase(value, "PASSWORD")) {
      return DynamicFormFieldType.SHORT_TEXT.name;
    } else if (StringUtils.equalsIgnoreCase(value, "NUMERIC")) {
      return DynamicFormFieldType.NUMBER.name;
    } else if (StringUtils.equalsIgnoreCase(value, "EMAIL")) {
      return DynamicFormFieldType.EMAIL.name;
    } else if (StringUtils.equalsIgnoreCase(value, "DATE")) {
      return DynamicFormFieldType.DATE.name;
    } else if (StringUtils.equalsIgnoreCase(value, "DATETIME")) {
      return DynamicFormFieldType.DATE_TIME.name;
    } else if (StringUtils.equalsIgnoreCase(value, "CHECKBOX")) {
      return DynamicFormFieldType.CHECK.name;
    } else if (StringUtils.equalsIgnoreCase(value, "COMBOBOX")) {
      return DynamicFormFieldType.DROPDOWN.name;
    } else if (StringUtils.equalsIgnoreCase(value, "DATA")) {
      return DynamicFormFieldType.DROPDOWN_DATA.name;
    } else {
      return DynamicFormFieldType.SHORT_TEXT.name;
    }
  }

  static Future<Map<String, dynamic>> encode({
    required HeaderForm headerForm,
  }) async {
    Future<Map<String, dynamic>> process({
      required List<Section> sections,
      required Map<String, dynamic> row,
    }) async {
      Map<String, dynamic> target = {};

      for (String key in row.keys) {
        dynamic value = row[key];

        if (value != null) {
          Field? field;

          outerLoop:
          for (Section checkSection in sections) {
            for (Field checkField in checkSection.fields) {
              if (checkField.name == key) {
                field = checkField;

                break outerLoop;
              }
            }
          }

          if (field != null) {
            if (StringUtils.inList(field.type, [DynamicFormFieldType.DATE.name, DynamicFormFieldType.DATE_TIME.name])) {
              target[key] = Formats.tryParseJiffy(value)!.format();
            } else if (StringUtils.inList(field.type, [DynamicFormFieldType.TIME.name])) {
              target[key] = Formats.time(value as TimeOfDay);
            } else if (StringUtils.inList(field.type, [DynamicFormFieldType.NUMERIC.name, DynamicFormFieldType.NUMBER.name])) {
              target[key] = Formats.tryParseNumber(value);
            } else if (StringUtils.inList(field.type, [DynamicFormFieldType.CHECK.name])) {
              target[key] = Formats.tryParseBool(value);
            } else if (StringUtils.inList(field.type, [DynamicFormFieldType.DROPDOWN_DATA.name])) {
              target[key] = value.toString();

              if (field.link != null) {
                String linkKey = field.link!.target;

                target[linkKey] = row[linkKey];
              }
            } else if (StringUtils.inList(field.type, [DynamicFormFieldType.FILE.name, DynamicFormFieldType.VIDEO.name, DynamicFormFieldType.FOTO.name, DynamicFormFieldType.UPLOAD_FOTO.name, DynamicFormFieldType.UPLOAD_VIDEO.name]))  {
              Attachment attachment = value;

              if (StringUtils.isNullOrEmpty(attachment.id)) {
                GoogleDrives googleDrives = await GoogleDrives.getInstance();

                String? fileId = await googleDrives.upload(
                  bytes: attachment.bytes!.toList(),
                );

                target[key] = fileId;
              } else {
                target[key] = attachment.id;
              }
            } else {
              target[key] = value;
            }
          } else {
            target[key] = value;
          }
        } else {
          target[key] = null;
        }
      }

      return target;
    }

    Map<String, dynamic> result = await process(
      sections: headerForm.template.sections,
      row: headerForm.data,
    );

    for (DetailForm detailForm in headerForm.detailForms) {
      result[detailForm.template.tableName] = [];

      for (Map<String, dynamic> row in detailForm.data) {
        Map<String, dynamic> target = await process(
          sections: detailForm.template.sections,
          row: row,
        );

        if (target.isNotEmpty) {
          result[detailForm.template.tableName].add(target);
        }
      }
    }

    return result;
  }

  static Future<dynamic> convert({
    required Field field,
    required dynamic value,
  }) async {
    if (value != null) {
      if (field.type == DynamicFormFieldType.DATE.name) {
        return DateTime.parse(value);
      } else if (field.type == DynamicFormFieldType.TIME.name) {
        return Formats.parseTime(value);
      } else if (field.type == DynamicFormFieldType.DATE_TIME.name) {
        return DateTime.parse(value);
      } else if (field.type == DynamicFormFieldType.NUMERIC.name) {
        num result = Formats.tryParseNumber(value);

        return result;
      } else if (field.type == DynamicFormFieldType.NUMBER.name) {
        num result = Formats.tryParseNumber(value);

        return result;
      } else if (field.type == DynamicFormFieldType.CHECK.name) {
        return value;
      } else if (field.type == DynamicFormFieldType.DROPDOWN_DATA.name) {
        return value;
      } else if (StringUtils.inList(field.type, [DynamicFormFieldType.FILE.name, DynamicFormFieldType.VIDEO.name, DynamicFormFieldType.FOTO.name, DynamicFormFieldType.UPLOAD_FOTO.name, DynamicFormFieldType.UPLOAD_VIDEO.name])) {
        if (StringUtils.isNotNullOrEmpty(value.toString())) {
          GoogleDrives googleDrives = await GoogleDrives.getInstance();

          List<int> bytes = await googleDrives.download(id: value);

          Attachment attachment = Attachment()
            ..id = value
            ..bytes = Uint8List.fromList(bytes);

          if (StringUtils.inList(field.type, [DynamicFormFieldType.VIDEO.name, DynamicFormFieldType.UPLOAD_VIDEO.name])) {
            File file = await CustomAttachments.temporarySave(
              fileName: "thumbnail-video",
              bytes: bytes,
            );

            attachment.thumbnail = await VideoThumbnail.thumbnailData(
              video: file.path,
              imageFormat: ImageFormat.JPEG,
              maxWidth: 128,
              quality: 25,
            );
          }

          return attachment;
        }
      } else {
        return value;
      }
    }

    return value;
  }

  static Future<void> decode({
    required HeaderForm headerForm,
  }) async {
    Future<void> process({
      required Template template,
      required Map<String, dynamic> row,
    }) async {
      for (MapEntry<String, dynamic> mapEntry in row.entries) {
        for (Section section in template.sections) {
          for (Field field in section.fields) {
            if (mapEntry.key == field.name) {
              row[mapEntry.key] = await convert(field: field, value: mapEntry.value);
            }
          }
        }
      }
    }

    await process(
      template: headerForm.template,
      row: headerForm.data,
    );

    for (DetailForm detailForm in headerForm.detailForms) {
      for (Map<String, dynamic> row in detailForm.data) {
        await process(
          template: detailForm.template,
          row: row,
        );
      }
    }
  }
}