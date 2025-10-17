// ignore_for_file: cascade_invocations

import "dart:convert";

import "package:basic_utils/basic_utils.dart";
import "package:collection/collection.dart";
import "package:dio/dio.dart";
import "package:dynamic_of_things/enumeration/dynamic_form_field_type.dart";
import "package:dynamic_of_things/helper/dml_assemblers.dart";
import "package:dynamic_of_things/helper/dot_apis.dart";
import "package:dynamic_of_things/helper/formats.dart";
import "package:dynamic_of_things/helper/realms.dart";
import "package:dynamic_of_things/helper/sqlites.dart";
import "package:dynamic_of_things/model/dynamic_form_resource_response.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/offline_model/dynamic_form_data/versioning_dynamic_form_data_response.dart";
import "package:dynamic_of_things/offline_model/dynamic_form_data/versioning_dynamic_form_data_schema_column_item.dart";
import "package:dynamic_of_things/realm/schemas.dart";
import "package:dynamic_of_things/realm/version_dao.dart";
import "package:flutter/foundation.dart";
import "package:realm/realm.dart";
import "package:sqflite/sqflite.dart";

class Data {
  final int size;
  final List<Map<String, dynamic>> items;

  Data({required this.size, required this.items});
}

class Offlines {
  static Future<void> insertOrUpdate({
    required int latestVersion,
    required List<Map<String, dynamic>> items,
    void Function(String message)? messageCallback,
  }) async {
    Realm realm = Realms.get();

    realm.write(() {
      for (Map<String, dynamic> item in items) {
        HeaderForm headerForm = HeaderForm.fromJson(item);

        DynamicForm? dynamicForm = findTemplate(headerForm.template.id);

        if (dynamicForm != null) {
          dynamicForm.json = jsonEncode(item);
        } else {
          dynamicForm = DynamicForm(headerForm.template.id, jsonEncode(item));

          realm.add(dynamicForm, update: true);
        }
      }

      VersionDao.updateVersion(
        realm: realm,
        key: VersionDao.form,
        lastVersion: latestVersion,
      );
    });

    for (Map<String, dynamic> item in items) {
      HeaderForm headerForm = HeaderForm.fromJson(item);

      await data(
        tableName: headerForm.template.tableName,
        messageCallback: messageCallback,
      );

      for (Resource resource in headerForm.template.resources) {
        await data(
          tableName: resource.table,
          messageCallback: messageCallback,
        );
      }
    }
  }

