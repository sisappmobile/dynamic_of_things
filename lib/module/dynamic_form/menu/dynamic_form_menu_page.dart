
// ignore_for_file: always_specify_types, cascade_invocations, always_put_required_named_parameters_first

import "package:base/base.dart";
import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";
import "package:dynamic_of_things/module/dynamic_form/list/dynamic_form_list_page.dart";
import "package:dynamic_of_things/module/dynamic_form/menu/dynamic_form_menu_bloc.dart";
import "package:dynamic_of_things/module/dynamic_form/menu/dynamic_form_menu_event.dart";
import "package:dynamic_of_things/module/dynamic_form/menu/dynamic_form_menu_state.dart";
import "package:dynamic_of_things/module/dynamic_report/dynamic_report_page.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:smooth_corner/smooth_corner.dart";

class DynamicFormMenuPage extends StatefulWidget {
  final String? customerId;

  const DynamicFormMenuPage({
    super.key,
    this.customerId,
  });

  @override
  DynamicFormMenuPageState createState() => DynamicFormMenuPageState();
}

class DynamicFormMenuPageState extends State<DynamicFormMenuPage> with WidgetsBindingObserver {
  DynamicFormMenuResponse? dynamicFormMenuResponse;

  bool loading = true;

  TextEditingController tecSearch = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DynamicFormMenuBloc, DynamicFormMenuState>(
      listener: (context, state) async {
        if (state is DynamicFormMenuLoadLoading) {
          setState(() {
            loading = true;
            dynamicFormMenuResponse = null;
          });
        } else if (state is DynamicFormMenuLoadSuccess) {
          setState(() {
            dynamicFormMenuResponse = state.dynamicFormMenuResponse;
          });
        } else if (state is DynamicFormMenuLoadFinished) {
          setState(() {
            loading = false;
          });
        }
      },
      child: BaseScaffold(
        context: context,
        statusBuilder: () {
          if (loading) {
            return BaseBodyStatus.loading;
          } else {
            if (dynamicFormMenuResponse != null) {
              if (filteredDynamicFormCategoryItems().isNotEmpty) {
                return BaseBodyStatus.loaded;
              } else {
                return BaseBodyStatus.empty;
              }
            } else {
              return BaseBodyStatus.fail;
            }
          }
        },
        appBar: BaseAppBar(
          context: context,
          name: "menu".tr(),
          tecSearch: tecSearch,
          onChanged: (value) => setState(() {}),
        ),
        contentBuilder: body,
        onRefresh: () async {
          refresh();
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();

    setState(() {});
  }

  List<DynamicFormCategoryItem> filteredDynamicFormCategoryItems() {
    return dynamicFormMenuResponse!.categories.where((element1) => element1.menus.any((element2) => element2.name.toLowerCase().contains(tecSearch.text.toLowerCase()))).toList();
  }

  List<DynamicFormMenuItem> filteredDynamicFormMenuItems({
    required DynamicFormCategoryItem dynamicFormCategoryItem,
  }) {
    return dynamicFormCategoryItem.menus.where((element) => element.name.toLowerCase().contains(tecSearch.text.toLowerCase())).toList();
  }

  void refresh() {
    context.read<DynamicFormMenuBloc>().add(
      DynamicFormMenuLoad(
        customerId: widget.customerId,
      ),
    );
  }

  Widget body() {
    return RefreshIndicator(
      onRefresh: () async {
        refresh();
      },
      child: ListView.separated(
        padding: EdgeInsets.all(Dimensions.size15),
        itemCount: filteredDynamicFormCategoryItems().length,
        separatorBuilder: (context, index) {
          return SizedBox(height: Dimensions.size15);
        },
        itemBuilder: (context, index1) {
          DynamicFormCategoryItem dynamicFormCategoryItem = filteredDynamicFormCategoryItems()[index1];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dynamicFormCategoryItem.name.toUpperCase(),
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: Dimensions.text16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: Dimensions.size10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDynamicFormMenuItems(dynamicFormCategoryItem: dynamicFormCategoryItem).length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: Dimensions.size60 * 2,
                  crossAxisSpacing: Dimensions.size10,
                  mainAxisSpacing: Dimensions.size10,
                ),
                itemBuilder: (BuildContext context, int index2) {
                  DynamicFormMenuItem dynamicFormMenuItem = filteredDynamicFormMenuItems(dynamicFormCategoryItem: dynamicFormCategoryItem)[index2];

                  return InkWell(
                    onTap: () async {
                      if (dynamicFormMenuItem.type == "REPORT") {
                        if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                          await Navigators.push(
                            DynamicReportPage(
                              dynamicFormMenuItem: dynamicFormMenuItem,
                              dynamicFormCategoryItem: dynamicFormCategoryItem,
                            ),
                          );
                        } else {
                          await context.push(
                            "/dynamic-reports",
                            extra: {
                              "dynamicFormMenuItem": dynamicFormMenuItem,
                              "dynamicFormCategoryItem": dynamicFormCategoryItem,
                            },
                          );
                        }
                      } else {
                        if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                          await Navigators.push(
                            DynamicFormListPage(
                              dynamicFormMenuItem: dynamicFormMenuItem,
                              customerId: widget.customerId,
                            ),
                          );
                        } else {
                          await context.push(
                            "/dynamic-forms/list",
                            extra: {
                              "dynamicFormMenuItem": dynamicFormMenuItem,
                              "customerId": widget.customerId,
                            },
                          );
                        }
                      }
                    },
                    customBorder: SmoothRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.size15),
                      smoothness: 1,
                    ),
                    child: Ink(
                      width: double.infinity,
                      height: Dimensions.size100,
                      decoration: ShapeDecoration(
                        shape: SmoothRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimensions.size15),
                          smoothness: 1,
                          side: BorderSide(
                            color: AppColors.onPrimaryContainer(),
                          ),
                        ),
                        color: AppColors.primaryContainer(),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: Dimensions.size10,
                        horizontal: Dimensions.size5,
                      ),
                      child: Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dynamicFormMenuItem.name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.onPrimaryContainer(),
                                fontSize: Dimensions.text14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

