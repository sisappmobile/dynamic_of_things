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

    final List<Map<String, Object?>> results = await databaseExecutor.rawQuery(
      _build(),
      _parameters,
    );

    List<Map<String, dynamic>> copy = [];

    for (Map<String, dynamic> result in results) {
      copy.add(Map<String, dynamic>.from(result));
    }

    return copy;
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