  static Future<void> data({
    required String tableName,
    void Function(String message)? messageCallback,
  }) async {
    if (messageCallback != null) {
      messageCallback("Mengunduh data $tableName...");
    }

    try {
      Realm realm = Realms.get();

      if (!(realm.dynamic.find(Version.schema.name, tableName)?.isValid ?? false)) {
        realm.write(() {
          realm.add(
            Version(
              tableName,
              0,
            ),
            update: true,
          );
        });
      }

      Response response = await DotApis.getInstance().versioningDynamicFormData(
        tableName: tableName,
        version: VersionDao.last(tableName),
      );

      if (response.statusCode == 200) {
        VersioningDynamicFormDataResponse versioningDynamicFormDataResponse = VersioningDynamicFormDataResponse.fromJson(response.data);

        Database database = await Sqlites.get();

        await database.transaction((txn) async {
          VersioningDynamicFormDataSchemaColumnItem? vdfdscPrimaryKey = versioningDynamicFormDataResponse.schema.columns.where((element) => element.primaryKey).firstOrNull;

          if (vdfdscPrimaryKey == null) {
            vdfdscPrimaryKey ??= versioningDynamicFormDataResponse.schema.columns.firstOrNull;

            if (vdfdscPrimaryKey != null) {
              vdfdscPrimaryKey.primaryKey = true;
            }
          }

          String createTableSql = "CREATE TABLE IF NOT EXISTS ${versioningDynamicFormDataResponse.schema.name} (";

          createTableSql += versioningDynamicFormDataResponse.schema.columns.map((e) {
            String subQuery = "${e.name} ${Sqlites.dataType(e.type)}";

            if (e.primaryKey) {
              subQuery += " PRIMARY KEY";
            }

            return subQuery;
          }).join(", ");

          createTableSql += ");";

          await txn.execute(createTableSql);

          List<Map<String, dynamic>> results = await txn.rawQuery("PRAGMA table_info(${versioningDynamicFormDataResponse.schema.name});");

          {
            bool hasPendingColumn = false;

            for (Map<String, dynamic> result in results) {
              if (StringUtils.equalsIgnoreCase(result["name"], "_pending")) {
                hasPendingColumn = true;

                break;
              }
            }

            if (!hasPendingColumn) {
              await txn.execute("ALTER TABLE ${versioningDynamicFormDataResponse.schema.name} ADD COLUMN _pending BOOLEAN");
            }
          }

          for (VersioningDynamicFormDataSchemaColumnItem versioningDynamicFormTemplateSchemaColumnItem in versioningDynamicFormDataResponse.schema.columns) {
            bool found = false;

            for (Map<String, dynamic> result in results) {
              if (StringUtils.equalsIgnoreCase(result["name"], versioningDynamicFormTemplateSchemaColumnItem.name)) {
                found = true;

                break;
              }
            }

            if (!found) {
              await txn.execute("ALTER TABLE ${versioningDynamicFormDataResponse.schema.name} ADD COLUMN ${versioningDynamicFormTemplateSchemaColumnItem.name} ${Sqlites.dataType(versioningDynamicFormTemplateSchemaColumnItem.type)}");
            }
          }

          if (versioningDynamicFormDataResponse.data.isNotEmpty) {
            VersioningDynamicFormDataSchemaColumnItem? vdfdscPrimaryKey = versioningDynamicFormDataResponse.schema.columns.where((element) => element.primaryKey).firstOrNull;

            vdfdscPrimaryKey ??= versioningDynamicFormDataResponse.schema.columns.firstOrNull;

            if (vdfdscPrimaryKey != null) {
              List<Map<String, dynamic>> columns = await txn.rawQuery("PRAGMA table_info($tableName);");

              for (Map<String, dynamic> row in versioningDynamicFormDataResponse.data) {
                bool exist = false;

                {
                  List<Map<String, dynamic>> results = await txn.rawQuery("SELECT COUNT(*) AS count FROM $tableName WHERE ${vdfdscPrimaryKey.name} = '${row[vdfdscPrimaryKey.name]}';");

                  if (results.isNotEmpty) {
                    exist = results[0]["count"] > 0;
                  }
                }

                if (exist) {
                  String updateSql = "UPDATE $tableName SET _pending = 'FALSE', ";

                  for (int b = 0; b < columns.length; b++) {
                    Map<String, dynamic> column = columns[b];

                    if (b > 0) {
                      updateSql += ", ";
                    }

                    dynamic value = row[column["name"]];

                    if (value != null) {
                      updateSql += "${column["name"]} = '${row[column["name"]]}'";
                    } else {
                      updateSql += "${column["name"]} = NULL";
                    }
                  }

                  updateSql += " WHERE ${vdfdscPrimaryKey.name} = '${row[vdfdscPrimaryKey.name]}';";

                  await txn.execute(updateSql);
                } else {
                  String insertSql = "INSERT INTO $tableName ( _pending, ";

                  insertSql += columns.map((column) => column["name"]).join(", ");
                  insertSql += " ) VALUES ( 'FALSE', ";
                  insertSql += columns.map((column) {
                    dynamic value = row[column["name"]];

                    if (value != null) {
                      return "'${value.toString().replaceAll("'", "''")}'";
                    } else {
                      return "NULL";
                    }
                  }).join(", ");

                  insertSql += " );";

                  await txn.execute(insertSql);
                }
              }
            }
          }
        });

        int latestVersion = 0;

        for (Map<String, dynamic> data in versioningDynamicFormDataResponse.data) {
          int version = Formats.tryParseNumber(data["version"]).toInt();

          if (version > latestVersion) {
            latestVersion = version;
          }
        }

        realm.write(() {
          Schema? schema = findSchema(versioningDynamicFormDataResponse.schema.name);

          if (schema != null) {
            schema.json = jsonEncode(response.data["schema"]["columns"]);
          } else {
            schema = Schema(versioningDynamicFormDataResponse.schema.name, jsonEncode(response.data["schema"]["columns"]));

            realm.add(schema, update: true);
          }

          VersionDao.updateVersion(
            realm: realm,
            key: tableName,
            lastVersion: latestVersion,
          );
        });
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(s);
      }

      rethrow;
    }
  }

