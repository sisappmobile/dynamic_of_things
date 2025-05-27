import "package:base/base.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:jiffy/jiffy.dart";

class Formats {
  static Jiffy? tryParseJiffy(dynamic value) {
    if (value != null) {
      if (value is String) {
        try {
          return Jiffy.parse(value);
        } catch (ex) {
          try {
            return Jiffy.parseFromDateTime(DateTime.parse(value));
          } catch (_) {}
        }
      } else if (value is int) {
        try {
          return Jiffy.parseFromMillisecondsSinceEpoch(value);
        } catch (_) {}
      } else if (value is DateTime) {
        try {
          return Jiffy.parseFromDateTime(value.toLocal());
        } catch (_) {}
      }
    }

    return null;
  }

  static num tryParseNumber(dynamic value) {
    if (value != null) {
      if (value is String) {
        try {
          return NumberFormat("", "id").parse(value);
        } catch (ignored) {
          return num.tryParse(value) ?? 0;
        }
      } else if (value is int) {
        return value;
      } else if (value is double) {
        return value;
      } else {
        return 0;
      }
    } else {
      return 0;
    }
  }

  static bool tryParseBool(dynamic value) {
    if (value != null) {
      if (value is String) {
        try {
          return bool.parse(value);
        } catch (ex) {
          return value == "Y";
        }
      } else if (value is int) {
        return value == 1;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  static TimeOfDay parseTime(String string) {
    return TimeOfDay(hour: int.parse(string.split(":")[0]), minute: int.parse(string.split(":")[1]));
  }

  static String date(dynamic value, {String? defaultString}) {
    if (value != null) {
      if (value is DateTime) {
        return DateFormat("d MMM ''yy", "id").format(value.toLocal());
      } else if (value is Jiffy) {
        return value.toLocal().format(pattern: "d MMM 'yy");
      }
    }

    return defaultString ?? "common_n/a".tr();
  }

  static String time(TimeOfDay? timeOfDay, {String? defaultString}) {
    if (timeOfDay != null) {
      return const DefaultMaterialLocalizations().formatTimeOfDay(timeOfDay, alwaysUse24HourFormat: true);
    } else {
      return defaultString ?? "common_n/a".tr();
    }
  }

  static String dateTime(dynamic value, {String? defaultString}) {
    if (value != null) {
      if (value is DateTime) {
        return DateFormat("d MMM ''yy HH:mm", "id").format(value.toLocal());
      } else if (value is Jiffy) {
        return value.toLocal().format(pattern: "d MMM 'yy HH:mm");
      }
    }

    return defaultString ?? "common_n/a".tr();
  }

  static Map<String, dynamic> convert(Map<String, dynamic> map) {
    map.forEach((key, value) {
      if (value != null) {
        if (value is Jiffy) {
          map[key] = value.format();
        } else if (value is DateTime) {
          map[key] = Jiffy.parseFromDateTime(value).dateFormat();
        } else if (value is List) {
          for (dynamic detailValue in value) {
            if (detailValue is Jiffy) {
              detailValue = detailValue.format();
            } else if (detailValue is DateTime) {
              detailValue = Jiffy.parseFromDateTime(detailValue).dateFormat();
            } else if (detailValue is Map<String, dynamic>) {
              convert(detailValue);
            }
          }
        } else if (value is Map<String, dynamic>) {
          convert(value);
        }
      }
    });

    return map;
  }
}