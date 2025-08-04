import "dart:convert";
import "dart:io";

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:collection/collection.dart";
import "package:dynamic_of_things/enumeration/dynamic_form_field_type.dart";
import "package:dynamic_of_things/helper/custom_attachments.dart";
import "package:dynamic_of_things/helper/formats.dart";
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

  static Future<void> encodeValue({
    required Map<String, dynamic> row,
    required MapEntry<String, dynamic> entry,
    required Field? field,
  }) async {
    String key = entry.key;
    dynamic value = entry.value;

    if (value != null) {
      if (field != null) {
        if (StringUtils.inList(field.type, [DynamicFormFieldType.DATE.name, DynamicFormFieldType.DATE_TIME.name])) {
          row[key] = Formats.tryParseJiffy(value)!.format();
        } else if (StringUtils.inList(field.type, [DynamicFormFieldType.TIME.name])) {
          row[key] = Formats.time(value as TimeOfDay);
        } else if (StringUtils.inList(field.type, [DynamicFormFieldType.NUMERIC.name, DynamicFormFieldType.NUMBER.name])) {
          row[key] = Formats.tryParseNumber(value);
        } else if (StringUtils.inList(field.type, [DynamicFormFieldType.CHECK.name])) {
          row[key] = Formats.tryParseBool(value);
        } else if (StringUtils.inList(field.type, [DynamicFormFieldType.DROPDOWN_DATA.name])) {
          row[key] = value.toString();

          if (field.link != null) {
            String linkKey = field.link!.target;

            row[linkKey] = row[linkKey];
          }
        } else if (StringUtils.inList(field.type, [DynamicFormFieldType.FILE.name, DynamicFormFieldType.VIDEO.name, DynamicFormFieldType.FOTO.name, DynamicFormFieldType.UPLOAD_FOTO.name, DynamicFormFieldType.UPLOAD_VIDEO.name]))  {
          Attachment attachment = value;

          row[key] = {
            "name": attachment.name,
            "mime": attachment.mime,
            "bytes": base64Encode(attachment.bytes!),
          };
        } else {
          row[key] = value;
        }
      } else {
        row[key] = value;
      }
    } else {
      row[key] = null;
    }
  }

  static Future<Map<String, dynamic>> encode(HeaderForm headerForm) async {
    Map<String, dynamic> headerRow = Map<String, dynamic>.from(headerForm.data);

    for (MapEntry<String, dynamic> headerMapEntry in headerForm.data.entries) {
      if (headerMapEntry.value is Map || headerMapEntry.value is List) {
        DetailForm? detailForm = headerForm.detailForms.firstWhereOrNull((element) => element.template.tableName == headerMapEntry.key);

        if (detailForm != null) {
          Future<void> detailProcess(Map<String, dynamic> detailRow) async {
            for (MapEntry<String, dynamic> detailMapEntry in detailRow.entries) {
              if (detailMapEntry.value is Map || detailMapEntry.value is List) {
                SubDetailForm? subDetailForm = detailForm.subDetailForms.firstWhereOrNull((element) => element.template.tableName == detailMapEntry.key);

                if (subDetailForm != null) {
                  Future<void> subDetailProcess(Map<String, dynamic> subDetailRow) async {
                    for (MapEntry<String, dynamic> subDetailMapEntry in subDetailRow.entries) {
                      Field? subDetailField;

                      outerLoop:
                      for (Section subDetailSection in subDetailForm.template.sections) {
                        for (Field subDetailFieldCheck in subDetailSection.fields) {
                          if (subDetailFieldCheck.name == subDetailMapEntry.key) {
                            subDetailField = subDetailFieldCheck;

                            break outerLoop;
                          }
                        }
                      }

                      await encodeValue(
                        row: subDetailRow,
                        entry: subDetailMapEntry,
                        field: subDetailField,
                      );
                    }
                  }

                  if (detailMapEntry.value is Map) {
                    Map<String, dynamic> subDetailRow = detailMapEntry.value;

                    await subDetailProcess(subDetailRow);
                  } else {
                    for (Map<String, dynamic> subDetailRow in detailMapEntry.value) {
                      await subDetailProcess(subDetailRow);
                    }
                  }
                }
              } else {
                Field? detailField;

                outerLoop:
                for (Section detailSection in detailForm.template.sections) {
                  for (Field detailFieldCheck in detailSection.fields) {
                    if (detailFieldCheck.name == detailMapEntry.key) {
                      detailField = detailFieldCheck;

                      break outerLoop;
                    }
                  }
                }

                await encodeValue(
                  row: detailRow,
                  entry: detailMapEntry,
                  field: detailField,
                );
              }
            }
          }

          if (headerMapEntry.value is Map) {
            Map<String, dynamic> detailRow = headerMapEntry.value;

            await detailProcess(detailRow);
          } else {
            for (Map<String, dynamic> detailRow in headerMapEntry.value) {
              await detailProcess(detailRow);
            }
          }
        }
      } else {
        Field? headerField;

        outerLoop:
        for (Section headerSection in headerForm.template.sections) {
          for (Field headerFieldCheck in headerSection.fields) {
            if (headerFieldCheck.name == headerMapEntry.key) {
              headerField = headerFieldCheck;

              break outerLoop;
            }
          }
        }

        await encodeValue(
          row: headerRow,
          entry: headerMapEntry,
          field: headerField,
        );
      }
    }

    return headerRow;
  }

  static Future<dynamic> decodeValue({
    required Field? field,
    required dynamic value,
  }) async {
    if (value != null) {
      if (field != null) {
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
        } else if (StringUtils.inList(field.type, [DynamicFormFieldType.FILE.name, DynamicFormFieldType.VIDEO.name, DynamicFormFieldType.FOTO.name, DynamicFormFieldType.UPLOAD_FOTO.name, DynamicFormFieldType.UPLOAD_VIDEO.name])) {
          if (value is Map) {
            Map<String, dynamic> json = Map<String, dynamic>.from(value);

            Attachment attachment = Attachment()
              ..name = json["name"]
              ..mime = json["mime"]
              ..bytes = base64Decode(json["bytes"]);

            if (StringUtils.inList(field.type, [DynamicFormFieldType.VIDEO.name, DynamicFormFieldType.UPLOAD_VIDEO.name])) {
              File file = await CustomAttachments.temporarySave(
                fileName: "thumbnail-video",
                bytes: attachment.bytes!,
              );

              attachment.thumbnail = await VideoThumbnail.thumbnailData(
                video: file.path,
                imageFormat: ImageFormat.JPEG,
                maxWidth: 128,
                quality: 25,
              );
            }

            return attachment;
          } else {
            return null;
          }
        }
      }
    }

    return value;
  }

  static Future<void> decode(HeaderForm headerForm) async {
    Map<String, dynamic> headerRow = headerForm.data;

    for (MapEntry<String, dynamic> headerMapEntry in headerForm.data.entries) {
      Future<void> headerPrimitiveValue() async {
        Field? headerField;

        outerLoop:
        for (Section headerSection in headerForm.template.sections) {
          for (Field headerFieldCheck in headerSection.fields) {
            if (headerFieldCheck.name == headerMapEntry.key) {
              headerField = headerFieldCheck;

              break outerLoop;
            }
          }
        }

        headerRow[headerMapEntry.key] = await decodeValue(field: headerField, value: headerMapEntry.value);
      }

      if (headerMapEntry.value is Map || headerMapEntry.value is List) {
        DetailForm? detailForm = headerForm.detailForms.firstWhereOrNull((element) => element.template.tableName == headerMapEntry.key);

        if (detailForm != null) {
          Future<void> detailProcess(Map<String, dynamic> detailRow) async {
            for (MapEntry<String, dynamic> detailMapEntry in detailRow.entries) {
              Future<void> detailPrimitiveValue() async {
                Field? detailField;

                outerLoop:
                for (Section detailSection in detailForm.template.sections) {
                  for (Field detailFieldCheck in detailSection.fields) {
                    if (detailFieldCheck.name == detailMapEntry.key) {
                      detailField = detailFieldCheck;

                      break outerLoop;
                    }
                  }
                }

                detailRow[detailMapEntry.key] = await decodeValue(field: detailField, value: detailMapEntry.value);
              }

              if (detailMapEntry.value is Map || detailMapEntry.value is List) {
                SubDetailForm? subDetailForm = detailForm.subDetailForms.firstWhereOrNull((element) => element.template.tableName == detailMapEntry.key);

                if (subDetailForm != null) {
                  Future<void> subDetailProcess(Map<String, dynamic> subDetailRow) async {
                    for (MapEntry<String, dynamic> subDetailMapEntry in subDetailRow.entries) {
                      Field? subDetailField;

                      outerLoop:
                      for (Section subDetailSection in subDetailForm.template.sections) {
                        for (Field subDetailFieldCheck in subDetailSection.fields) {
                          if (subDetailFieldCheck.name == subDetailMapEntry.key) {
                            subDetailField = subDetailFieldCheck;

                            break outerLoop;
                          }
                        }
                      }

                      subDetailRow[subDetailMapEntry.key] = await decodeValue(field: subDetailField, value: subDetailMapEntry.value);
                    }
                  }

                  if (detailMapEntry.value is Map) {
                    Map<String, dynamic> subDetailRow = detailMapEntry.value;

                    await subDetailProcess(subDetailRow);
                  } else {
                    for (Map<String, dynamic> subDetailRow in detailMapEntry.value) {
                      await subDetailProcess(subDetailRow);
                    }
                  }
                } else {
                  await detailPrimitiveValue();
                }
              } else {
                await detailPrimitiveValue();
              }
            }
          }

          if (headerMapEntry.value is Map) {
            Map<String, dynamic> detailRow = headerMapEntry.value;

            await detailProcess(detailRow);
          } else {
            for (Map<String, dynamic> detailRow in headerMapEntry.value) {
              await detailProcess(detailRow);
            }
          }
        } else {
          await headerPrimitiveValue();
        }
      } else {
        await headerPrimitiveValue();
      }
    }
  }
}