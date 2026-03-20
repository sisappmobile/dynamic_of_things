class PgToSqliteConverter {
  final _protector = _StringProtector();

  String convert(String sql) {
    String result = sql;

    // 1. Protect string literals
    result = _protector.protect(result);

    // 2. Structural transforms (must come first)
    result = _convertZippedUnnest(result);
    result = _convertExtract(result);

    // 3. Expression transforms
    result = _convertCastingOperator(result);
    result = _convertBoolean(result);

    // 4. Cleanup
    result = _cleanup(result);

    // 5. Restore string literals
    result = _protector.restore(result);

    return result.trim();
  }

  // =========================
  // 🔐 STRING PROTECTION
  // =========================
  String _cleanup(String sql) {
    return sql.replaceAll(RegExp(r"\s+"), " ");
  }

  // =========================
  // 🔥 ZIPPED UNNEST HANDLER
  // =========================
  String _convertZippedUnnest(String sql) {
    final regex = RegExp(
      r"unnest\(array\[(.*?)\]\)\s+as\s+(\w+)\s*,\s*unnest\(array\[(.*?)\]\)\s+as\s+(\w+)",
      caseSensitive: false,
    );

    return sql.replaceAllMapped(regex, (match) {
      final list1 = match.group(1)!.split(",");
      final col1 = match.group(2)!;

      final list2 = match.group(3)!.split(",");
      final col2 = match.group(4)!;

      if (list1.length != list2.length) {
        throw Exception("Unnest arrays length mismatch");
      }

      final rows = <String>[];

      for (int i = 0; i < list1.length; i++) {
        rows.add(
          "SELECT ${list1[i].trim()} AS $col1, ${list2[i].trim()} AS $col2",
        );
      }

      return rows.join(" UNION ALL ");
    });
  }

  // =========================
  // 🔥 EXTRACT → STRFTIME
  // =========================
  String _convertExtract(String sql) {
    return sql
        .replaceAllMapped(
      RegExp(r"extract\(year from ([^)]+)\)", caseSensitive: false),
          (m) => "strftime('%Y', ${m.group(1)})",
    )
        .replaceAllMapped(
      RegExp(r"extract\(month from ([^)]+)\)", caseSensitive: false),
          (m) => "CAST(strftime('%m', ${m.group(1)}) AS INTEGER)",
    );
  }

  // =========================
  // 🔥 SAFE :: CAST
  // =========================
  String _convertCastingOperator(String sql) {
    return sql.replaceAllMapped(
      RegExp(r"(\b[\w\.]+\b)::(\w+(\(\d+\))?)"),
          (match) {
        final value = match.group(1);
        final type = _mapType(match.group(2)!);
        return "CAST($value AS $type)";
      },
    );
  }

  // =========================
  // BOOLEAN
  // =========================
  String _convertBoolean(String sql) {
    return sql
        .replaceAll(RegExp(r"\bTRUE\b", caseSensitive: false), "1")
        .replaceAll(RegExp(r"\bFALSE\b", caseSensitive: false), "0");
  }

  String _mapType(String type) {
    final t = type.toUpperCase();

    if (t.contains("INT")) return "INTEGER";
    if (t.contains("CHAR") || t.contains("TEXT")) return "TEXT";
    if (t.contains("NUMERIC") || t.contains("REAL") || t.contains("DOUBLE")) {
      return "REAL";
    }

    return type;
  }
}

class _StringProtector {
  final Map<String, String> _map = {};
  int _i = 0;

  String protect(String sql) {
    return sql.replaceAllMapped(RegExp(r"'([^']*)'"), (match) {
      final key = "__STR_${_i++}__";
      _map[key] = match.group(0)!;
      return key;
    });
  }

  String restore(String sql) {
    _map.forEach((k, v) {
      sql = sql.replaceAll(k, v);
    });
    return sql;
  }
}