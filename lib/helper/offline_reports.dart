// ignore_for_file: cascade_invocations

import "dart:convert";
import "dart:typed_data";

import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/helper/dml_assemblers.dart";
import "package:dynamic_of_things/helper/offlines.dart";
import "package:dynamic_of_things/model/dynamic_report_data.dart";
import "package:dynamic_of_things/model/dynamic_report_template.dart";
import "package:easy_localization/easy_localization.dart";
import "package:syncfusion_flutter_xlsio/xlsio.dart";

class OfflineReports {
  static Future<Template> template(String id) async {
    Map<String, dynamic>? customReportView = await DMLAssemblers
        .create()
        .select("*")
        .from("c_custom_report")
        .equalTo("id", id)
        .first();

    if (customReportView == null) {
      throw Exception("Laporan tidak ditemukan");
    }

    Template template = Template();

    template.id = customReportView["id"].toString();
    template.title = customReportView["report_name"];
    template.pivotable = customReportView["f_pivot_mode"] == "Y";

    List<Map<String, dynamic>> customReportFieldViews = await DMLAssemblers
        .create()
        .select("*")
        .from("c_custom_report_field")
        .equalTo("custom_report_id", customReportView["id"])
        .asc("field_index")
        .all();

    for (Map<String, dynamic> customReportFieldView in customReportFieldViews) {
      if (customReportFieldView["f_show_field"] == "Y") {
        Field field = Field();

        field.id = customReportFieldView["id"].toString();
        field.name = customReportFieldView["field_name"];
        field.caption = customReportFieldView["field_caption"];
        field.type = customReportFieldView["field_type"];
        field.formatting = customReportFieldView["formatting"] ?? "";
        field.summarize = customReportFieldView["f_show_summary"] == "Y";

        template.fields.add(field);
      }
    }

    List<Map<String, dynamic>> customReportFilterViews = await DMLAssemblers
        .create()
        .select("*")
        .from("c_custom_report_filter")
        .equalTo("custom_report_id", customReportView["id"])
        .asc("field_index")
        .all();

    for (Map<String, dynamic> customReportFilterView in customReportFilterViews) {
      if (customReportFilterView["f_manual_hidden"] != "Y") {
        Filter filter = Filter();

        filter.id = customReportFilterView["id"].toString();
        filter.name = customReportFilterView["field_name"];
        filter.caption = customReportFilterView["field_caption"];
        filter.type = customReportFilterView["field_type"];
        filter.operator = customReportFilterView["field_operator"];
        filter.defaultValue = customReportFilterView["default_value"] ?? "";

        template.filters.add(filter);
      }
    }

    return template;
  }

