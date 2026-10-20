import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/helper/sqlites.dart";
import "package:sqflite/sqflite.dart";

class DMLAssemblers {
  DMLAssemblers._internal();

  static DMLAssemblers create() {
    return DMLAssemblers._internal();
  }

  final List<String> _selects = [];
  final List<String> _distincts = [];
  final List<String> _froms = [];
  final List<String> _joins = [];
  final List<String> _groups = [];
  final List<String> _orders = [];
  final List<String> _wheres = [];

  int _offset = 0;
  int _limit = 0;
  String? _having;
  final List<dynamic> _parameters = [];

  // sqflite only accepts num, String, Uint8List (and null) as raw query
  // arguments - a DateTime passed straight through triggers
  // "Invalid argument ... with type DateTime" (currently just a warning,
  // but documented to become a thrown exception in a future version).
  // Every place that pushes onto _parameters routes through here so any
  // DateTime is normalized once, in one place, rather than requiring every
  // caller to remember to format it first.
  dynamic _normalizeParameter(dynamic value) {
    if (value is DateTime) {
      return value.toIso8601String();
    }

    return value;
  }

  DMLAssemblers select(String column, {bool condition = true}) {
    if (condition) {
      _selects.add(column);
    }

    return this;
  }

  DMLAssemblers distinct(String column, {bool condition = true}) {
    if (condition) {
      _distincts.add(column);
    }

    return this;
  }

  DMLAssemblers from(String table) {
    _froms.add(table);

    return this;
  }

  DMLAssemblers join(String command) {
    _joins.add(command);

    return this;
  }

  DMLAssemblers and({bool condition = true}) {
    if (condition && _wheres.isNotEmpty) {
      _wheres.add("AND");
    }

    return this;
  }

  DMLAssemblers or({bool condition = true}) {
    if (condition && _wheres.isNotEmpty) {
      _wheres.add("OR");
    }

    return this;
  }

  DMLAssemblers equalTo(
    String column,
    dynamic parameter, {
    bool condition = true,
  }) {
    if (condition) {
      if (parameter != null) {
        _wheres.add("$column = ?");
        _parameters.add(_normalizeParameter(parameter));
      }
    }

    return this;
  }

  DMLAssemblers notEqualTo(
    String column,
    dynamic parameter, {
    bool condition = true,
  }) {
    if (condition) {
      if (parameter != null) {
        _wheres.add("$column != ?");
        _parameters.add(_normalizeParameter(parameter));
      }
    }

    return this;
  }

  DMLAssemblers lessThan(
    String column,
    dynamic parameter, {
    bool condition = true,
  }) {
    if (condition) {
      if (parameter != null) {
        _wheres.add("$column < ?");
        _parameters.add(_normalizeParameter(parameter));
      }
    }

    return this;
  }

  DMLAssemblers lessThanOrEqualTo(
    String column,
    dynamic parameter, {
    bool condition = true,
  }) {
    if (condition) {
      if (parameter != null) {
        _wheres.add("$column <= ?");
        _parameters.add(_normalizeParameter(parameter));
      }
    }

    return this;
  }

  DMLAssemblers greaterThan(
    String column,
    dynamic parameter, {
    bool condition = true,
  }) {
    if (condition) {
      if (parameter != null) {
        _wheres.add("$column > ?");
        _parameters.add(_normalizeParameter(parameter));
      }
    }

    return this;
  }

  DMLAssemblers greaterThanOrEqualTo(
    String column,
    dynamic parameter, {
    bool condition = true,
  }) {
    if (condition) {
      if (parameter != null) {
        _wheres.add("$column >= ?");
        _parameters.add(_normalizeParameter(parameter));
      }
    }

    return this;
  }

  DMLAssemblers inn(
    String column,
    List<dynamic> parameters, {
    bool condition = true,
  }) {
    if (condition) {
      if (parameters.isNotEmpty) {
        String tags = "";

        for (int i = 0; i < parameters.length; i++) {
          dynamic parameter = parameters[i];

          if (parameter != null) {
            if (StringUtils.isNotNullOrEmpty(tags)) {
              tags += ", ";
            }

            tags += "?";

            _parameters.add(_normalizeParameter(parameter));
          }
        }

        _wheres.add("$column IN ($tags)");
      }
    }

    return this;
  }

  DMLAssemblers isNotNull(String column, {bool condition = true}) {
    if (condition) {
      _wheres.add("$column IS NOT NULL");
    }

    return this;
  }

  DMLAssemblers isNull(String column, {bool condition = true}) {
    if (condition) {
      _wheres.add("$column IS NULL");
    }

    return this;
  }

