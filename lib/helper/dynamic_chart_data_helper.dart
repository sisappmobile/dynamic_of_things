import "package:dynamic_of_things/enumeration/chart_model.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:jiffy/jiffy.dart";

List<MapEntry<String, num>> topWithOther(
  Map<String, num> map, {
  int take = 5,
  String othersLabel = "Lainnya",
}) {
  final List<MapEntry<String, num>> sorted = map.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  if (sorted.length <= take) {
    return sorted;
  }

  final List<MapEntry<String, num>> head = sorted.take(take).toList();
  final num tailSum = sorted.skip(take).fold<num>(0, (p, e) => p + e.value);

  return <MapEntry<String, num>>[
    ...head,
    MapEntry<String, num>(othersLabel, tailSum),
  ];
}

InsightWidget buildInsight(List<Map<String, dynamic>> src) {
  final Map<String, num> byCategory = <String, num>{};
  final Map<String, num> byVariable = <String, num>{};

  num total = 0;
  int rows = 0;

  for (final Map<String, dynamic> entry in src) {
    rows += 1;

    final String category = (entry["category"] ?? "").toString().trim();
    final String variable = (entry["variable"] ?? "").toString().trim();
    final num value = parseChartNumber(entry["value"]);

    total += value;

    final String safeCategory = category.isEmpty ? "-" : category;
    final String safeVariable = variable.isEmpty ? "-" : variable;

    byCategory[safeCategory] = (byCategory[safeCategory] ?? 0) + value;
    byVariable[safeVariable] = (byVariable[safeVariable] ?? 0) + value;
  }

  return InsightWidget(
    total: total,
    rows: rows,
    compositionByVariable: topWithOther(
      byVariable,
      take: 5,
      othersLabel: "other".tr(),
    ),
    compositionByCategory: topWithOther(
      byCategory,
      take: 5,
      othersLabel: "other".tr(),
    ),
  );
}

num parseChartNumber(dynamic value) {
  if (value is num) {
    return value;
  }

  final String raw = (value ?? "").toString().trim();
  if (raw.isEmpty) {
    return 0;
  }

  String normalized = raw.replaceAll(RegExp(r"[^0-9,.\-]"), "");
  if (normalized.isEmpty ||
      normalized == "-" ||
      normalized == "." ||
      normalized == ",") {
    return 0;
  }

  if (normalized.contains(",") && normalized.contains(".")) {
    if (normalized.lastIndexOf(",") > normalized.lastIndexOf(".")) {
      normalized = normalized.replaceAll(".", "").replaceAll(",", ".");
    } else {
      normalized = normalized.replaceAll(",", "");
    }
  } else if (normalized.contains(",")) {
    if (RegExp(r",\d{1,2}$").hasMatch(normalized)) {
      normalized = normalized.replaceAll(".", "").replaceAll(",", ".");
    } else {
      normalized = normalized.replaceAll(",", "");
    }
  } else if (normalized.contains(".") &&
      !RegExp(r"\.\d{1,2}$").hasMatch(normalized)) {
    normalized = normalized.replaceAll(".", "");
  }

  return num.tryParse(normalized) ?? 0;
}

String formatChartNumber(num value) {
  final bool wholeNumber = value == value.roundToDouble();
  final NumberFormat formatter = wholeNumber
      ? NumberFormat.decimalPattern("id")
      : NumberFormat("#,##0.##", "id");
  return formatter.format(value);
}

NumberFormat chartAxisNumberFormat() {
  return NumberFormat("#,##0.##", "id");
}

String formatChartValue(dynamic value) {
  if (value == null) {
    return "";
  }

  if (value is num) {
    return formatChartNumber(value);
  }

  final String raw = value.toString().trim();
  if (raw.isEmpty) {
    return "";
  }

  final RegExpMatch? match = RegExp(r"-?[\d.,]+").firstMatch(raw);
  if (match == null) {
    return raw;
  }

  final String token = match.group(0) ?? "";
  if (token.isEmpty) {
    return raw;
  }

  final String formatted = formatChartNumber(parseChartNumber(token));
  return raw.replaceRange(match.start, match.end, formatted);
}

List<Map<String, dynamic>> normalizeChartRows(dynamic data) {
  if (data is! List) {
    if (data is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(data);
      final bool looksLikePoint = map.containsKey("value") &&
          (map.containsKey("category") || map.containsKey("variable"));
      if (looksLikePoint) {
        return <Map<String, dynamic>>[
          <String, dynamic>{
            "variable": (map["variable"] ?? "").toString().trim(),
            "category": (map["category"] ?? "").toString().trim(),
            "value": parseChartNumber(map["value"]),
          },
        ];
      }
    }
    return <Map<String, dynamic>>[];
  }

  return data.whereType<Map>().map((dynamic item) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(item as Map);
    return <String, dynamic>{
      "variable": (map["variable"] ?? "").toString().trim(),
      "category": (map["category"] ?? "").toString().trim(),
      "value": parseChartNumber(map["value"]),
    };
  }).toList();
}

