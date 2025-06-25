// ignore_for_file: always_specify_types, cascade_invocations, always_put_required_named_parameters_first, empty_catches, use_build_context_synchronously

import "package:base/base.dart";
import "package:dynamic_of_things/helper/bottom_sheets.dart";
import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";
import "package:dynamic_of_things/model/dynamic_form_schedule_response.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_page.dart";
import "package:dynamic_of_things/module/dynamic_form/schedule/dynamic_form_schedule_bloc.dart";
import "package:dynamic_of_things/module/dynamic_form/schedule/dynamic_form_schedule_event.dart";
import "package:dynamic_of_things/module/dynamic_form/schedule/dynamic_form_schedule_state.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:smooth_corner/smooth_corner.dart";
import "package:syncfusion_flutter_calendar/calendar.dart";

class DynamicFormSchedulePage extends StatefulWidget {
  final DynamicFormMenuItem dynamicFormMenuItem;
  final String? customerId;

  const DynamicFormSchedulePage({
    required this.dynamicFormMenuItem,
    required this.customerId,
    super.key,
  });

  @override
  DynamicFormSchedulePageState createState() => DynamicFormSchedulePageState();
}

class DynamicFormSchedulePageState extends State<DynamicFormSchedulePage> with WidgetsBindingObserver {
  ScheduleResponse? scheduleResponse;

  bool loading = true;

  DateTime today = DateTime.now();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DynamicFormScheduleBloc, DynamicFormScheduleState>(
      listener: (context, state) async {
        if (state is DynamicFormScheduleLoadLoading) {
          setState(() {
            loading = true;
            scheduleResponse = null;
          });
        } else if (state is DynamicFormScheduleLoadSuccess) {
          setState(() {
            scheduleResponse = state.scheduleResponse;
          });
        } else if (state is DynamicFormScheduleLoadFinished) {
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
            if (scheduleResponse != null) {
              if (scheduleResponse!.items.isNotEmpty) {
                return BaseBodyStatus.loaded;
              } else {
                return BaseBodyStatus.empty;
              }
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
    context.read<DynamicFormScheduleBloc>().add(
      DynamicFormScheduleLoad(
        id: widget.dynamicFormMenuItem.id,
        customerId: widget.customerId,
        name: widget.dynamicFormMenuItem.name,
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

    return BaseAppBar(
      context: context,
      name: widget.dynamicFormMenuItem.name,
      trailings: [addButton()],
    );
  }

  Widget body() {
    return SfCalendar(
      view: CalendarView.month,
      initialDisplayDate: DateTime(today.year, today.month, today.day),
      dataSource: ItemDataSource(scheduleResponse!.items),
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
        showAgenda: true,
        appointmentDisplayCount: 3,
      ),
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
    return scheduleResponse != null && scheduleResponse!.actions.any((element) => element.resourceId == "BTN_CREATE");
  }

  bool hasViewAccess() {
    return scheduleResponse != null && scheduleResponse!.actions.any((element) => element.resourceId == "BTN_VIEW");
  }

  bool hasEditAccess() {
    return scheduleResponse != null && scheduleResponse!.actions.any((element) => element.resourceId == "BTN_EDIT");
  }
}

class ItemDataSource extends CalendarDataSource {
  final List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blueAccent,
    Colors.black,
    Colors.cyan,
    Colors.blueGrey,
    Colors.purpleAccent,
    Colors.indigo,
    Colors.deepOrange,
    Colors.brown,
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
    return colors[index];
  }

  Item _getItemData(int index) {
    return appointments![index] as Item;
  }
}