  DMLAssemblers customWhere(String clause, {bool condition = true}) {
    if (condition) {
      _wheres.add(clause);
    }

    return this;
  }

  DMLAssemblers groupBy(String column, {bool condition = true}) {
    if (condition) {
      _groups.add(column);
    }

    return this;
  }

  DMLAssemblers asc(String column, {bool condition = true}) {
    if (condition) {
      _orders.add("$column ASC");
    }

    return this;
  }

  DMLAssemblers desc(String column, {bool condition = true}) {
    if (condition) {
      _orders.add("$column DESC");
    }

    return this;
  }

  DMLAssemblers customOrder(String command, {bool condition = true}) {
    if (condition) {
      _orders.add(command);
    }

    return this;
  }

  DMLAssemblers offset(int offset) {
    _offset = offset;

    return this;
  }

  DMLAssemblers limit(int limit) {
    _limit = limit;

    return this;
  }

  DMLAssemblers having(String having) {
    _having = having;

    return this;
  }

  DMLAssemblers parameter(dynamic value, {bool condition = true}) {
    if (condition) {
      _parameters.add(_normalizeParameter(value));
    }

    return this;
  }

  bool hasWhere() {
    return _wheres.isNotEmpty;
  }

  String _build([bool count = false]) {
    String stringBuilder = "";

    stringBuilder += "SELECT ";

    if (count) {
      stringBuilder += "COUNT(0) AS count ";
    } else {
      if (_distincts.isNotEmpty) {
        String compile = "";

        for (int i = 0; i < _distincts.length; i++) {
          String distinct = _distincts[i];

          if (StringUtils.isNotNullOrEmpty(distinct)) {
            if (StringUtils.isNotNullOrEmpty(compile)) {
              compile += ", ";
            }

            compile += distinct;
          }
        }

        stringBuilder += "DISTINCT ON ($compile) ";
      }

      {
        String compile = "";

        for (int i = 0; i < _selects.length; i++) {
          String select = _selects[i];

          if (StringUtils.isNotNullOrEmpty(select)) {
            if (StringUtils.isNotNullOrEmpty(compile)) {
              compile += ", ";
            }

            compile += select;
          }
        }

        stringBuilder += compile;
      }
    }

    stringBuilder += " FROM ";

    {
      String compile = "";

      for (int i = 0; i < _froms.length; i++) {
        String from = _froms[i];

        if (StringUtils.isNotNullOrEmpty(from)) {
          if (StringUtils.isNotNullOrEmpty(compile)) {
            compile += ", ";
          }

          compile += from;
        }
      }

      stringBuilder += compile;
    }

    if (_joins.isNotEmpty) {
      String compile = "";

      for (int i = 0; i < _joins.length; i++) {
        String join = _joins[i];

        if (StringUtils.isNotNullOrEmpty(join)) {
          if (StringUtils.isNotNullOrEmpty(compile)) {
            compile += " ";
          }

          compile += join;
        }
      }

      stringBuilder += " $compile";
    }

    if (_wheres.isNotEmpty) {
      String compile = "";

      for (int i = 0; i < _wheres.length; i++) {
        String where = _wheres[i];

        if (StringUtils.isNotNullOrEmpty(where)) {
          if (StringUtils.isNotNullOrEmpty(compile)) {
            compile += " ";
          }

          compile += where;
        }
      }

      stringBuilder += " WHERE $compile";
    }

    if (!count) {
      if (_groups.isNotEmpty) {
        String compile = "";

        for (int i = 0; i < _groups.length; i++) {
          String group = _groups[i];

          if (StringUtils.isNotNullOrEmpty(group)) {
            if (StringUtils.isNotNullOrEmpty(compile)) {
              compile += ", ";
            }

            compile += group;
          }
        }

        stringBuilder += " GROUP BY $compile";
      }

      if (StringUtils.isNotNullOrEmpty(_having)) {
        stringBuilder += " HAVING $_having";
      }

      if (_orders.isNotEmpty) {
        String compile = "";

        for (int i = 0; i < _orders.length; i++) {
          String order = _orders[i];

          if (StringUtils.isNotNullOrEmpty(order)) {
            if (StringUtils.isNotNullOrEmpty(compile)) {
              compile += ", ";
            }

            compile += order;
          }
        }

        stringBuilder += " ORDER BY $compile";
      }

      if (_limit > 0) {
        stringBuilder += " LIMIT $_limit";
      }

      if (_offset > 0) {
        stringBuilder += " OFFSET $_offset";
      }
    }

    stringBuilder += ";";

    return stringBuilder;
  }