  static Future<DataResponse> data({
    required String id,
    required DataRequest dataRequest,
  }) async {
    Map<String, dynamic>? customReportView = await DMLAssemblers
        .create()
        .select("a.*")
        .select("b.view_name")
        .from("c_custom_report a")
        .join("INNER JOIN c_segment_report b ON b.id = a.segment_id")
        .equalTo("a.id", id)
        .first();

    if (customReportView == null) {
      throw Exception("Laporan tidak ditemukan");
    }

    DMLAssemblers dmlAssemblers = DMLAssemblers.create()
        .select("*")
        .from(customReportView["view_name"]);

    List<Map<String, dynamic>> customReportFilterViews = await DMLAssemblers
        .create()
        .select("*")
        .from("c_custom_report_filter")
        .equalTo("custom_report_id", customReportView["id"])
        .asc("field_index")
        .all();

    for (Map<String, dynamic> customReportFilterView in customReportFilterViews) {
      if (customReportFilterView["logic_operator"] == "OR") {
        dmlAssemblers.or();
      } else {
        dmlAssemblers.and();
      }

      if (customReportFilterView["f_manual_hidden"] == "Y") {
        if (StringUtils.isNotNullOrEmpty(customReportFilterView["default_value"])) {
          String parameter;

          if (customReportFilterView["default_value"] == "\$selector") {
            parameter = currentBusinessUnitId;
          } else if (customReportFilterView["default_value"] == "\$selectorcompany") {
            parameter = currentCompanyId;
          } else if (customReportFilterView["default_value"] == "\$selectorcompany") {
            parameter = currentCompanyId;
          } else if (customReportFilterView["default_value"] == "\$user_id") {
            parameter = currentSalesUnitId;
          } else {
            parameter = customReportFilterView["default_value"];
          }

          dmlAssemblers.equalTo("${customReportView["view_name"]}.${customReportFilterView["field_name"]}", parameter);
        }
      } else {
        if (dataRequest.filters.containsKey(customReportFilterView["id"])) {
          String filterValue = dataRequest.filters[customReportFilterView["id"]].toString();

          dmlAssemblers.customWhere("${customReportView["view_name"]}.${customReportFilterView["field_name"]} ${customReportFilterView["field_operator"]} ?");

          if (customReportFilterView["field_operator"] == "LIKE") {
            dmlAssemblers.parameter("%$filterValue%");
          } else {
            dmlAssemblers.parameter(filterValue);
          }
        }
      }
    }

    if (StringUtils.isNotNullOrEmpty(dataRequest.sortField)) {
      if (dataRequest.sortDirection == "DESC") {
        dmlAssemblers.desc(dataRequest.sortField!);
      } else {
        dmlAssemblers.asc(dataRequest.sortField!);
      }
    }

    dmlAssemblers.limit(dataRequest.size);
    dmlAssemblers.offset(dataRequest.index * dataRequest.size);

    return DataResponse(
      size: await dmlAssemblers.count(),
      rows: await dmlAssemblers.all(),
    );
  }

  static Future<Map<String, String>?> resource({
    required String id,
    required String field,
  }) async {
    Map<String, dynamic>? customReportView = await DMLAssemblers
        .create()
        .select("a.*")
        .select("b.view_name")
        .from("c_custom_report a")
        .join("INNER JOIN c_segment_report b ON b.id = a.segment_id")
        .equalTo("a.id", id)
        .first();

    if (customReportView == null) {
      throw Exception("Laporan tidak ditemukan");
    }

    String table = customReportView["view_name"];
    String fieldName = field.replaceAll("_id", "_name");

    List<Map<String, dynamic>> rows = await DMLAssemblers
        .create()
        .select("DISTINCT ON ($field) $field AS id, $fieldName AS name")
        .from(table)
        .isNotNull(field)
        .asc(fieldName)
        .all();

    Map<String, String> results = {};

    for (Map<String, dynamic> row in rows) {
      results[row["id"]] = row["name"];
    }

    return results;
  }

