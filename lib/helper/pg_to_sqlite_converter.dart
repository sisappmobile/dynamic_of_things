class PgToSqliteConverter {
  final _protector = _StringProtector();

  String convert(String sql) {
    String result = sql;

    // 0. Forms that need to see the raw quoted text (interval literals)
    //    before string-literal protection swaps them for placeholder
    //    tokens - must run before step 1.
    result = _convertInterval(result);
    result = _convertNow(result);

    // 1. Protect string literals
    result = _protector.protect(result);

    // 2. Structural transforms (must come first)
    result = _convertZippedUnnest(result);
    result = _convertUnnest(result);
    result = _convertExtract(result);

    // 3. Expression transforms
    result = _convertCastingOperator(result);
    result = _convertBoolean(result);
    result = _convertIlike(result);

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
  // 🔥 NOW() / INTERVAL ARITHMETIC
  // =========================
  // `<expr> + interval '<amount>'` (also `-`) has no SQLite equivalent
  // operator - rewritten into datetime()'s modifier-argument form. Must run
  // before string protection since it needs the raw quoted interval text.
  String _convertInterval(String sql) {
    final regex = RegExp(
      r"(now\(\)|current_date|current_timestamp|[A-Za-z_][\w.]*)\s*([+-])\s*interval\s+'([^']*)'",
      caseSensitive: false,
    );

    return sql.replaceAllMapped(regex, (match) {
      final expr = match.group(1)!;
      final sign = match.group(2)!;
      final amount = match.group(3)!;

      return "datetime($expr, '$sign$amount')";
    });
  }

  // Any now() not already consumed by _convertInterval above.
  String _convertNow(String sql) {
    return sql.replaceAll(
      RegExp(r"\bnow\(\s*\)", caseSensitive: false),
      "datetime('now')",
    );
  }

  // =========================
  // 🔥 ILIKE → LIKE
  // =========================
  // SQLite has no ILIKE; its LIKE is already case-insensitive for ASCII,
  // which is what every ILIKE use in these reports relies on.
  String _convertIlike(String sql) {
    return sql.replaceAll(RegExp(r"\bilike\b", caseSensitive: false), "LIKE");
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
  // 🔥 SINGLE-COLUMN UNNEST HANDLER
  // =========================
  // Must run after _convertZippedUnnest so a double-unnest pair is consumed
  // by that pass first, instead of being partially matched here.
  String _convertUnnest(String sql) {
    // A leading "select" is consumed into the match (not just unnest(...)
    // itself) since the replacement supplies its own SELECT for every row -
    // leaving the original "select" in place would double it up into
    // "select SELECT ...".
    final regex = RegExp(
      r"(?:select\s+)?unnest\(array\[(.*?)\]\)\s+as\s+(\w+)",
      caseSensitive: false,
    );

    return sql.replaceAllMapped(regex, (match) {
      final items = match.group(1)!.split(",");
      final col = match.group(2)!;

      return items
          .map((item) => "SELECT ${item.trim()} AS $col")
          .join(" UNION ALL ");
    });
  }

  // =========================
  // 🔥 EXTRACT → STRFTIME
  // =========================
  // A regex capturing "everything up to the next )" breaks the moment the
  // FROM expression itself contains parens (e.g. `extract(dow from now())`)
  // - it matches now()'s closing paren instead of extract's own, leaving a
  // dangling ")" and a mangled capture. Scanned by hand instead, balancing
  // parens so nested calls inside the FROM expression are handled correctly.
  String _convertExtract(String sql) {
    String result = sql;
    final startRegex = RegExp(
      r"extract\s*\(\s*(\w+)\s+from\s+",
      caseSensitive: false,
    );

    while (true) {
      final match = startRegex.firstMatch(result);

      if (match == null) {
        break;
      }

      final String unit = match.group(1)!.toLowerCase();
      final String? format = switch (unit) {
        "year" => "%Y",
        "month" => "%m",
        "day" => "%d",
        "dow" => "%w",
        "doy" => "%j",
        _ => null,
      };

      if (format == null) {
        // Unknown unit - leave it as-is rather than looping forever or
        // silently mistranslating it; SQLite will still fail loudly on it.
        break;
      }

      final int exprStart = match.end;
      int depth = 1;
      int i = exprStart;

      while (i < result.length && depth > 0) {
        if (result[i] == "(") {
          depth++;
        } else if (result[i] == ")") {
          depth--;
        }

        if (depth == 0) {
          break;
        }

        i++;
      }

      final String expr = result.substring(exprStart, i).trim();
      final String before = result.substring(0, match.start);
      final String after = result.substring(i + 1);

      result = "${before}CAST(strftime('$format', $expr) AS INTEGER)$after";
    }

    return result;
  }

  // =========================
  // 🔥 SAFE :: CAST
  // =========================
  // A regex requiring the left operand to be a bare identifier only handles
  // `column::type` - it misses `(expr)::type` and `func(...)::type`, both of
  // which are common here (e.g. `strftime(...)::int`,
  // `(coalesce(x,0))::numeric(16,2)`). Scanned by hand instead: when the
  // character before `::` is `)`, the matching `(` is found by balancing
  // parens backward, then extended further back over any identifier
  // (function name) immediately preceding it.
  String _convertCastingOperator(String sql) {
    String result = sql;

    while (true) {
      final int idx = result.indexOf("::");

      if (idx == -1) {
        break;
      }

      int typeEnd = idx + 2;

      while (typeEnd < result.length && _isWordChar(result[typeEnd])) {
        typeEnd++;
      }

      if (typeEnd < result.length && result[typeEnd] == "(") {
        int depth = 1;
        int j = typeEnd + 1;

        while (j < result.length && depth > 0) {
          if (result[j] == "(") {
            depth++;
          } else if (result[j] == ")") {
            depth--;
          }

          j++;
        }

        typeEnd = j;
      }

      final String rawType = result.substring(idx + 2, typeEnd);
      final String baseType =
          rawType.replaceAll(RegExp(r"\(.*\)"), "").trim();

      int operandStart;

      if (idx > 0 && result[idx - 1] == ")") {
        int depth = 0;
        int k = idx - 1;

        while (k >= 0) {
          if (result[k] == ")") {
            depth++;
          } else if (result[k] == "(") {
            depth--;
          }

          if (depth == 0) {
            break;
          }

          k--;
        }

        operandStart = k;

        while (operandStart > 0 && _isWordChar(result[operandStart - 1])) {
          operandStart--;
        }
      } else {
        int k = idx;

        while (k > 0 &&
            (_isWordChar(result[k - 1]) || result[k - 1] == ".")) {
          k--;
        }

        operandStart = k;
      }

      final String operand = result.substring(operandStart, idx);
      final String before = result.substring(0, operandStart);
      final String after = result.substring(typeEnd);

      final String replacement = switch (baseType.toLowerCase()) {
        "date" => "date($operand)",
        "timestamp" || "timestamptz" => "datetime($operand)",
        _ => "CAST($operand AS ${_mapType(baseType)})",
      };

      result = "$before$replacement$after";
    }

    return result;
  }

  bool _isWordChar(String char) {
    return RegExp(r"[A-Za-z0-9_]").hasMatch(char);
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

    if (t.contains("INT")) {
      return "INTEGER";
    }
    if (t.contains("CHAR") || t.contains("TEXT")) {
      return "TEXT";
    }
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