  static List<HeaderForm> headerForms(bool journey) {
    RealmResults<DynamicForm> dynamicForms = Realms.get().all<DynamicForm>();

    List<HeaderForm> headerForms = [];

    for (DynamicForm dynamicForm in dynamicForms) {
      HeaderForm headerForm = HeaderForm.fromJson(Map<String, dynamic>.from(jsonDecode(dynamicForm.json)));

      if (headerForm.template.journey == journey) {
        headerForms.add(headerForm);
      }
    }

    return headerForms;
  }

  static DynamicForm? findTemplate(String id) {
    return Realms.get().find<DynamicForm>(id);
  }

  static Schema? findSchema(String id) {
    return Realms.get().find<Schema>(id);
  }

  static HeaderForm? headerForm(String id) {
    DynamicForm? dynamicForm = findTemplate(id);

    if (dynamicForm != null) {
      return HeaderForm.fromJson(Map<String, dynamic>.from(jsonDecode(dynamicForm.json)));
    }

    return null;
  }

  static Future<List<Map<String, dynamic>>> list({
    required String tableName,
    String? customerId,
    List<String>? columns,
    List<String>? customWhere,
  }) async {
    DMLAssemblers dmlAssemblers = DMLAssemblers.create()
        .from(tableName);

    if (columns != null && columns.isNotEmpty) {
      for (var e in columns) {
        dmlAssemblers.select(e);
      }
    } else {
      dmlAssemblers.select("*");
    }

    if (customWhere != null && customWhere.isNotEmpty) {
      dmlAssemblers.customWhere(customWhere.join(" AND "));

      dmlAssemblers.customWhere("COLLATE NOCASE");
    }

    if (StringUtils.isNotNullOrEmpty(customerId)) {
      dmlAssemblers.equalTo("customer_id", customerId);
    }

    return await dmlAssemblers.all();
  }

  static Future<List<Map<String, dynamic>>> listPending({
    required String tableName,
  }) async {
    return DMLAssemblers.create()
        .select("*")
        .from(tableName)
        .customWhere("_pending = 'TRUE'")
        .all();
  }

  static Future<List<Map<String, dynamic>>> listDetail({
    required String tableName,
    String? headerId,
  }) async {
    if (StringUtils.isNotNullOrEmpty(headerId)) {
      Database database = await Sqlites.get();

      return List.from(
        await database.rawQuery(
          "SELECT * FROM $tableName WHERE header_id = ?",
          [headerId],
        ),
      );
    }

    return [];
  }

  static Future<Map<String, dynamic>?> rowData({
    required String tableName,
    required String id,
  }) async {
    DMLAssemblers dmlAssemblers = DMLAssemblers.create()
        .select("*")
        .from(tableName);

    if (StringUtils.isNotNullOrEmpty(id)) {
      dmlAssemblers.equalTo("id", id);
    }

    List<Map<String, dynamic>> results = await dmlAssemblers.all();

    if (results.isNotEmpty) {
      return Map<String, dynamic>.from(results.first);
    }

    return null;
  }

  static Future<DynamicFormResourceResponse?> resource({
    required HeaderForm headerForm,
    required String name,
    required Map<String, dynamic> data,
    String? customerId,
  }) async {
    for (Resource resource in headerForm.template.resources) {
      if (StringUtils.equalsIgnoreCase(resource.name, name)) {
        Schema? schema = findSchema(resource.table);

        if (schema != null) {
          List<ListColumn> listColumns = List<ListColumn>.from(List<Map<String, dynamic>>.from(jsonDecode(schema.json)).map((e) => ListColumn.fromJson(e)));

          return DynamicFormResourceResponse(
            key: resource.key,
            fields: listColumns.where((element) {
              return element.primaryKey || resource.fields.contains(element.name);
            }).map((element) {
              return DynamicFormResourceFieldItem(
                name: element.name,
                type: element.type,
                description: element.description,
                showed: true,
              );
            }).toList(),
            detailSetups: resource.detailSetups.map((element) {
              return DynamicFormResourceDetailSetupItem(
                srcKey: element.srcKey,
                dstKey: element.dstKey,
              );
            }).toList(),
            loadOnFields: resource.loadOnFields.map((element) {
              return DynamicFormResourceLoadOnFieldItem(
                detail: element.detail,
                source: element.source,
                target: element.target,
              );
            }).toList(),
          );
        }
      }
    }

    return null;
  }

