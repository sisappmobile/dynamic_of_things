// ignore_for_file: cascade_invocations, avoid_print

import "dart:convert";

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:collection/collection.dart";
import "package:dynamic_of_things/enumeration/dynamic_form_field_type.dart";
import "package:dynamic_of_things/helper/dml_assemblers.dart";
import "package:dynamic_of_things/helper/json_script_engine.dart";
import "package:dynamic_of_things/helper/sqlites.dart";
import "package:dynamic_of_things/model/dynamic_form_list_response.dart";
import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";
import "package:dynamic_of_things/model/dynamic_form_resource_response.dart";
import "package:dynamic_of_things/model/header_form.dart" hide Action, Field;
import "package:sqflite/sqflite.dart";
import "package:uuid/uuid.dart";

class SubDetailCarrier {
  late Map<String, dynamic> customFormView;
  late List<Map<String, dynamic>> fields;
}

class DetailCarrier {
  late Map<String, dynamic> customFormView;
  late List<Map<String, dynamic>> fields;
  final List<SubDetailCarrier> subDetailCarriers = [];
}

class Carrier {
  late Map<String, dynamic> customFormView;
  late List<Map<String, dynamic>> fields;
  final List<DetailCarrier> detailCarriers = [];
}

class FormContainer {
  late Carrier carrier;
  late Map<String, dynamic> data;

  Map<String, dynamic> convert() {
    Map<String, dynamic> hashMap = {};

    outerLoop:
    for (MapEntry<String, dynamic> mapEntry in data.entries) {
      if (mapEntry.value != null) {
        if (!(mapEntry.value is List || mapEntry.value is Map)) {
          Map<String, dynamic>? fieldCustomFormView = carrier.fields.firstWhereOrNull((element) => element["field_name"] == mapEntry.key);

          hashMap[mapEntry.key] = Offlines.convert(mapEntry.value, fieldCustomFormView);
        } else {
          for (DetailCarrier detailCarrier in carrier.detailCarriers) {
            if (mapEntry.key == detailCarrier.customFormView["table_name"]) {
              if (mapEntry.value is Map) {
                Map<String, dynamic> detailData = Map<String, dynamic>.from(mapEntry.value);

                hashMap[mapEntry.key] = Offlines.hashDTOToMap(detailData, detailCarrier.fields);
              } else {
                List<Map<String, dynamic>> details = List<Map<String, dynamic>>.from(mapEntry.value);

                List<Map<String, dynamic>> detailMaps = [];

                for (Map<String, dynamic> detailDTO in details) {
                  Map<String, dynamic> detailMap = {};

                  for (MapEntry<String, dynamic> detailMapEntry in detailDTO.entries) {
                    if (detailMapEntry.value != null) {
                      if (detailMapEntry.value is List) {
                        for (SubDetailCarrier subDetailCarrier in detailCarrier.subDetailCarriers) {
                          if (detailMapEntry.key == subDetailCarrier.customFormView["table_name"]) {
                            List<Map<String, dynamic>> subDetails = detailMapEntry.value as List<Map<String, dynamic>>;

                            List<Map<String, dynamic>> subDetailMaps = [];

                            for (Map<String, dynamic> subDetailDTO in subDetails) {
                              if (subDetailDTO["header_id"] == detailDTO["id"]) {
                                Map<String, dynamic> subDetailMap = Offlines.hashDTOToMap(subDetailDTO, subDetailCarrier.fields);

                                subDetailMaps.add(subDetailMap);
                              }
                            }

                            detailMap[detailMapEntry.key] = subDetailMaps;
                          }
                        }
                      } else {
                        Map<String, dynamic>? fieldCustomFormView = detailCarrier.fields.firstWhereOrNull((element) => element["field_name"] == detailMapEntry.key);

                        detailMap[detailMapEntry.key] = Offlines.convert(detailMapEntry.value, fieldCustomFormView);
                      }
                    }
                  }

                  detailMaps.add(detailMap);
                }

                hashMap[mapEntry.key] = detailMaps;
              }

              continue outerLoop;
            }
          }
        }
      }
    }

    return hashMap;
  }
}

Future<void> setSalesUnitId(String value) async {
  await BasePreferences.getInstance().setString("dot-sales-unit-id", value);
}

String get currentSalesUnitId => BasePreferences.getInstance().getString("dot-sales-unit-id")!;

Future<void> setUsername(String value) async {
  await BasePreferences.getInstance().setString("dot-username", value);
}

String get currentUsername => BasePreferences.getInstance().getString("dot-username")!;

Future<void> setBusinessUnitId(String value) async {
  await BasePreferences.getInstance().setString("dot-business-unit-id", value);
}

String get currentBusinessUnitId => BasePreferences.getInstance().getString("dot-business-unit-id")!;

Future<void> setBusinessUnitCode(String value) async {
  await BasePreferences.getInstance().setString("dot-business-unit-code", value);
}

