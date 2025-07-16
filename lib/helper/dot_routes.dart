import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_page.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_page.dart";
import "package:dynamic_of_things/module/dynamic_form/list/dynamic_form_list_page.dart";
import "package:dynamic_of_things/module/dynamic_form/menu/dynamic_form_menu_page.dart";
import "package:dynamic_of_things/module/dynamic_form/schedule/dynamic_form_schedule_page.dart";
import "package:dynamic_of_things/module/dynamic_report/dynamic_report_page.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_bulk_detail_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_detail_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_sub_detail_form.dart";
import "package:go_router/go_router.dart";

final List<GoRoute> dotRoutes = [
  GoRoute(
    path: "/dynamic-forms/menus",
    builder: (context, state) {
      return DynamicFormMenuPage();
    },
  ),
  GoRoute(
    path: "/dynamic-forms/list",
    builder: (context, state) {
      Map<String, dynamic> extra = state.extra as Map<String, dynamic>;

      return DynamicFormListPage(
        dynamicFormMenuItem: extra["dynamicFormMenuItem"],
        customerId: extra["customerId"],
      );
    },
  ),
  GoRoute(
    path: "/dynamic-forms/schedule",
    builder: (context, state) {
      Map<String, dynamic> extra = state.extra as Map<String, dynamic>;

      return DynamicFormSchedulePage(
        dynamicFormMenuItem: extra["dynamicFormMenuItem"],
        customerId: extra["customerId"],
      );
    },
  ),
  GoRoute(
    path: "/dynamic-forms",
    builder: (context, state) {
      Map<String, dynamic> extra = state.extra as Map<String, dynamic>;

      return DynamicFormPage(
        dynamicFormMenuItem: extra["dynamicFormMenuItem"],
        readOnly: extra["readOnly"] ?? false,
        dataId: extra["dataId"],
        customerId: extra["customerId"],
        headerForm: extra["headerForm"],
      );
    },
  ),
  GoRoute(
    path: "/dynamic-form-details",
    builder: (context, state) {
      Map<String, dynamic> extra = state.extra as Map<String, dynamic>;

      return CustomDynamicFormDetailForm(
        customerId: extra["customerId"],
        readOnly: extra["readOnly"],
        headerForm: extra["headerForm"],
        detailForm: extra["detailForm"],
        data: extra["data"] ?? {},
      );
    },
  ),
  GoRoute(
    path: "/dynamic-form-bulk-details",
    builder: (context, state) {
      Map<String, dynamic> extra = state.extra as Map<String, dynamic>;

      return CustomDynamicFormBulkDetailForm(
        customerId: extra["customerId"],
        readOnly: extra["readOnly"],
        headerForm: extra["headerForm"],
        detailForm: extra["detailForm"],
        rows: extra["rows"] ?? [],
      );
    },
  ),
  GoRoute(
    path: "/dynamic-form-sub-details",
    builder: (context, state) {
      Map<String, dynamic> extra = state.extra as Map<String, dynamic>;

      return CustomDynamicFormSubDetailForm(
        customerId: extra["customerId"],
        readOnly: extra["readOnly"],
        headerForm: extra["headerForm"],
        detailForm: extra["detailForm"],
        subDetailForm: extra["subDetailForm"],
        data: extra["data"] ?? {},
      );
    },
  ),
  GoRoute(
    path: "/dynamic-reports",
    builder: (context, state) {
      Map<String, dynamic> extra = state.extra as Map<String, dynamic>;

      return DynamicReportPage(
        dynamicFormMenuItem: extra["dynamicFormMenuItem"],
        dynamicFormCategoryItem: extra["dynamicFormCategoryItem"],
      );
    },
  ),
  GoRoute(
    path: "/dynamic-charts",
    builder: (context, state) {
      return DynamicChartPage();
    },
  ),
];