  static Future<Data?> resourceData({
    required HeaderForm headerForm,
    required String name,
    required Map<String, dynamic> data,
    required int pageIndex,
    required int pageSize,
    required String? query,
    required String? customerId,
  }) async {
    for (Resource resource in headerForm.template.resources) {
      if (StringUtils.equalsIgnoreCase(resource.name, name)) {
        Schema? schema = findSchema(resource.table);

        if (schema != null) {
          DMLAssemblers dmlAssemblers = DMLAssemblers.create();

          dmlAssemblers.select("*");
          dmlAssemblers.from(resource.table);

          List<ManualFilter> manualFilters = resource.manualFilters.where((element) => StringUtils.isNotNullOrEmpty(element.value)).toList();

          for (ManualFilter manualFilterItem in manualFilters) {
            if (dmlAssemblers.hasWhere()) {
              if (StringUtils.equalsIgnoreCase(manualFilterItem.operation, "OR")) {
                dmlAssemblers.or();
              } else {
                dmlAssemblers.and();
              }
            }

            dmlAssemblers.customWhere("${manualFilterItem.key} ${manualFilterItem.operator} ?");

            // if (manualFilterItem.value.contains("\$selector")) {
            //   if (StringUtils.equalsIgnoreCase(manualFilterItem.operator, "LIKE")) {
            //     dmlAssemblers.parameter("%${(Preferences.getInstance().getString(SharedPreferenceKey.BUSINESS_UNIT_ID) ?? "").toUpperCase()}%");
            //   } else {
            //     dmlAssemblers.parameter(Preferences.getInstance().getString(SharedPreferenceKey.BUSINESS_UNIT_ID));
            //   }
            // } else {
            if (StringUtils.equalsIgnoreCase(manualFilterItem.operator, "LIKE")) {
              dmlAssemblers.parameter("%${manualFilterItem.value.toUpperCase()}%");
            } else {
              dmlAssemblers.parameter(manualFilterItem.value);
            }
            // }
          }

          List<AutoFilter> autoFilters = resource.autoFilters.where((element) => StringUtils.isNotNullOrEmpty(element.value)).toList();

          for (AutoFilter autoFilter in autoFilters) {
            dynamic value;

            if (StringUtils.equalsIgnoreCase(autoFilter.key, "customer_id") && StringUtils.equalsIgnoreCase(autoFilter.value, "customer_id")) {
              if (StringUtils.isNotNullOrEmpty(customerId)) {
                value = customerId;
              }
            } else {
              value = data[autoFilter.key];
            }

            if (value != null) {
              if (dmlAssemblers.hasWhere()) {
                if (StringUtils.equalsIgnoreCase(autoFilter.operation, "OR")) {
                  dmlAssemblers.or();
                } else {
                  dmlAssemblers.and();
                }
              }

              dmlAssemblers.equalTo(autoFilter.key, value);
            }
          }

          bool hasFlagDeleted = ((await (await Sqlites.get()).rawQuery("SELECT COUNT(*) AS result FROM pragma_table_info('${resource.table}') WHERE name='f_delete'")).first["result"] as int) > 0;

          if (hasFlagDeleted) {
            if (dmlAssemblers.hasWhere()) {
              dmlAssemblers.and();
            }

            dmlAssemblers.customWhere("COALESCE(f_delete, 'N') = 'N'");
          }

          bool hasId = ((await (await Sqlites.get()).rawQuery("SELECT COUNT(*) AS result FROM pragma_table_info('${resource.table}') WHERE name='id'")).first["result"] as int) > 0;

          if (hasId) {
            dmlAssemblers.desc("id");
          }

          if (StringUtils.isNotNullOrEmpty(query)) {
            dmlAssemblers
                .and()
                .customWhere("(${resource.fields.map((element) => "COALESCE(CAST($element AS VARCHAR), '')").join("||")}) LIKE '%$query%'");
          }

          dmlAssemblers.limit(pageSize);
          dmlAssemblers.offset((pageIndex - 1) * pageSize);

          return Data(
            size: await dmlAssemblers.count(),
            items: await dmlAssemblers.all(),
          );
        }
      }
    }

    return null;
  }

