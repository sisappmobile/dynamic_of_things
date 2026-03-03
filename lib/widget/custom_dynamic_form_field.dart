// ignore_for_file: empty_catches, use_build_context_synchronously, deprecated_member_use, depend_on_referenced_packages

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:camera/camera.dart";
import "package:collection/collection.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/enumeration/dynamic_form_field_type.dart";
import "package:dynamic_of_things/enumeration/dynamic_form_validation_type.dart";
import "package:dynamic_of_things/helper/bottom_sheets.dart";
import "package:dynamic_of_things/helper/custom_attachments.dart";
import "package:dynamic_of_things/helper/dialogs.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/helper/formats.dart";
import "package:dynamic_of_things/helper/images.dart";
import "package:dynamic_of_things/helper/offlines.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/model/attachment.dart";
import "package:dynamic_of_things/model/dynamic_form_resource_response.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_bloc.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_event.dart";
import "package:dynamic_of_things/widget/barcode_scanner_page.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:dynamic_of_things/widget/signature_page.dart";
import "package:dynamic_of_things/widget/spinner_page.dart";
import "package:easy_localization/easy_localization.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_image_compress/flutter_image_compress.dart";
import "package:get/get_utils/src/extensions/internacionalization.dart"
    hide Trans;
import "package:go_router/go_router.dart";
import "package:loader_overlay/loader_overlay.dart";
import "package:material_symbols_icons/material_symbols_icons.dart";
import "package:mime/mime.dart";
import "package:mobile_scanner/mobile_scanner.dart";
import "package:pattern_formatter/numeric_formatter.dart";
import "package:smooth_corner/smooth_corner.dart";
import "package:validators/validators.dart";
import "package:video_player/video_player.dart";
import "package:video_thumbnail/video_thumbnail.dart" as vt;

class CustomDynamicFormField extends StatefulWidget {
  final bool readOnly;
  final String? customerId;
  final HeaderForm headerForm;
  final Template template;
  final Field field;
  final Map<String, dynamic> data;

  const CustomDynamicFormField({
    required this.readOnly,
    required this.customerId,
    required this.headerForm,
    required this.template,
    required this.field,
    required this.data,
    super.key,
  });

  @override
  State<CustomDynamicFormField> createState() => CustomDynamicFormFieldState();
}

class CustomDynamicFormFieldState extends State<CustomDynamicFormField> {
  TextEditingController controller = TextEditingController();

  static const double _r = 14;

  bool get isGlass {
    try {
      return (Preferences.getInstance()
                  .getInt(SharedPreferenceKey.DASHBOARD_UI_TYPE) ??
              1) ==
          2;
    } catch (_) {
      return false;
    }
  }

  Color soft(BuildContext c) {
    if (isGlass) {
      return Colors.white.withOpacity(0.08);
    }
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.surfaceContainer()
        : AppColors.surfaceContainerLowest();
  }

  Color pillBg(BuildContext c) {
    if (isGlass) {
      return Colors.white.withOpacity(0.10);
    }
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.surfaceContainerLow()
        : AppColors.surfaceContainerLowest();
  }

  Color primary(BuildContext c) => Theme.of(c).colorScheme.primary;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    controller.text = widget.field.label(widget.data);

