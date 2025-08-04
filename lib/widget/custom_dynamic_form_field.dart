// ignore_for_file: always_specify_types, use_build_context_synchronously, empty_catches, cascade_invocations, always_put_required_named_parameters_first, invalid_use_of_protected_member

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:camera/camera.dart";
import "package:collection/collection.dart";
import "package:dynamic_of_things/enumeration/dynamic_form_field_type.dart";
import "package:dynamic_of_things/enumeration/dynamic_form_validation_type.dart";
import "package:dynamic_of_things/helper/bottom_sheets.dart";
import "package:dynamic_of_things/helper/custom_attachments.dart";
import "package:dynamic_of_things/helper/dialogs.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/helper/formats.dart";
import "package:dynamic_of_things/helper/images.dart";
import "package:dynamic_of_things/model/attachment.dart";
import "package:dynamic_of_things/model/dynamic_form_resource_response.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_bloc.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_event.dart";
import "package:dynamic_of_things/widget/barcode_scanner_page.dart";
import "package:dynamic_of_things/widget/signature_page.dart";
import "package:easy_localization/easy_localization.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_image_compress/flutter_image_compress.dart";
import "package:get/get_utils/src/extensions/internacionalization.dart" hide Trans;
import "package:go_router/go_router.dart";
import "package:loader_overlay/loader_overlay.dart";
import "package:material_symbols_icons/material_symbols_icons.dart";
import "package:mime/mime.dart";
import "package:mobile_scanner/mobile_scanner.dart";
import "package:pattern_formatter/numeric_formatter.dart";
import "package:smooth_corner/smooth_corner.dart";
import "package:validators/validators.dart";
import "package:video_thumbnail/video_thumbnail.dart" as vt;

class CustomDynamicFormField extends StatefulWidget {
  final bool readOnly;
  final String? customerId;
  final HeaderForm headerForm;
  final Template template;
  final Field field;
  final Map<String, dynamic> data;

  const CustomDynamicFormField({
    super.key,
    required this.readOnly,
    required this.customerId,
    required this.headerForm,
    required this.template,
    required this.field,
    required this.data,
  });

  @override
  State<CustomDynamicFormField> createState() => CustomDynamicFormFieldState();
}

