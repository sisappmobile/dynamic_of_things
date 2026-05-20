class JsonScriptEngine {
  late Map<String, dynamic> root;
  late List<String> _lines;
  Map<String, dynamic> scope = {};

  Map<String, dynamic> run(Map<String, dynamic> json, String script) {
    root = _deepConvert(json);
    scope.clear();

    _lines = script.split("\n");

    final cleaned = _lines.map((e) => e.trim()).toList();

    _exec(cleaned, 0, cleaned.length);

    return root;
  }

  Map<String, dynamic> _deepConvert(Map input) {
    return input.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _deepConvert(value));
      } else if (value is List) {
        return MapEntry(
          key.toString(),
          value.map((e) {
            if (e is Map) {
              return _deepConvert(e);
            }
            return e;
          }).toList(),
        );
      }
      return MapEntry(key.toString(), value);
    });
  }

  void _exec(List<String> lines, int start, int end) {
    int i = start;

    while (i < end) {
      String line = lines[i];

      try {
        if (line.isEmpty || line == "BEGIN" || line == "END") {
          i++;
          continue;
        }

        if (line == "EDITMODE") {
          root["EDITMODE"] = true;
          i++;
          continue;
        }

        if (line.startsWith("FOR")) {
          final parts = line.split(RegExp(r"\s+"));
          final varName = parts[1];
          final listPath = parts[3];

          final list = _getValue(listPath) as List;

          final endFor = _findBlockEnd(lines, i, "FOR");

          for (var item in list) {
            scope[varName] = item;
            _exec(lines, i + 1, endFor);
          }

          scope.remove(varName);
          i = endFor;
        } else if (line.startsWith("IF")) {
          final endIf = _findBlockEnd(lines, i, "IF");

          int cursor = i;
          bool executed = false;

          while (cursor < endIf) {
            String currentLine = lines[cursor];

            if (currentLine.startsWith("IF") ||
                currentLine.startsWith("ELSIF")) {
              String cond;
              if (currentLine.startsWith("ELSIF")) {
                cond = currentLine.substring(5).trim();
              } else {
                cond = currentLine.substring(2).trim();
              }

              int nextBranch = _findNextBranch(lines, cursor + 1, endIf);

              if (!executed && _evalCondition(cond)) {
                _exec(lines, cursor + 1, nextBranch);
                executed = true;
              }

              cursor = nextBranch;
              continue;
            }

            if (currentLine == "ELSE") {
              if (!executed) {
                _exec(lines, cursor + 1, endIf);
              }

              break;
            }

            cursor++;
          }

          i = endIf;
        } else if (line.startsWith("ERROR")) {
          _handleError(line, i);
        } else if (line.startsWith("ASSERT")) {
          _handleAssert(line, i);
        } else if (line.startsWith("REQUIRE")) {
          _handleRequire(line, i);
        } else if (line.contains("=")) {
          _assign(line);
        }
      } catch (e) {
        if (e is ScriptValidationException) {
          rethrow;
        }

        throw ScriptValidationException(
          e.toString(),
          i + 1,
          _lines[i],
        );
      }

      i++;
    }
  }

  int _findNextBranch(List<String> lines, int start, int endIf) {
    int level = 0;
    for (int i = start; i < endIf; i++) {
      final line = lines[i];
      if (line.startsWith("IF ")) {
        level++;
      } else if (line == "ENDIF") {
        level--;
      } else if (level == 0 && (line.startsWith("ELSIF ") || line == "ELSE")) {
        return i;
      }
    }
    return endIf;
  }

  void _handleError(String line, int index) {
    String message = line.substring(5).trim();

    if (message.startsWith('"') && message.endsWith('"')) {
      message = message.substring(1, message.length - 1);
    }

    throw ScriptValidationException(message, index + 1, _lines[index]);
  }

  void _handleAssert(String line, int index) {
    final match = RegExp(r'ASSERT (.+?) "(.*)"').firstMatch(line);

    if (match == null) {
      throw ScriptValidationException(
        "Invalid ASSERT syntax",
        index + 1,
        _lines[index],
      );
    }

    final condition = match.group(1)!;
    final message = match.group(2)!;

    if (!_evalCondition(condition)) {
      throw ScriptValidationException(
        _evalExpression(message).toString(),
        index + 1,
        _lines[index],
      );
    }
  }

  void _handleRequire(String line, int index) {
    final match = RegExp(r'REQUIRE (.+?) "(.*)"').firstMatch(line);

    if (match == null) {
      throw ScriptValidationException(
        "Invalid REQUIRE syntax",
        index + 1,
        _lines[index],
      );
    }

    final condition = match.group(1)!;
    final message = match.group(2)!;

    if (!_evalCondition(condition)) {
      throw ScriptValidationException(
        _evalExpression(message).toString(),
        index + 1,
        _lines[index],
      );
    }
  }

  void _assign(String line) {
    // handle ??=
    if (line.contains("??=")) {
      final parts = line.split("??=");
      final path = parts[0].trim();
      final expr = parts[1].trim();

      final currentValue = _getValue(path);

      if (currentValue == null) {
        final value = _evalExpression(expr);
        _setValue(path, value);
      }

      return;
    }

    // normal =
    final parts = line.split("=");
    final path = parts[0].trim();
    final expr = parts.sublist(1).join("=").trim();

    final value = _evalExpression(expr);
    _setValue(path, value);
  }

  dynamic _evalExpression(String expr) {
    if (expr.startsWith("DATEDIFF(")) {
      return _handleDateDiff(expr);
    }

    final parser = ExpressionParser(_value);
    return parser.evaluate(expr);
  }

  dynamic _handleDateDiff(String expr) {
    final inside = expr.substring(9, expr.length - 1);
    final parts = _splitArgs(inside);

    if (parts.length != 3) {
      throw Exception("DATEDIFF requires 3 arguments");
    }

    final start = _toDateTime(_evalExpression(parts[0]));
    final end = _toDateTime(_evalExpression(parts[1]));
    final unit = parts[2].replaceAll(String.fromCharCode(34), "").trim();

    final diff = end.difference(start);

    switch (unit) {
      case "second":
        return diff.inSeconds;
      case "minute":
        return diff.inMinutes;
      case "hour":
        return diff.inHours;
      case "day":
        return diff.inDays;
      default:
        throw Exception("Unsupported unit: $unit");
    }
  }

  List<String> _splitArgs(String raw) {
    List<String> result = [];
    int bracket = 0;
    String current = "";

    for (int i = 0; i < raw.length; i++) {
      final c = raw[i];

      if (c == "," && bracket == 0) {
        result.add(current.trim());
        current = "";
      } else {
        if (c == "(") {
          bracket++;
        }
        if (c == ")") {
          bracket--;
        }
        current += c;
      }
    }

    if (current.isNotEmpty) {
      result.add(current.trim());
    }

    return result;
  }

  DateTime _toDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.parse(value);
    }

    throw Exception("Invalid datetime value: $value");
  }

  bool _evalCondition(String cond) {
    if (cond.contains(" AND ")) {
      final p = cond.split(" AND ");
      return _evalCondition(p[0]) && _evalCondition(p[1]);
    }

    if (cond.contains(" OR ")) {
      final p = cond.split(" OR ");
      return _evalCondition(p[0]) || _evalCondition(p[1]);
    }

    if (cond.contains(">=")) {
      final p = cond.split(">=");
      return _evalExpression(p[0]) >= _evalExpression(p[1]);
    }

    if (cond.contains("<=")) {
      final p = cond.split("<=");
      return _evalExpression(p[0]) <= _evalExpression(p[1]);
    }

    if (cond.contains("!=")) {
      final p = cond.split("!=");
      return _evalExpression(p[0]) != _evalExpression(p[1]);
    }

    if (cond.contains("==")) {
      final p = cond.split("==");
      return _evalExpression(p[0]) == _evalExpression(p[1]);
    }

    if (cond.contains(">")) {
      final p = cond.split(">");
      return _evalExpression(p[0]) > _evalExpression(p[1]);
    }

    if (cond.contains("<")) {
      final p = cond.split("<");
      return _evalExpression(p[0]) < _evalExpression(p[1]);
    }

    if (cond.contains(" IS NULL")) {
      var p = cond.split(" IS NULL");
      return _evalExpression(p[0]) == null;
    }

    if (cond.contains(" IS NOT NULL")) {
      var p = cond.split(" IS NOT NULL");
      return _evalExpression(p[0]) != null;
    }

    return _value(cond) == true;
  }

  dynamic _value(String v) {
    v = v.trim();

    if (v == "true") {
      return true;
    }
    if (v == "false") {
      return false;
    }

    // 🔥 constant NOW
    if (v == "NOW") {
      return DateTime.now();
    }

    if (num.tryParse(v) != null) {
      return num.parse(v);
    }

    return _getValue(v);
  }

  dynamic _getValue(String path) {
    if (path.endsWith(".size")) {
      final base = path.substring(0, path.length - 5);

      final list = _getValue(base);

      if (list is List) {
        return list.length;
      }

      return 0;
    }

    final indexMatch = RegExp(r"(.*)\[(\d+)\]").firstMatch(path);

    if (indexMatch != null) {
      final arr = _getValue(indexMatch.group(1)!);
      final idx = int.parse(indexMatch.group(2)!);
      return arr[idx];
    }

    final parts = path.split(".");

    dynamic current;

    if (scope.containsKey(parts.first)) {
      current = scope[parts.first];
      parts.removeAt(0);
    } else {
      current = root;
    }

    for (var p in parts) {
      if (current is Map && current.containsKey(p)) {
        current = current[p];
      } else {
        return null;
      }
    }

    return current;
  }

  void _setValue(String path, dynamic value) {
    var parts = path.split(".");

    dynamic current;

    // cek apakah referensi dari scope
    if (scope.containsKey(parts.first)) {
      current = scope[parts.first];
      parts.removeAt(0);
    } else {
      current = root;
    }

    for (int i = 0; i < parts.length - 1; i++) {
      var key = parts[i];

      if (current[key] == null) {
        current[key] = {};
      }

      if (current[key] is! Map) {
        throw Exception("Path error: $key is not an object");
      }

      current = current[key];
    }

    var lastKey = parts.last;

    if (current is Map) {
      current[lastKey] = value;
    } else {
      throw Exception("Cannot assign to non-object path: $path");
    }
  }

  int _findBlockEnd(List<String> lines, int start, String blockType) {
    int level = 0;
    String startKeyword = blockType; // "IF" or "FOR"
    String endKeyword = "END$blockType"; // "ENDIF" or "ENDFOR"

    for (int i = start + 1; i < lines.length; i++) {
      final line = lines[i];

      // We only want to match IF/FOR that are commands, not arbitrary strings containing IF.
      // So checking startsWith("IF ") or equals "IF", same for FOR.
      if (line.startsWith("$startKeyword ") || line == startKeyword) {
        level++;
      } else if (line == endKeyword) {
        if (level == 0) {
          return i;
        }
        level--;
      }
    }
    throw Exception("$endKeyword not found");
  }
}

