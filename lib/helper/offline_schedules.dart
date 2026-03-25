// ignore_for_file: cascade_invocations

import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/helper/dml_assemblers.dart";
import "package:dynamic_of_things/helper/offlines.dart";
import "package:dynamic_of_things/model/dynamic_schedule_template.dart";
import "package:jiffy/jiffy.dart";

class OfflineSchedules {
  static Future<Template?> template(String id) async {
    Map<String, dynamic>? customFormView = await Offlines.loadCustomFormView(id);

    if (customFormView != null) {
      Template template = Template();

      List<Map<String, dynamic>> customFunctionsViews = await DMLAssemblers
          .create()
          .select("CAST(e.function_id AS TEXT) AS id")
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

      for (Map<String, dynamic> customFunctionsView in customFunctionsViews) {
        Action action = Action();

        action.id = customFunctionsView["id"];
        action.resourceId = customFunctionsView["resource_id"];
        action.name = customFunctionsView["name"];

        template.actions.add(action);
      }

      List<Map<String, dynamic>> rows = await DMLAssemblers
          .create()
          .select("DISTINCT CAST(b.id AS TEXT) AS id")
          .select("b.form_desc AS name")
          .from("${customFormView["table_name"]} a")
          .join("INNER JOIN c_custom_form b ON b.id = a.custom_form_id")
          .all();

      for (Map<String, dynamic> row in rows) {
        template.forms[row["id"]] = row["name"];
      }

      return template;
    }

    return null;
  }

  static Future<List<Map<String, dynamic>>> data({
    required String id,
    required Jiffy begin,
    required Jiffy until,
    String? customerId,
    String? formId,
  }) async {
    Map<String, dynamic>? customFormView = await Offlines.loadCustomFormView(id);

    if (customFormView != null) {
      DMLAssemblers dmlAssemblers = DMLAssemblers
          .create()
          .select("a.*")
          .select("b.form_desc AS form_name")
          .from("${customFormView["table_name"]} a")
          .join("LEFT JOIN c_custom_form b ON b.id = a.custom_form_id")
          .equalTo("a.company_id", currentCompanyId)
          .and()
          .customWhere("DATE(a.start_date) >= DATE('${begin.format()}')")
          .and()
          .customWhere("DATE(a.end_date) <= DATE('${until.format()}')");

      if (formId != null) {
        dmlAssemblers
            .and()
            .equalTo("a.custom_form_id", formId);
      }

      if (customerId != null) {
        dmlAssemblers
            .and()
            .equalTo("a.customer_id", customerId);
      }

      List<String> userIds = [];
      List<String> salesUnitIds = [];

      if (customFormView["f_creator"] == "Y") {
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

      String dataFilterClauseBuilder = "";

      if (userIds.isNotEmpty) {
        dataFilterClauseBuilder += "a.create_who IN (${List.generate(userIds.length, (index) => "?").join(", ")})";

        for (String userId in userIds) {
          dmlAssemblers.parameter(userId);
        }
      }

      if (salesUnitIds.isNotEmpty) {
        if (dataFilterClauseBuilder.isNotEmpty) {
          dataFilterClauseBuilder += " OR ";
        }

        dataFilterClauseBuilder += "a.salesunit_id IN (${List.generate(salesUnitIds.length, (index) => "?").join(", ")})";

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

          dataFilterClauseBuilder += "a.$columnName IN (?, ?)";

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
      
      return rows.map((row) {
        return {
          "id": row["id"],
          "title": row["title"],
          "description": row["description"],
          "begin": row["start_date"],
          "until": row["end_date"],
          "formId": row["formId"],
          "formName": row["formName"],
        };
      }).toList();
    }

    return [];
  }
}