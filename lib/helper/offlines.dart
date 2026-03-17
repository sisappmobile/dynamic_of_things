// ignore_for_file: cascade_invocations

import "dart:convert";

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/enumeration/dynamic_form_field_type.dart";
import "package:dynamic_of_things/helper/dml_assemblers.dart";
import "package:dynamic_of_things/helper/sqlites.dart";
import "package:dynamic_of_things/model/dynamic_form_list_response.dart";
import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";
import "package:dynamic_of_things/model/dynamic_form_resource_response.dart";
import "package:dynamic_of_things/model/header_form.dart" hide Action, Field;
import "package:sqflite/sqflite.dart";

class Data {
  final int size;
  final List<Map<String, dynamic>> items;

  Data({required this.size, required this.items});
}

Future<void> setSalesUnitId(String value) async {
  await BasePreferences.getInstance().setString("dot-sales-unit-id", value);
}

String get currentSalesUnitId => BasePreferences.getInstance().getString("dot-sales-unit-id")!;

Future<void> setUserId(String? value) async {
  if (StringUtils.isNotNullOrEmpty(value)) {
    await BasePreferences.getInstance().setString("dot-user-id", value);
  }
}

String? get currentUserId => BasePreferences.getInstance().getString("dot-user-id");

Future<void> setCompanyId(String value) async {
  await BasePreferences.getInstance().setString("dot-company-id", value);
}

String get currentCompanyId => BasePreferences.getInstance().getString("dot-company-id")!;

class Offlines {
  static Future<DynamicFormMenuResponse> menus(bool journey) async {
    List<Map<String, dynamic>> rows = await DMLAssemblers
        .create()
        .select("DISTINCT CAST(COALESCE(d.category_id, c.category_id) AS TEXT) AS category_id")
        .select("CAST(COALESCE(d.id, c.id) AS TEXT) AS id")
        .select("COALESCE(d.report_name, c.form_desc) AS name")
        .select('COALESCE(d."index", c."index") AS "index"')
        .select("(CASE WHEN COALESCE(a.custom_type, 'FORM') = 'FORM' THEN (CASE WHEN c.template_mode = 'SCHEDULE' THEN 'SCHEDULE' ELSE 'FORM' END) ELSE 'REPORT' END) AS type")
        .select("(CASE WHEN COALESCE(a.custom_type, 'FORM') = 'FORM' THEN c.base_path_icon END) AS icon")
        .select("(CASE WHEN COALESCE(a.custom_type, 'FORM') = 'FORM' THEN (SELECT CAST(z.id AS TEXT) FROM c_custom_form z WHERE z.table_header_id = c.source_table_reference_id) END) AS reference_id")
        .select("(CASE WHEN COALESCE(a.custom_type, 'FORM') = 'FORM' THEN (SELECT z.form_desc FROM c_custom_form z WHERE z.table_header_id = c.source_table_reference_id) END) AS reference_name")
        .from("c_sales_access_custom_form a")
        .join("INNER JOIN c_group_access_sales_unit_custom_form_detail b ON b.group_id = a.group_id")
        .join("LEFT JOIN c_custom_form c ON c.id = a.custom_id AND COALESCE(a.custom_type, 'FORM') = 'FORM' AND c.company_id = ? AND COALESCE(c.f_visit, 'N') = 'Y' AND COALESCE(c.f_journey, 'N') = ? and coalesce(c.f_active,'N') = 'Y'")
        .parameter(currentCompanyId)
        .parameter(journey ? "Y" : "N")
        .join("LEFT JOIN c_custom_report d ON d.id = a.custom_id AND COALESCE(a.custom_type, 'FORM') = 'REPORT' AND d.company_id = ?")
        .parameter(currentCompanyId)
        .equalTo("b.user_id", currentSalesUnitId)
        .and()
        .customWhere("(d.id IS NOT NULL OR c.id IS NOT NULL)")
        .all();

    DynamicFormMenuResponse dynamicFormMenuResponse = DynamicFormMenuResponse(categories: []);

    for (Map<String, dynamic> row in rows) {
      DynamicFormCategoryItem? dynamicFormCategoryItem;

      for (DynamicFormCategoryItem dynamicFormCategoryItemCheck in dynamicFormMenuResponse.categories) {
        if (dynamicFormCategoryItemCheck.id == row["category_id"]) {
          dynamicFormCategoryItem = dynamicFormCategoryItemCheck;

          break;
        }
      }

      if (dynamicFormCategoryItem == null) {
        Map<String, dynamic>? category = await DMLAssemblers
            .create()
            .select("*")
            .from("c_custom_form_category")
            .equalTo("id", row["category_id"])
            .first();

        if (category != null) {
          dynamicFormCategoryItem = DynamicFormCategoryItem(
            id: category["id"].toString(),
            name: category["description"],
            index: category["index"] ?? 99,
            menus: [],
          );

          dynamicFormMenuResponse.categories.add(dynamicFormCategoryItem);
        }
      }

      if (dynamicFormCategoryItem != null) {
        String icon = row["icon"] ?? "";

        icon = utf8.decode(base64Decode(icon.substring(icon.indexOf(",") + 1)));

        // 2. Definisi Regex
        // Di Dart, kita menggunakan raw string (r'...') agar tidak perlu double escape backslash
        final regex = RegExp(r"<svg[^>]*?>\s*(<svg.*?</svg>)\s*</svg>", dotAll: true);

        // 3. Pencocokan pola
        final match = regex.firstMatch(icon);

        if (match != null) {
          // group(1) mengambil hasil tangkapan di dalam tanda kurung pertama
          icon = match.group(1)!;
        }

        DynamicFormMenuItem dynamicFormMenuItem = DynamicFormMenuItem(
          id: row["id"],
          name: row["name"],
          index: row["index"] ?? 99,
          type: row["type"],
          icon: icon,
          referenceId: row["reference_id"],
          referenceName: row["reference_name"],
        );

        dynamicFormCategoryItem.menus.add(dynamicFormMenuItem);
      }
    }

    return dynamicFormMenuResponse;
  }

