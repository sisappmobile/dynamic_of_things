// ignore_for_file: cascade_invocations

import "package:dynamic_of_things/helper/dml_assemblers.dart";
import "package:dynamic_of_things/helper/formats.dart";
import "package:dynamic_of_things/helper/offlines.dart";
import "package:dynamic_of_things/helper/pg_to_sqlite_converter.dart";
import "package:dynamic_of_things/helper/sqlites.dart";
import "package:dynamic_of_things/model/dynamic_chart_list_response.dart";
import "package:jiffy/jiffy.dart";
import "package:sqflite/sqflite.dart";

class OfflineCharts {
  static Future<ListResponse?> list() async {
    List<Map<String, dynamic>> dynamicChartViews = await DMLAssemblers
        .create()
        .select("c.*")
        .from("c_sales_access_custom_form a")
        .join("INNER JOIN c_group_access_sales_unit_custom_form_detail b ON b.group_id = a.group_id")
        .join("INNER JOIN t_dynamic_chart c ON c.id = a.custom_id")
        .customWhere("COALESCE(a.custom_type, 'FORM') = 'CHART'")
        .and()
        .customWhere("COALESCE(c.show, 'N') = 'Y'")
        .and()
        .equalTo("b.user_id", currentSalesUnitId)
        .and()
        .equalTo("c.company_id", currentCompanyId)
        .asc('c."index"')
        .all();

    ListResponse listResponse = ListResponse();

    for (Map<String, dynamic> dynamicChartView in dynamicChartViews) {
      if (dynamicChartView["type"] == "Card") {
        Summary summary = Summary();

        summary.id = dynamicChartView["id"].toString();
        summary.title = dynamicChartView["title"];
        summary.type = dynamicChartView["type"];
        summary.size = Formats.tryParseNumber(dynamicChartView["size"]).toInt();
        summary.icon = dynamicChartView["config_2"];
        summary.color = dynamicChartView["config_3"];

        listResponse.charts.add(summary);
      } else if (dynamicChartView["type"] == "Bar Chart") {
        Bar bar = Bar();

        bar.id = dynamicChartView["id"].toString();
        bar.title = dynamicChartView["title"];
        bar.type = dynamicChartView["type"];
        bar.size = Formats.tryParseNumber(dynamicChartView["size"]).toInt();

        List<Map<String, dynamic>> dynamicChartDetailViews = await DMLAssemblers
            .create()
            .select("*")
            .from("t_dynamic_chart_detail")
            .equalTo("id_chart", dynamicChartView["id"])
            .asc("id")
            .all();

        for (Map<String, dynamic> dynamicChartDetailView in dynamicChartDetailViews) {
          if (dynamicChartDetailView["axis"] == "Category") {
            bar.xLabel = dynamicChartDetailView["name"];
          }

          if (dynamicChartDetailView["axis"] == "Value") {
            bar.xLabel = dynamicChartDetailView["name"];
          }
        }

        listResponse.charts.add(bar);
      }
    }

    return listResponse;
  }

  static Future<dynamic> data({
    required String id,
    required Jiffy begin,
    required Jiffy until,
  }) async {
    Map<String, dynamic>? dynamicChartView = await DMLAssemblers
        .create()
        .select("a.*")
        .select("b.view_name")
        .select("b.segment_report_query")
        .from("t_dynamic_chart a")
        .join("INNER JOIN c_segment_report b ON b.id = a.segment_id")
        .equalTo("a.id", id)
        .first();

    if (dynamicChartView != null) {
      if (dynamicChartView["type"] == "Card") {
        Database database = await Sqlites.get();

        PgToSqliteConverter pgToSqliteConverter = PgToSqliteConverter();

        Map<String, dynamic>? dataTable = (await database.rawQuery(pgToSqliteConverter.convert(dynamicChartView["segment_report_query"]))).firstOrNull;

        if (dataTable != null) {
          List<Map<String, dynamic>> dynamicChartDetailViews = await DMLAssemblers
              .create()
              .select("*")
              .from("t_dynamic_chart_detail")
              .equalTo("id_chart", dynamicChartView["id"])
              .asc("id")
              .all();

          String key = "";
          String value = "";

          for (Map<String, dynamic> dynamicChartDetailView in dynamicChartDetailViews) {
            if (dynamicChartDetailView["axis"] == "Category") {
              key = (dynamicChartDetailView["name"] as String).replaceAll("\${var}", dataTable[dynamicChartDetailView["field_name"]]);
            }

            if (dynamicChartDetailView["axis"] == "Value") {
              value = (dynamicChartDetailView["name"] as String).replaceAll("\${var}", dataTable[dynamicChartDetailView["field_name"]]);
            }
          }

          return {
            "label": key,
            "value": value,
          };
        }
      } else if (dynamicChartView["type"] == "Bar Chart") {
        String? categoryField;
        String? valueField;
        String? variableField;

        List<Map<String, dynamic>> dynamicChartDetailViews = await DMLAssemblers
            .create()
            .select("*")
            .from("t_dynamic_chart_detail")
            .equalTo("id_chart", dynamicChartView["id"])
            .asc("id")
            .all();

        for (Map<String, dynamic> dynamicChartDetailView in dynamicChartDetailViews) {
          if (dynamicChartDetailView["axis"] == "Category") {
            categoryField = dynamicChartDetailView["field_name"];
          } else if (dynamicChartDetailView["axis"] == "Value") {
            valueField = dynamicChartDetailView["field_name"];
          } else if (dynamicChartDetailView["axis"] == "Variable") {
            variableField = dynamicChartDetailView["field_name"];
          }
        }

        List<Map<String, dynamic>> results = [];

        if (categoryField != null && valueField != null) {
          DMLAssemblers dmlAssemblers = DMLAssemblers
              .create()
              .select("*")
              .from(dynamicChartView["view_name"]);

          if (dynamicChartView["user_filter_field"] != null) {
            dmlAssemblers.equalTo(dynamicChartView["user_filter_field"], currentSalesUnitId);
          }

          List<Map<String, dynamic>> rows = await dmlAssemblers.all();

          for (Map<String, dynamic> row in rows) {
            Map<String, dynamic> result = {
              "category": row[categoryField],
              "value": row[valueField],
            };

            if (variableField != null) {
              result["variable"] = row[variableField];
            }

            results.add(result);
          }
        }

        return results;
      }
    }
  }
}