class CustomDynamicFormFieldState extends State<CustomDynamicFormField> {
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.field,
      builder: (context, child) {
        controller.text = widget.field.label(widget.data);

        return body();
      },
    );
  }

  Widget body() {
    if (widget.field.type == DynamicFormFieldType.SHORT_TEXT.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: textField(
              field,
              onChanged: (value) => widget.field.setValue(widget.data, value),
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.LONG_TEXT.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: textField(
              field,
              onChanged: (value) => widget.field.setValue(widget.data, value),
              maxLines: null,
              minLines: 3,
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.NUMBER.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: textField(
              field,
              onChanged: (value) => widget.field.setValue(widget.data, Formats.tryParseNumber(value)),
              inputFormatters: [
                ThousandsFormatter(
                  formatter: NumberFormat.decimalPattern("id"),
                  allowFraction: true,
                ),
              ],
              keyboardType: TextInputType.number,
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.EMAIL.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: textField(
              field,
              onChanged: (value) => widget.field.setValue(widget.data, value),
              keyboardType: TextInputType.emailAddress,
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.URL.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: textField(
              field,
              onChanged: (value) => widget.field.setValue(widget.data, value),
              keyboardType: TextInputType.url,
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.DATE.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: textField(
              field,
              readOnly: true,
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.TIME.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: textField(
              field,
              readOnly: true,
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.DATE_TIME.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: textField(
              field,
              readOnly: true,
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.RADIO.name) {
      // TODO: Need to be checked
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          if (widget.field.getValue(widget.data) == null) {
            widget.field.setValue(widget.data, widget.field.data[0]);
          }

          return formField(
            field: field,
            body: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                String string = widget.field.data[index];

                return Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Radio(
                        value: string,
                        groupValue: widget.field.getValue(widget.data),
                        onChanged: !isReadOnly() ? (value) => changed(value) : null,
                      ),
                    ),
                    Text(
                      string,
                      style: TextStyle(
                        fontSize: Dimensions.text14,
                      ),
                    ),
                  ],
                );
              },
              separatorBuilder: (context, index) => SizedBox(height: Dimensions.size15),
              itemCount: widget.field.data.length,
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.CHECK.name) {
      // TODO: Need to be checked
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: Switch(
              value: (widget.field.getValue(widget.data) ?? false) as bool,
              onChanged: !isReadOnly() ? (value) {
                setState(() {
                  widget.field.setValue(widget.data, value);
                });
              } : null,
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.DROPDOWN.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: spinnerField(field),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.FILE.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fileWidgets(),
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.FOTO.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fileWidgets(),
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.VIDEO.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fileWidgets(),
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.UPLOAD_FOTO.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fileWidgets(),
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.UPLOAD_VIDEO.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fileWidgets(),
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.DROPDOWN_DATA.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: spinnerField(field),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.QRCODE.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: textField(
              field,
              onChanged: (value) => widget.field.setValue(widget.data, value),
              readOnly: true,
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.BARCODE.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          return formField(
            field: field,
            body: textField(
              field,
              onChanged: (value) => widget.field.setValue(widget.data, value),
              readOnly: true,
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  String? contains(String? value) {
    value ??= "";

    Validation? validation = widget.field.validations.firstWhereOrNull((element) => element.type == DynamicFormValidationType.CONTAINS.name);

    if (validation != null) {
      if (!value.contains(validation.value)) {
        if (StringUtils.isNotNullOrEmpty(validation.errorMessage)) {
          return validation.errorMessage;
        } else {
          return "value_must_contain".tr(args: [validation.value.toString()]);
        }
      }
    }

    return null;
  }

  Widget? suffixIcon() {
    if (!isReadOnly() && StringUtils.inList(widget.field.type, [DynamicFormFieldType.SHORT_TEXT.name, DynamicFormFieldType.LONG_TEXT.name, DynamicFormFieldType.NUMBER.name, DynamicFormFieldType.EMAIL.name, DynamicFormFieldType.URL.name])) {
      return IconButton(
        icon: const Icon(
          Icons.more_vert,
        ),
        onPressed: () {
          BottomSheets.popupMenu(
            context: context,
            menuItems: [
              MenuItem(
                iconData: Icons.backspace,
                title: "clear_text".tr(),
                onTap: () async {
                  if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                    Navigators.pop();
                  } else {
                    context.pop();
                  }

                  widget.field.setValue(widget.data, null);
                },
              ),
              MenuItem(
                iconData: Icons.qr_code_scanner,
                title: "scan_barcode".tr(),
                onTap: () async {
                  if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                    Navigators.pop();
                  } else {
                    context.pop();
                  }

                  Navigators.push(
                    BarcodeScannerPage(
                      onSuccess: (data) {
                        widget.field.setValue(widget.data, data);
                      },
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    } else if (!isReadOnly() && StringUtils.inList(widget.field.type, [DynamicFormFieldType.QRCODE.name, DynamicFormFieldType.BARCODE.name])) {
      return IconButton(
        icon: const Icon(
          Icons.qr_code_scanner,
        ),
        onPressed: () async {
          List<BarcodeFormat> barcodeFormats = [];

          if (widget.field.type == DynamicFormFieldType.QRCODE.name) {
            barcodeFormats.add(BarcodeFormat.qrCode);
          } else {
            barcodeFormats.addAll([
              BarcodeFormat.code128,
              BarcodeFormat.code39,
              BarcodeFormat.code93,
              BarcodeFormat.codabar,
              BarcodeFormat.dataMatrix,
              BarcodeFormat.ean13,
              BarcodeFormat.ean8,
              BarcodeFormat.itf,
              BarcodeFormat.upcA,
              BarcodeFormat.upcE,
              BarcodeFormat.pdf417,
              BarcodeFormat.aztec,
            ]);
          }

          await Navigators.push(
            BarcodeScannerPage(
              formats: barcodeFormats,
              onSuccess: (data) {
                widget.field.setValue(widget.data, data);
              },
            ),
          );
        },
      );
    } else if (StringUtils.inList(widget.field.type, [DynamicFormFieldType.DATE.name, DynamicFormFieldType.DATE_TIME.name])) {
      return IconButton(
        icon: const Icon(
          Icons.event,
        ),
        onPressed: !isReadOnly() ? () => onPressed() : null,
      );
    } else if (StringUtils.inList(widget.field.type, [DynamicFormFieldType.TIME.name])) {
      return IconButton(
        icon: const Icon(
          Icons.access_time,
        ),
        onPressed: !isReadOnly() ? () => onPressed() : null,
      );
    } else {
      return null;
    }
  }

  String? notContains(String? value) {
    value ??= "";

    Validation? validation = widget.field.validations.firstWhereOrNull((element) => element.type == DynamicFormValidationType.NOT_CONTAINS.name);

    if (validation != null) {
      if (value.contains(validation.value)) {
        if (StringUtils.isNotNullOrEmpty(validation.errorMessage)) {
          return validation.errorMessage;
        } else {
          return "value_cannot_contain".tr(args: [validation.value.toString()]);
        }
      }
    }

    return null;
  }

  String? minLength(String? value) {
    value ??= "";

    Validation? validation = widget.field.validations.firstWhereOrNull((element) => element.type == DynamicFormValidationType.MIN_LENGTH.name);

    if (validation != null) {
      int minLength;

      if (validation.value is int) {
        minLength = validation.value;
      } else {
        minLength = int.parse(validation.value);
      }

      if (value.length < minLength) {
        if (StringUtils.isNotNullOrEmpty(validation.errorMessage)) {
          return validation.errorMessage;
        } else {
          return "minimum_character_is".tr(args: [validation.value.toString()]);
        }
      }
    }

    return null;
  }

  int? maxLengthValue() {
    Validation? validation = widget.field.validations.firstWhereOrNull((element) => element.type == DynamicFormValidationType.MAX_LENGTH.name);

    int result = 0;

    if (validation != null) {
      if (validation.value is int) {
        result = validation.value;
      } else {
        result = int.parse(validation.value);
      }
    }

    if (result > 0) {
      return result;
    } else {
      return null;
    }
  }

  String? maxLength(String? value) {
    value ??= "";

    Validation? validation = widget.field.validations.firstWhereOrNull((element) => element.type == DynamicFormValidationType.MAX_LENGTH.name);

    if (validation != null) {
      int? maxLength = maxLengthValue();

      if (maxLength != null) {
        if (value.length > maxLength) {
          if (StringUtils.isNotNullOrEmpty(validation.errorMessage)) {
            return validation.errorMessage;
          } else {
            return "maximum_character_is".tr(args: [validation.value.toString()]);
          }
        }
      }
    }

    return null;
  }

  String? greaterThan(int value) {
    Validation? validation = widget.field.validations.firstWhereOrNull((element) => element.type == DynamicFormValidationType.GREATER_THAN.name);

    if (validation != null) {
      int greaterThan;

      if (validation.value is int) {
        greaterThan = validation.value;
      } else {
        greaterThan = int.parse(validation.value);
      }

      if (value <= greaterThan) {
        if (StringUtils.isNotNullOrEmpty(validation.errorMessage)) {
          return validation.errorMessage;
        } else {
          return "value_must_be_greater_than".tr(args: [validation.value.toString()]);
        }
      }
    }

    return null;
  }

  String? greaterThanOrEqualTo(int value) {
    Validation? validation = widget.field.validations.firstWhereOrNull((element) => element.type == DynamicFormValidationType.GREATER_THAN_OR_EQUAL_TO.name);

    if (validation != null) {
      int greaterThanOrEqualTo;

      if (validation.value is int) {
        greaterThanOrEqualTo = validation.value;
      } else {
        greaterThanOrEqualTo = int.parse(validation.value);
      }

      if (value < greaterThanOrEqualTo) {
        if (StringUtils.isNotNullOrEmpty(validation.errorMessage)) {
          return validation.errorMessage;
        } else {
          return "value_must_be_greater_than_or_equal_to".tr(args: [validation.value.toString()]);
        }
      }
    }

    return null;
  }

  String? lessThan(int value) {
    Validation? validation = widget.field.validations.firstWhereOrNull((element) => element.type == DynamicFormValidationType.LESS_THAN.name);

    if (validation != null) {
      int lessThan;

      if (validation.value is int) {
        lessThan = validation.value;
      } else {
        lessThan = int.parse(validation.value);
      }

      if (value >= lessThan) {
        if (StringUtils.isNotNullOrEmpty(validation.errorMessage)) {
          return validation.errorMessage;
        } else {
          return "value_must_be_less_than".tr(args: [validation.value.toString()]);
        }
      }
    }

    return null;
  }

  String? lessThanOrEqualTo(int value) {
    Validation? validation = widget.field.validations.firstWhereOrNull((element) => element.type == DynamicFormValidationType.LESS_THAN_OR_EQUAL_TO.name);

    if (validation != null) {
      int lessThanOrEqualTo;

      if (validation.value is int) {
        lessThanOrEqualTo = validation.value;
      } else {
        lessThanOrEqualTo = int.parse(validation.value);
      }

      if (value > lessThanOrEqualTo) {
        if (StringUtils.isNotNullOrEmpty(validation.errorMessage)) {
          return validation.errorMessage;
        } else {
          return "value_must_be_less_than_or_equal_to".tr(args: [validation.value.toString()]);
        }
      }
    }

    return null;
  }

  String? email(String? value) {
    value ??= "";

    if (StringUtils.isNotNullOrEmpty(value)) {
      if (!RegExp(r'^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$').hasMatch(value)) {
        return "incorrect_email_format".tr();
      }
    }

    return null;
  }

  String? url(String? value) {
    value ??= "";

    if (StringUtils.isNotNullOrEmpty(value)) {
      if (!isURL(value)) {
        return "incorrect_url_format".tr();
      }
    }

    return null;
  }

  String? before(dynamic object) {
    Validation? validation = widget.field.validations.firstWhereOrNull((element) => element.type == DynamicFormValidationType.BEFORE.name);

    if (validation != null) {
      if (widget.field.type == DynamicFormFieldType.DATE.name) {
        DateTime dateTime = DateTime.parse(validation.value);

        if ((object as DateTime).compareTo(dateTime) > 0) {
          if (StringUtils.isNotNullOrEmpty(validation.errorMessage)) {
            return validation.errorMessage;
          } else {
            return "value_must_be_before".tr(args: [Formats.date(dateTime)]);
          }
        }
      } else if (widget.field.type == DynamicFormFieldType.TIME.name) {
        TimeOfDay timeOfDay = Formats.parseTime(validation.value);

        if ((object as TimeOfDay).compareTo(timeOfDay) > 0) {
          if (StringUtils.isNotNullOrEmpty(validation.errorMessage)) {
            return validation.errorMessage;
          } else {
            return "value_must_be_before".tr(args: [Formats.time(timeOfDay)]);
          }
        }
      } else if (widget.field.type == DynamicFormFieldType.DATE_TIME.name) {
        DateTime dateTime = DateTime.parse(validation.value);

        if ((object as DateTime).compareTo(dateTime) > 0) {
          if (StringUtils.isNotNullOrEmpty(validation.errorMessage)) {
            return validation.errorMessage;
          } else {
            return "value_must_be_before".tr(args: [Formats.date(dateTime)]);
          }
        }
      }
    }

    return null;
  }

  String? after(dynamic value) {
    Validation? validation = widget.field.validations.firstWhereOrNull((element) => element.type == DynamicFormValidationType.AFTER.name);

    if (validation != null) {
      if (widget.field.type == DynamicFormFieldType.DATE.name) {
        DateTime dateTime = DateTime.parse(validation.value);

        if ((value as DateTime).compareTo(dateTime) < 0) {
          if (StringUtils.isNotNullOrEmpty(validation.errorMessage)) {
            return validation.errorMessage;
          } else {
            return "value_must_be_after".tr(args: [Formats.date(dateTime)]);
          }
        }
      } else if (widget.field.type == DynamicFormFieldType.TIME.name) {
        TimeOfDay timeOfDay = Formats.parseTime(validation.value);

        if ((value as TimeOfDay).compareTo(timeOfDay) < 0) {
          if (StringUtils.isNotNullOrEmpty(validation.errorMessage)) {
            return validation.errorMessage;
          } else {
            return "value_must_be_after".tr(args: [Formats.time(timeOfDay)]);
          }
        }
      } else if (widget.field.type == DynamicFormFieldType.DATE_TIME.name) {
        DateTime dateTime = DateTime.parse(validation.value);

        if ((value as DateTime).compareTo(dateTime) < 0) {
          if (StringUtils.isNotNullOrEmpty(validation.errorMessage)) {
            return validation.errorMessage;
          } else {
            return "value_must_be_after".tr(args: [Formats.date(dateTime)]);
          }
        }
      }
    }

    return null;
  }

  void onPressed() async {
    if (widget.field.type == DynamicFormFieldType.DATE.name) {
      DateTime? dateTime = await showDatePicker(
        context: context,
        initialDate: initialDate(),
        firstDate: minDate() != null ? minDate()! : DateTime(1900, 1, 1),
        lastDate: maxDate() != null ? maxDate()! : DateTime(2099, 12, 31),
      );

      if (dateTime != null) {
        widget.field.setValue(widget.data, dateTime);
      }
    } else if (widget.field.type == DynamicFormFieldType.TIME.name) {
      TimeOfDay? timeOfDay = await showTimePicker(
        context: context,
        initialTime: initialTime(),
      );

      if (timeOfDay != null) {
        widget.field.setValue(widget.data, timeOfDay);
      }
    } else if (widget.field.type == DynamicFormFieldType.DATE_TIME.name) {
      DateTime? dateTime = await showDatePicker(
        context: context,
        initialDate: initialDate(),
        firstDate: minDate() != null ? minDate()! : DateTime(1900, 1, 1),
        lastDate: maxDate() != null ? maxDate()! : DateTime(2099, 12, 31),
      );

      if (dateTime != null) {
        TimeOfDay? timeOfDay = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

        if (timeOfDay != null) {
          setState(() {
            DateTime finalDateTime = DateTime(
              dateTime.year,
              dateTime.month,
              dateTime.day,
              timeOfDay.hour,
              timeOfDay.minute,
            );

            widget.field.setValue(widget.data, finalDateTime);
          });
        }
      }
    } else if (widget.field.type == DynamicFormFieldType.FILE.name) {
      FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.any,
      );

      if (filePickerResult != null && filePickerResult.files.isNotEmpty) {
        PlatformFile platformFile = filePickerResult.files.first;

        Attachment attachment = Attachment()
          ..name = platformFile.name
          ..mime = lookupMimeType(platformFile.path!);

        if (StringUtils.inList(platformFile.extension!, ["jpg", "jpeg", "png"])) {
          XFile? xFile = await FlutterImageCompress.compressAndGetFile(
            platformFile.path!,
            await CustomAttachments.temporaryPath(fileName: platformFile.name),
            quality: 20,
          );

          if (xFile != null) {
            attachment.bytes = await xFile.readAsBytes();
          }
        } else {
          attachment.bytes = platformFile.bytes;
        }

        widget.field.setValue(widget.data, attachment);
      }
    } else if (widget.field.type == DynamicFormFieldType.FOTO.name) {
      Images.camera(
        context: context,
        callback: (bytes) async {
          Attachment attachment = Attachment();

          attachment.name = DateTime.now().millisecondsSinceEpoch.toString();
          attachment.mime = "image/png";
          attachment.bytes = bytes;

          widget.field.setValue(widget.data, attachment);
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.VIDEO.name) {
      await availableCameras().then((value) {
        Navigators.push(
          RecordPage(
            cameraDescriptions: value,
            callback: (xFile) async {
              Attachment attachment = Attachment();

              attachment.name = DateTime.now().millisecondsSinceEpoch.toString();
              attachment.mime = "video/mp4";
              attachment.bytes = await xFile.readAsBytes();
              attachment.thumbnail = await vt.VideoThumbnail.thumbnailData(
                video: xFile.path,
                imageFormat: vt.ImageFormat.JPEG,
                maxWidth: 128,
                quality: 25,
              );

              widget.field.setValue(widget.data, attachment);
            },
          ),
        );
      });
    } else if (widget.field.type == DynamicFormFieldType.UPLOAD_FOTO.name) {
      Dialogs.image(
        context: context,
        title: "choose_file".tr(),
        multiple: false,
        allowGallery: true,
        callback: (files) async {
          if (files.isNotEmpty) {
            Attachment attachment = Attachment();

            attachment.name = files.first.name;
            attachment.mime = files.first.mimeType;
            attachment.bytes = await files.first.readAsBytes();

            widget.field.setValue(widget.data, attachment);
          }
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.UPLOAD_VIDEO.name) {
      Dialogs.video(
        context: context,
        title: "choose_file".tr(),
        allowGallery: true,
        callback: (files) async {
          if (files.isNotEmpty) {
            Attachment attachment = Attachment();

            attachment.name = files.first.name;
            attachment.mime = "video/${files.first.extension}";
            attachment.bytes = files.first.bytes;
            attachment.thumbnail = await vt.VideoThumbnail.thumbnailData(
              video: files.first.path!,
              imageFormat: vt.ImageFormat.JPEG,
              maxWidth: 128,
              quality: 25,
            );

            widget.field.setValue(widget.data, attachment);
          }
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.DROPDOWN.name) {
      SpinnerItem? selectedItem = await BaseSheets.spinner(
        context: context,
        title: widget.field.title,
        spinnerItems: widget.field.data.map((e) => SpinnerItem(identity: e, description: e)).toList(),
      );

      if (selectedItem != null) {
        changed(selectedItem.identity);
      }
    } else if (widget.field.type == DynamicFormFieldType.DROPDOWN_DATA.name) {
      DynamicFormResourceResponse? dynamicFormResourceResponse;

      try {
        context.loaderOverlay.show();

        dynamicFormResourceResponse = await DotApis.getInstance().dynamicFormResource(
          formId: widget.template.id,
          name: widget.field.name,
          data: widget.data,
          customerId: widget.customerId,
        );
      } catch (e) {
        BaseOverlays.error(message: "something_wrong_please_try_again".tr());
      } finally {
        context.loaderOverlay.hide();
      }

      if (dynamicFormResourceResponse != null) {
        final selectedItem = await BottomSheets.dynamicFormSpinner(
          context: context,
          title: widget.field.title,
          dynamicFormResourceResponse: dynamicFormResourceResponse,
        );

        if (selectedItem != null) {
          dynamic value = selectedItem[dynamicFormResourceResponse.key];

          try {
            context.loaderOverlay.show();

            Map<String, dynamic>? result = await DotApis.getInstance().dynamicFormSelect(
              formId: widget.template.id,
              name: widget.field.name,
              value: value,
              customerId: widget.customerId,
            );

            if (result != null) {
              if (widget.field.link != null) {
                String linkValue = selectedItem[widget.field.link!.source];

                widget.data[widget.field.link!.target] = linkValue;
              }

              widget.field.setValue(widget.data, value);

              if (dynamicFormResourceResponse.loadOnFields.isNotEmpty) {
                for (DynamicFormResourceLoadOnFieldItem dynamicFormResourceLoadOnFieldItem in dynamicFormResourceResponse.loadOnFields) {
                  if (!dynamicFormResourceLoadOnFieldItem.detail) {
                    dynamic value = selectedItem[dynamicFormResourceLoadOnFieldItem.source];

                    if (value != null) {
                      bool found = false;

                      for (Section section in widget.template.sections) {
                        for (Field field in section.fields) {
                          if (StringUtils.equalsIgnoreCase(field.name, dynamicFormResourceLoadOnFieldItem.target)) {
                            field.setValue(widget.data, await DynamicForms.decodeValue(field: field, value: value));

                            found = true;
                          }
                        }
                      }

                      if (!found) {
                        widget.data[dynamicFormResourceLoadOnFieldItem.target] = value;
                      }
                    }
                  }
                }
              }

              if (widget.field.getValue(widget.data) != null) {
                for (Section section in widget.template.sections) {
                  for (Field field in section.fields) {
                    if (StringUtils.isNotNullOrEmpty(field.enableAfter)) {
                      if (StringUtils.equalsIgnoreCase(field.enableAfter, widget.field.name)) {
                        field.enable();
                      }
                    }
                  }
                }
              }

              if (dynamicFormResourceResponse.detailSetups.isNotEmpty) {
                context.loaderOverlay.show();

                try {
                  List<Map<String, dynamic>> details = selectedItem["details"] != null ? List<Map<String, dynamic>>.from(selectedItem["details"].map((e) => e)) : [];

                  DetailForm? detailForm = widget.headerForm.detailForms.firstOrNull;

                  if (detailForm != null) {
                    if (details.isNotEmpty) {
                      for (Map<String, dynamic> detail in details) {
                        Map<String, dynamic> row = {};

                        for (String key in detail.keys) {
                          for (Section section in detailForm.template.sections) {
                            for (Field field in section.fields) {
                              if (field.name == key) {
                                field.setValue(row, detail[key]);
                              }
                            }
                          }
                        }

                        detailForm.addRow(widget.headerForm, row);
                      }

                      if (detailForm.hasOnChangeEvent) {
                        context.read<DynamicFormBloc>().add(
                          DynamicFormRefresh(
                            formId: widget.headerForm.template.id,
                            customerId: widget.customerId,
                            headerForm: widget.headerForm,
                          ),
                        );
                      }
                    }
                  }
                } catch (e) {
                  BaseOverlays.error(message: "Ada sesuatu yang salah, silahkan coba kembali beberapa saat kemudian.");
                } finally {
                  context.loaderOverlay.hide();
                }
              }

              for (DetailForm detailForm in widget.headerForm.detailForms) {
                List<Map<String, dynamic>> details = result[detailForm.template.tableName] != null ? List<Map<String, dynamic>>.from(result[detailForm.template.tableName].map((e) => e)) : [];

                if (details.isNotEmpty) {
                  for (Map<String, dynamic> detail in details) {
                    Map<String, dynamic> row = {};

                    for (String key in detail.keys) {
                      for (Section section in detailForm.template.sections) {
                        for (Field field in section.fields) {
                          if (field.name == key) {
                            field.setValue(row, detail[key]);
                          }
                        }
                      }
                    }

                    detailForm.addRow(widget.headerForm, row);
                  }
                }
              }
            }
          } catch (e) {
            BaseOverlays.error(message: "something_wrong_please_try_again".tr());
          } finally {
            context.loaderOverlay.hide();
          }
        }
      }
    }
  }

  void changed(dynamic value) {
    if (widget.field.type == DynamicFormFieldType.RADIO.name) {
      widget.field.setValue(widget.data, value);
    } else if (widget.field.type == DynamicFormFieldType.DROPDOWN.name) {
      widget.field.setValue(widget.data, value);
    }
  }

  DateTime initialDate() {
    if (widget.field.getValue(widget.data) == null) {
      {
        DateTime? dateTime = minDate();

        if (dateTime != null) {
          if (DateTime.now().difference(dateTime).isNegative) {
            return dateTime;
          }
        }
      }

      {
        DateTime? dateTime = maxDate();

        if (dateTime != null) {
          if (!DateTime.now().difference(dateTime).isNegative) {
            return dateTime;
          }
        }
      }
    } else {
      return widget.field.getValue(widget.data)!;
    }

    return DateTime.now();
  }

  TimeOfDay initialTime() {
    if (widget.field.getValue(widget.data) == null) {
      {
        TimeOfDay? timeOfDay = minTime();

        if (timeOfDay != null) {
          if (TimeOfDay.now().compareTo(timeOfDay) < 1) {
            return timeOfDay;
          }
        }
      }

      {
        TimeOfDay? timeOfDay = maxTime();

        if (timeOfDay != null) {
          if (TimeOfDay.now().compareTo(timeOfDay) > 1) {
            return timeOfDay;
          }
        }
      }
    } else {
      return widget.field.getValue(widget.data)!;
    }

    return TimeOfDay.now();
  }

  DateTime? minDate() {
    Validation? validation = widget.field.validations.firstWhereOrNull((element) => element.type == DynamicFormValidationType.AFTER.name);

    if (validation != null) {
      return DateTime.parse(validation.value);
    }

    return null;
  }

  DateTime? maxDate() {
    Validation? validation = widget.field.validations.firstWhereOrNull((element) => element.type == DynamicFormValidationType.BEFORE.name);

    if (validation != null) {
      return DateTime.parse(validation.value);
    }

    return null;
  }

  TimeOfDay? minTime() {
    Validation? validation = widget.field.validations.firstWhereOrNull((element) => element.type == DynamicFormValidationType.AFTER.name);

    if (validation != null) {
      return Formats.parseTime(validation.value);
    }

    return null;
  }

  TimeOfDay? maxTime() {
    Validation? validation = widget.field.validations.firstWhereOrNull((element) => element.type == DynamicFormValidationType.BEFORE.name);

    if (validation != null) {
      return Formats.parseTime(validation.value);
    }

    return null;
  }

  String? required(dynamic value) {
    if (widget.field.required) {
      if (value == null) {
        return "this_field_is_required".tr();
      } else {
        if (value is String) {
          if (!StringUtils.isNotNullOrEmpty(value)) {
            return "this_field_is_required".tr();
          }
        }
      }
    }

    return null;
  }

  String? validate() {
    dynamic value = widget.field.getValue(widget.data);

    String? result;

    result = required(value);

    if (result != null) {
      return result;
    }

    if (value != null) {
      if (widget.field.type == DynamicFormFieldType.SHORT_TEXT.name) {
        result = contains(value as String);

        if (result != null) {
          return result;
        }

        result = notContains(value);

        if (result != null) {
          return result;
        }

        result = minLength(value);

        if (result != null) {
          return result;
        }

        result = maxLength(value);

        if (result != null) {
          return result;
        }
      } else if (widget.field.type == DynamicFormFieldType.LONG_TEXT.name) {
        result = minLength(value as String);

        if (result != null) {
          return result;
        }

        result = maxLength(value);

        if (result != null) {
          return result;
        }
      } else if (widget.field.type == DynamicFormFieldType.NUMBER.name) {
        int integer = 0;

        try {
          integer = int.parse(value as String);
        } catch (e) {}

        result = greaterThan(integer);

        if (result != null) {
          return result;
        }

        result = greaterThanOrEqualTo(integer);

        if (result != null) {
          return result;
        }

        result = lessThan(integer);

        if (result != null) {
          return result;
        }

        result = lessThanOrEqualTo(integer);

        if (result != null) {
          return result;
        }
      } else if (widget.field.type == DynamicFormFieldType.EMAIL.name) {
        result = email(value as String);

        if (result != null) {
          return result;
        }
      } else if (widget.field.type == DynamicFormFieldType.URL.name) {
        result = url(value as String);

        if (result != null) {
          return result;
        }
      } else if (widget.field.type == DynamicFormFieldType.DATE.name) {
        result = before(value);

        if (result != null) {
          return result;
        }

        result = after(value);

        if (result != null) {
          return result;
        }
      } else if (widget.field.type == DynamicFormFieldType.TIME.name) {
        result = before(value);

        if (result != null) {
          return result;
        }

        result = after(value);

        if (result != null) {
          return result;
        }
      } else if (widget.field.type == DynamicFormFieldType.DATE_TIME.name) {
        result = before(value);

        if (result != null) {
          return result;
        }

        result = after(value);

        if (result != null) {
          return result;
        }
      }
    }

    if (widget.field.type == DynamicFormFieldType.CHECK.name) {
      value ??= [];

      if (widget.field.required) {
        if ((value as List).isEmpty) {
          return "this_field_is_required".tr();
        }
      }
    } else if (widget.field.type == DynamicFormFieldType.FILE.name) {
      if (widget.field.required) {
        if (value == null) {
          return "this_field_is_required".tr();
        }
      }
    } else if (widget.field.type == DynamicFormFieldType.FOTO.name) {
      if (widget.field.required) {
        if (value == null) {
          return "this_field_is_required".tr();
        }
      }
    } else if (widget.field.type == DynamicFormFieldType.VIDEO.name) {
      if (widget.field.required) {
        if (value == null) {
          return "this_field_is_required".tr();
        }
      }
    } else if (widget.field.type == DynamicFormFieldType.UPLOAD_FOTO.name) {
      if (widget.field.required) {
        if (value == null) {
          return "this_field_is_required".tr();
        }
      }
    } else if (widget.field.type == DynamicFormFieldType.UPLOAD_VIDEO.name) {
      if (widget.field.required) {
        if (value == null) {
          return "this_field_is_required".tr();
        }
      }
    } else if (widget.field.type == DynamicFormFieldType.QRCODE.name) {
      if (widget.field.required) {
        if (value == null) {
          return "this_field_is_required".tr();
        }
      }
    } else if (widget.field.type == DynamicFormFieldType.BARCODE.name) {
      if (widget.field.required) {
        if (value == null) {
          return "this_field_is_required".tr();
        }
      }
    }

    return result;
  }

  List<Widget> fileWidgets() {
    Widget signatureButton() {
      if (StringUtils.inList(widget.field.type, [DynamicFormFieldType.UPLOAD_FOTO.name, DynamicFormFieldType.FILE.name])) {
        return Container(
          margin: EdgeInsets.only(left: Dimensions.size10),
          child: OutlinedButton(
            onPressed: () async {
              Uint8List? bytes = await Navigators.push(SignaturePage());

              if (bytes != null) {
                Attachment attachment = Attachment();

                attachment.name = DateTime.now().millisecondsSinceEpoch.toString();
                attachment.mime = "image/png";
                attachment.bytes = bytes;

                widget.field.setValue(widget.data, attachment);
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Symbols.signature,
                ),
                SizedBox(
                  width: Dimensions.size5,
                ),
                Text(
                  "signature".tr().toUpperCase(),
                ),
              ],
            ),
          ),
        );
      }

      return const SizedBox.shrink();
    }

    List<Widget> widgets = [];

    if (!isReadOnly()) {
      if (widget.field.type == DynamicFormFieldType.VIDEO.name) {
        widgets.add(
          OutlinedButton(
            onPressed: () => onPressed(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.video_call,
                ),
                SizedBox(
                  width: Dimensions.size5,
                ),
                Text(
                  "record_video".tr().toUpperCase(),
                ),
              ],
            ),
          ),
        );
      } else if (widget.field.type == DynamicFormFieldType.FOTO.name) {
        widgets.add(
          OutlinedButton(
            onPressed: () => onPressed(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.camera_alt,
                ),
                SizedBox(
                  width: Dimensions.size5,
                ),
                Text(
                  "take_photo".tr().toUpperCase(),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () => onPressed(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.upload,
                    ),
                    SizedBox(
                      width: Dimensions.size5,
                    ),
                    Text(
                      "choose_file".tr().toUpperCase(),
                    ),
                  ],
                ),
              ),
              signatureButton(),
            ],
          ),
        );
      }
    }

    if (widget.field.getValue(widget.data) != null) {
      widgets.add(
        SizedBox(
          height: Dimensions.size5,
        ),
      );

      Attachment attachment = widget.field.getValue(widget.data);

      Widget thumbnailWidget = Image(
        image: MemoryImage(attachment.thumbnail ?? attachment.bytes!),
        width: Dimensions.size100,
        height: Dimensions.size100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: Dimensions.size100,
            height: Dimensions.size100,
            color: AppColors.primary(),
            child: Center(
              child: Text(
                attachment.name ?? "",
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.onPrimary(),
                  fontSize: Dimensions.text12,
                ),
              ),
            ),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          return Container(
            margin: EdgeInsets.only(top: Dimensions.size5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                Dimensions.size10,
              ),
              child: Stack(
                children: [
                  child,
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (attachment.thumbnail != null) {
                            BottomSheets.videoPreview(
                              context: context,
                              bytes: attachment.bytes!,
                            );
                          } else {
                            BottomSheets.imagePreview(
                              context: context,
                              imageProvider: MemoryImage(attachment.thumbnail ?? attachment.bytes!),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      widgets.add(
        Container(
          margin: EdgeInsets.only(right: Dimensions.size10),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  Dimensions.size10,
                ),
                child: thumbnailWidget,
              ),
              Visibility(
                visible: !isReadOnly(),
                child: Column(
                  children: [
                    SizedBox(
                      height: Dimensions.size5,
                    ),
                    OutlinedButton(
                      onPressed: () {
                        widget.field.setValue(widget.data, null);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.delete,
                            size: 16,
                          ),
                          SizedBox(
                            width: Dimensions.size5,
                          ),
                          Text(
                            "delete".tr().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  Widget helperWidget(FormFieldState field) {
    List<Widget> widgets = [];

    if (field.hasError) {
      widgets.add(
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.error,
                color: AppColors.error(),
              ),
              SizedBox(width: Dimensions.size5),
              Expanded(
                child: Text(
                  field.errorText ?? "",
                  style: TextStyle(
                    fontSize: Dimensions.text12,
                    color: AppColors.error(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if ((maxLengthValue() ?? 0) > 0 && !isReadOnly()) {
      if (widget.field.getValue(widget.data) is String) {
        String value = widget.field.getValue(widget.data) ?? "";

        widgets.add(
          Text(
            "${value.length}/${maxLengthValue()}",
            style: TextStyle(
              fontSize: Dimensions.text10,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface().withValues(alpha: 80),
            ),
          ),
        );
      }
    }

    if (widgets.isNotEmpty) {
      return Container(
        margin: EdgeInsets.only(
          top: Dimensions.size5,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: widgets,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget formField({
    required FormFieldState field,
    required Widget body,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labelWidget(),
        body,
        helperWidget(field),
      ],
    );
  }

  Widget labelWidget() {
    Widget descriptionWidget() {
      if (StringUtils.isNotNullOrEmpty(widget.field.description)) {
        return Text(
          widget.field.description,
          style: TextStyle(
            fontSize: Dimensions.text12,
            color: AppColors.onSurface(),
            fontWeight: FontWeight.w300,
          ),
        );
      }

      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(
        bottom: Dimensions.size5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${widget.field.title}${widget.field.required ? "*" : ""}",
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface(),
            ),
          ),
          descriptionWidget(),
        ],
      ),
    );
  }

  Widget textField(FormFieldState field, {
    ValueChanged<String>? onChanged,
    int? maxLines,
    int? minLines,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    bool? readOnly,
  }) {
    readOnly ??= isReadOnly();

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: Dimensions.size55,
      ),
      decoration: ShapeDecoration(
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          smoothness: 1,
          side: BorderSide(
            color: borderColor(field),
          ),
        ),
        color: AppColors.surfaceContainerLowest(),
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size5,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        buildCounter: (context, {required currentLength, required isFocused, required maxLength}) {
          return const SizedBox.shrink();
        },
        maxLines: maxLines,
        minLines: minLines,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
          suffixIcon: suffixIcon(),
        ),
        maxLength: maxLengthValue(),
        readOnly: readOnly,
      ),
    );
  }

  Widget spinnerField(FormFieldState field) {
    return Material(
      child: InkWell(
        onTap: !isReadOnly() ? onPressed : null,
        customBorder: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          smoothness: 1,
        ),
        child: Ink(
          width: double.infinity,
          height: Dimensions.size55,
          decoration: ShapeDecoration(
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              smoothness: 1,
              side: BorderSide(
                color: borderColor(field),
              ),
            ),
            color: AppColors.surfaceContainerLowest(),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.size15,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.field.label(widget.data),
                  style: TextStyle(
                    fontSize: Dimensions.text16,
                  ),
                ),
              ),
              SizedBox(width: Dimensions.size10),
              Icon(
                Icons.arrow_downward,
                size: Dimensions.size20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color borderColor(FormFieldState field) {
    if (isReadOnly()) {
      return AppColors.surfaceDim();
    } else {
      if (field.hasError) {
        return AppColors.error();
      } else {
        return AppColors.outline();
      }
    }
  }

  bool isReadOnly() {
    return widget.readOnly || widget.field.readOnly;
  }
}