  static Future<ListResponse?> list({
    required String id,
    String? customerId,
  }) async {
    Map<String, dynamic>? customFormView = await DMLAssemblers
        .create()
        .select("a.*")
        .select("b.table_name")
        .from("c_custom_form a")
        .join("INNER JOIN f_dynamic_table b ON b.id = a.table_header_id")
        .equalTo("a.id", id)
        .first();

    if (customFormView == null) {
      throw Exception("Form tidak ditemukan");
    }

    ListResponse listResponse = ListResponse(
      createUsingScanQr: customFormView["f_create_using_scan_qr"] == "Y",
      actions: [],
      fields: [],
      data: [],
    );

    List<Map<String, dynamic>> actions = await DMLAssemblers
        .create()
        .select("DISTINCT CAST(e.function_id AS TEXT) AS id")
        .select("e.resource_id AS resource_id")
        .select("e.function_name AS name")
        .from("c_group_access_sales_unit_custom_form a")
        .join("INNER JOIN c_group_access_sales_unit_custom_form_detail b ON b.group_id = a.id")
        .join("INNER JOIN c_sales_access_custom_form c ON c.group_id = a.id")
        .join("INNER JOIN c_sales_access_function_custom_form d ON d.access_id = c.id")
        .join("INNER JOIN c_custom_functions e ON e.resource_id = d.resource_id AND e.custom_id = c.custom_id")
        .equalTo("b.user_id", currentSalesUnitId)
        .and()
        .equalTo("c.custom_id", id)
        .and()
        .customWhere("(COALESCE(e.f_show_inlist, 'N') = 'Y' OR e.resource_id IN ('BTN_CREATE', 'BTN_EDIT', 'BTN_VIEW'))")
        .all();

    for (Map<String, dynamic> action in actions) {
      listResponse.actions.add(
        Action(
          id: action["id"],
          resourceId: action["resource_id"],
          name: action["name"],
        ),
      );
    }

    List<Map<String, dynamic>> fields = await DMLAssemblers
        .create()
        .select("*")
        .from("c_field_custom_form")
        .equalTo("custom_id", id)
        .and()
        .customWhere("(COALESCE(f_show_list, 'N') = 'Y' OR COALESCE(f_pk, 'N') = 'Y')")
        .desc("COALESCE(f_pk, 'N')")
        .asc("COALESCE(index_field, 0)")
        .all();

    for (Map<String, dynamic> field in fields) {
      listResponse.fields.add(
        Field(
          name: field["field_name"],
          type: DynamicFormFieldType.convert(field["field_data_type"]).name,
          description: field["field_caption"],
          primaryKey: field["f_pk"] == "Y",
        ),
      );
    }

    DMLAssemblers dmlAssemblers = DMLAssemblers
        .create()
        .select("*")
        .from(customFormView["table_name"])
        .equalTo("company_id", currentCompanyId);

    if (customerId != null) {
      dmlAssemblers
          .and()
          .equalTo("customer_id", customerId);
    }

    List<Map<String, dynamic>> filterFields = await DMLAssemblers
        .create()
        .select("a.*")
        .select("b.column_name")
        .from("c_custom_filter_field a")
        .join("INNER JOIN f_dynamic_table_detail b ON b.id = a.field_name")
        .equalTo("a.custom_id", id)
        .all();

    for (Map<String, dynamic> filterField in filterFields) {
      String fieldType = filterField["field_type"];
      String? filterValue = filterField["value"] ?? filterField["default_value"];

      if (filterValue != null) {
        dmlAssemblers.customWhere("${filterField["column_name"]} ${filterField["field_operator"]} ?");

        if (filterField["field_operator"] == "LIKE") {
          if (filterValue == "\$selector") {
            dmlAssemblers.parameter("%,$currentSalesUnitId,%");
          } else {
            dmlAssemblers.parameter("%$filterValue%");
          }
        } else {
          dmlAssemblers.parameter(filterValue);
        }
      }
    }

    List<String> userIds = [];
    List<String> salesUnitIds = [];

    if (customFormView["f_visit"] == "Y" && customFormView["f_creator"] == "Y") {
      salesUnitIds.add(currentSalesUnitId);
    }

    if (customFormView["f_user_group"] == "Y") {
      List<String> userGroupIds = (customFormView["list_user_group"] as String).split(",");

      List<Map<String, dynamic>> userGroups = await DMLAssemblers
          .create()
          .select("user_source")
          .select("user_id")
          .from("c_user_group_detail")
          .inn("user_group_id", userGroupIds)
          .all();

      for (Map<String, dynamic> userGroup in userGroups) {
        String userSource = userGroup["user_source"];
        String userId = userGroup["user_id"];

        if (userSource == "VISITQU") {
          salesUnitIds.add(userId);
        } else {
          userIds.add(userId);
        }
      }
    }

    // TODO: Filter by sales structure

    String dataFilterClauseBuilder = "";

    if (userIds.isNotEmpty) {
      dataFilterClauseBuilder += "create_who IN (${List.generate(userIds.length, (index) => "?").join(", ")})";

      for (String userId in userIds) {
        dmlAssemblers.parameter(userId);
      }
    }

    if (salesUnitIds.isNotEmpty) {
      if (dataFilterClauseBuilder.isNotEmpty) {
        dataFilterClauseBuilder += " OR ";
      }

      dataFilterClauseBuilder += "salesunit_id IN (${List.generate(salesUnitIds.length, (index) => "?").join(", ")})";

      for (String salesUnitId in salesUnitIds) {
        dmlAssemblers.parameter(salesUnitId);
      }
    }

    if (customFormView["f_by_field_value"] == "Y") {
      String? columnName = (await DMLAssemblers
          .create()
          .select("column_name")
          .from("f_dynamic_table_detail")
          .equalTo("id", customFormView["by_field_value_id"])
          .first())?["column_name"];

      if (StringUtils.isNotNullOrEmpty(columnName)) {
        if (dataFilterClauseBuilder.isNotEmpty) {
          dataFilterClauseBuilder += " OR ";
        }

        dataFilterClauseBuilder += "$columnName IN (?, ?)";

        String userId = currentUserId ?? "-1";

        dmlAssemblers.parameter(currentSalesUnitId);
        dmlAssemblers.parameter(userId);
      }
    }

    if (dataFilterClauseBuilder.isNotEmpty) {
      dmlAssemblers
          .and()
          .customWhere("($dataFilterClauseBuilder)");
    }

    listResponse.data.addAll(await dmlAssemblers.all());

    return listResponse;
  }

  static Future<HeaderForm?> create({
    required String formId,
    String? customerId,
    String? extra,
    String? referenceId,
  }) async {
    return null;
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
    return null;
  }

  static Future<void> save({
    required HeaderForm headerForm,
    required Map<String, dynamic> data,
  }) async {

  }

  static Future<void> send({
    required String formId,
    required String dataId,
    String? customerId,
  }) async {

  }
}