String get currentBusinessUnitCode => BasePreferences.getInstance().getString("dot-business-unit-code")!;

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
      String fieldDataType = field["field_data_type"];

      if (field["field_name"] == "salesunit_id") {
        fieldDataType = "SHORT_TEXT";
      } else {
        fieldDataType = DynamicFormFieldType.convert(fieldDataType).name;
      }
      listResponse.fields.add(
        Field(
          name: field["field_name"],
          type: fieldDataType,
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
      String _ = filterField["field_type"];
      String? filterValue = filterField["value"] ?? filterField["default_value"];

      if (filterValue != null) {
        dmlAssemblers
            .and()
            .customWhere("${filterField["column_name"]} ${filterField["field_operator"]} ?");

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

    if (customFormView["f_structure"] == "Y") {
      List<Map<String, dynamic>> childSalesUnits = await DMLAssemblers
          .create()
          .select("CAST(c.salesunit_id AS TEXT) AS salesunit_id")
          .from("m_salesunit a")
          .join("INNER JOIN m_sales_structure_detail b ON b.sales_structure_upper_id = a.sales_structure_id")
          .join("INNER JOIN m_salesunit c ON c.sales_structure_id = b.sales_structure_lower_id")
          .equalTo("a.salesunit_id", currentSalesUnitId)
          .all();

      for (Map<String, dynamic> childSalesUnit in childSalesUnits) {
        salesUnitIds.add(childSalesUnit["salesunit_id"]);
      }
    }

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

    List<Map<String, dynamic>> rows = await dmlAssemblers.all();

    for (Map<String, dynamic> row in rows) {
      if (row.containsKey("salesunit_id")) {
        row["salesunit_id"] = (await DMLAssemblers
            .create()
            .select("salesunit_name")
            .from("m_salesunit")
            .equalTo("salesunit_id", row["salesunit_id"])
            .first()
        )?["salesunit_name"];
      }
    }

    listResponse.data.addAll(rows);

    return listResponse;
  }

  static Future<Map<String, dynamic>?> loadCustomFormView(String formId) async {
    return await DMLAssemblers
        .create()
        .select("a.*")
        .select("b.table_name")
        .from("c_custom_form a")
        .join("INNER JOIN f_dynamic_table b ON b.id = a.table_header_id")
        .equalTo("a.id", formId)
        .first();
  }

  static Future<HeaderForm?> create({
    required String formId,
    String? customerId,
    String? extra,
    String? referenceId,
  }) async {
    Map<String, dynamic>? customFormView = await loadCustomFormView(formId);

    if (customFormView != null) {
      FormContainer container = await loadContainer(customFormView);

      Map<String, dynamic>? customFunctionsView = await DMLAssemblers
          .create()
          .select("*")
          .from("c_custom_functions")
          .equalTo("custom_id", customFormView["id"])
          .and()
          .customWhere("COALESCE(f_default, 'N') = 'Y'")
          .and()
          .equalTo("resource_id = ?", "BTN_CREATE")
          .first();

      if (customFunctionsView != null) {
        List<String> scripts = [];

        if (StringUtils.isNotNullOrEmpty(customFunctionsView["pseudo_code"])) {
          scripts.add(customFunctionsView["pseudo_code"]);
        }

        if (scripts.isNotEmpty) {
          JsonScriptEngine jsonScriptEngine = JsonScriptEngine();

          for (String script in scripts) {
            try {
              container.data = jsonScriptEngine.run(container.data, script);
            } on ScriptValidationException catch (e) {
              BaseOverlays.error(message: e.message);

              return null;
            }
          }
        }
      }

      HeaderForm headerForm = await Offlines.loadHeaderForm(0, container);

      if (StringUtils.isNotNullOrEmpty(referenceId)) {
        String? tableName = (await DMLAssemblers
            .create()
            .select("b.table_name")
            .from("c_custom_form a")
            .join("INNER JOIN f_dynamic_table b ON b.id = a.source_table_reference_id")
            .equalTo("a.id", formId)
            .and()
            .customWhere("COALESCE(a.f_create_from_reference, 'N') = 'Y'")
            .first())?["table_name"];

        if (tableName != null) {
          Map<String, dynamic>? referenceRow = await DMLAssemblers
              .create()
              .select("*")
              .from(tableName)
              .equalTo("id", referenceId)
              .first();

          if (referenceRow != null) {
            List<Map<String, dynamic>> createFromReferenceViews = await DMLAssemblers
                .create()
                .select("*")
                .from("c_create_from_reference")
                .equalTo("custom_id", customFormView["id"])
                .asc("create_date")
                .all();

            for (Map<String, dynamic> createFromReferenceView in createFromReferenceViews) {
              headerForm.data[createFromReferenceView["dst_key"]] = referenceRow[createFromReferenceView["src_key"]];
            }
          }
        }
      }

      if (StringUtils.isNotNullOrEmpty(extra)) {
        Map<String, dynamic>? qrMetaData = await DMLAssemblers
            .create()
            .select("b.table_name")
            .select("c.column_name")
            .from("c_custom_form a")
            .join("INNER JOIN f_dynamic_table b ON b.id = a.source_table_qr_id")
            .join("INNER JOIN f_dynamic_table_detail c ON c.id = a.source_field_qr_id")
            .equalTo("a.id", formId)
            .and()
            .equalTo("a.using_qr_type", "LOAD_ON_FIELD")
            .first();

        if (qrMetaData != null) {
          Map<String, dynamic>? qrRow = await DMLAssemblers
              .create()
              .select("*")
              .from(qrMetaData["table_name"])
              .equalTo(qrMetaData["column_name"], extra)
              .first();

          if (qrRow != null) {
            List<Map<String, dynamic>> createUsingScanQrViews = await DMLAssemblers
                .create()
                .select("*")
                .from("c_create_using_scan_qr")
                .equalTo("custom_id", customFormView["id"])
                .asc("create_date")
                .all();

            for (Map<String, dynamic> createUsingScanQrView in createUsingScanQrViews) {
              if (headerForm.data.containsKey(createUsingScanQrView["dst_key"])) {
                if (headerForm.data[createUsingScanQrView["dst_key"]] != qrRow[createUsingScanQrView["src_key"]]) {
                  BaseOverlays.error(message: "Data QR tidak sama dengan data referensi");

                  return null;
                }
              }

              headerForm.data[createUsingScanQrView["dst_key"]] = qrRow[createUsingScanQrView["src_key"]];
            }
          }

          for (Map<String, dynamic> fieldCustomFormView in container.carrier.fields) {
            if (StringUtils.inList(fieldCustomFormView["field_data_type"], ["DATA", "MULTIDATA"])) {
              List<Map<String, dynamic>> selectedFields = await DMLAssemblers
                  .create()
                  .select("column_name")
                  .from("f_dynamic_table_detail")
                  .customWhere("id IN (${fieldCustomFormView["column_data_select"]})")
                  .all();

              if (selectedFields.any((selectedField) => selectedField["column_name"] == qrMetaData["column_name"])) {
                String? keyColumnName = (await DMLAssemblers
                    .create()
                    .select("d.column_name AS key_column_name")
                    .from("c_field_custom_form a")
                    .join("INNER JOIN f_dynamic_table_detail b ON b.id = a.column_id")
                    .join("INNER JOIN f_dynamic_table c ON c.id = b.src_table_id")
                    .join("INNER JOIN f_dynamic_table_detail d ON d.id = b.src_column_id")
                    .equalTo("a.id", fieldCustomFormView["id"])
                    .first()
                )?["key_column_name"];

                if (keyColumnName != null) {
                  Map<String, dynamic>? resourceData = await dynamicFormResourceData(
                    formId: formId,
                    name: fieldCustomFormView["field_name"],
                    dataMap: {},
                    pageIndex: 1,
                    pageSize: 50,
                    query: null,
                    customerId: customerId,
                  );

                  if (resourceData != null) {
                    List<Map<String, dynamic>> items = resourceData["items"];

                    for (Map<String, dynamic> item in items) {
                      if (extra == item[qrMetaData["column_name"]]) {
                        headerForm.data[fieldCustomFormView["field_name"]] = item[keyColumnName];

                        List<Map<String, dynamic>> fieldLoadOnFieldViews = await DMLAssemblers
                            .create()
                            .select("*")
                            .from("c_field_load_on_field")
                            .equalTo("field_id", fieldCustomFormView["id"])
                            .all();

                        for (Map<String, dynamic> fieldLoadOnFieldView in fieldLoadOnFieldViews) {
                          headerForm.data[fieldLoadOnFieldView["dst_key"]] = item[fieldLoadOnFieldView["src_key"]];
                        }

                        List<Map<String, dynamic>> fieldLoadOnFieldDetailViews = await DMLAssemblers
                            .create()
                            .select("*")
                            .from("c_field_load_on_field_detail")
                            .equalTo("field_id", fieldCustomFormView["id"])
                            .all();

                        if (fieldLoadOnFieldDetailViews.isNotEmpty && container.carrier.detailCarriers.isNotEmpty) {
                          List<Map<String, dynamic>>? detailItems = item["details"];
                          List<Map<String, dynamic>> detailDatas = [];

                          if (detailItems != null) {
                            for (Map<String, dynamic> detailItem in detailItems) {
                              Map<String, dynamic> detailData = {};

                              for (Map<String, dynamic> fieldLoadOnFieldDetailView in fieldLoadOnFieldDetailViews) {
                                detailData[fieldLoadOnFieldDetailView["src_key"]] = detailItem[fieldLoadOnFieldDetailView["dst_key"]];
                              }

                              detailDatas.add(detailData);
                            }
                          }

                          headerForm.data[container.carrier.detailCarriers[0].customFormView["table_name"]] = detailDatas;
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      return headerForm;
    }

    return null;
  }

  static Future<HeaderForm?> view({
    required String formId,
    required String dataId,
  }) async {
    Map<String, dynamic>? customFormView = await loadCustomFormView(formId);

    if (customFormView != null) {
      FormContainer container = await loadContainer(customFormView, dataId);

      HeaderForm headerForm = await Offlines.loadHeaderForm(1, container);

      return headerForm;
    }

    return null;
  }

  static Future<HeaderForm?> edit({
    required String formId,
    required String dataId,
  }) async {
    Map<String, dynamic>? customFormView = await loadCustomFormView(formId);

    if (customFormView != null) {
      FormContainer container = await loadContainer(customFormView, dataId);

      Map<String, dynamic>? customFunctionsView = await DMLAssemblers
          .create()
          .select("*")
          .from("c_custom_functions")
          .equalTo("custom_id", customFormView["id"])
          .and()
          .customWhere("COALESCE(f_default, 'N') = 'Y'")
          .and()
          .equalTo("resource_id = ?", "BTN_EDIT")
          .first();

      if (customFunctionsView != null) {
        List<String> scripts = [];

        if (StringUtils.isNotNullOrEmpty(customFunctionsView["pseudo_code"])) {
          scripts.add(customFunctionsView["pseudo_code"]);
        }

        if (scripts.isNotEmpty) {
          JsonScriptEngine jsonScriptEngine = JsonScriptEngine();

          for (String script in scripts) {
            try {
              container.data = jsonScriptEngine.run(container.data, script);
            } on ScriptValidationException catch (e) {
              BaseOverlays.error(message: e.message);

              return null;
            }
          }
        }
      }

      HeaderForm headerForm = await Offlines.loadHeaderForm(2, container);

      return headerForm;
    }

    return null;
  }

  static Future<FormContainer> loadContainer(Map<String, dynamic> customFormView, [dynamic variable]) async {
    FormContainer container = FormContainer();

    {
      Carrier carrier = Carrier();

      carrier.customFormView = customFormView;
      carrier.fields = await loadFields(customFormView);

      for (Map<String, dynamic> cfvDetail in await loadDetailForms(customFormView)) {
        DetailCarrier detailCarrier = DetailCarrier();

        detailCarrier.customFormView = cfvDetail;
        detailCarrier.fields = await loadFields(cfvDetail);

        for (Map<String, dynamic> cfvSubDetail in await loadSubDetailForms(cfvDetail)) {
          SubDetailCarrier subDetailCarrier = SubDetailCarrier();

          subDetailCarrier.customFormView = cfvSubDetail;
          subDetailCarrier.fields = await loadFields(cfvSubDetail);

          detailCarrier.subDetailCarriers.add(subDetailCarrier);
        }

        carrier.detailCarriers.add(detailCarrier);
      }

      container.carrier = carrier;
    }

    {
      Map<String, dynamic> targetHeader;

      if (variable != null) {
        if (variable is Map) {
          Map<String, dynamic> sourceHeader = Map<String, dynamic>.from(variable);

          targetHeader = mapToHashDTO(sourceHeader);

          for (DetailCarrier detailCarrier in container.carrier.detailCarriers) {
            if (detailCarrier.customFormView["template_mode"] == "LIST") {
              List<Map<String, dynamic>> sourceDetails = sourceHeader[detailCarrier.customFormView["table_name"]];

              List<Map<String, dynamic>> targetDetails = [];

              for (Map<String, dynamic> sourceDetail in sourceDetails) {
                Map<String, dynamic> targetDetail = mapToHashDTO(sourceDetail);

                for (SubDetailCarrier subDetailCarrier in detailCarrier.subDetailCarriers) {
                  List<Map<String, dynamic>> sourceSubDetails = sourceDetail[subDetailCarrier.customFormView["table_name"]];

                  List<Map<String, dynamic>> targetSubDetails = [];

                  for (Map<String, dynamic> sourceSubDetail in sourceSubDetails) {
                    Map<String, dynamic> targetSubDetail = mapToHashDTO(sourceSubDetail);

                    targetSubDetails.add(targetSubDetail);
                  }

                  targetDetail[subDetailCarrier.customFormView["table_name"]] = targetSubDetails;
                }

                targetDetails.add(targetDetail);
              }

              targetHeader[detailCarrier.customFormView["table_name"]] = targetDetails;
            } else {
              Map<String, dynamic> sourceDetail = sourceHeader[detailCarrier.customFormView["table_name"]];

              targetHeader[detailCarrier.customFormView["table_name"]] = mapToHashDTO(sourceDetail);
            }
          }
        } else {
          targetHeader = (await DMLAssemblers
              .create()
              .select("*")
              .from(container.carrier.customFormView["table_name"])
              .equalTo("id", variable)
              .first())!;

          for (DetailCarrier detailCarrier in container.carrier.detailCarriers) {
            if (detailCarrier.customFormView["template_mode"] == "LIST") {
              List<Map<String, dynamic>> targetDetails = await DMLAssemblers
                  .create()
                  .select("*")
                  .from(detailCarrier.customFormView["table_name"])
                  .equalTo("header_id", targetHeader["id"])
                  .and()
                  .customWhere("COALESCE(f_delete, 'N') = 'N'")
                  .all();

              for (Map<String, dynamic> targetDetail in targetDetails) {
                for (SubDetailCarrier subDetailCarrier in detailCarrier.subDetailCarriers) {
                  List<Map<String, dynamic>> targetSubDetails = await DMLAssemblers
                      .create()
                      .select("*")
                      .from(subDetailCarrier.customFormView["table_name"])
                      .equalTo("header_id", targetDetail["id"])
                      .and()
                      .customWhere("COALESCE(f_delete, 'N') = 'N'")
                      .all();

                  targetDetail[subDetailCarrier.customFormView["table_name"]] = targetSubDetails;
                }
              }

              targetHeader[detailCarrier.customFormView["table_name"]] = targetDetails;
            } else {
              Map<String, dynamic> targetDetail = (await DMLAssemblers
                  .create()
                  .select("*")
                  .from(detailCarrier.customFormView["table_name"])
                  .equalTo("header_id", targetHeader["id"])
                  .and()
                  .customWhere("COALESCE(f_delete, 'N') = 'N'")
                  .first()) ?? {};

              targetHeader[detailCarrier.customFormView["table_name"]] = targetDetail;
            }
          }
        }
      } else {
        targetHeader = {};
      }

      container.data = targetHeader;
    }

    return container;
  }

  static Map<String, dynamic> mapToHashDTO(Map<String, dynamic> map) {
    Map<String, dynamic> hashDTO = {};

    for (MapEntry<String, dynamic> mapEntry in map.entries) {
      if (mapEntry.value != null) {
        if (mapEntry.value is! List) {
          hashDTO[mapEntry.key] = mapEntry.value;
        }
      }
    }

    return hashDTO;
  }

  static Future<List<Map<String, dynamic>>> loadFields(Map<String, dynamic> customFormView) async {
    return await DMLAssemblers
        .create()
        .select("*")
        .from("c_field_custom_form")
        .equalTo("custom_id", customFormView["id"])
        .asc("group_field_index")
        .asc("index_field")
        .all();
  }

  static Future<List<Map<String, dynamic>>> loadDetailForms(Map<String, dynamic> customFormView) async {
    List<Map<String, dynamic>> results = [];

    if (customFormView["table_detail_id"] != null) {
      results.addAll(
        await DMLAssemblers
            .create()
            .select("a.*")
            .select("b.table_name")
            .select("b.sequence_name")
            .from("c_custom_form a")
            .join("INNER JOIN f_dynamic_table b ON b.id = a.table_header_id")
            .equalTo("a.id", customFormView["table_detail_id"])
            .all(),
      );
    } else {
      results.addAll(
        await DMLAssemblers
            .create()
            .select("b.*")
            .select("c.table_name")
            .select("c.sequence_name")
            .from("c_custom_multiple_detail a")
            .join("INNER JOIN c_custom_form b ON b.id = a.table_id")
            .join("INNER JOIN f_dynamic_table c ON c.id = b.table_header_id")
            .equalTo("a.custom_id", customFormView["id"])
            .asc('a."index"')
            .all(),
      );
    }

    results.addAll(
      await DMLAssemblers
          .create()
          .select("b.*")
          .select("c.table_name")
          .select("c.sequence_name")
          .from("c_custom_form_group a")
          .join("INNER JOIN c_custom_form b ON b.id = a.form_id")
          .join("INNER JOIN f_dynamic_table c ON c.id = b.table_header_id")
          .equalTo("a.form_group_id", customFormView["id"])
          .asc("a.form_group_index")
          .all(),
    );

    return results;
  }

  static Future<List<Map<String, dynamic>>> loadSubDetailForms(Map<String, dynamic> customFormView) async {
    return await DMLAssemblers
        .create()
        .select("b.*")
        .select("c.table_name")
        .select("c.sequence_name")
        .from("c_custom_form_sub_detail a")
        .join("INNER JOIN c_custom_form b ON b.id = a.custom_detail_id")
        .join("INNER JOIN f_dynamic_table c ON c.id = b.table_header_id")
        .equalTo("a.custom_detail_header_id", customFormView["id"])
        .and()
        .customWhere("COALESCE(a.f_delete, 'N') = 'N'")
        .asc("a.detail_layer")
        .all();
  }

  static Future<HeaderForm> loadHeaderForm(int mode, FormContainer container, {
    Transaction? transaction,
  }) async {
    HeaderForm headerForm = HeaderForm();

    {
      Map<String, dynamic> customFormCategoryView = (await DMLAssemblers
          .create()
          .select("*")
          .from("c_custom_form_category")
          .equalTo("id", container.carrier.customFormView["category_id"])
          .first(transaction))!;

      Category category = Category();

      category.id = customFormCategoryView["id"].toString();
      category.name = customFormCategoryView["description"];
      category.index = customFormCategoryView["index"] ?? 99;

      Menu menu = Menu();

      menu.id = container.carrier.customFormView["id"].toString();
      menu.name = container.carrier.customFormView["form_desc"];
      menu.index = container.carrier.customFormView["index"];
      menu.type = "FORM";

      category.menu = menu;

      headerForm.category = category;
    }

    headerForm.template = await Template.loadTemplate(mode, container.carrier.customFormView, container.carrier.fields, transaction: transaction);

    for (DetailCarrier detailCarrier in container.carrier.detailCarriers) {
      headerForm.detailForms.add(await DetailForm.load(mode: mode, detailCarrier: detailCarrier, transaction: transaction));
    }

    if (headerForm.detailForms.length == 1) {
      if (container.carrier.customFormView["detail_index"] != null) {
        headerForm.detailForms.elementAt(0).sectionIndex = container.carrier.customFormView["detail_index"];
      }
    }

    headerForm.data = container.convert();
    headerForm.hasOnChangeEvent = container.carrier.fields.any((element) => StringUtils.isNotNullOrEmpty(element["pseudo_code"]));

    return headerForm;
  }

  static dynamic convert(dynamic value, Map<String, dynamic>? fieldCustomFormView) {
    if (value != null && fieldCustomFormView != null) {
      String dataType = fieldCustomFormView["field_data_type"];

      if (StringUtils.inList(dataType, ["FILE", "FOTO", "VIDEO", "SIGNATURE", "UPLOAD_FOTO", "UPLOAD_VIDEO", "UPLOAD_SIGNATURE"])) {
        return jsonDecode(value);
      }
    }

    return value;
  }

  static Map<String, dynamic> hashDTOToMap(Map<String, dynamic> hashDTO, List<Map<String, dynamic>> fields) {
    Map<String, dynamic> hashMap = {};

    for (MapEntry<String, dynamic> mapEntry in hashDTO.entries) {
      if (mapEntry.value != null) {
        if (!(mapEntry.value is List || mapEntry.value is Map)) {
          Map<String, dynamic>? fieldCustomFormView = fields.firstWhereOrNull((element) => element["field_name"] == mapEntry.key);

          hashMap[mapEntry.key] = Offlines.convert(mapEntry.value, fieldCustomFormView);
        }
      }
    }

    return hashMap;
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
    required String formId,
    required String name,
    required Map<String, dynamic> data,
    String? customerId,
  }) async {
    Map<String, dynamic>? customFormView = await loadCustomFormView(formId);

    if (customFormView != null) {
      List<Map<String, dynamic>> fields = await loadFields(customFormView);

      Map<String, dynamic>? currentFieldCustomFormView = fields.firstWhereOrNull((element) => element["field_name"] == name);

      if (currentFieldCustomFormView != null) {
        Map<String, dynamic>? sourceDTO = await DMLAssemblers
            .create()
            .select("c.table_name")
            .select("CAST(b.src_column_id AS TEXT) AS key_column_id")
            .select("d.column_name AS key_column_name")
            .from("c_field_custom_form a")
            .join("INNER JOIN f_dynamic_table_detail b ON b.id = a.column_id")
            .join("INNER JOIN f_dynamic_table c ON c.id = b.src_table_id")
            .join("INNER JOIN f_dynamic_table_detail d ON d.id = b.src_column_id")
            .equalTo("a.id", currentFieldCustomFormView["id"])
            .first();

        if (sourceDTO != null) {
          DynamicFormResourceResponse dynamicFormResourceResponse = DynamicFormResourceResponse();

          String keyColumnId = sourceDTO["key_column_id"];
          String keyColumnName = sourceDTO["key_column_name"];

          dynamicFormResourceResponse.key = keyColumnName;

          List<String> requiredFields = [];

          List<Map<String, dynamic>> selectedFields = await DMLAssemblers
              .create()
              .select("column_name")
              .select("data_type")
              .select("column_caption")
              .select("COALESCE(f_pk, 'N') AS primary_key")
              .select("(CASE WHEN id IN (${currentFieldCustomFormView["column_data_select"]}) THEN 'Y' ELSE 'N' END) AS showed")
              .from("f_dynamic_table_detail")
              .customWhere("id IN (${currentFieldCustomFormView["column_data_select"]},$keyColumnId)")
              .all();

          for (Map<String, dynamic> selectedField in selectedFields) {
            String columnName = selectedField["column_name"];
            String dataType = selectedField["data_type"];
            String columnCaption = selectedField["column_caption"];

            if (!requiredFields.contains(columnName)) {
              requiredFields.add(columnName);

              DynamicFormResourceFieldItem dynamicFormResourceFieldItem = DynamicFormResourceFieldItem();

              dynamicFormResourceFieldItem.name = columnName;
              dynamicFormResourceFieldItem.type = dataType;
              dynamicFormResourceFieldItem.description = columnCaption;
              dynamicFormResourceFieldItem.showed = selectedField["showed"] == "Y";

              dynamicFormResourceResponse.fields.add(dynamicFormResourceFieldItem);
            }
          }

          if (currentFieldCustomFormView["f_link_value"] == "Y") {
            if (!requiredFields.contains(currentFieldCustomFormView["src_link_field_value"])) {
              requiredFields.add(currentFieldCustomFormView["src_link_field_value"]);
            }
          }

          List<Map<String, dynamic>> loadOnFields = await DMLAssemblers
              .create()
              .select("*")
              .from("c_field_load_on_field")
              .equalTo("field_id", currentFieldCustomFormView["id"])
              .and()
              .isNotNull("src_key")
              .all();

          for (Map<String, dynamic> loadOnField in loadOnFields) {
            if (!requiredFields.contains(loadOnField["src_key"])) {
              requiredFields.add(loadOnField["src_key"]);
            }

            DynamicFormResourceLoadOnFieldItem dynamicFormResourceLoadOnFieldItem = DynamicFormResourceLoadOnFieldItem();

            dynamicFormResourceLoadOnFieldItem.detail = loadOnField["f_load_detail"] == "Y";
            dynamicFormResourceLoadOnFieldItem.source = loadOnField["src_key"];
            dynamicFormResourceLoadOnFieldItem.target = loadOnField["dst_key"];

            dynamicFormResourceResponse.loadOnFields.add(dynamicFormResourceLoadOnFieldItem);
          }

          List<Map<String, dynamic>> loadOnFieldDetails = await DMLAssemblers
              .create()
              .select("*")
              .from("c_field_load_on_field_detail")
              .equalTo("field_id", currentFieldCustomFormView["id"])
              .all();

          for (Map<String, dynamic> loadOnFieldDetail in loadOnFieldDetails) {
            DynamicFormResourceDetailSetupItem dynamicFormResourceDetailSetupItem = DynamicFormResourceDetailSetupItem();

            dynamicFormResourceDetailSetupItem.srcKey = loadOnFieldDetail["src_key"];
            dynamicFormResourceDetailSetupItem.dstKey = loadOnFieldDetail["dst_key"];

            dynamicFormResourceResponse.detailSetups.add(dynamicFormResourceDetailSetupItem);
          }

          return dynamicFormResourceResponse;
        }
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>?> dynamicFormResourceData({
    required String formId,
    required String name,
    required Map<String, dynamic> dataMap,
    required int pageIndex,
    required int pageSize,
    required String? query,
    required String? customerId,
  }) async {
    Map<String, dynamic>? customFormView = await loadCustomFormView(formId);

    if (customFormView != null) {
      List<Map<String, dynamic>> fields = await loadFields(customFormView);

      Map<String, dynamic>? currentFieldCustomFormView = fields.firstWhereOrNull((element) => element["field_name"] == name);

      if (currentFieldCustomFormView == null) {
        if (customFormView["table_detail_id"] != null) {
          customFormView = await DMLAssemblers
              .create()
              .select("a.*")
              .select("b.table_name")
              .from("c_custom_form a")
              .join("INNER JOIN f_dynamic_table b ON b.id = a.table_header_id")
              .equalTo("a.id", customFormView["table_detail_id"])
              .first();

          if (customFormView != null) {
            fields = await loadFields(customFormView);

            currentFieldCustomFormView = fields.firstWhereOrNull((element) => element["field_name"] == name);
          }
        }
      }

      if (currentFieldCustomFormView == null) {
        List<Map<String, dynamic>> details = await DMLAssemblers
            .create()
            .select("b.*")
            .from("c_custom_multiple_detail a")
            .join("INNER JOIN c_custom_form b ON b.id = a.table_detail_id")
            .equalTo("a.custom_id", customFormView?["id"])
            .all();

        for (Map<String, dynamic> detail in details) {
          customFormView = detail;

          fields = await loadFields(customFormView);

          currentFieldCustomFormView = fields.firstWhereOrNull((element) => element["field_name"] == name);

          if (currentFieldCustomFormView != null) {
            break;
          }
        }
      }

      if (currentFieldCustomFormView != null) {
        Map<String, dynamic>? sourceDTO = await DMLAssemblers
            .create()
            .select("c.table_name")
            .select("CAST(b.src_column_id AS TEXT) AS key_column_id")
            .select("d.column_name AS key_column_name")
            .from("c_field_custom_form a")
            .join("INNER JOIN f_dynamic_table_detail b ON b.id = a.column_id")
            .join("INNER JOIN f_dynamic_table c ON c.id = b.src_table_id")
            .join("INNER JOIN f_dynamic_table_detail d ON d.id = b.src_column_id")
            .equalTo("a.id", currentFieldCustomFormView["id"])
            .first();

        if (sourceDTO != null) {
          String sourceTableName = sourceDTO["table_name"];
          String keyColumnId = sourceDTO["key_column_id"];
          String keyColumnName = sourceDTO["key_column_name"];

          List<String> requiredFields = [];

          List<Map<String, dynamic>> selectedFields = await DMLAssemblers
              .create()
              .select("column_name")
              .select("data_type")
              .select("column_caption")
              .select("COALESCE(f_pk, 'N') AS primary_key")
              .select("(CASE WHEN id IN (${currentFieldCustomFormView["column_data_select"]}) THEN 'Y' ELSE 'N' END) AS showed")
              .from("f_dynamic_table_detail")
              .customWhere("id IN (${currentFieldCustomFormView["column_data_select"]},$keyColumnId)")
              .all();

          for (Map<String, dynamic> selectedField in selectedFields) {
            String columnName = selectedField["column_name"];

            if (!requiredFields.contains(columnName)) {
              requiredFields.add(columnName);
            }
          }

          if (currentFieldCustomFormView["f_link_value"] == "Y") {
            if (!requiredFields.contains(currentFieldCustomFormView["src_link_field_value"])) {
              requiredFields.add(currentFieldCustomFormView["src_link_field_value"]);
            }
          }

          if (requiredFields.isNotEmpty) {
            DMLAssemblers dmlAssemblers = DMLAssemblers.create();

            for (String requiredField in requiredFields) {
              dmlAssemblers.select(requiredField);
            }

            dmlAssemblers.from(sourceTableName);

            List<Map<String, dynamic>> manualFilters = await DMLAssemblers
                .create()
                .select("*")
                .from("c_filter_field_list_data")
                .equalTo("field_id", currentFieldCustomFormView["id"])
                .all();

            for (Map<String, dynamic> manualFilter in manualFilters) {
              String? fieldClause = (await DMLAssemblers
                  .create()
                  .select("column_name")
                  .from("f_dynamic_table_detail")
                  .equalTo("id", manualFilter["key"])
                  .first()
              )?["column_name"];

              if (StringUtils.isNotNullOrEmpty(fieldClause)) {
                if (manualFilter["operation"] == "OR") {
                  dmlAssemblers.or();
                } else {
                  dmlAssemblers.and();
                }

                if (manualFilter["f_from_login"] == "Y") {
                  fieldClause = "CAST($fieldClause AS TEXT)";

                  dmlAssemblers.customWhere("($fieldClause ${manualFilter["operator"]} '$currentSalesUnitId' OR $fieldClause ${manualFilter["operator"]} '$currentUsername')");
                } else if (StringUtils.isNullOrEmpty(manualFilter["value"])) {
                  if (manualFilter["operator"] == "IS") {
                    dmlAssemblers.customWhere("$fieldClause IS NULL");
                  } else {
                    dmlAssemblers.customWhere("$fieldClause IS NOT NULL");
                  }
                } else {
                  dmlAssemblers.customWhere("$fieldClause ${manualFilter["operator"]} ?");

                  if (manualFilter["operator"] == "LIKE") {
                    if (manualFilter["value"] == "\$selector") {
                      dmlAssemblers.parameter("%$currentBusinessUnitId%");
                    } else {
                      dmlAssemblers.parameter("%${manualFilter["value"]}%");
                    }
                  } else {
                    if (manualFilter["value"] == "\$selector") {
                      dmlAssemblers.parameter(currentBusinessUnitId);
                    } else {
                      dmlAssemblers.parameter(manualFilter["value"]);
                    }
                  }
                }
              }
            }

            List<Map<String, dynamic>> autoFilters = await DMLAssemblers
                .create()
                .select("*")
                .from("c_field_filter_from_field")
                .equalTo("field_id", currentFieldCustomFormView["id"])
                .all();

            for (Map<String, dynamic> autoFilter in autoFilters) {
              if (autoFilter["operation"] == "OR") {
                dmlAssemblers.or();
              } else {
                dmlAssemblers.and();
              }

              if (StringUtils.inList(autoFilter["key"], ["customer_id", "cust_id"]) && StringUtils.inList(autoFilter["value"], ["customer_id", "cust_id"])) {
                if (customerId != null) {
                  dmlAssemblers.customWhere("${autoFilter["key"]} ${autoFilter["operator"]} ?");
                  dmlAssemblers.parameter(customerId);
                }
              } else {
                dynamic value = dataMap[autoFilter["value"]];

                if (value != null) {
                  dmlAssemblers.customWhere("${autoFilter["key"]} ${autoFilter["operator"]} ?");

                  if (autoFilter["operator"] == "LIKE") {
                    dmlAssemblers.parameter("%$value%");
                  } else {
                    dmlAssemblers.parameter(value);
                  }
                }
              }
            }

            List<Map<String, dynamic>> actualColumns = await (await Sqlites.get()).rawQuery("PRAGMA table_info($sourceTableName)");

            if (actualColumns.any((element) => element["name"] == "f_delete")) {
              dmlAssemblers
                  .and()
                  .customWhere("COALESCE(f_delete, 'N') = 'N'");
            }

            if (StringUtils.isNotNullOrEmpty(query)) {
              dmlAssemblers.customWhere("LOWER(${requiredFields.map((e) => "COALESCE(CAST($e AS TEXT), '')").join("||")}) LIKE ?");
              dmlAssemblers.parameter("%$query%");
            }

            if (StringUtils.isNotNullOrEmpty(currentFieldCustomFormView["order_view"])) {
              dmlAssemblers.customOrder(currentFieldCustomFormView["order_view"]);
            } else {
              if (actualColumns.any((element) => element["name"] == "id")) {
                dmlAssemblers.desc("id");
              }
            }

            dmlAssemblers
                .limit(pageSize)
                .offset((pageIndex - 1) * pageSize);

            List<Map<String, dynamic>> data = await dmlAssemblers.all();

            List<Map<String, dynamic>> items = [];

            int dataSize = await dmlAssemblers.count();

            String? sourceDetailTableName = (await DMLAssemblers
                .create()
                .select("c.table_name")
                .from("c_custom_form a")
                .join("INNER JOIN c_field_custom_form b ON b.src_form_detail_id = a.id")
                .join("INNER JOIN f_dynamic_table c ON c.id = a.table_header_id")
                .equalTo("b.id", currentFieldCustomFormView["id"])
                .first()
            )?["table_name"];

            List<Map<String, dynamic>> loadOnFieldDetails = await DMLAssemblers
                .create()
                .select("*")
                .from("c_field_load_on_field_detail")
                .equalTo("field_id", currentFieldCustomFormView["id"])
                .all();

            for (Map<String, dynamic> hashDTO in data) {
              Map<String, dynamic> hashMap = hashDTOToMap(hashDTO, fields);

              if (loadOnFieldDetails.isNotEmpty) {
                if (StringUtils.isNotNullOrEmpty(sourceDetailTableName)) {
                  DMLAssemblers dmlAssemblers = DMLAssemblers.create();

                  for (Map<String, dynamic> loadOnFieldDetail in loadOnFieldDetails) {
                    dmlAssemblers.select(loadOnFieldDetail["src_key"]);
                  }

                  dmlAssemblers.from(sourceDetailTableName!);
                  dmlAssemblers.equalTo("header_id", hashMap[keyColumnName]);

                  hashMap["details"] = await dmlAssemblers.all();
                }
              }

              items.add(hashMap);
            }

            return {
              "items": items,
              "size": dataSize,
            };
          }
        }
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>?> dynamicFormSelect({
    required String formId,
    required String name,
    required dynamic value,
    String? customerId,
  }) async {
    Map<String, dynamic>? customFormView = await loadCustomFormView(formId);

    if (customFormView != null) {
      FormContainer container = await loadContainer(customFormView, null);

      Map<String, dynamic>? currentFieldCustomFormView = container.carrier.fields.firstWhereOrNull((element) => element["field_name"] == name);

      if (currentFieldCustomFormView != null) {
        Map<String, dynamic>? tableDetail = await DMLAssemblers
            .create()
            .select("*")
            .from("f_dynamic_table_detail")
            .equalTo("id", currentFieldCustomFormView["column_id"])
            .first();

        if (tableDetail != null) {
          String? srcFieldDepend = (await DMLAssemblers
              .create()
              .select("column_name")
              .from("f_dynamic_table_detail")
              .equalTo("id", tableDetail["src_column_id"])
              .first()
          )?["column_name"];

          if (customFormView["template_mode"] == "CARD" && customFormView["f_multiple_detail"] == "Y") {
            if (customFormView["f_auto_load_detail_form"] == "Y") {
              Map<String, dynamic>? cfReference = await DMLAssemblers
                  .create()
                  .select("a.*")
                  .from("c_custom_form a")
                  .join("INNER JOIN f_dynamic_table_detail b ON b.src_table_id = a.table_header_id")
                  .equalTo("b.id", currentFieldCustomFormView["column_id"])
                  .first();

              if (cfReference != null) {
                if (cfReference["f_multiple_detail"] == "Y" && srcFieldDepend == "id") {
                  List<Map<String, dynamic>> mdReferences = await DMLAssemblers
                      .create()
                      .select("*")
                      .from("c_custom_multiple_detail")
                      .equalTo("custom_id", cfReference["id"])
                      .asc('"index"')
                      .all();

                  for (Map<String, dynamic> mdReference in mdReferences) {
                    String? tableNameReference = (await DMLAssemblers
                        .create()
                        .select("table_name")
                        .from("f_dynamic_table")
                        .equalTo("id", mdReference["table_load_on_field"])
                        .first()
                    )?["table_name"];

                    if (tableNameReference != null) {
                      List<Map<String, dynamic>> actualColumns = await (await Sqlites.get()).rawQuery("PRAGMA table_info($tableNameReference)");

                      List<Map<String, dynamic>> listDetailReferences = await DMLAssemblers
                          .create()
                          .select("*")
                          .from(tableNameReference)
                          .equalTo("header_id", value)
                          .and()
                          .equalTo("form_id", cfReference["id"])
                          .and()
                          .customWhere("COALESCE(f_delete,'N') = 'N'")
                          .asc("custom_form_index", condition: actualColumns.any((element) => element["name"] == "custom_form_index"))
                          .asc("id")
                          .all();

                      if (listDetailReferences.isNotEmpty) {
                        List<Map<String, dynamic>> multipleDetailViews = await DMLAssemblers
                            .create()
                            .select("*")
                            .from("c_custom_multiple_detail")
                            .equalTo("custom_id", customFormView["id"])
                            .asc('"index"')
                            .all();

                        for (Map<String, dynamic> multipleDetailView in multipleDetailViews) {
                          if (multipleDetailView["table_reference_id"] == mdReference["table_load_on_field"]) {
                            for (DetailCarrier detailCarrier in container.carrier.detailCarriers) {
                              if (detailCarrier.customFormView["table_header_id"] == multipleDetailView["table_load_on_field"]) {
                                for (Map<String, dynamic> listDetailReference in listDetailReferences) {
                                  List<Map<String, dynamic>> dtoList = container.data[detailCarrier.customFormView["table_name"]] ?? [];

                                  dtoList.add(listDetailReference);

                                  container.data[detailCarrier.customFormView["table_name"]] = dtoList;
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          Map<String, dynamic> result = {};

          for (DetailCarrier detailCarrier in container.carrier.detailCarriers) {
            List<Map<String, dynamic>>? detailData = container.data[detailCarrier.customFormView["table_name"]];

            if (detailData != null) {
              List<Map<String, dynamic>> maps = [];

              for (Map<String, dynamic> hashDTO in detailData) {
                maps.add(hashDTOToMap(hashDTO, detailCarrier.fields));
              }

              result[detailCarrier.customFormView["table_name"]] = maps;
            }
          }

          return result;
        }
      }
    }

    return null;
  }

  static Future<HeaderForm?> dynamicFormRefresh({
    required String formId,
    required Map<String, dynamic> data,
    String? customerId,
  }) async {
    Map<String, dynamic>? customFormView = await loadCustomFormView(formId);

    if (customFormView != null) {
      FormContainer container = await loadContainer(customFormView, data);

      List<String> scripts = [];

      for (Map<String, dynamic> fieldCustomFormView in container.carrier.fields) {
        if (StringUtils.isNotNullOrEmpty(fieldCustomFormView["pseudo_code"])) {
          if (!scripts.contains(fieldCustomFormView["pseudo_code"])) {
            scripts.add(fieldCustomFormView["pseudo_code"]);
          }
        }

        for (DetailCarrier detailCarrier in container.carrier.detailCarriers) {
          for (Map<String, dynamic> detailFieldCustomFormView in detailCarrier.fields) {
            if (StringUtils.isNotNullOrEmpty(detailFieldCustomFormView["pseudo_code"])) {
              if (!scripts.contains(detailFieldCustomFormView["pseudo_code"])) {
                scripts.add(detailFieldCustomFormView["pseudo_code"]);
              }
            }
          }
        }
      }

      if (scripts.isNotEmpty) {
        JsonScriptEngine jsonScriptEngine = JsonScriptEngine();

        for (String script in scripts) {
          container.data = jsonScriptEngine.run(container.data, script);
        }
      }

      HeaderForm headerForm = await Offlines.loadHeaderForm(0, container);

      return headerForm;
    }

    return null;
  }

  static Future<HeaderForm?> dynamicFormCustomAction({
    required String actionId,
    required String formId,
    required String dataId,
    String? customerId,
  }) async {
    Map<String, dynamic>? customFormView = await loadCustomFormView(formId);

    if (customFormView != null) {
      FormContainer container = await loadContainer(customFormView, dataId);

      Map<String, dynamic>? customFunctionsView = await DMLAssemblers
          .create()
          .select("*")
          .from("c_custom_functions")
          .equalTo("function_id", actionId)
          .first();

      if (customFunctionsView != null) {
        List<Map<String, dynamic>> customFunctionsValidationViews = await DMLAssemblers
            .create()
            .select("*")
            .from("c_custom_functions_validation")
            .equalTo("function_id", customFunctionsView["function_id"])
            .all();

        if (customFunctionsValidationViews.isNotEmpty) {
          DMLAssemblers dmlAssemblers = DMLAssemblers
              .create()
              .select("*")
              .from(customFormView["table_name"])
              .equalTo("id", dataId);

          for (Map<String, dynamic> customFunctionsValidationView in customFunctionsValidationViews) {
            if (StringUtils.isNotNullOrEmpty(customFunctionsValidationView["value"])) {
              if (customFunctionsValidationView["operation"] == "OR") {
                dmlAssemblers.or();
              } else {
                dmlAssemblers.and();
              }

              dmlAssemblers.customWhere("${customFunctionsValidationView["key"]} ${customFunctionsValidationView["operator"]} ?");
              dmlAssemblers.parameter(customFunctionsValidationView["value"]);
            } else {
              dmlAssemblers.customWhere("${customFunctionsValidationView["key"]} IS NULL");
            }
          }

          int count = await dmlAssemblers.count();

          if (count == 0) {
            BaseOverlays.error(message: "Can't perform this operation because the criteria are not met");

            return null;
          }
        }

        List<Map<String, dynamic>> customFunctionsQueryActionViews = await DMLAssemblers
            .create()
            .select("*")
            .from("c_custom_functions_query_action")
            .equalTo("function_id", customFunctionsView["function_id"])
            .asc("index_action")
            .all();

        if (customFunctionsQueryActionViews.isNotEmpty) {
          for (Map<String, dynamic> customFunctionsQueryActionView in customFunctionsQueryActionViews) {
            Map<String, dynamic>? customQueryActionView = await DMLAssemblers
                .create()
                .select("*")
                .from("c_custom_query_action")
                .equalTo("id", customFunctionsQueryActionView["query_action_id"])
                .first();

            if (customQueryActionView != null) {
              Map<String, dynamic>? segmentReportView = await DMLAssemblers
                  .create()
                  .select("*")
                  .from("c_segment_report")
                  .equalTo("id", customQueryActionView["segment_id"])
                  .first();

              if (segmentReportView != null) {
                DMLAssemblers dmlAssemblers = DMLAssemblers
                    .create()
                    .from(segmentReportView["view_name"]);

                List<Map<String, dynamic>> customQueryActionFilterViews = await DMLAssemblers
                    .create()
                    .select("*")
                    .from("c_custom_query_action_filter")
                    .equalTo("custom_query_action_id", customQueryActionView["id"])
                    .asc("id")
                    .all();

                for (Map<String, dynamic> customQueryActionFilterView in customQueryActionFilterViews) {
                  if (StringUtils.isNotNullOrEmpty(customQueryActionFilterView["operation"])) {
                    if (customQueryActionFilterView["f_multiple"] == "Y") {
                      List<String> fields = (customQueryActionFilterView["field_name"] as String).split(",");

                      if (customQueryActionFilterView["operation"] == "OR") {
                        dmlAssemblers.or();
                      } else {
                        dmlAssemblers.and();
                      }

                      dmlAssemblers.customWhere("(${fields.join(", ")}) ${customQueryActionFilterView["operator"]} (${List.generate(fields.length, (index) => "?").join(", ")})");

                      for (String field in fields) {
                        dynamic value = container.data[field];

                        dmlAssemblers.parameter(value ?? "NULL");
                      }
                    } else {
                      dynamic paramValue;

                      if (customQueryActionFilterView["f_manual"] == "Y") {
                        paramValue = customQueryActionFilterView["manual_value"];
                      } else {
                        paramValue = container.data[customQueryActionFilterView["dst_custom_field_name"]];
                      }

                      if (customQueryActionFilterView["operation"] == "OR") {
                        dmlAssemblers.or();
                      } else {
                        dmlAssemblers.and();
                      }

                      if (paramValue != null && paramValue != "") {
                        dmlAssemblers.customWhere("${customQueryActionFilterView["field_name"]} ${customQueryActionFilterView["operator"]} ?");
                        dmlAssemblers.parameter(paramValue);
                      } else {
                        dmlAssemblers.customWhere("${customQueryActionFilterView["field_name"]} IS NULL");
                      }
                    }
                  }
                }

                if (customQueryActionView["output"] == "VALIDATION") {
                  int count = await dmlAssemblers.count();

                  bool valid = false;

                  if (customQueryActionView["condition"] == "EXIST" && count > 0) {
                    valid = true;
                  } else if (customQueryActionView["condition"] == "NOT_EXIST" && count == 0) {
                    valid = true;
                  }

                  if (valid) {
                    BaseOverlays.error(message: customQueryActionView["message"] ?? "Can't perform this operation because the criteria are not met");

                    return null;
                  }
                } else if (customQueryActionView["output"] == "SHOW_DATA") {
                  // TODO: Tambahkan support untuk query action show data
                }
              }
            }
          }
        }

        List<Map<String, dynamic>> customFunctionsActionViews = await DMLAssemblers
            .create()
            .select("*")
            .from("c_custom_functions_action")
            .equalTo("function_id", customFunctionsView["function_id"])
            .all();

        String updateSyntaxBuilder = "UPDATE ${customFormView["table_name"]} SET ${customFunctionsActionViews.map((customFunctionsActionView) => "${customFunctionsActionView["key"]} = '${customFunctionsActionView["value"]}'").join(", ")}";

        if (customFunctionsActionViews.isNotEmpty) {
          updateSyntaxBuilder += ", ";
        }

        if (customFunctionsView["btn_delete"] == "Y") {
          updateSyntaxBuilder += "f_delete = 'Y', ";
        }

        updateSyntaxBuilder += "change_who = '$currentUsername'";
        updateSyntaxBuilder += ", change_date = DATETIME()";
        updateSyntaxBuilder += " WHERE id = $dataId";

        Database database = await Sqlites.get();

        return await database.transaction((txn) async {
          await txn.execute(updateSyntaxBuilder);

          List<String> scripts = [];

          if (StringUtils.isNotNullOrEmpty(customFunctionsView["pseudo_code"])) {
            scripts.add(customFunctionsView["pseudo_code"]);
          }

          if (scripts.isNotEmpty) {
            JsonScriptEngine jsonScriptEngine = JsonScriptEngine();

            for (String script in scripts) {
              container.data = jsonScriptEngine.run(container.data, script);
            }

            if (container.data["EDITMODE"] ?? false) {
              HeaderForm headerForm = await Offlines.loadHeaderForm(2, container, transaction: txn);

              return headerForm;
            }
          }

          return null;
        });
      }
    }

    return null;
  }

  static Future<void> dynamicFormSave({
    required String formId,
    required Map<String, dynamic> data,
    String? customerId,
  }) async {
    Map<String, dynamic>? customFormView = await DMLAssemblers
        .create()
        .select("a.*")
        .select("b.table_name")
        .select("b.sequence_name")
        .from("c_custom_form a")
        .join("INNER JOIN f_dynamic_table b ON b.id = a.table_header_id")
        .equalTo("a.id", formId)
        .first();

    if (customFormView != null) {
      FormContainer container = await loadContainer(customFormView, data);

      Map<String, dynamic>? customFunctionsView = await DMLAssemblers
          .create()
          .select("*")
          .from("c_custom_functions")
          .equalTo("custom_id", customFormView["id"])
          .and()
          .customWhere("COALESCE(f_default, 'N') = 'Y'")
          .and()
          .equalTo("resource_id = ?", "BTN_SAVE")
          .first();

      if (customFunctionsView != null) {
        List<String> scripts = [];

        if (StringUtils.isNotNullOrEmpty(customFunctionsView["pseudo_code"])) {
          scripts.add(customFunctionsView["pseudo_code"]);
        }

        if (scripts.isNotEmpty) {
          JsonScriptEngine jsonScriptEngine = JsonScriptEngine();

          for (String script in scripts) {
            try {
              container.data = jsonScriptEngine.run(container.data, script);
            } on ScriptValidationException catch (e) {
              BaseOverlays.error(message: e.message);

              return;
            }
          }
        }
      }

      Map<String, dynamic> headerDTO = container.data;

      Database database = await Sqlites.get();

      await database.transaction((transaction) async {
        await getSqlStatements(
          transaction: transaction,
          hashDTO: headerDTO,
          headerDTO: null,
          customFormView: container.carrier.customFormView,
          headerCustomFormView: null,
          fields: container.carrier.fields,
          customerId: customerId,
        );

        for (DetailCarrier detailCarrier in container.carrier.detailCarriers) {
          if (detailCarrier.customFormView["template_mode"] == "LIST") {
            List<Map<String, dynamic>> detailDTOs = headerDTO[detailCarrier.customFormView["table_name"]];

            for (Map<String, dynamic> detailDTO in detailDTOs) {
              await getSqlStatements(
                transaction: transaction,
                hashDTO: detailDTO,
                headerDTO: headerDTO,
                customFormView: detailCarrier.customFormView,
                headerCustomFormView: container.carrier.customFormView,
                fields: detailCarrier.fields,
                customerId: customerId,
              );

              for (SubDetailCarrier subDetailCarrier in detailCarrier.subDetailCarriers) {
                List<Map<String, dynamic>> subDetailDTOs = detailDTO[subDetailCarrier.customFormView["table_name"]];

                for (Map<String, dynamic> subDetailDTO in subDetailDTOs) {
                  await getSqlStatements(
                    transaction: transaction,
                    hashDTO: subDetailDTO,
                    headerDTO: detailDTO,
                    customFormView: subDetailCarrier.customFormView,
                    headerCustomFormView: detailCarrier.customFormView,
                    fields: subDetailCarrier.fields,
                    customerId: customerId,
                  );
                }
              }
            }
          } else {
            Map<String, dynamic> detailDTO = headerDTO[detailCarrier.customFormView["table_name"]];

            await getSqlStatements(
              transaction: transaction,
              hashDTO: detailDTO,
              headerDTO: headerDTO,
              customFormView: detailCarrier.customFormView,
              headerCustomFormView: container.carrier.customFormView,
              fields: detailCarrier.fields,
              customerId: customerId,
            );
          }
        }

        await insertSyncQueue(
          transaction: transaction,
          entity: customFormView["table_name"],
          payload: headerDTO,
        );
      });
    }
  }

  static Future<void> getSqlStatements({
    required Transaction transaction,
    required Map<String, dynamic> hashDTO,
    required Map<String, dynamic>? headerDTO,
    required Map<String, dynamic> customFormView,
    required Map<String, dynamic>? headerCustomFormView,
    required List<Map<String, dynamic>> fields,
    required String? customerId,
  }) async {
    Map<String, dynamic> metadata = {
      "sequence": customFormView["sequence_name"],
      "generate_numbers": List<Map<String, dynamic>>.empty(growable: true),
      "files": List<Map<String, dynamic>>.empty(growable: true),
    };

    for (Map<String, dynamic> fieldCustomFormView in fields) {
      if (fieldCustomFormView["f_default_value"] == "Y") {
        String? defaultValue = fieldCustomFormView["default_value"];

        if (defaultValue != null) {
          if (defaultValue.contains("\$GENERATE_NUMBER")) {
            (metadata["generate_numbers"] as List<Map<String, dynamic>>).add({
              "field_name": fieldCustomFormView["field_name"],
              "template": defaultValue,
            });

            defaultValue = await generateNumberSeries("${customFormView["table_name"]}_${fieldCustomFormView["field_name"]}", defaultValue);
          } else if (fieldCustomFormView["field_data_type"] == "NUMERIC") {
            defaultValue = defaultValue.replaceAll(",", "");
          }

          if (!StringUtils.equalsIgnoreCase(defaultValue, "NULL")) {
            hashDTO[fieldCustomFormView["field_name"]] = defaultValue;
          }
        }
      }
    }

    for (Map<String, dynamic> fieldCustomFormView in fields) {
      for (String fieldName in hashDTO.keys) {
        if (fieldName == fieldCustomFormView["field_name"]) {
          if (StringUtils.inList(fieldCustomFormView["field_data_type"], ["FILE", "FOTO", "VIDEO", "SIGNATURE", "UPLOAD_FOTO", "UPLOAD_VIDEO", "UPLOAD_SIGNATURE"])) {
            Map<String, dynamic>? fileMap = hashDTO[fieldName];

            if (fileMap != null) {
              hashDTO[fieldName] = jsonEncode(fileMap);

              (metadata["files"] as List<Map<String, dynamic>>).add({
                "field_name": fieldName,
                "data_type": fieldCustomFormView["field_data_type"],
              });
            }
          }
        }
      }
    }

    if (hashDTO["id"] != null) {
      metadata["action"] = "update";

      hashDTO["_metadata"] = metadata;

      await updateStatement(
        transaction: transaction,
        hashDTO: hashDTO,
        customFormView: customFormView,
        headerDTO: headerDTO,
        headerCustomFormView: headerCustomFormView,
        customerId: customerId,
      );

      await updateSchedule(
        transaction: transaction,
        hashDTO: hashDTO,
        customFormView: customFormView,
      );
    } else {
      metadata["action"] = "insert";

      hashDTO["_metadata"] = metadata;

      await insertStatement(
        transaction: transaction,
        hashDTO: hashDTO,
        customFormView: customFormView,
        headerDTO: headerDTO,
        headerCustomFormView: headerCustomFormView,
        customerId: customerId,
      );

      await insertSchedule(
        transaction: transaction,
        hashDTO: hashDTO,
        customFormView: customFormView,
      );
    }

    await insertHistory(
      transaction: transaction,
      hashDTO: hashDTO,
      customFormView: customFormView,
    );
  }

  static Future<void> insertStatement({
    required Transaction transaction,
    required Map<String, dynamic> hashDTO,
    required Map<String, dynamic> customFormView,
    required Map<String, dynamic>? headerDTO,
    required Map<String, dynamic>? headerCustomFormView,
    required String? customerId,
  }) async {
    String tableName = customFormView["table_name"];

    List<String> actualFields = await getActualFields(tableName, transaction);

    for (String actualField in actualFields) {
      bool found = false;

      for (String fieldName in hashDTO.keys) {
        if (fieldName == actualField) {
          found = true;

          break;
        }
      }

      if (!found) {
        hashDTO[actualField] = null;
      }
    }

    for (String fieldName in hashDTO.keys) {
      if (fieldName == "id") {
        hashDTO[fieldName] = nextIdempotentId();
      } else if (fieldName == "company_id") {
        hashDTO[fieldName] = currentCompanyId;
      } else if (fieldName == "bu_id") {
        hashDTO[fieldName] = currentBusinessUnitId;
      } else if (fieldName == "salesunit_id") {
        hashDTO[fieldName] = currentSalesUnitId;
      } else if (fieldName == "user_id") {
        hashDTO[fieldName] = currentUsername;
      } else if (fieldName == "customer_id") {
        hashDTO[fieldName] = customerId;
      } else if (fieldName == "table_id") {
        hashDTO[fieldName] = customFormView["table_header_id"];
      } else if (fieldName == "form_id") {
        hashDTO[fieldName] = customFormView["id"];
      } else if (fieldName == "header_id") {
        hashDTO[fieldName] = headerDTO?["id"];
      } else if (fieldName == "custom_group_id") {
        hashDTO[fieldName] = headerDTO?["id"];
      } else if (fieldName == "custom_group_form_id") {
        hashDTO[fieldName] = headerCustomFormView?["id"];
      } else if (fieldName == "create_who") {
        hashDTO[fieldName] = currentUsername;
      } else if (fieldName == "create_date") {
        hashDTO[fieldName] = DateTime.now().toIso8601String();
      }
    }

    Iterable<MapEntry<String, dynamic>> iterable = hashDTO.entries.where((entry) => !(entry.value is List || entry.value is Map) && actualFields.contains(entry.key));

    Map<String, dynamic>? newRow = (await transaction.rawQuery("INSERT INTO $tableName ( ${iterable.map((entry) => entry.key).join(", ")} ) VALUES ( ${iterable.map((entry) => entry.value != null ? "'${entry.value}'" : "NULL").join(", ")} ) RETURNING *;")).firstOrNull;

    if (newRow != null) {
      await handleTrigger(
        states: ["BEFORE", "AFTER"],
        operations: ["INSERT", "INSERT OR UPDATE"],
        transaction: transaction,
        oldRow: {},
        newRow: Map<String, dynamic>.from(newRow),
        customFormView: customFormView,
      );
    }
  }

  static Future<void> handleTrigger({
    required List<String> states,
    required List<String> operations,
    required Transaction transaction,
    required Map<String, dynamic> oldRow,
    required Map<String, dynamic> newRow,
    required Map<String, dynamic> customFormView,
  }) async {
    List<Map<String, dynamic>> dynamicTableTriggerViews = await DMLAssemblers
        .create()
        .select("*")
        .from("f_dynamic_table_trigger")
        .equalTo("table_id", customFormView["table_header_id"])
        .and()
        .inn("trigger_state", states)
        .and()
        .inn("trigger_operation", operations)
        .all(transaction);

    for (Map<String, dynamic> dynamicTableTriggerView in dynamicTableTriggerViews) {
      List<Map<String, dynamic>> dynamicTableTriggerActionViews = await DMLAssemblers
          .create()
          .select("*")
          .from("f_dynamic_table_trigger_action")
          .equalTo("trigger_id", dynamicTableTriggerView["id"])
          .asc("sequence_index")
          .all(transaction);

      List<Map<String, dynamic>> dynamicTableTriggerVariableViews = await DMLAssemblers
          .create()
          .select("*")
          .from("f_dynamic_table_trigger_variable")
          .equalTo("trigger_id", dynamicTableTriggerView["id"])
          .all(transaction);

      Map<String, dynamic> variable = {};

      for (Map<String, dynamic> dynamicTableTriggerVariableView in dynamicTableTriggerVariableViews) {
        Map<String, dynamic>? result = await DMLAssemblers
            .create()
            .select("*")
            .from(dynamicTableTriggerVariableView["source_table_name"])
            .equalTo(dynamicTableTriggerVariableView["column_key"], newRow[dynamicTableTriggerVariableView["column_value"]])
            .first(transaction);

        if (result != null) {
          variable[dynamicTableTriggerVariableView["variable_name"]] = result;
        }
      }

      for (Map<String, dynamic> dynamicTableTriggerActionView in dynamicTableTriggerActionViews) {
        if (dynamicTableTriggerActionView["action_function"] == "INSERT") {
          await handleTriggerActionInsert(
            transaction: transaction,
            oldRow: oldRow,
            newRow: newRow,
            dynamicTableTriggerActionView: dynamicTableTriggerActionView,
            variable: variable,
          );
        } else if (dynamicTableTriggerActionView["action_function"] == "UPDATE") {
          await handleTriggerActionUpdate(
            transaction: transaction,
            oldRow: oldRow,
            newRow: newRow,
            dynamicTableTriggerActionView: dynamicTableTriggerActionView,
            variable: variable,
          );
        } else if (dynamicTableTriggerActionView["action_function"] == "DELETE") {
          await handleTriggerActionDelete(
            transaction: transaction,
            oldRow: oldRow,
            newRow: newRow,
            dynamicTableTriggerActionView: dynamicTableTriggerActionView,
            variable: variable,
          );
        }
      }
    }
  }

  static Future<void> handleTriggerUpdate({
    required Transaction transaction,
    required Map<String, dynamic> oldRow,
    required Map<String, dynamic> newRow,
    required Map<String, dynamic> customFormView,
  }) async {
    List<Map<String, dynamic>> dynamicTableTriggerViews = await DMLAssemblers
        .create()
        .select("*")
        .from("f_dynamic_table_trigger")
        .equalTo("table_id", customFormView["table_header_id"])
        .and()
        .inn("trigger_state", ["BEFORE", "AFTER"])
        .and()
        .inn("trigger_operation", ["UPDATE", "INSERT OR UPDATE"])
        .all(transaction);

    for (Map<String, dynamic> dynamicTableTriggerView in dynamicTableTriggerViews) {
      List<Map<String, dynamic>> dynamicTableTriggerActionViews = await DMLAssemblers
          .create()
          .select("*")
          .from("f_dynamic_table_trigger_action")
          .equalTo("trigger_id", dynamicTableTriggerView["id"])
          .asc("sequence_index")
          .all(transaction);

      List<Map<String, dynamic>> dynamicTableTriggerVariableViews = await DMLAssemblers
          .create()
          .select("*")
          .from("f_dynamic_table_trigger_variable")
          .equalTo("trigger_id", dynamicTableTriggerView["id"])
          .all(transaction);

      Map<String, dynamic> variable = {};

      for (Map<String, dynamic> dynamicTableTriggerVariableView in dynamicTableTriggerVariableViews) {
        Map<String, dynamic>? result = await DMLAssemblers
            .create()
            .select("*")
            .from(dynamicTableTriggerVariableView["source_table_name"])
            .equalTo(dynamicTableTriggerVariableView["column_key"], newRow[dynamicTableTriggerVariableView["column_value"]])
            .first(transaction);

        if (result != null) {
          variable[dynamicTableTriggerVariableView["variable_name"]] = result;
        }
      }

      for (Map<String, dynamic> dynamicTableTriggerActionView in dynamicTableTriggerActionViews) {
        if (dynamicTableTriggerActionView["action_function"] == "INSERT") {
          await handleTriggerActionInsert(
            transaction: transaction,
            oldRow: {},
            newRow: newRow,
            dynamicTableTriggerActionView: dynamicTableTriggerActionView,
            variable: variable,
          );
        } else if (dynamicTableTriggerActionView["action_function"] == "UPDATE") {
          await handleTriggerActionUpdate(
            transaction: transaction,
            oldRow: {},
            newRow: newRow,
            dynamicTableTriggerActionView: dynamicTableTriggerActionView,
            variable: variable,
          );
        } else if (dynamicTableTriggerActionView["action_function"] == "DELETE") {
          await handleTriggerActionDelete(
            transaction: transaction,
            oldRow: {},
            newRow: newRow,
            dynamicTableTriggerActionView: dynamicTableTriggerActionView,
            variable: variable,
          );
        }
      }
    }
  }

  static String buildKey({
    required Map<String, dynamic> oldRow,
    required Map<String, dynamic> newRow,
    required Map<String, dynamic> variable,
    required Map<String, dynamic> dynamicTableTriggerActionDetailView,
  }) {
    if (dynamicTableTriggerActionDetailView["f_manual_key"] == "Y") {
      String? columnKey = dynamicTableTriggerActionDetailView["column_key"];

      if (StringUtils.isNotNullOrEmpty(columnKey)) {
        List<List<String>> pairedVariableKeywords = extractAllTableColumn(columnKey!);

        for (List<String> pairedVariableKeyword in pairedVariableKeywords) {
          String key = pairedVariableKeyword[0];
          String value = pairedVariableKeyword[1];

          if (StringUtils.inList(key, ["new", "NEW"])) {
            columnKey = columnKey!.replaceAll("$key.$value", newRow[value] != null ? "'${newRow[value]}'" : "NULL");
          } else if (StringUtils.inList(key, ["old", "OLD"])) {
            columnKey = columnKey!.replaceAll("$key.$value", oldRow[value] != null ? "'${oldRow[value]}'" : "NULL");
          } else {
            columnKey = columnKey!.replaceAll("$key.$value", variable[key][value] != null ? "'${variable[key][value]}'" : "NULL");
          }
        }

        return columnKey!;
      } else {
        return "NULL";
      }
    } else {
      return dynamicTableTriggerActionDetailView["column_key"];
    }
  }

  static String buildValue({
    required Map<String, dynamic> oldRow,
    required Map<String, dynamic> newRow,
    required Map<String, dynamic> variable,
    required Map<String, dynamic> dynamicTableTriggerActionDetailView,
  })  {
    if (dynamicTableTriggerActionDetailView["f_manual_value"] == "Y") {
      String? columnValue = dynamicTableTriggerActionDetailView["column_value"];

      if (StringUtils.isNotNullOrEmpty(columnValue)) {
        List<List<String>> pairedVariableKeywords = extractAllTableColumn(columnValue!);

        for (List<String> pairedVariableKeyword in pairedVariableKeywords) {
          String key = pairedVariableKeyword[0];
          String value = pairedVariableKeyword[1];

          if (StringUtils.inList(key, ["new", "NEW"])) {
            columnValue = columnValue!.replaceAll("$key.$value", newRow[value] != null ? "'${newRow[value]}'" : "NULL");
          } else if (StringUtils.inList(key, ["old", "OLD"])) {
            columnValue = columnValue!.replaceAll("$key.$value", oldRow[value] != null ? "'${oldRow[value]}'" : "NULL");
          } else {
            columnValue = columnValue!.replaceAll("$key.$value", variable[key][value] != null ? "'${variable[key][value]}'" : "NULL");
          }
        }

        return columnValue!;
      } else {
        return "NULL";
      }
    } else if (dynamicTableTriggerActionDetailView["f_variable"] == "Y") {
      return variable[dynamicTableTriggerActionDetailView["variable_name"]][dynamicTableTriggerActionDetailView["column_value"]] != null ? "'${variable[dynamicTableTriggerActionDetailView["variable_name"]][dynamicTableTriggerActionDetailView["column_value"]]}'" : "NULL";
    } else if (dynamicTableTriggerActionDetailView["f_sequence_id"] == "Y") {
      return "'${nextIdempotentId()}'";
    } else {
      if (newRow.isEmpty) {
        return oldRow[dynamicTableTriggerActionDetailView["column_value"]] != null ? "'${oldRow[dynamicTableTriggerActionDetailView["column_value"]]}'" : "NULL";
      } else {
        return newRow[dynamicTableTriggerActionDetailView["column_value"]] != null ? "'${newRow[dynamicTableTriggerActionDetailView["column_value"]]}'" : "NULL";
      }
    }
  }

  static String buildOperation(String operation) {
    if (operation == "ILIKE") {
      return "LIKE";
    } else {
      return operation;
    }
  }

  static String buildOperand(String? operand) {
    return operand ?? "";
  }

  static Future<void> handleTriggerActionInsert({
    required Transaction transaction,
    required Map<String, dynamic> oldRow,
    required Map<String, dynamic> newRow,
    required Map<String, dynamic> dynamicTableTriggerActionView,
    required Map<String, dynamic> variable,
  }) async {
    String buildData(Map<String, dynamic> dynamicTableTriggerActionDetailView) {
      return dynamicTableTriggerActionDetailView["key"];
    }

    String buildCondition(Map<String, dynamic> dynamicTableTriggerActionDetailView) {
      return buildValue(
        oldRow: oldRow,
        newRow: newRow,
        variable: variable,
        dynamicTableTriggerActionDetailView: dynamicTableTriggerActionDetailView,
      );
    }

    String buildConditionExtra(Map<String, dynamic> dynamicTableTriggerActionDetailView) {
      String key = buildKey(
        oldRow: oldRow,
        newRow: newRow,
        variable: variable,
        dynamicTableTriggerActionDetailView: dynamicTableTriggerActionDetailView,
      );

      String value = buildValue(
        oldRow: oldRow,
        newRow: newRow,
        variable: variable,
        dynamicTableTriggerActionDetailView: dynamicTableTriggerActionDetailView,
      );

      String operation = buildOperation(dynamicTableTriggerActionDetailView["operation"]);
      String operand = buildOperand(dynamicTableTriggerActionDetailView["operand"]);

      if (StringUtils.inList(operation, ["IN", "NOT IN"])) {
        return "$key $operation ($value) $operand";
      } else {
        return "$key $operation $value $operand";
      }
    }

    String tableName = dynamicTableTriggerActionView["dest_table_name"];

    List<Map<String, dynamic>> dynamicTableTriggerActionDetailViews = await DMLAssemblers
        .create()
        .select("*")
        .from("f_dynamic_table_trigger_action_detail")
        .equalTo("action_id", dynamicTableTriggerActionView["id"])
        .asc("action_mode")
        .asc("index_field")
        .all(transaction);

    Map<String, dynamic>? affectedRow = (await transaction.rawQuery("""
        INSERT INTO $tableName ( ${dynamicTableTriggerActionDetailViews.where((element) => element["action_mode"] == "DATA").map((dynamicTableTriggerActionDetailView) => buildData(dynamicTableTriggerActionDetailView)).join(", ")} )
        SELECT ${dynamicTableTriggerActionDetailViews.where((dynamicTableTriggerActionDetailView) => dynamicTableTriggerActionDetailView["action_mode"] == "CONDITION").map((dynamicTableTriggerActionDetailView) => buildCondition(dynamicTableTriggerActionDetailView)).join(", ")}
        WHERE ${dynamicTableTriggerActionDetailViews.isNotEmpty ? dynamicTableTriggerActionDetailViews.where((dynamicTableTriggerActionDetailView) => dynamicTableTriggerActionDetailView["action_mode"] == "CONDITION_EXTRA").map((dynamicTableTriggerActionDetailView) => buildConditionExtra(dynamicTableTriggerActionDetailView)).join(" ") : "TRUE"}
        RETURNING * 
      """
    )).firstOrNull;

    if (affectedRow != null) {
      String? sequenceName = (await DMLAssemblers
          .create()
          .select("sequence_name")
          .from("f_dynamic_table")
          .equalTo("table_name", tableName)
          .first(transaction))?["sequence_name"];

      if (StringUtils.isNotNullOrEmpty(sequenceName)) {
        Map<String, dynamic> finalizedAffectedRow = Map<String, dynamic>.from(affectedRow);

        List<Map<String, dynamic>> generateNumbers = await DMLAssemblers
            .create()
            .select("c.field_name")
            .select("c.default_value AS template")
            .from("f_dynamic_table a")
            .join("INNER JOIN c_custom_form b ON b.table_header_id = a.id")
            .join("INNER JOIN c_field_custom_form c ON c.custom_id = b.id")
            .equalTo("a.table_name", tableName)
            .and()
            .customWhere("c.default_value LIKE '%\$GENERATE_NUMBER%'")
            .all(transaction);

        finalizedAffectedRow["_metadata"] = {
          "action": "insert",
          "sequence": sequenceName,
          "generate_numbers": generateNumbers,
        };

        await insertSyncQueue(
          transaction: transaction,
          entity: tableName,
          payload: finalizedAffectedRow,
        );
      }
    }
  }

  static Future<void> handleTriggerActionUpdate({
    required Transaction transaction,
    required Map<String, dynamic> oldRow,
    required Map<String, dynamic> newRow,
    required Map<String, dynamic> dynamicTableTriggerActionView,
    required Map<String, dynamic> variable,
  }) async {
    String buildData(Map<String, dynamic> dynamicTableTriggerActionDetailView) {
      String value = buildValue(
        oldRow: oldRow,
        newRow: newRow,
        variable: variable,
        dynamicTableTriggerActionDetailView: dynamicTableTriggerActionDetailView,
      );

      return "${dynamicTableTriggerActionDetailView["column_key"]} = $value";
    }

    String buildCondition(Map<String, dynamic> dynamicTableTriggerActionDetailView) {
      String key = buildKey(
        oldRow: oldRow,
        newRow: newRow,
        variable: variable,
        dynamicTableTriggerActionDetailView: dynamicTableTriggerActionDetailView,
      );

      String value = buildValue(
        oldRow: oldRow,
        newRow: newRow,
        variable: variable,
        dynamicTableTriggerActionDetailView: dynamicTableTriggerActionDetailView,
      );

      String operation = buildOperation(dynamicTableTriggerActionDetailView["operation"]);
      String operand = buildOperand(dynamicTableTriggerActionDetailView["operand"]);

      if (StringUtils.inList(operation, ["IN", "NOT IN"])) {
        return "$key $operation ($value) $operand";
      } else {
        return "$key $operation $value $operand";
      }
    }

    String tableName = dynamicTableTriggerActionView["dest_table_name"];

    List<Map<String, dynamic>> dynamicTableTriggerActionDetailViews = await DMLAssemblers
        .create()
        .select("*")
        .from("f_dynamic_table_trigger_action_detail")
        .equalTo("action_id", dynamicTableTriggerActionView["id"])
        .asc("action_mode")
        .asc("index_field")
        .all(transaction);

    Map<String, dynamic>? affectedRow = (await transaction.rawQuery("""
        UPDATE $tableName
        SET ${dynamicTableTriggerActionDetailViews.where((element) => element["action_mode"] == "DATA").map((dynamicTableTriggerActionDetailView) => buildData(dynamicTableTriggerActionDetailView)).join(", ")}
        WHERE ${dynamicTableTriggerActionDetailViews.isNotEmpty ? dynamicTableTriggerActionDetailViews.where((dynamicTableTriggerActionDetailView) => dynamicTableTriggerActionDetailView["action_mode"] == "CONDITION").map((dynamicTableTriggerActionDetailView) => buildCondition(dynamicTableTriggerActionDetailView)).join(" ") : "TRUE"}
        RETURNING *
      """
    )).firstOrNull;

    if (affectedRow != null) {
      String? sequenceName = (await DMLAssemblers
          .create()
          .select("sequence_name")
          .from("f_dynamic_table")
          .equalTo("table_name", tableName)
          .first(transaction))?["sequence_name"];

      if (StringUtils.isNotNullOrEmpty(sequenceName)) {
        Map<String, dynamic> finalizedAffectedRow = Map<String, dynamic>.from(affectedRow);

        List<Map<String, dynamic>> generateNumbers = await DMLAssemblers
            .create()
            .select("c.field_name")
            .select("c.default_value AS template")
            .from("f_dynamic_table a")
            .join("INNER JOIN c_custom_form b ON b.table_header_id = a.id")
            .join("INNER JOIN c_field_custom_form c ON c.custom_id = b.id")
            .equalTo("a.table_name", tableName)
            .and()
            .customWhere("c.default_value LIKE '%\$GENERATE_NUMBER%'")
            .all(transaction);

        finalizedAffectedRow["_metadata"] = {
          "action": "update",
          "sequence": sequenceName,
          "generate_numbers": generateNumbers,
        };

        await insertSyncQueue(
          transaction: transaction,
          entity: tableName,
          payload: finalizedAffectedRow,
        );
      }
    }
  }

  static Future<void> handleTriggerActionDelete({
    required Transaction transaction,
    required Map<String, dynamic> oldRow,
    required Map<String, dynamic> newRow,
    required Map<String, dynamic> dynamicTableTriggerActionView,
    required Map<String, dynamic> variable,
  }) async {
    String buildCondition(Map<String, dynamic> dynamicTableTriggerActionDetailView) {
      String key = buildKey(
        oldRow: oldRow,
        newRow: newRow,
        variable: variable,
        dynamicTableTriggerActionDetailView: dynamicTableTriggerActionDetailView,
      );

      String value = buildValue(
        oldRow: oldRow,
        newRow: newRow,
        variable: variable,
        dynamicTableTriggerActionDetailView: dynamicTableTriggerActionDetailView,
      );

      String operation = buildOperation(dynamicTableTriggerActionDetailView["operation"]);
      String operand = buildOperand(dynamicTableTriggerActionDetailView["operand"]);

      if (StringUtils.inList(operation, ["IN", "NOT IN"])) {
        return "$key $operation ($value) $operand";
      } else {
        return "$key $operation $value $operand";
      }
    }

    String tableName = dynamicTableTriggerActionView["dest_table_name"];

    List<Map<String, dynamic>> dynamicTableTriggerActionDetailViews = await DMLAssemblers
        .create()
        .select("*")
        .from("f_dynamic_table_trigger_action_detail")
        .equalTo("action_id", dynamicTableTriggerActionView["id"])
        .asc("action_mode")
        .asc("index_field")
        .all(transaction);

    Map<String, dynamic>? affectedRow = (await transaction.rawQuery("""
        DELETE FROM $tableName
        WHERE ${dynamicTableTriggerActionDetailViews.isNotEmpty ? dynamicTableTriggerActionDetailViews.where((dynamicTableTriggerActionDetailView) => dynamicTableTriggerActionDetailView["action_mode"] == "CONDITION").map((dynamicTableTriggerActionDetailView) => buildCondition(dynamicTableTriggerActionDetailView)).join(" ") : "TRUE"}
        RETURNING *
      """
    )).firstOrNull;

    if (affectedRow != null) {
      String? sequenceName = (await DMLAssemblers
          .create()
          .select("sequence_name")
          .from("f_dynamic_table")
          .equalTo("table_name", tableName)
          .first(transaction))?["sequence_name"];

      if (StringUtils.isNotNullOrEmpty(sequenceName)) {
        Map<String, dynamic> finalizedAffectedRow = Map<String, dynamic>.from(affectedRow);

        List<Map<String, dynamic>> generateNumbers = await DMLAssemblers
            .create()
            .select("c.field_name")
            .select("c.default_value AS template")
            .from("f_dynamic_table a")
            .join("INNER JOIN c_custom_form b ON b.table_header_id = a.id")
            .join("INNER JOIN c_field_custom_form c ON c.custom_id = b.id")
            .equalTo("a.table_name", tableName)
            .and()
            .customWhere("c.default_value LIKE '%\$GENERATE_NUMBER%'")
            .all(transaction);

        finalizedAffectedRow["_metadata"] = {
          "action": "delete",
          "sequence": sequenceName,
          "generate_numbers": generateNumbers,
        };

        await insertSyncQueue(
          transaction: transaction,
          entity: tableName,
          payload: finalizedAffectedRow,
        );
      }
    }
  }

  static Future<void> insertSchedule({
    required Transaction transaction,
    required Map<String, dynamic> hashDTO,
    required Map<String, dynamic> customFormView,
  }) async {
    if (customFormView["f_allow_schedule"] == "Y") {
      Map<String, dynamic>? scheduleMetaData = await DMLAssemblers
          .create()
          .select("a.id AS table_id")
          .select("a.table_name")
          .select("b.id AS form_id")
          .from("f_dynamic_table a")
          .join("INNER JOIN c_custom_form b ON b.table_header_id = a.id")
          .equalTo("a.id", customFormView["table_schedule_id"])
          .and()
          .equalTo("b.template_mode", "SCHEDULE")
          .first(transaction);

      if (scheduleMetaData != null) {
        List<Map<String, dynamic>> dynamicScheduleMappingViews = await DMLAssemblers
            .create()
            .select("*")
            .from("t_dynamic_schedule_mapping")
            .equalTo("custom_form_id", customFormView["id"])
            .all(transaction);

        Iterable<MapEntry<String, dynamic>> iterable = hashDTO.entries.where((entry) => !(entry.value is List || entry.value is Map || StringUtils.inList(entry.key, ["id", "create_date", "create_who"])) && dynamicScheduleMappingViews.any((dynamicScheduleMappingView) => dynamicScheduleMappingView["master_column"] == entry.key));

        await transaction.execute("INSERT INTO ${scheduleMetaData["table_name"]} ( id, create_date, create_who, company_id, bu_id, table_id, form_id, custom_form_data, custom_form_id, ${dynamicScheduleMappingViews.map((dynamicScheduleMappingView) => dynamicScheduleMappingView["schedule_column"] as String).join(", ")} ) VALUES ( '${nextIdempotentId()}', DATETIME(), '$currentUsername', '$currentCompanyId', '$currentBusinessUnitId', '${scheduleMetaData["table_id"]}', '${scheduleMetaData["form_id"]}', '${hashDTO["id"]}', '${hashDTO["form_id"]}', ${iterable.map((entry) => entry.value != null ? "'${entry.value}'" : "NULL").join(", ")} );");
      }
    }
  }

  static Future<void> updateStatement({
    required Transaction transaction,
    required Map<String, dynamic> hashDTO,
    required Map<String, dynamic> customFormView,
    required Map<String, dynamic>? headerDTO,
    required Map<String, dynamic>? headerCustomFormView,
    required String? customerId,
  }) async {
    String tableName = customFormView["table_name"];

    List<String> actualFields = await getActualFields(tableName, transaction);

    for (String actualField in actualFields) {
      bool found = false;

      for (String fieldName in hashDTO.keys) {
        if (fieldName == actualField) {
          found = true;

          break;
        }
      }

      if (!found) {
        hashDTO[actualField] = null;
      }
    }

    for (String fieldName in hashDTO.keys) {
      if (fieldName == "company_id") {
        hashDTO[fieldName] = currentCompanyId;
      } else if (fieldName == "bu_id") {
        hashDTO[fieldName] = currentBusinessUnitId;
      } else if (fieldName == "salesunit_id") {
        hashDTO[fieldName] = currentSalesUnitId;
      } else if (fieldName == "user_id") {
        hashDTO[fieldName] = currentUsername;
      } else if (fieldName == "customer_id") {
        hashDTO[fieldName] = customerId;
      } else if (fieldName == "table_id") {
        hashDTO[fieldName] = customFormView["table_header_id"];
      } else if (fieldName == "form_id") {
        hashDTO[fieldName] = customFormView["id"];
      } else if (fieldName == "header_id") {
        hashDTO[fieldName] = headerDTO?["id"];
      } else if (fieldName == "custom_group_id") {
        hashDTO[fieldName] = headerDTO?["id"];
      } else if (fieldName == "custom_group_form_id") {
        hashDTO[fieldName] = headerCustomFormView?["id"];
      } else if (fieldName == "change_who") {
        hashDTO[fieldName] = currentUsername;
      } else if (fieldName == "change_date") {
        hashDTO[fieldName] = DateTime.now().toIso8601String();
      }
    }

    Map<String, dynamic>? oldRow = await DMLAssemblers
        .create()
        .select("*")
        .from(tableName)
        .equalTo("id", hashDTO["id"])
        .first(transaction);

    if (oldRow != null) {
      Iterable<MapEntry<String, dynamic>> iterable = hashDTO.entries.where((entry) => !(entry.value is List || entry.value is Map || StringUtils.inList(entry.key, ["salesunit_id", "user_id"])) && actualFields.contains(entry.key));

      Map<String, dynamic>? newRow = (await transaction.rawQuery("UPDATE $tableName SET ${iterable.map((entry) => "${entry.key} = ${entry.value != null ? "'${entry.value}'" : "NULL"}").join(", ")} WHERE id = '${hashDTO["id"]}' RETURNING *;")).firstOrNull;

      if (newRow != null) {
        await handleTrigger(
          states: ["BEFORE", "AFTER"],
          operations: ["UPDATE", "INSERT OR UPDATE"],
          transaction: transaction,
          oldRow: oldRow,
          newRow: newRow,
          customFormView: customFormView,
        );
      }
    }
  }

  static Future<void> updateSchedule({
    required Transaction transaction,
    required Map<String, dynamic> hashDTO,
    required Map<String, dynamic> customFormView,
  }) async {
    if (customFormView["f_allow_schedule"] == "Y") {
      Map<String, dynamic>? scheduleMetaData = await DMLAssemblers
          .create()
          .select("a.id AS table_id")
          .select("a.table_name")
          .select("b.id AS form_id")
          .from("f_dynamic_table a")
          .join("INNER JOIN c_custom_form b ON b.table_header_id = a.id")
          .equalTo("a.id", customFormView["table_schedule_id"])
          .and()
          .equalTo("b.template_mode", "SCHEDULE")
          .first(transaction);

      if (scheduleMetaData != null) {
        List<Map<String, dynamic>> dynamicScheduleMappingViews = await DMLAssemblers
            .create()
            .select("*")
            .from("t_dynamic_schedule_mapping")
            .equalTo("custom_form_id", customFormView["id"])
            .all(transaction);

        Iterable<MapEntry<String, dynamic>> iterable = hashDTO.entries.where((entry) => !(entry.value is List || entry.value is Map || StringUtils.inList(entry.key, ["id", "create_date", "create_who"])) && dynamicScheduleMappingViews.any((dynamicScheduleMappingView) => dynamicScheduleMappingView["master_column"] == entry.key));

        await transaction.execute("UPDATE ${scheduleMetaData["table_name"]} SET change_date = DATETIME(), change_who = '$currentUsername',  ${dynamicScheduleMappingViews.map((dynamicScheduleMappingView) => "${dynamicScheduleMappingView["schedule_column"]} = ${iterable.firstWhereOrNull((element) => element.key == dynamicScheduleMappingView["master_column"])?.value != null ? "'${iterable.firstWhereOrNull((element) => element.key == dynamicScheduleMappingView["master_column"])?.value}'" : "NULL"}" ).join(", ")} WHERE custom_form_data = '${hashDTO["id"]}' AND custom_form_id = '${hashDTO["form_id"]}';");
      }
    }
  }

  static Future<void> insertHistory({
    required Transaction transaction,
    required Map<String, dynamic> hashDTO,
    required Map<String, dynamic> customFormView,
  }) async {
    String? tableName = (await DMLAssemblers
        .create()
        .select("b.table_name")
        .from("f_dynamic_table a")
        .join("INNER JOIN f_dynamic_table b ON b.table_name = a.history_table")
        .equalTo("a.id", customFormView["table_header_id"])
        .first(transaction)
    )?["table_name"];

    if (tableName != null) {
      List<String> actualFields = await getActualFields(tableName, transaction);

      Iterable<MapEntry<String, dynamic>> iterable = hashDTO.entries.where((entry) => !(entry.value is List || entry.value is Map || StringUtils.inList(entry.key, ["id", "create_date", "create_who"])) && actualFields.contains(entry.key));

      await transaction.execute("INSERT INTO $tableName ( id, create_date, create_who, history_system_id, ${iterable.map((entry) => entry.key).join(", ")} ) VALUES ( '${nextIdempotentId()}', DATETIME(), '$currentUsername', '${hashDTO["id"]}', ${iterable.map((entry) => entry.value != null ? "'${entry.value}'" : "NULL").join(", ")} );");
    }
  }

  static Future<void> insertSyncQueue({
    required Transaction transaction,
    required String entity,
    required Map<String, dynamic> payload,
  }) async {
    await transaction.execute("INSERT INTO _sync_queues ( id, entity, payload, created_at ) VALUES ( '${Uuid().v4()}', '$entity', '${jsonEncode(payload)}', DATETIME() );");
  }

  static String nextIdempotentId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  static Future<int> nextSequence(String name, [Transaction? transaction]) async {
    DatabaseExecutor databaseExecutor = transaction ?? await Sqlites.get();

    int value = (await databaseExecutor.rawQuery(
      "INSERT INTO _sequences (id, value) VALUES (?, 1) ON CONFLICT (id) DO UPDATE SET value = value + 1 RETURNING value",
      [name],
    ))[0]["value"] as int;

    return value;
  }

  static Future<String> generateNumberSeries(String name, String template, [Transaction? transaction]) async {
    try {
      final data = template.split("#");

      if (data.length != 3) {
        throw Exception("Invalid Length # Format (Format : \$GENERATE_NUMBER#PREFIX#DIGIT_LENGTH) !");
      }

      String prefix = data[1];

      // Replace %BU%
      if (prefix.contains("%BU%")) {
        prefix = prefix.replaceAll("%BU%", currentBusinessUnitCode);
      }

      final now = DateTime.now();

      // Replace %dd%
      if (prefix.contains("%dd%")) {
        final dtPrefix = now.day.toString().padLeft(2, "0");
        prefix = prefix.replaceAll("%dd%", dtPrefix);
      }

      // Replace %MM%
      if (prefix.contains("%MM%")) {
        final dtPrefix = now.month.toString().padLeft(2, "0");
        prefix = prefix.replaceAll("%MM%", dtPrefix);
      }

      // Replace %yyyy%
      if (prefix.contains("%yyyy%")) {
        final dtPrefix = now.year.toString();
        prefix = prefix.replaceAll("%yyyy%", dtPrefix);
      }

      // Replace %yy%
      if (prefix.contains("%yy%")) {
        final dtPrefix = now.year.toString().substring(2);
        prefix = prefix.replaceAll("%yy%", dtPrefix);
      }

      final digit = int.parse(data[2]);

      // Call your ID generator (you must implement this in Dart)
      final generatedNumber = "${await nextSequence(name, transaction)}".padLeft(digit - prefix.length, "0");

      print("Success Generated Number Series Dynamic with prefix $prefix to be : $generatedNumber");

      return "$prefix${generatedNumber}_";
    } catch (e) {
      print("Failed generate Number Series on Dynamic Default Value cause format invalid");
    }

    return template;
  }

  static Future<List<String>> getActualFields(String tableName, [Transaction? transaction]) async {
    DatabaseExecutor databaseExecutor = transaction ?? await Sqlites.get();

    return (await databaseExecutor.rawQuery("PRAGMA table_info($tableName)")).map((e) => e["name"] as String).toList();
  }

  static List<List<String>> extractAllTableColumn(String input) {
    final regex = RegExp(r"([a-zA-Z0-9_]+)\.([a-zA-Z0-9_]+)");

    return regex.allMatches(input).map((match) {
      return [match.group(1)!, match.group(2)!];
    }).toList();
  }
}