  static Future<void> save({
    required HeaderForm headerForm,
    required Map<String, dynamic> data,
  }) async {
    Database database = await Sqlites.get();

    await database.transaction((txn) async {
      Iterable<MapEntry<String, dynamic>> entries = data
          .entries
          .where((element) => !(element.value is Map || element.value is List));

      String? id = data["id"];

      if (id != null) {
        String updateSql = "";

        updateSql = "UPDATE ";
        updateSql += headerForm.template.tableName;
        updateSql += " SET ";
        updateSql += "_pending = 'TRUE', ";

        for (int i = 0; i < entries.length; i++) {
          MapEntry<String, dynamic> entry = entries.elementAt(i);

          if (i > 0) {
            updateSql += ", ";
          }

          bool file = false;

          outerLoop:
          for (Section section in headerForm.template.sections) {
            for (Field field in section.fields) {
              if (field.name == entry.key) {
                if (StringUtils.inList(field.type, [DynamicFormFieldType.FILE.name, DynamicFormFieldType.FOTO.name, DynamicFormFieldType.VIDEO.name, DynamicFormFieldType.SIGNATURE.name, DynamicFormFieldType.UPLOAD_FOTO.name, DynamicFormFieldType.UPLOAD_VIDEO.name, DynamicFormFieldType.UPLOAD_SIGNATURE.name])) {
                  file = true;

                  break outerLoop;
                }
              }
            }
          }

          if (entry.value != null) {
            if (file) {
              updateSql += "${entry.key} = '${jsonEncode(entry.value)}'";
            } else {
              updateSql += "${entry.key} = '${entry.value}'";
            }
          } else {
            updateSql += "${entry.key} = NULL";
          }
        }

        updateSql += " WHERE id = '$id';";

        await txn.execute(updateSql);
      } else {
        String insertSql = "";

        insertSql = "INSERT INTO ";
        insertSql += headerForm.template.tableName;
        insertSql += " ( _pending, id, ";
        insertSql += entries.map((e) => e.key).join(", ");
        insertSql += " ) VALUES ( 'TRUE', '*${DateTime.now().millisecondsSinceEpoch}', ";

        for (int i = 0; i < entries.length; i++) {
          MapEntry<String, dynamic> entry = entries.elementAt(i);

          if (i > 0) {
            insertSql += ", ";
          }

          bool file = false;

          outerLoop:
          for (Section section in headerForm.template.sections) {
            for (Field field in section.fields) {
              if (field.name == entry.key) {
                if (StringUtils.inList(field.type, [DynamicFormFieldType.FILE.name, DynamicFormFieldType.FOTO.name, DynamicFormFieldType.VIDEO.name, DynamicFormFieldType.SIGNATURE.name, DynamicFormFieldType.UPLOAD_FOTO.name, DynamicFormFieldType.UPLOAD_VIDEO.name, DynamicFormFieldType.UPLOAD_SIGNATURE.name])) {
                  file = true;

                  break outerLoop;
                }
              }
            }
          }

          if (entry.value != null) {
            if (file) {
              insertSql += "'${jsonEncode(entry.value)}'";
            } else {
              insertSql += "'${entry.value}'";
            }
          } else {
            insertSql += "NULL";
          }
        }

        insertSql += " );";

        await txn.execute(insertSql);
      }
    });
  }

  static Future<void> send({
    required String formId,
    required String dataId,
    String? customerId,
  }) async {
    HeaderForm? headerForm = Offlines.headerForm(formId);

    if (headerForm != null) {
      Map<String, dynamic>? data = await DMLAssemblers
          .create()
          .select("*")
          .from(headerForm.template.tableName)
          .equalTo("id", dataId)
          .first();

      if (data != null) {
        Map<String, dynamic> row = Map<String, dynamic>.from(data);

        row.removeWhere((key, value) {
          for (Section section in headerForm.template.sections) {
            for (Field field in section.fields) {
              if (field.name == key) {
                return false;
              }
            }
          }

          return true;
        });

        if (dataId.contains("*")) {
          row["id"] = null;

          await DotApis.getInstance().dynamicFormInsert(
            formId: formId,
            data: row,
            customerId: customerId,
          );

          final Database database = await Sqlites.get();

          await database.rawQuery("DELETE FROM ${headerForm.template.tableName} WHERE id = ?", [dataId]);
        } else {
          await DotApis.getInstance().dynamicFormUpdate(
            dataId: dataId,
            formId: formId,
            data: row,
            customerId: customerId,
          );
        }
      }
    }
  }
}