class ExpressionParser {
  final dynamic Function(String) resolver;

  ExpressionParser(this.resolver);

  late List<String> tokens;
  int pos = 0;

  dynamic evaluate(String input) {
    tokens = _tokenize(input);
    pos = 0;
    return _parseExpression();
  }

  // ================= TOKENIZER =================

  List<String> _tokenize(String input) {
    final regex = RegExp(
      r'''\s*("(?:[^"\\]|\\.)*"|\?\?|==|!=|>=|<=|[0-9]+\.?[0-9]*|[()+\-*/]|[A-Za-z0-9_.]+)\s*''',
    );
    return regex.allMatches(input).map((m) => m.group(1)!).toList();
  }

  String _peek() => pos < tokens.length ? tokens[pos] : "";

  String _next() => tokens[pos++];

  bool _match(String t) {
    if (_peek() == t) {
      pos++;
      return true;
    }
    return false;
  }

  // ================= PARSER =================

  dynamic _parseExpression() {
    return _parseNullCoalescing();
  }

  dynamic _parseNullCoalescing() {
    var left = _parseAddSub();

    while (_match("??")) {
      var right = _parseAddSub();
      left = (left == null) ? right : left;
    }

    return left;
  }

  dynamic _parseAddSub() {
    var left = _parseMulDiv();

    while (true) {
      if (_match("+")) {
        left = left + _parseMulDiv();
      } else if (_match("-")) {
        left = left - _parseMulDiv();
      } else {
        break;
      }
    }

    return left;
  }

  dynamic _parseMulDiv() {
    var left = _parseUnary();

    while (true) {
      if (_match("*")) {
        left = left * _parseUnary();
      } else if (_match("/")) {
        left = left / _parseUnary();
      } else {
        break;
      }
    }

    return left;
  }

  dynamic _parseUnary() {
    if (_match("-")) {
      return -_parseUnary();
    }
    return _parsePrimary();
  }

  dynamic _parsePrimary() {
    var token = _next();

    // 🔥 STRING
    if (token.startsWith('"') && token.endsWith('"')) {
      return token.substring(1, token.length - 1);
    }

    // number
    if (num.tryParse(token) != null) {
      return num.parse(token);
    }

    // parentheses
    if (token == "(") {
      var value = _parseExpression();
      _match(")");
      return value;
    }

    // variable
    return resolver(token);
  }
}

class ScriptValidationException implements Exception {
  final String message;
  final int line;
  final String code;

  ScriptValidationException(this.message, this.line, this.code);

  @override
  String toString() {
    return "Line $line: $message\n> $code";
  }
}
