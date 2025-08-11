// ignore_for_file: always_specify_types, cascade_invocations, always_put_required_named_parameters_first, empty_catches, use_build_context_synchronously

import "package:base/base.dart";
import "package:dynamic_of_things/helper/bottom_sheets.dart";
import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";
import "package:dynamic_of_things/model/dynamic_schedule_data.dart";
import "package:dynamic_of_things/model/dynamic_schedule_template.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_page.dart";
import "package:dynamic_of_things/module/dynamic_schedule/dynamic_schedule_bloc.dart";
import "package:dynamic_of_things/module/dynamic_schedule/dynamic_schedule_event.dart";
import "package:dynamic_of_things/module/dynamic_schedule/dynamic_schedule_state.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:jiffy/jiffy.dart";
import "package:loader_overlay/loader_overlay.dart";
import "package:smooth_corner/smooth_corner.dart";
import "package:syncfusion_flutter_calendar/calendar.dart";

class DynamicSchedulePage extends StatefulWidget {
  final DynamicFormMenuItem dynamicFormMenuItem;
  final String? customerId;

  const DynamicSchedulePage({
    required this.dynamicFormMenuItem,
    required this.customerId,
    super.key,
  });

  @override
  DynamicSchedulePageState createState() => DynamicSchedulePageState();
}

class DynamicSchedulePageState extends State<DynamicSchedulePage> with WidgetsBindingObserver {
  Template? template;

  List<Item> items = [];

  bool loading = true;

  DateTime today = DateTime.now();

  String? formId;

  List<DateTime> visibleDates = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    context.read<DynamicScheduleBloc>().add(
      DynamicScheduleTemplate(
        id: widget.dynamicFormMenuItem.id,
        customerId: widget.customerId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DynamicScheduleBloc, DynamicScheduleState>(
      listener: (context, state) async {
        if (state is DynamicScheduleTemplateLoading) {
          setState(() {
            loading = true;
            template = null;
          });
        } else if (state is DynamicScheduleTemplateSuccess) {
          setState(() {
            template = state.template;
          });
        } else if (state is DynamicScheduleTemplateFinished) {
          setState(() {
            loading = false;
          });
        } else if (state is DynamicScheduleDataLoading) {
          context.loaderOverlay.show();

          setState(() {
            items.clear();
          });
        } else if (state is DynamicScheduleDataSuccess) {
          setState(() {
            items.addAll(state.items);
          });
        } else if (state is DynamicScheduleDataFinished) {
          context.loaderOverlay.hide();
        }
      },
      child: BaseScaffold(
        context: context,
        statusBuilder: () {
          if (loading) {
            return BaseBodyStatus.loading;
          } else {
            if (template != null) {
              return BaseBodyStatus.loaded;
            } else {
              return BaseBodyStatus.fail;
            }
          }
        },
        appBar: appBar(),
        contentBuilder: body,
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

  void refresh() {
    context.read<DynamicScheduleBloc>().add(
      DynamicScheduleData(
        id: widget.dynamicFormMenuItem.id,
        begin: Jiffy.parseFromDateTime(visibleDates.first),
        until: Jiffy.parseFromDateTime(visibleDates.last),
        formId: formId,
        customerId: widget.customerId,
      ),
    );
  }

  BaseAppBar appBar() {
    Widget addButton() {
      if (hasCreateAccess()) {
        return OutlinedButton.icon(
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
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              smoothness: 1,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.size10,
            ),
          ),
          icon: Icon(Icons.add),
          label: Text("add".tr()),
        );
      }

      return const SizedBox.shrink();
    }

    PreferredSize? bottomWidget() {
      if (template != null && template!.forms.isNotEmpty) {
        return PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: SizedBox(
            height: 50,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                Dimensions.size15,
                0,
                Dimensions.size15,
                Dimensions.size15,
              ),
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return FilterChip(
                    label: Text("all".tr()),
                    selected: formId == null,
                    shape: SmoothRectangleBorder(
                      smoothness: 1,
                      borderRadius: BorderRadius.circular(Dimensions.size10),
                      side: BorderSide(color: formId == null ? AppColors.onPrimaryContainer() : AppColors.outline()),
                    ),
                    selectedColor: AppColors.primaryContainer(),
                    onSelected: (value) {
                      formId = null;

                      refresh();
                    },
                  );
                } else {
                  MapEntry<String, String> mapEntry = template!.forms.entries.elementAt(index - 1);

                  return FilterChip(
                    label: Text(mapEntry.value),
                    selected: formId == mapEntry.key,
                    shape: SmoothRectangleBorder(
                      smoothness: 1,
                      borderRadius: BorderRadius.circular(Dimensions.size10),
                      side: BorderSide(color: formId == mapEntry.key ? AppColors.onPrimaryContainer() : AppColors.outline()),
                    ),
                    selectedColor: AppColors.primaryContainer(),
                    onSelected: (value) {
                      formId = mapEntry.key;

                      refresh();
                    },
                  );
                }
              },
              separatorBuilder: (context, index) {
                return SizedBox(width: Dimensions.size5);
              },
              itemCount: template!.forms.length + 1,
            ),
          ),
        );
      }

      return null;
    }

    return BaseAppBar(
      context: context,
      name: widget.dynamicFormMenuItem.name,
      trailings: [addButton()],
      bottom: bottomWidget(),
    );
  }

  Widget body() {
    return SfCalendar(
      view: CalendarView.month,
      initialDisplayDate: DateTime(today.year, today.month, today.day),
      dataSource: ItemDataSource(items),
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
        showAgenda: true,
        appointmentDisplayCount: 3,
      ),
      onViewChanged: (viewChangedDetails) {
        visibleDates = viewChangedDetails.visibleDates;

        refresh();
      },
      onTap: (CalendarTapDetails details) {
        if (details.targetElement == CalendarElement.appointment && details.appointments != null && details.appointments!.isNotEmpty) {
          Item item = details.appointments!.first as Item;

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
                      dataId: item.id,
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
                      "dataId": item.id,
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
                      dataId: item.id,
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
                      "dataId": item.id,
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

          BottomSheets.popupMenu(
            context: context,
            menuItems: menuItems,
          );
        }
      },
    );
  }

  bool hasCreateAccess() {
    return template != null && template!.actions.any((element) => element.resourceId == "BTN_CREATE");
  }

  bool hasViewAccess() {
    return template != null && template!.actions.any((element) => element.resourceId == "BTN_VIEW");
  }

  bool hasEditAccess() {
    return template != null && template!.actions.any((element) => element.resourceId == "BTN_EDIT");
  }
}

class ItemDataSource extends CalendarDataSource {
  final List<Color> colors = [
    ...Colors.primaries,
    ...Colors.accents,
  ];

  ItemDataSource(List<Item> source) {
    appointments = source;
  }

  @override
  Object? getId(int index) {
    return _getItemData(index).id;
  }

  @override
  DateTime getStartTime(int index) {
    return _getItemData(index).begin.dateTime;
  }

  @override
  DateTime getEndTime(int index) {
    return _getItemData(index).until.dateTime;
  }

  @override
  String getSubject(int index) {
    return _getItemData(index).title;
  }

  @override
  String getNotes(int index) {
    return _getItemData(index).description;
  }

  @override
  Color getColor(int index) {
    return colors[index % colors.length];
  }

  Item _getItemData(int index) {
    return appointments![index] as Item;
  }
}