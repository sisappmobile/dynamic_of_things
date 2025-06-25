// ignore_for_file: always_specify_types, cascade_invocations, always_put_required_named_parameters_first, empty_catches, use_build_context_synchronously

import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:collection/collection.dart";
import "package:dynamic_of_things/helper/bottom_sheets.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/model/dynamic_form_list_response.dart";
import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_page.dart";
import "package:dynamic_of_things/module/dynamic_form/list/dynamic_form_list_bloc.dart";
import "package:dynamic_of_things/module/dynamic_form/list/dynamic_form_list_event.dart";
import "package:dynamic_of_things/module/dynamic_form/list/dynamic_form_list_state.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:loader_overlay/loader_overlay.dart";

class DynamicFormListPage extends StatefulWidget {
  final DynamicFormMenuItem dynamicFormMenuItem;
  final String? customerId;

  const DynamicFormListPage({
    required this.dynamicFormMenuItem,
    required this.customerId,
    super.key,
  });

  @override
  DynamicFormListPageState createState() => DynamicFormListPageState();
}

class DynamicFormListPageState extends State<DynamicFormListPage> with WidgetsBindingObserver {
  ListResponse? listResponse;

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
    return BlocListener<DynamicFormListBloc, DynamicFormListState>(
      listener: (context, state) async {
        if (state is DynamicFormListLoadLoading) {
          setState(() {
            loading = true;
            listResponse = null;
          });
        } else if (state is DynamicFormListLoadSuccess) {
          setState(() {
            listResponse = state.listResponse;
          });
        } else if (state is DynamicFormListLoadFinished) {
          setState(() {
            loading = false;
          });
        } else if (state is DynamicFormListCustomActionLoading) {
          context.loaderOverlay.show();
        } else if (state is DynamicFormListCustomActionSuccess) {
          if (state.headerForm != null) {
            bool result = false;

            if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
              result = await Navigators.push(
                DynamicFormPage(
                  dynamicFormMenuItem: widget.dynamicFormMenuItem,
                  readOnly: false,
                  customerId: widget.customerId,
                  headerForm: state.headerForm,
                ),
              ) ?? false;
            } else {
              result = await context.push(
                "/dynamic-forms",
                extra: {
                  "dynamicFormMenuItem": widget.dynamicFormMenuItem,
                  "readOnly": false,
                  "customerId": widget.customerId,
                  "headerForm": state.headerForm,
                },
              ) ?? false;
            }

            if (result) {
              refresh();
            }
          } else {
            await BaseOverlays.success(message: "data_has_been_successfully_saved".tr());

            refresh();
          }
        } else if (state is DynamicFormListCustomActionFinished) {
          context.loaderOverlay.hide();
        }
      },
      child: BaseScaffold(
        context: context,
        statusBuilder: () {
          if (loading) {
            return BaseBodyStatus.loading;
          } else {
            if (listResponse != null) {
              if (filteredDatas().isNotEmpty) {
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
          name: widget.dynamicFormMenuItem.name,
          tecSearch: tecSearch,
          onChanged: (value) {
            setState(() {});
          },
        ),
        contentBuilder: body,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: floatingActionButton(),
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

  List<Map<String, dynamic>> filteredDatas() {
    return listResponse!.data.where((element) {
      String searchKey = "";

      for (Field field in listResponse!.fields) {
        searchKey += DynamicForms.spell(
          type: field.type,
          value: element[field.name],
        );
      }

      if (searchKey.toLowerCase().contains(tecSearch.text.toLowerCase())) {
        return true;
      } else {
        return false;
      }
    }).toList();
  }

  void refresh() {
    context.read<DynamicFormListBloc>().add(
      DynamicFormListLoad(
        id: widget.dynamicFormMenuItem.id,
        customerId: widget.customerId,
        name: widget.dynamicFormMenuItem.name,
      ),
    );
  }

  Widget body() {
    List<Field> fields = listResponse!.fields.where((element) => !element.primaryKey).toList();

    Field? primaryKey = listResponse!.fields.firstWhereOrNull((element) => element.primaryKey);

    return RefreshIndicator(
      onRefresh: () async {
        refresh();
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredDatas().length,
        separatorBuilder: (BuildContext context, int index) {
          return Divider(
            color: AppColors.outline(),
            height: 0,
          );
        },
        itemBuilder: (BuildContext context, int index) {
          Map<String, dynamic> map = filteredDatas()[index];

          List<Widget> widgets = [];

          for (int i = 0; i < fields.length; i++) {
            if (i % 2 == 0) {
              List<Widget> children = [];

              Field leftField = fields[i];

              children.add(
                childrenWidget(
                  description: leftField.description,
                  value: DynamicForms.spell(
                    type: leftField.type,
                    value: map[leftField.name],
                  ),
                  left: true,
                ),
              );

              if (i + 1 < fields.length) {
                Field rightField = fields[i + 1];

                children.add(
                  SizedBox(
                    width: Dimensions.size15,
                  ),
                );

                children.add(
                  childrenWidget(
                    description: rightField.description,
                    value: DynamicForms.spell(
                      type: rightField.type,
                      value: map[rightField.name],
                    ),
                    left: false,
                  ),
                );
              }

              widgets.add(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              );

              if (i + 2 < fields.length) {
                widgets.add(
                  SizedBox(
                    height: Dimensions.size10,
                  ),
                );
              }
            }
          }

          return InkWell(
            onTap: () async {
              if (primaryKey != null) {
                List<MenuItem> menuItems = [
                  MenuItem(
                    iconData: Icons.visibility,
                    title: "Lihat Data",
                    onTap: hasViewAccess() ? () async {
                      bool result = false;

                      if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                        Navigators.pop();

                        result = await Navigators.push(
                          DynamicFormPage(
                            dynamicFormMenuItem: widget.dynamicFormMenuItem,
                            readOnly: true,
                            dataId: map[primaryKey.name].toString(),
                            customerId: widget.customerId,
                          ),
                        ) ?? false;
                      } else {
                        context.pop();

                        result = await context.push(
                          "/dynamic-forms",
                          extra: {
                            "dynamicFormMenuItem": widget.dynamicFormMenuItem,
                            "readOnly": true,
                            "dataId": map[primaryKey.name].toString(),
                            "customerId": widget.customerId,
                          },
                        ) ?? false;
                      }

                      if (result) {
                        refresh();
                      }
                    } : null,
                  ),
                  MenuItem(
                    iconData: Icons.edit,
                    title: "edit".tr(),
                    onTap: hasEditAccess() ? () async {
                      bool result = false;

                      if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                        Navigators.pop();

                        result = await Navigators.push(
                          DynamicFormPage(
                            dynamicFormMenuItem: widget.dynamicFormMenuItem,
                            readOnly: false,
                            dataId: map[primaryKey.name].toString(),
                            customerId: widget.customerId,
                          ),
                        ) ?? false;
                      } else {
                        context.pop();

                        result = await context.push(
                          "/dynamic-forms",
                          extra: {
                            "dynamicFormMenuItem": widget.dynamicFormMenuItem,
                            "readOnly": false,
                            "dataId": map[primaryKey.name].toString(),
                            "customerId": widget.customerId,
                          },
                        ) ?? false;
                      }

                      if (result) {
                        refresh();
                      }
                    } : null,
                  ),
                ];

                listResponse!.actions.where((element) => !StringUtils.inList(element.resourceId, ["BTN_CREATE", "BTN_EDIT", "BTN_VIEW"])).forEach((element) {
                  MenuItem menuItem = MenuItem(
                    title: element.name,
                    onTap: () {
                      if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                        Navigators.pop();
                      } else {
                        context.pop();
                      }

                      BaseDialogs.confirmation(
                        title: "are_you_sure_want_to_proceed".tr(),
                        positiveCallback: () {
                          context.read<DynamicFormListBloc>().add(
                            DynamicFormListCustomAction(
                              actionId: element.id,
                              formId: widget.dynamicFormMenuItem.id,
                              dataId: map[primaryKey.name].toString(),
                              customerId: widget.customerId,
                            ),
                          );
                        },
                      );
                    },
                  );

                  menuItems.add(menuItem);
                });

                BottomSheets.popupMenu(
                  context: context,
                  menuItems: menuItems,
                );
              }
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(Dimensions.size15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widgets,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget childrenWidget({
    required String description,
    required String value,
    required bool left,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            description,
            textAlign: left ? TextAlign.start : TextAlign.end,
          ),
          Text(
            value,
            textAlign: left ? TextAlign.start : TextAlign.end,
            style: TextStyle(
              fontSize: Dimensions.text16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget floatingActionButton() {
    if (hasCreateAccess()) {
      return FloatingActionButton.extended(
        onPressed: () async {
          bool result = false;

          if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
            result = await Navigators.push(
              DynamicFormPage(
                dynamicFormMenuItem: widget.dynamicFormMenuItem,
                customerId: widget.customerId,
              ),
            ) ?? false;
          } else {
            result = await context.push(
              "/dynamic-forms",
              extra: {
                "dynamicFormMenuItem": widget.dynamicFormMenuItem,
                "customerId": widget.customerId,
              },
            ) ?? false;
          }

          if (result) {
            refresh();
          }
        },
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          "Create",
        ),
      );
    }

    return const SizedBox.shrink();
  }

  bool hasCreateAccess() {
    return listResponse != null && listResponse!.actions.any((element) => element.resourceId == "BTN_CREATE");
  }

  bool hasViewAccess() {
    return listResponse != null && listResponse!.actions.any((element) => element.resourceId == "BTN_VIEW");
  }

  bool hasEditAccess() {
    return listResponse != null && listResponse!.actions.any((element) => element.resourceId == "BTN_EDIT");
  }
}