  static Future<Map<String, dynamic>?> export({
    required String id,
    required DataRequest dataRequest,
  }) async {
    Map<String, dynamic>? customReportView = await DMLAssemblers
        .create()
        .select("a.*")
        .select("b.view_name")
        .from("c_custom_report a")
        .join("INNER JOIN c_segment_report b ON b.id = a.segment_id")
        .equalTo("a.id", id)
        .first();

    if (customReportView == null) {
      throw Exception("Laporan tidak ditemukan");
    }

    List<Map<String, dynamic>> customReportFieldViews = await DMLAssemblers
        .create()
        .select("*")
        .from("c_custom_report_field")
        .equalTo("custom_report_id", customReportView["id"])
        .asc("field_index")
        .all();

    DataResponse dataResponse = await data(id: id, dataRequest: dataRequest);

    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    sheet.name = "DATA";

    // =========================
    // STYLES
    // =========================
    final Style headerStyle = workbook.styles.add("headerStyle");
    headerStyle.bold = true;
    headerStyle.hAlign = HAlignType.center;
    headerStyle.backColor = "#D9D9D9";
    headerStyle.borders.all.lineStyle = LineStyle.medium;

    final Style contentStyle = workbook.styles.add("contentStyle");
    contentStyle.hAlign = HAlignType.left;
    contentStyle.borders.all.lineStyle = LineStyle.thin;

    final Style hyperlinkStyle = workbook.styles.add("hyperlinkStyle");
    hyperlinkStyle.underline = true;
    hyperlinkStyle.fontColor = "#0000FF";

    // =========================
    // HEADER (Row 3 in Excel → index 2)
    // =========================
    int totalShowField = 0;

    for (Map<String, dynamic> customReportFieldView in customReportFieldViews) {
      if (customReportFieldView["f_show_field"] == "Y") {
        final cell = sheet.getRangeByIndex(3, totalShowField + 1);
        cell.setText(customReportFieldView["field_caption"]);
        cell.cellStyle = headerStyle;
        totalShowField++;
      }
    }

    // =========================
    // TITLE (merge row 1-2)
    // =========================
    sheet.getRangeByIndex(1, 1, 2, totalShowField).merge();
    final titleCell = sheet.getRangeByIndex(1, 1);
    titleCell.setText(customReportView["report_name"]);
    titleCell.cellStyle = headerStyle;

    // =========================
    // DATA
    // =========================
    int rowIndex = 4; // start from row 4 (same as i+3 in Java)

    Map<String, double> grandTotalData = {};
    int totalColumn = 0;

    for (int i = 0; i < dataResponse.rows.length; i++) {
      final data = dataResponse.rows[i];

      int columnIndex = 1;

      for (Map<String, dynamic> customReportFieldView in customReportFieldViews) {
        if (customReportFieldView["f_show_field"] == "Y") {
          final cell = sheet.getRangeByIndex(rowIndex, columnIndex);

          // FOTO handling
          if (customReportFieldView["field_type"] == "FOTO") {
            final value = data[customReportFieldView["field_name"]];
            final encodedFileId = base64Encode(utf8.encode(value.toString()));

            final link =
                "https://posdemo.sisapp.com:8443/previewimage?file_id=$encodedFileId";

            cell.setText("Lihat Foto");
            cell.cellStyle = hyperlinkStyle;

            // Add hyperlink (correct way)
            sheet.hyperlinks.add(
              cell,
              HyperlinkType.url,
              link,
            );
          } else {
            // Normal value
            final value = data[customReportFieldView["field_name"]];
            cell.setText(value?.toString() ?? "");
            cell.cellStyle = contentStyle;
          }

          // =========================
          // SUMMARY
          // =========================
          if (customReportFieldView["f_show_summary"] == "Y") {
            String valSummary = data[customReportFieldView["field_name"]]?.toString() ?? "Empty";

            String keySummary =
                "Summary ${customReportFieldView["field_caption"]} $valSummary";

            double currentTotal = grandTotalData[keySummary] ?? 0;

            if (customReportFieldView["field_type"] == "NUMERIC") {
              keySummary = "Summary ${customReportFieldView["field_caption"]}";
              final value =
                  (data[customReportFieldView["field_name"]] as num?)?.toDouble() ?? 0;
              currentTotal += value;
            } else if (customReportFieldView["field_type"] != "FOTO") {
              currentTotal += 1;
            }

            grandTotalData[keySummary] = currentTotal;
          }

          columnIndex++;
        }
      }

      totalColumn = columnIndex - 1;
      rowIndex++;
    }

    // =========================
    // SUMMARY SECTION
    // =========================
    rowIndex += 4;

    int centerColumn = (totalColumn / 2).floor();
    int currentColumn = totalColumn;

    for (var entry in grandTotalData.entries) {
      if (currentColumn <= centerColumn) {
        currentColumn = totalColumn;
        rowIndex += 2;
      }

      final keyCell =
      sheet.getRangeByIndex(rowIndex, currentColumn);
      keyCell.setText(entry.key);
      keyCell.cellStyle = headerStyle;

      final valueCell =
      sheet.getRangeByIndex(rowIndex + 1, currentColumn);
      valueCell.setText(entry.value.toString());
      valueCell.cellStyle = contentStyle;

      currentColumn--;
    }

    // =========================
    // SAVE
    // =========================
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    return {
      "fileName": "${customReportView["report_name"]}_${DateFormat("ddMMyyHHmmss").format(DateTime.now())}.xlsx",
      "bytes": Uint8List.fromList(bytes),
    };
  }
}