class DynamicSummarySnapshot {
  final String label;
  final String value;
  final num? numericValue;

  const DynamicSummarySnapshot({
    required this.label,
    required this.value,
    required this.numericValue,
  });
}

DynamicSummarySnapshot? parseSummarySnapshot(dynamic data) {
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final String label = (map["label"] ?? "").toString().trim();
    final dynamic rawValue = map["value"];
    final String value = formatChartValue(rawValue);
    final bool hasUsableValue = value.trim().isNotEmpty;

    if (!hasUsableValue) {
      return null;
    }

    return DynamicSummarySnapshot(
      label: label,
      value: hasUsableValue ? value : "-",
      numericValue: rawValue == null ? null : parseChartNumber(rawValue),
    );
  }

  final List<Map<String, dynamic>> rows = normalizeChartRows(data);
  if (rows.isEmpty) {
    return null;
  }

  final InsightWidget insight = buildInsight(rows);
  return DynamicSummarySnapshot(
    label: "Total data",
    value: formatChartNumber(insight.total),
    numericValue: insight.total,
  );
}

class DynamicSummaryValuePresentation {
  final String headline;
  final String amount;

  const DynamicSummaryValuePresentation({
    required this.headline,
    required this.amount,
  });
}

DynamicSummaryValuePresentation splitDynamicSummaryValue(
  DynamicSummarySnapshot snapshot,
) {
  final String raw = snapshot.value.trim();
  if (raw.isEmpty) {
    return const DynamicSummaryValuePresentation(
      headline: "",
      amount: "-",
    );
  }

  if (RegExp(r"^-?\d[\d.,]*\s*/\s*-?\d[\d.,]*$").hasMatch(raw)) {
    return DynamicSummaryValuePresentation(
      headline: "",
      amount: raw.replaceAll(RegExp(r"\s*/\s*"), "/"),
    );
  }

  final RegExpMatch? match = RegExp(r"^(.*?)(-?\d[\d.,]*)$").firstMatch(raw);
  if (match != null) {
    final String headline = (match.group(1) ?? "")
        .replaceAll(RegExp(r"\s+"), " ")
        .replaceFirst(RegExp(r"[:\-\s]+$"), "")
        .trim();
    final String amount = (match.group(2) ?? "").trim();

    if (headline.isNotEmpty && amount.isNotEmpty) {
      return DynamicSummaryValuePresentation(
        headline: headline,
        amount: amount,
      );
    }
  }

  if (snapshot.numericValue != null) {
    return DynamicSummaryValuePresentation(
      headline: "",
      amount: formatChartNumber(snapshot.numericValue!),
    );
  }

  return DynamicSummaryValuePresentation(
    headline: "",
    amount: raw,
  );
}

Color summaryAccentColor(String? raw) {
  final String value = (raw ?? "").trim().toLowerCase();
  if (value.isEmpty) {
    return const Color(0xFF4C6FFF);
  }
  if (value.contains("red")) {
    return const Color(0xFFE03131);
  }
  if (value.contains("green")) {
    return const Color(0xFF2F9E44);
  }
  if (value.contains("orange")) {
    return const Color(0xFFF08C00);
  }
  if (value.contains("purple")) {
    return const Color(0xFF7B61FF);
  }
  if (value.contains("blue")) {
    return const Color(0xFF1971C2);
  }

  final String hex = value.replaceAll("#", "");
  if (hex.length == 6 || hex.length == 8) {
    final String normalized = hex.length == 6 ? "FF$hex" : hex;
    final int? parsed = int.tryParse(normalized, radix: 16);
    if (parsed != null) {
      return Color(parsed);
    }
  }

  return const Color(0xFF4C6FFF);
}

IconData summaryIcon(String? raw) {
  final String value = (raw ?? "").trim().toLowerCase();

  if (value.contains("money") || value.contains("cash")) {
    return Icons.payments_rounded;
  }
  if (value.contains("person") || value.contains("user")) {
    return Icons.person_rounded;
  }
  if (value.contains("cart") || value.contains("bag")) {
    return Icons.shopping_bag_rounded;
  }
  if (value.contains("box") || value.contains("inventory")) {
    return Icons.inventory_2_rounded;
  }
  if (value.contains("trend") || value.contains("chart")) {
    return Icons.trending_up_rounded;
  }

  return Icons.auto_graph_rounded;
}

bool sameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String buildChartDateRangeLabel(Jiffy begin, Jiffy until) {
  final String start = begin.format(pattern: "d MMM yyyy");
  final String end = until.format(pattern: "d MMM yyyy");
  return "$start - $end";
}