  Future<List<Map<String, Object?>>> all([Transaction? transaction]) async {
    if (transaction == null && !Sqlites.supported) {
      return <Map<String, Object?>>[];
    }

    DatabaseExecutor databaseExecutor = transaction ?? await Sqlites.get();

    List<Map<String, Object?>> results;

    try {
      results = await databaseExecutor.rawQuery(_build(), _parameters);
    } on DatabaseException catch (e) {
      // A dynamic-form table whose f_dynamic_table metadata already synced
      // but which has zero rows so far never gets created locally - it's
      // otherwise only ever created reactively, the first time an actual
      // data row for it shows up in a pull (see Pulls.process()). Rather
      // than requiring every one of this app's many call sites to
      // pre-emptively know about that and guard against it individually,
      // self-heal once here, at the single choke point every query
      // already goes through: parse the missing table's name straight out
      // of SQLite's own error message (works whether it's the primary
      // FROM table or one pulled in via a JOIN), create it from its
      // metadata if that metadata exists, and retry exactly once.
      final String? missingTable = _missingTableName(e);

      if (missingTable == null ||
          !await _ensureTableExists(databaseExecutor, missingTable)) {
        rethrow;
      }

      results = await databaseExecutor.rawQuery(_build(), _parameters);
    }

    List<Map<String, dynamic>> copy = [];

    for (Map<String, dynamic> result in results) {
      copy.add(Map<String, dynamic>.from(result));
    }

    return copy;
  }

  static String? _missingTableName(DatabaseException e) {
    final RegExpMatch? match =
        RegExp(r"no such table:\s*([A-Za-z0-9_]+)").firstMatch(e.toString());

    return match?.group(1);
  }

  // Mirrors Pulls.getTableInfos()'s table-creation logic (f_dynamic_table +
  // f_dynamic_table_detail -> CREATE TABLE), duplicated here rather than
  // shared - Pulls already depends on DMLAssemblers, so calling back into
  // Pulls from here would be circular. Uses raw rawQuery/execute instead of
  // DMLAssemblers' own query builder so it works identically whether
  // databaseExecutor is a Transaction or the raw Database.
  static Future<bool> _ensureTableExists(
    DatabaseExecutor databaseExecutor,
    String tableName,
  ) async {
    List<Map<String, Object?>> existing =
        await databaseExecutor.rawQuery("PRAGMA table_info($tableName)");

    if (existing.isNotEmpty) {
      return true;
    }

    List<Map<String, Object?>> tableRows = await databaseExecutor.rawQuery(
      "SELECT * FROM f_dynamic_table WHERE table_name = ? LIMIT 1",
      [tableName],
    );

    if (tableRows.isEmpty) {
      return false;
    }

    List<Map<String, Object?>> columns = await databaseExecutor.rawQuery(
      "SELECT * FROM f_dynamic_table_detail WHERE table_id = ?",
      [tableRows.first["id"]],
    );

    if (columns.isEmpty) {
      return false;
    }

    String? pkColumn;

    for (Map<String, Object?> column in columns) {
      if (column["f_pk"] == "Y") {
        pkColumn = column["column_name"] as String?;

        break;
      }
    }

    List<String> columnNames = [];

    for (Map<String, Object?> column in columns) {
      columnNames.add(column["column_name"] as String);
    }

    const List<String> additionalColumns = [
      "create_who",
      "create_date",
      "change_who",
      "change_date",
      "table_id",
      "form_id",
      "f_delete",
      "version",
      "user_id",
      "header_id",
    ];

    for (String additionalColumn in additionalColumns) {
      if (!columnNames.contains(additionalColumn)) {
        columnNames.add(additionalColumn);
      }
    }

    await databaseExecutor.execute(
      "CREATE TABLE $tableName ( ${columnNames.toSet().map((column) => '"$column" TEXT ${column == pkColumn ? "PRIMARY KEY" : ""}').join(", ")} )",
    );

    return true;
  }

  Future<int> count([Transaction? transaction]) async {
    if (transaction == null && !Sqlites.supported) {
      return 0;
    }

    DatabaseExecutor databaseExecutor = transaction ?? await Sqlites.get();

    final List<Map<String, Object?>> result = await databaseExecutor.rawQuery(
      _build(true),
      _parameters,
    );

    return result[0]["count"] as int;
  }

  Future<Map<String, dynamic>?> first([Transaction? transaction]) async {
    final List<Map<String, Object?>> result = await all(transaction);

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }
}