    return ListenableBuilder(
      listenable: widget.field,
      builder: (context, child) {
        if (!StringUtils.inList(widget.field.type, [
              DynamicFormFieldType.SHORT_TEXT.name,
              DynamicFormFieldType.LONG_TEXT.name,
              DynamicFormFieldType.NUMBER.name,
              DynamicFormFieldType.EMAIL.name,
              DynamicFormFieldType.URL.name,
            ]) ||
            widget.field.forceRefresh) {
          controller.text = widget.field.label(widget.data);

          widget.field.forceRefresh = false;
        }

        return body();
      },
    );
  }

  Widget wrapCard({
    required Widget child,
    EdgeInsets? padding,
  }) {
    if (isGlass) {
      return GlassContainer(
        blur: Dimensions.size20,
        borderRadius: Dimensions.size20,
        opacity: 0.12,
        borderOpacity: 0.22,
        padding: padding ?? EdgeInsets.all(Dimensions.size10),
        child: child,
      );
    }

    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(Dimensions.size10),
      decoration: ShapeDecoration(
        color: isGlass ? Colors.white.withOpacity(0.10) : AppColors.surface(),
        shadows: [
          BoxShadow(
            blurRadius: Dimensions.size20,
            offset: Offset(0, Dimensions.size10),
            color: Colors.black.withValues(
              alpha:
                  Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.06,
            ),
          ),
        ],
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: isGlass
                ? Colors.white.withOpacity(0.18)
                : AppColors.outline().withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.26
                        : 0.16,
                  ),
          ),
        ),
      ),
      child: child,
    );
  }

  Widget chip({
    required String text,
    IconData? icon,
    Color? color,
  }) {
    final Color c = color ?? primary(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size10,
        vertical: Dimensions.size5,
      ),
      decoration: BoxDecoration(
        color: c.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.10,
        ),
        borderRadius: BorderRadius.circular(Dimensions.size100),
        border: Border.all(
          color: c.withValues(
            alpha:
                Theme.of(context).brightness == Brightness.dark ? 0.32 : 0.22,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: Dimensions.size15, color: c),
            SizedBox(width: Dimensions.size5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: Dimensions.text11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget body() {
    if (widget.field.type == DynamicFormFieldType.SHORT_TEXT.name) {
      if (widget.readOnly && widget.field.linkUrl) {
        return NetworkVideoPlayer(url: widget.field.getValue(widget.data));
      } else {
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
      }
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
              onChanged: (value) => widget.field
                  .setValue(widget.data, Formats.tryParseNumber(value)),
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
                final bool selected =
                    string == widget.field.getValue(widget.data);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: !isReadOnly() ? () => changed(string) : null,
                    borderRadius: BorderRadius.circular(Dimensions.size15),
                    child: Ink(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.size10,
                        vertical: Dimensions.size10,
                      ),
                      decoration: ShapeDecoration(
                        color: soft(context),
                        shape: SmoothRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.size15),
                          smoothness: Dimensions.size1,
                          side: BorderSide(
                            color: selected
                                ? primary(context).withValues(alpha: 0.30)
                                : isGlass
                                    ? Colors.white.withOpacity(0.18)
                                    : AppColors.outline().withValues(
                                        alpha: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? 0.28
                                            : 0.18,
                                      ),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            height: Dimensions.size25,
                            width: Dimensions.size25,
                            child: Radio(
                              value: string,
                              groupValue: widget.field.getValue(widget.data),
                              onChanged: !isReadOnly()
                                  ? (value) => changed(value)
                                  : null,
                            ),
                          ),
                          SizedBox(width: Dimensions.size10),
                          Expanded(
                            child: Text(
                              string,
                              style: TextStyle(
                                fontSize: Dimensions.text14,
                                fontWeight: FontWeight.w800,
                                color: isGlass
                                    ? Colors.white.withOpacity(0.92)
                                    : AppColors.onSurface(),
                              ),
                            ),
                          ),
                          if (selected)
                            chip(
                              text: "Selected",
                              icon: Icons.check_rounded,
                              color: primary(context),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) =>
                  SizedBox(height: Dimensions.size10),
              itemCount: widget.field.data.length,
            ),
          );
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.CHECK.name) {
      return FormField(
        validator: (value) {
          return validate();
        },
        builder: (field) {
          final bool v = (widget.field.getValue(widget.data) ?? false) as bool;

          return formField(
            field: field,
            body: wrapCard(
              padding: EdgeInsets.fromLTRB(
                Dimensions.size10,
                Dimensions.size10,
                Dimensions.size10,
                Dimensions.size10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.field.label(widget.data),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: isGlass
                            ? Colors.white.withOpacity(0.92)
                            : AppColors.onSurface(),
                      ),
                    ),
                  ),
                  Switch(
                    value: v,
                    onChanged: !isReadOnly()
                        ? (value) {
                            setState(() {
                              widget.field.setValue(widget.data, value);
                            });

                            if (widget.field.hasScript) {
                              context.read<DynamicFormBloc>().add(
                                    DynamicFormRefresh(
                                      formId: widget.headerForm.template.id,
                                      customerId: widget.customerId,
                                      headerForm: widget.headerForm,
                                    ),
                                  );
                            }
                          }
                        : null,
                  ),
                ],
              ),
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
    } else if (StringUtils.inList(widget.field.type, [
      DynamicFormFieldType.FILE.name,
      DynamicFormFieldType.FOTO.name,
      DynamicFormFieldType.VIDEO.name,
      DynamicFormFieldType.SIGNATURE.name,
      DynamicFormFieldType.UPLOAD_FOTO.name,
      DynamicFormFieldType.UPLOAD_VIDEO.name,
      DynamicFormFieldType.UPLOAD_SIGNATURE.name,
    ])) {
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

    Validation? validation = widget.field.validations.firstWhereOrNull(
      (element) => element.type == DynamicFormValidationType.CONTAINS.name,
    );

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
    if (!isReadOnly() &&
        StringUtils.inList(widget.field.type, [
          DynamicFormFieldType.SHORT_TEXT.name,
          DynamicFormFieldType.LONG_TEXT.name,
          DynamicFormFieldType.NUMBER.name,
          DynamicFormFieldType.EMAIL.name,
          DynamicFormFieldType.URL.name,
        ])) {
      return IconButton(
        icon: const Icon(Icons.more_vert),
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
                      silent: false,
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
    } else if (!isReadOnly() &&
        StringUtils.inList(widget.field.type, [
          DynamicFormFieldType.QRCODE.name,
          DynamicFormFieldType.BARCODE.name,
        ])) {
      return IconButton(
        icon: const Icon(Icons.qr_code_scanner),
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
              silent: false,
              formats: barcodeFormats,
              onSuccess: (data) {
                widget.field.setValue(widget.data, data);
              },
            ),
          );
        },
      );
    } else if (StringUtils.inList(widget.field.type, [
      DynamicFormFieldType.DATE.name,
      DynamicFormFieldType.DATE_TIME.name,
    ])) {
      return IconButton(
        icon: const Icon(Icons.event),
        onPressed: !isReadOnly() ? () => onPressed() : null,
      );
    } else if (StringUtils.inList(widget.field.type, [
      DynamicFormFieldType.TIME.name,
    ])) {
      return IconButton(
        icon: const Icon(Icons.access_time),
        onPressed: !isReadOnly() ? () => onPressed() : null,
      );
    } else {
      return null;
    }
  }

  String? notContains(String? value) {
    value ??= "";

    Validation? validation = widget.field.validations.firstWhereOrNull(
      (element) => element.type == DynamicFormValidationType.NOT_CONTAINS.name,
    );

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

    Validation? validation = widget.field.validations.firstWhereOrNull(
      (element) => element.type == DynamicFormValidationType.MIN_LENGTH.name,
    );

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
    Validation? validation = widget.field.validations.firstWhereOrNull(
      (element) => element.type == DynamicFormValidationType.MAX_LENGTH.name,
    );

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

    Validation? validation = widget.field.validations.firstWhereOrNull(
      (element) => element.type == DynamicFormValidationType.MAX_LENGTH.name,
    );

    if (validation != null) {
      int? maxLength = maxLengthValue();

      if (maxLength != null) {
        if (value.length > maxLength) {
          if (StringUtils.isNotNullOrEmpty(validation.errorMessage)) {
            return validation.errorMessage;
          } else {
            return "maximum_character_is"
                .tr(args: [validation.value.toString()]);
          }
        }
      }
    }

    return null;
  }

  String? greaterThan(int value) {
    Validation? validation = widget.field.validations.firstWhereOrNull(
      (element) => element.type == DynamicFormValidationType.GREATER_THAN.name,
    );

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
          return "value_must_be_greater_than"
              .tr(args: [validation.value.toString()]);
        }
      }
    }

    return null;
  }

  String? greaterThanOrEqualTo(int value) {
    Validation? validation = widget.field.validations.firstWhereOrNull(
      (element) =>
          element.type ==
          DynamicFormValidationType.GREATER_THAN_OR_EQUAL_TO.name,
    );

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
          return "value_must_be_greater_than_or_equal_to"
              .tr(args: [validation.value.toString()]);
        }
      }
    }

    return null;
  }

  String? lessThan(int value) {
    Validation? validation = widget.field.validations.firstWhereOrNull(
      (element) => element.type == DynamicFormValidationType.LESS_THAN.name,
    );

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
          return "value_must_be_less_than"
              .tr(args: [validation.value.toString()]);
        }
      }
    }

    return null;
  }

  String? lessThanOrEqualTo(int value) {
    Validation? validation = widget.field.validations.firstWhereOrNull(
      (element) =>
          element.type == DynamicFormValidationType.LESS_THAN_OR_EQUAL_TO.name,
    );

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
          return "value_must_be_less_than_or_equal_to"
              .tr(args: [validation.value.toString()]);
        }
      }
    }

    return null;
  }

  String? email(String? value) {
    value ??= "";

    if (StringUtils.isNotNullOrEmpty(value)) {
      if (!RegExp(
        r'^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
      ).hasMatch(value)) {
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
    Validation? validation = widget.field.validations.firstWhereOrNull(
      (element) => element.type == DynamicFormValidationType.BEFORE.name,
    );

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
    Validation? validation = widget.field.validations.firstWhereOrNull(
      (element) => element.type == DynamicFormValidationType.AFTER.name,
    );

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

        if (widget.field.hasScript) {
          context.read<DynamicFormBloc>().add(
                DynamicFormRefresh(
                  formId: widget.headerForm.template.id,
                  customerId: widget.customerId,
                  headerForm: widget.headerForm,
                ),
              );
        }
      }
    } else if (widget.field.type == DynamicFormFieldType.TIME.name) {
      TimeOfDay? timeOfDay = await showTimePicker(
        context: context,
        initialTime: initialTime(),
      );

      if (timeOfDay != null) {
        widget.field.setValue(widget.data, timeOfDay);

        if (widget.field.hasScript) {
          context.read<DynamicFormBloc>().add(
                DynamicFormRefresh(
                  formId: widget.headerForm.template.id,
                  customerId: widget.customerId,
                  headerForm: widget.headerForm,
                ),
              );
        }
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

            if (widget.field.hasScript) {
              context.read<DynamicFormBloc>().add(
                    DynamicFormRefresh(
                      formId: widget.headerForm.template.id,
                      customerId: widget.customerId,
                      headerForm: widget.headerForm,
                    ),
                  );
            }
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

        if (StringUtils.inList(
          platformFile.extension!,
          ["jpg", "jpeg", "png"],
        )) {
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
          Attachment attachment = Attachment()
            ..name = DateTime.now().millisecondsSinceEpoch.toString()
            ..mime = "image/png"
            ..bytes = bytes;
          widget.field.setValue(widget.data, attachment);
        },
      );
    } else if (widget.field.type == DynamicFormFieldType.VIDEO.name) {
      await availableCameras().then((value) {
        Navigators.push(
          RecordPage(
            cameraDescriptions: value,
            callback: (xFile) async {
              Attachment attachment = Attachment()
                ..name = DateTime.now().millisecondsSinceEpoch.toString()
                ..mime = "video/mp4"
                ..bytes = await xFile.readAsBytes()
                ..thumbnail = await vt.VideoThumbnail.thumbnailData(
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
            Attachment attachment = Attachment()
              ..name = files.first.name
              ..mime = files.first.mimeType
              ..bytes = await files.first.readAsBytes();
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
            Attachment attachment = Attachment()
              ..name = files.first.name
              ..mime = "video/${files.first.extension}"
              ..bytes = files.first.bytes
              ..thumbnail = await vt.VideoThumbnail.thumbnailData(
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
        spinnerItems: widget.field.data
            .map((e) => SpinnerItem(identity: e, description: e))
            .toList(),
      );

      if (selectedItem != null) {
        changed(selectedItem.identity);
      }
    } else if (widget.field.type == DynamicFormFieldType.DROPDOWN_DATA.name) {
      DynamicFormResourceResponse? dynamicFormResourceResponse;

      if (DynamicForms.offline) {
        dynamicFormResourceResponse = await Offlines.resource(
          headerForm: widget.headerForm,
          name: widget.field.name,
          data: widget.data,
        );
      } else {
        try {
          context.loaderOverlay.show();

          dynamicFormResourceResponse =
              await DotApis.getInstance().dynamicFormResource(
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
      }

      if (dynamicFormResourceResponse != null) {
        Map<String, dynamic>? selectedItem = await Navigators.push(
          SpinnerPage(
            headerForm: widget.headerForm,
            title: widget.field.title,
            name: widget.field.name,
            data: widget.data,
            dynamicFormResourceResponse: dynamicFormResourceResponse,
            customerId: widget.customerId,
          ),
        );

        if (selectedItem != null) {
          dynamic value = selectedItem[dynamicFormResourceResponse.key];

          if (widget.field.link != null) {
            String linkValue = selectedItem[widget.field.link!.source];
            widget.data[widget.field.link!.target] = linkValue;
          }

          widget.field.setValue(widget.data, value);

          if (dynamicFormResourceResponse.loadOnFields.isNotEmpty) {
            for (DynamicFormResourceLoadOnFieldItem item
                in dynamicFormResourceResponse.loadOnFields) {
              if (!item.detail) {
                dynamic v = selectedItem[item.source];

                if (v != null) {
                  bool found = false;

                  for (Section section in widget.template.sections) {
                    for (Field f in section.fields) {
                      if (StringUtils.equalsIgnoreCase(f.name, item.target)) {
                        f
                          ..setValue(
                            widget.data,
                            await DynamicForms.decodeValue(
                              field: f,
                              value: v,
                            ),
                          )
                          ..forceRefresh = true;
                        found = true;
                      }
                    }
                  }

                  if (!found) {
                    widget.data[item.target] = v;
                  }
                }
              }
            }
          }

          if (widget.field.getValue(widget.data) != null) {
            for (Section section in widget.template.sections) {
              for (Field f in section.fields) {
                if (StringUtils.isNotNullOrEmpty(f.enableAfter)) {
                  if (StringUtils.equalsIgnoreCase(
                    f.enableAfter,
                    widget.field.name,
                  )) {
                    f.enable();
                  }
                }
              }
            }
          }

          bool needRefresh = false;

          if (dynamicFormResourceResponse.detailSetups.isNotEmpty) {
            List<Map<String, dynamic>> details = selectedItem["details"] != null
                ? List<Map<String, dynamic>>.from(
                    selectedItem["details"].map((e) => e),
                  )
                : [];

            DetailForm? detailForm = widget.headerForm.detailForms.firstOrNull;

            if (detailForm != null) {
              if (details.isNotEmpty) {
                for (Map<String, dynamic> detail in details) {
                  Map<String, dynamic> row = {};

                  for (String key in detail.keys) {
                    for (Section section in detailForm.template.sections) {
                      for (Field f in section.fields) {
                        if (f.name == key) {
                          f.setValue(row, detail[key]);
                        }
                      }
                    }
                  }

                  detailForm.addRow(widget.headerForm, row);
                }

                if (detailForm.hasOnChangeEvent) {
                  needRefresh = true;
                }
              }
            }
          }

          if (needRefresh || widget.field.hasScript) {
            context.read<DynamicFormBloc>().add(
                  DynamicFormRefresh(
                    formId: widget.headerForm.template.id,
                    customerId: widget.customerId,
                    headerForm: widget.headerForm,
                  ),
                );
          }

          if (!DynamicForms.offline &&
              widget.headerForm.detailForms.isNotEmpty) {
            try {
              context.loaderOverlay.show();

              Map<String, dynamic>? result =
                  await DotApis.getInstance().dynamicFormSelect(
                formId: widget.template.id,
                name: widget.field.name,
                value: value,
                customerId: widget.customerId,
              );

              if (result != null) {
                for (DetailForm detailForm in widget.headerForm.detailForms) {
                  List<Map<String, dynamic>> details =
                      result[detailForm.template.tableName] != null
                          ? List<Map<String, dynamic>>.from(
                              result[detailForm.template.tableName]
                                  .map((e) => e),
                            )
                          : [];

                  if (details.isNotEmpty) {
                    for (Map<String, dynamic> detail in details) {
                      Map<String, dynamic> row = {};

                      for (String key in detail.keys) {
                        for (Section section in detailForm.template.sections) {
                          for (Field f in section.fields) {
                            if (f.name == key) {
                              f.setValue(row, detail[key]);
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
              BaseOverlays.error(
                message: "something_wrong_please_try_again".tr(),
              );
            } finally {
              context.loaderOverlay.hide();
            }
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

    if (widget.field.hasScript) {
      context.read<DynamicFormBloc>().add(
            DynamicFormRefresh(
              formId: widget.headerForm.template.id,
              customerId: widget.customerId,
              headerForm: widget.headerForm,
            ),
          );
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
    Validation? validation = widget.field.validations.firstWhereOrNull(
      (element) => element.type == DynamicFormValidationType.AFTER.name,
    );

    if (validation != null) {
      return DateTime.parse(validation.value);
    }

    return null;
  }

  DateTime? maxDate() {
    Validation? validation = widget.field.validations.firstWhereOrNull(
      (element) => element.type == DynamicFormValidationType.BEFORE.name,
    );

    if (validation != null) {
      return DateTime.parse(validation.value);
    }

    return null;
  }

  TimeOfDay? minTime() {
    Validation? validation = widget.field.validations.firstWhereOrNull(
      (element) => element.type == DynamicFormValidationType.AFTER.name,
    );

    if (validation != null) {
      return Formats.parseTime(validation.value);
    }

    return null;
  }

  TimeOfDay? maxTime() {
    Validation? validation = widget.field.validations.firstWhereOrNull(
      (element) => element.type == DynamicFormValidationType.BEFORE.name,
    );

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
        result = contains(value?.toString());
        if (result != null) {
          return result;
        }

        result = notContains(value?.toString());
        if (result != null) {
          return result;
        }

        result = minLength(value?.toString());
        if (result != null) {
          return result;
        }

        result = maxLength(value?.toString());
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
    } else if (StringUtils.inList(widget.field.type, [
      DynamicFormFieldType.FILE.name,
      DynamicFormFieldType.FOTO.name,
      DynamicFormFieldType.VIDEO.name,
      DynamicFormFieldType.SIGNATURE.name,
      DynamicFormFieldType.UPLOAD_FOTO.name,
      DynamicFormFieldType.UPLOAD_VIDEO.name,
      DynamicFormFieldType.UPLOAD_SIGNATURE.name,
      DynamicFormFieldType.QRCODE.name,
      DynamicFormFieldType.BARCODE.name,
    ])) {
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
      return actionPill(
        icon: Symbols.signature,
        text: "signature".tr().toUpperCase(),
        onTap: () async {
          Uint8List? bytes = await Navigators.push(SignaturePage());

          if (bytes != null) {
            Attachment attachment = Attachment()
              ..name = DateTime.now().millisecondsSinceEpoch.toString()
              ..mime = "image/png"
              ..bytes = bytes;

            widget.field.setValue(widget.data, attachment);
          }
        },
      );
    }

    List<Widget> widgets = [];

    if (!isReadOnly()) {
      if (widget.field.type == DynamicFormFieldType.VIDEO.name) {
        widgets.add(
          actionPill(
            icon: Icons.video_call,
            text: "record_video".tr().toUpperCase(),
            onTap: () => onPressed(),
          ),
        );
      } else if (widget.field.type == DynamicFormFieldType.FOTO.name) {
        widgets.add(
          actionPill(
            icon: Icons.camera_alt,
            text: "take_photo".tr().toUpperCase(),
            onTap: () => onPressed(),
          ),
        );
      } else if (widget.field.type == DynamicFormFieldType.SIGNATURE.name) {
        widgets.add(signatureButton());
      } else {
        widgets.add(
          Wrap(
            spacing: Dimensions.size10,
            runSpacing: Dimensions.size10,
            children: [
              actionPill(
                icon: Icons.upload,
                text: "choose_file".tr().toUpperCase(),
                onTap: () => onPressed(),
              ),
              Visibility(
                visible: widget.field.type ==
                    DynamicFormFieldType.UPLOAD_SIGNATURE.name,
                child: signatureButton(),
              ),
            ],
          ),
        );
      }
    }

    if (widget.field.getValue(widget.data) != null) {
      widgets.add(SizedBox(height: Dimensions.size10));

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
            color: primary(context).withValues(alpha: 0.12),
            child: Center(
              child: Text(
                attachment.name ?? "",
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isGlass
                      ? Colors.white.withOpacity(0.92)
                      : AppColors.onSurface(),
                  fontSize: Dimensions.text12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.size15),
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
                            imageProvider: MemoryImage(
                              attachment.thumbnail ?? attachment.bytes!,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                Positioned(
                  right: Dimensions.size10,
                  bottom: Dimensions.size10,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.size10,
                      vertical: Dimensions.size5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(Dimensions.size100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          attachment.thumbnail != null
                              ? Icons.play_arrow_rounded
                              : Icons.open_in_full_rounded,
                          size: Dimensions.size15,
                          color: Colors.white,
                        ),
                        SizedBox(width: Dimensions.size5),
                        Text(
                          attachment.thumbnail != null ? "Preview" : "Open",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Dimensions.text11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      widgets.add(
        wrapCard(
          padding: EdgeInsets.all(Dimensions.size10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: Dimensions.size100,
                height: Dimensions.size100,
                child: thumbnailWidget,
              ),
              SizedBox(width: Dimensions.size10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.name ?? "-",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: isGlass
                            ? Colors.white.withOpacity(0.92)
                            : AppColors.onSurface(),
                        fontSize: Dimensions.text13,
                      ),
                    ),
                    SizedBox(height: Dimensions.size5),
                    Text(
                      attachment.mime ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isGlass
                            ? Colors.white.withOpacity(0.92)
                            : AppColors.onSurface().withValues(alpha: 0.65),
                        fontSize: Dimensions.text12,
                      ),
                    ),
                    if (!isReadOnly()) ...[
                      SizedBox(height: Dimensions.size10),
                      dangerPill(
                        icon: Icons.delete_rounded,
                        text: "delete".tr().toUpperCase(),
                        onTap: () {
                          widget.field.setValue(widget.data, null);
                        },
                      ),
                    ],
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

  Widget actionPill({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.size20),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.size10,
            vertical: Dimensions.size10,
          ),
          decoration: ShapeDecoration(
            color: pillBg(context),
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size20),
              smoothness: Dimensions.size1,
              side: BorderSide(
                color: isGlass
                    ? Colors.white.withOpacity(0.18)
                    : AppColors.outline().withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.28
                            : 0.18,
                      ),
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: Dimensions.size30,
                height: Dimensions.size30,
                decoration: BoxDecoration(
                  color: primary(context).withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.16
                        : 0.12,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primary(context).withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.30
                          : 0.22,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  size: Dimensions.size20,
                  color: primary(context),
                ),
              ),
              SizedBox(width: Dimensions.size10),
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                  color: isGlass
                      ? Colors.white.withOpacity(0.92)
                      : AppColors.onSurface(),
                  fontSize: Dimensions.text12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget dangerPill({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final Color c = AppColors.error();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.size20),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.size10,
            vertical: Dimensions.size10,
          ),
          decoration: ShapeDecoration(
            color: c.withValues(alpha: 0.08),
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size20),
              smoothness: Dimensions.size1,
              side: BorderSide(color: c.withValues(alpha: 0.22)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: Dimensions.size20, color: c),
              SizedBox(width: Dimensions.size10),
              Text(
                text,
                style: TextStyle(
                  fontSize: Dimensions.text12,
                  fontWeight: FontWeight.w900,
                  color: c,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget helperWidget(FormFieldState field) {
    List<Widget> widgets = [];

    if (field.hasError) {
      widgets.add(
        Expanded(
          child: Container(
            padding: EdgeInsets.all(Dimensions.size10),
            decoration: ShapeDecoration(
              color: AppColors.error().withValues(alpha: 0.08),
              shape: SmoothRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.size15),
                smoothness: Dimensions.size1,
                side: BorderSide(
                  color: AppColors.error().withValues(alpha: 0.22),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error, color: AppColors.error()),
                SizedBox(width: Dimensions.size10),
                Expanded(
                  child: Text(
                    field.errorText ?? "",
                    style: TextStyle(
                      fontSize: Dimensions.text12,
                      color: AppColors.error(),
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
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
              fontSize: Dimensions.text11,
              fontWeight: FontWeight.w900,
              color: isGlass
                  ? Colors.white.withOpacity(0.92)
                  : AppColors.onSurface().withValues(alpha: 0.55),
            ),
          ),
        );
      }
    }

    if (widgets.isNotEmpty) {
      return Container(
        margin: EdgeInsets.only(top: Dimensions.size10),
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
        SizedBox(height: Dimensions.size10),
        body,
        helperWidget(field),
      ],
    );
  }

  Widget labelWidget() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.field.title,
            style: TextStyle(
              fontSize: Dimensions.text13,
              fontWeight: FontWeight.w900,
              color: isGlass
                  ? Colors.white.withOpacity(0.92)
                  : AppColors.onSurface(),
              letterSpacing: 0.1,
            ),
          ),
        ),
        if (widget.field.required) chip(text: "Required"),
      ],
    );
  }

  Widget textField(
    FormFieldState field, {
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
      constraints: BoxConstraints(minHeight: Dimensions.size55),
      decoration: ShapeDecoration(
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(_r),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: borderColor(field),
          ),
        ),
        color: soft(context),
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size10,
        vertical: Dimensions.size2,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: isGlass
            ? Colors.white.withOpacity(0.92)
            : Theme.of(context).colorScheme.primary,
        style: TextStyle(
          color:
              isGlass ? Colors.white.withOpacity(0.95) : AppColors.onSurface(),
        ),
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        buildCounter: (
          context, {
          required currentLength,
          required isFocused,
          required maxLength,
        }) {
          return const SizedBox.shrink();
        },
        maxLines: maxLines,
        minLines: minLines,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: readOnly ? null : widget.field.title,
          hintStyle: TextStyle(
            color: isGlass
                ? Colors.white.withOpacity(0.92)
                : AppColors.onSurface().withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.55
                        : 0.45,
                  ),
            fontWeight: FontWeight.w700,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: Dimensions.size5,
            vertical: Dimensions.size15,
          ),
          suffixIcon: suffixIcon() != null
              ? Container(
                  margin: EdgeInsets.only(right: Dimensions.size5),
                  decoration: BoxDecoration(
                    color: isGlass
                        ? Colors.white.withOpacity(0.16)
                        : Theme.of(context).brightness == Brightness.dark
                            ? AppColors.surfaceContainerHigh()
                            : isGlass
                                ? Colors.white.withOpacity(0.10)
                                : AppColors.surface(),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isGlass
                          ? Colors.white.withOpacity(0.18)
                          : AppColors.outline().withValues(
                              alpha: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? 0.30
                                  : 0.18,
                            ),
                    ),
                  ),
                  child: suffixIcon(),
                )
              : null,
        ),
        maxLength: maxLengthValue(),
        readOnly: readOnly,
      ),
    );
  }

  Widget spinnerField(FormFieldState field) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: !isReadOnly() ? onPressed : null,
        customBorder: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(_r),
          smoothness: Dimensions.size1,
        ),
        child: Ink(
          width: double.infinity,
          height: Dimensions.size55,
          decoration: ShapeDecoration(
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(_r),
              smoothness: 1,
              side: BorderSide(
                color: borderColor(field),
              ),
            ),
            color: soft(context),
          ),
          padding: EdgeInsets.symmetric(horizontal: Dimensions.size15),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.field.label(widget.data),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Dimensions.text14,
                    fontWeight: FontWeight.w900,
                    color: isGlass
                        ? Colors.white.withOpacity(0.92)
                        : AppColors.onSurface(),
                  ),
                ),
              ),
              SizedBox(width: Dimensions.size10),
              Container(
                width: Dimensions.size30,
                height: Dimensions.size30,
                decoration: BoxDecoration(
                  color: isGlass
                      ? Colors.white.withOpacity(0.16)
                      : Theme.of(context).brightness == Brightness.dark
                          ? AppColors.surfaceContainerHigh()
                          : isGlass
                              ? Colors.white.withOpacity(0.10)
                              : AppColors.surface(),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isGlass
                        ? Colors.white.withOpacity(0.18)
                        : AppColors.outline().withValues(
                            alpha:
                                Theme.of(context).brightness == Brightness.dark
                                    ? 0.30
                                    : 0.18,
                          ),
                  ),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: Dimensions.size20,
                  color: isGlass
                      ? Colors.white.withOpacity(0.92)
                      : AppColors.onSurface().withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.88
                              : 0.75,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color borderColor(FormFieldState field) {
    if (isReadOnly()) {
      return isGlass ? Colors.white.withOpacity(0.25) : AppColors.surfaceDim();
    } else {
      if (field.hasError) {
        return AppColors.error();
      } else {
        return isGlass
            ? Colors.white.withOpacity(0.18)
            : AppColors.outline().withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.55
                    : 1.0,
              );
      }
    }
  }

  bool isReadOnly() {
    return widget.readOnly || widget.field.readOnly;
  }
}

class NetworkVideoPlayer extends StatefulWidget {
  final String url;

  const NetworkVideoPlayer({required this.url, super.key});

  @override
  State<NetworkVideoPlayer> createState() => NetworkVideoPlayerState();
}

class NetworkVideoPlayerState extends State<NetworkVideoPlayer> {
  late VideoPlayerController controller;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        controller.play();

        setState(() {
          isInitialized = true;
        });
      });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(controller),
          VideoProgressIndicator(controller, allowScrubbing: true),
          Center(
            child: IconButton(
              icon: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 48,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  controller.value.isPlaying
                      ? controller.pause()
                      : controller.play();
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
