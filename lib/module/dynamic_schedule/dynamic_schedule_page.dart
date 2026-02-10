// ignore_for_file: deprecated_member_use

import "dart:io";

import "package:base/base.dart";
import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";
import "package:dynamic_of_things/model/dynamic_schedule_data.dart";
import "package:dynamic_of_things/model/dynamic_schedule_template.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_page.dart";
import "package:dynamic_of_things/module/dynamic_schedule/dynamic_schedule_bloc.dart";
import "package:dynamic_of_things/module/dynamic_schedule/dynamic_schedule_event.dart";
import "package:dynamic_of_things/module/dynamic_schedule/dynamic_schedule_state.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
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

class DynamicSchedulePageState extends State<DynamicSchedulePage>
    with WidgetsBindingObserver {
  Template? template;
  bool _prefsReady = false;

  List<Item> items = <Item>[];
  ItemDataSource dataSource = ItemDataSource(<Item>[]);

  bool loading = true;

  final DateTime today = DateTime.now();

  String? formId;
  List<DateTime> visibleDates = <DateTime>[];

  DateTime selectedDate = DateTime.now();
  final CalendarController calendarController = CalendarController();

  String? lastFetchKey;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _initPrefs();

    selectedDate = DateTime(today.year, today.month, today.day);
    calendarController.view = CalendarView.month;

    context.read<DynamicScheduleBloc>().add(
          DynamicScheduleTemplate(
            id: widget.dynamicFormMenuItem.id,
            customerId: widget.customerId,
          ),
        );
  }

  Future<void> _initPrefs() async {
    try {
      await Preferences.getInstance().init();
    } catch (_) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _prefsReady = true;
    });
  }

  bool get isGlass {
    if (!_prefsReady) {
      return false;
    }

    final int t = Preferences.getInstance()
            .getInt(SharedPreferenceKey.DASHBOARD_UI_TYPE) ??
        1;
    return t == 2;
  }

  Widget _glassBackground() {
    final String p = (Preferences.getInstance()
                .getString(SharedPreferenceKey.GLASS_BACKGROUND_PATH) ??
            "")
        .trim();

    if (p.isEmpty) {
      return Image.asset("assets/image/wallpaper_glass.jpg", fit: BoxFit.cover);
    }
    if (p.startsWith("assets/")) {
      return Image.asset(p, fit: BoxFit.cover);
    }

    final File f = File(p);
    if (f.existsSync()) {
      return Image.file(f, fit: BoxFit.cover);
    }

    return Image.asset("assets/image/wallpaper_glass.jpg", fit: BoxFit.cover);
  }

  Widget _glassOverlay() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.fromRGBO(0, 0, 0, 0.55),
            Color.fromRGBO(0, 0, 0, 0.22),
            Color.fromRGBO(0, 0, 0, 0.40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    calendarController.dispose();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;
    final bool glass = isGlass;

    return BlocListener<DynamicScheduleBloc, DynamicScheduleState>(
      listener: (context, state) async {
        if (state is DynamicScheduleTemplateLoading) {
          setState(() {
            loading = true;
            template = null;
            items = <Item>[];
            dataSource = ItemDataSource(<Item>[]);
          });
        } else if (state is DynamicScheduleTemplateSuccess) {
          setState(() {
            template = state.template;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
          });
        } else if (state is DynamicScheduleTemplateFinished) {
          setState(() {
            loading = false;
          });
        } else if (state is DynamicScheduleDataLoading) {
          context.loaderOverlay.show();
        } else if (state is DynamicScheduleDataSuccess) {
          final List<Item> deduped = duplicateByid(state.items);

          setState(() {
            items = deduped;
            dataSource = ItemDataSource(deduped);
          });
        } else if (state is DynamicScheduleDataFinished) {
          context.loaderOverlay.hide();
        }
      },
      child: Scaffold(
        backgroundColor:
            glass ? Colors.transparent : AppColors.surfaceContainerLowest(),
        body: Stack(
          children: [
            if (glass) ...[
              Positioned.fill(child: _glassBackground()),
              Positioned.fill(child: _glassOverlay()),
            ],
            Column(
              children: [
                SizedBox(height: safe.top),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    Dimensions.size15,
                    Dimensions.size10,
                    Dimensions.size15,
                    Dimensions.size10,
                  ),
                  child: appBar(),
                ),
                if (template != null && template!.forms.length > 1)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      Dimensions.size15,
                      0,
                      Dimensions.size15,
                      Dimensions.size10,
                    ),
                    child: chipRow(),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      Dimensions.size15,
                      0,
                      Dimensions.size15,
                      Dimensions.size15,
                    ),
                    child: separatedCard(),
                  ),
                ),
                SizedBox(height: safe.bottom),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void refresh() {
    if (template == null) {
      return;
    }

    final DateTime base = calendarController.displayDate ?? selectedDate;

    if (visibleDates.isNotEmpty) {
      refreshRange(visibleDates.first, visibleDates.last);
      return;
    }

    final DateTime first = DateTime(base.year, base.month, 1);
    final DateTime last = DateTime(base.year, base.month + 1, 0);
    refreshRange(first, last);
  }

  void refreshRange(DateTime begin, DateTime until) {
    if (template == null) {
      return;
    }

    final DateTime b = DateTime(begin.year, begin.month, begin.day);
    final DateTime u = DateTime(until.year, until.month, until.day);

    final String key =
        "${b.toIso8601String()}|${u.toIso8601String()}|${formId ?? "ALL"}";
    if (lastFetchKey == key) {
      return;
    }
    lastFetchKey = key;

    context.read<DynamicScheduleBloc>().add(
          DynamicScheduleData(
            id: widget.dynamicFormMenuItem.id,
            begin: Jiffy.parseFromDateTime(b),
            until: Jiffy.parseFromDateTime(u),
            formId: formId,
            customerId: widget.customerId,
          ),
        );
  }

  List<Item> duplicateByid(List<Item> source) {
    final Map<dynamic, Item> map = <dynamic, Item>{};
    for (final Item it in source) {
      map[it.id] = it;
    }
    final List<Item> out = map.values.toList()
      ..sort((a, b) => a.begin.dateTime.compareTo(b.begin.dateTime));
    return out;
  }

  bool hasCreateAccess() {
    return template != null &&
        template!.actions.any((element) => element.resourceId == "BTN_CREATE");
  }

  bool hasViewAccess() {
    return template != null &&
        template!.actions.any((element) => element.resourceId == "BTN_VIEW");
  }

  bool hasEditAccess() {
    return template != null &&
        template!.actions.any((element) => element.resourceId == "BTN_EDIT");
  }

  Widget separatedCard() {
    final bool glass = isGlass;

    if (loading) {
      return centerCard(child: BaseWidgets.shimmer());
    }

    if (template == null) {
      return centerCard(
        child: Text(
          "common_something_wrong".tr(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: glass
                ? Colors.white.withOpacity(0.80)
                : AppColors.onSurface().withValues(alpha: 0.75),
          ),
        ),
      );
    }

    final Widget calendarBody = Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.size15,
            Dimensions.size15,
            Dimensions.size15,
            Dimensions.size10,
          ),
          child: monthSwitcher(),
        ),
        SizedBox(
          height: 360,
          child: SfCalendar(
            key: ValueKey<String>(
              "${formId ?? "ALL"}-${items.length}-${(calendarController.displayDate ?? selectedDate).month}-${(calendarController.displayDate ?? selectedDate).year}",
            ),
            controller: calendarController,
            view: CalendarView.month,
            initialDisplayDate: DateTime(today.year, today.month, today.day),
            dataSource: dataSource,
            backgroundColor: glass ? Colors.transparent : AppColors.surface(),
            headerHeight: 0,
            viewHeaderHeight: Dimensions.size45,
            monthViewSettings: const MonthViewSettings(
              appointmentDisplayMode: MonthAppointmentDisplayMode.none,
              showAgenda: false,
              appointmentDisplayCount: 3,
            ),
            viewHeaderStyle: ViewHeaderStyle(
              backgroundColor: glass ? Colors.transparent : AppColors.surface(),
              dayTextStyle: TextStyle(
                fontWeight: FontWeight.w800,
                color: glass
                    ? Colors.white.withOpacity(0.70)
                    : AppColors.onSurface().withValues(alpha: 0.65),
              ),
              dateTextStyle: TextStyle(
                fontWeight: FontWeight.w900,
                color: glass
                    ? Colors.white.withOpacity(0.92)
                    : AppColors.onSurface(),
              ),
            ),
            monthCellBuilder: (context, details) {
              final DateTime d = details.date;

              final bool isToday = d.year == today.year &&
                  d.month == today.month &&
                  d.day == today.day;

              final bool isSelected = d.year == selectedDate.year &&
                  d.month == selectedDate.month &&
                  d.day == selectedDate.day;

              final Color fg = glass
                  ? Colors.white.withOpacity(0.90)
                  : AppColors.onSurface();
              final Color muted = glass
                  ? Colors.white.withOpacity(0.50)
                  : fg.withValues(alpha: 0.45);

              final DateTime display = calendarController.displayDate ?? d;
              final bool inSameMonth =
                  d.month == display.month && d.year == display.year;

              final Color textColor = inSameMonth ? fg : muted;

              final Color selectedBg = glass
                  ? Colors.white.withOpacity(0.16)
                  : AppColors.primaryContainer().withValues(alpha: 0.45);
              final Color selectedBorder = glass
                  ? Colors.white.withOpacity(0.30)
                  : AppColors.onPrimaryContainer().withValues(alpha: 0.18);
              final Color todayBg = glass
                  ? Colors.white.withOpacity(0.22)
                  : AppColors.primaryContainer();
              final Color todayText = glass
                  ? Colors.white.withOpacity(0.95)
                  : AppColors.onPrimaryContainer();

              return InkWell(
                onTap: () {
                  setState(() {
                    selectedDate = DateTime(d.year, d.month, d.day);
                  });
                },
                child: Padding(
                  padding: EdgeInsets.all(Dimensions.size5),
                  child: Container(
                    decoration: ShapeDecoration(
                      color: isSelected ? selectedBg : Colors.transparent,
                      shape: SmoothRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.size15),
                        smoothness: Dimensions.size1,
                        side: BorderSide(
                          color:
                              isSelected ? selectedBorder : Colors.transparent,
                        ),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: Dimensions.size10),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Dimensions.size10,
                                vertical: Dimensions.size5,
                              ),
                              decoration: ShapeDecoration(
                                color: isToday ? todayBg : Colors.transparent,
                                shape: SmoothRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.size15,
                                  ),
                                  smoothness: Dimensions.size1,
                                ),
                              ),
                              child: Text(
                                "${d.day}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: Dimensions.text12,
                                  color: isToday ? todayText : textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (details.appointments.isNotEmpty)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding:
                                  EdgeInsets.only(bottom: Dimensions.size5),
                              child: dotIndicator(details.appointments.length),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
            onViewChanged: (viewChangedDetails) {
              visibleDates = viewChangedDetails.visibleDates;

              final DateTime display =
                  calendarController.displayDate ?? selectedDate;

              if (selectedDate.month != display.month ||
                  selectedDate.year != display.year) {
                setState(() {
                  selectedDate = DateTime(display.year, display.month, 1);
                });
              }

              refresh();
            },
            onTap: (CalendarTapDetails details) {
              if (details.targetElement == CalendarElement.appointment &&
                  details.appointments != null &&
                  details.appointments!.isNotEmpty) {
                final Item item = details.appointments!.first as Item;
                openItemMenu(item);
              } else if (details.targetElement ==
                  CalendarElement.calendarCell) {
                final DateTime d = details.date ?? selectedDate;
                setState(() {
                  selectedDate = DateTime(d.year, d.month, d.day);
                });
              }
            },
          ),
        ),
      ],
    );

    final Widget calendarCard = glass
        ? GlassContainer(
            blur: Dimensions.size20,
            borderRadius: Dimensions.size25,
            opacity: 0.12,
            borderOpacity: 0.22,
            padding: EdgeInsets.zero,
            child: calendarBody,
          )
        : Container(
            decoration: ShapeDecoration(
              color: AppColors.surface(),
              shadows: [
                BoxShadow(
                  blurRadius: Dimensions.size25,
                  offset: const Offset(0, 12),
                  color: Colors.black.withValues(alpha: 0.10),
                ),
              ],
              shape: SmoothRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.size25),
                smoothness: Dimensions.size1,
                side: BorderSide(
                  color: AppColors.outline().withValues(alpha: 0.30),
                ),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: calendarBody,
          );

    final Widget agendaBody = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.size15,
            Dimensions.size15,
            Dimensions.size15,
            Dimensions.size10,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  agendaTitle(selectedDate),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: glass
                        ? Colors.white.withOpacity(0.92)
                        : AppColors.onSurface(),
                  ),
                ),
              ),
              badge("${itemForDay(selectedDate).length}"),
            ],
          ),
        ),
        Divider(
          height: 0,
          color: glass
              ? Colors.white.withOpacity(0.20)
              : AppColors.outline().withValues(alpha: 0.25),
        ),
        agendaList(),
      ],
    );

    final Widget agendaCard = glass
        ? GlassContainer(
            blur: Dimensions.size20,
            borderRadius: Dimensions.size25,
            opacity: 0.12,
            borderOpacity: 0.22,
            padding: EdgeInsets.zero,
            child: agendaBody,
          )
        : Container(
            decoration: ShapeDecoration(
              color: AppColors.surface(),
              shadows: [
                BoxShadow(
                  blurRadius: Dimensions.size25,
                  offset: Offset(0, Dimensions.size10),
                  color: Colors.black.withValues(alpha: 0.10),
                ),
              ],
              shape: SmoothRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.size25),
                smoothness: 1,
                side: BorderSide(
                  color: AppColors.outline().withValues(alpha: 0.30),
                ),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: agendaBody,
          );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          calendarCard,
          SizedBox(height: Dimensions.size10),
          agendaCard,
        ],
      ),
    );
  }

  Widget monthSwitcher() {
    final DateTime display = calendarController.displayDate ?? selectedDate;
    final DateTime prev = DateTime(display.year, display.month - 1, 1);
    final DateTime next = DateTime(display.year, display.month + 1, 1);

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: monthSide(
              label: monthName(prev),
              onTap: () => jumptToMonth(prev),
              alignLeft: true,
            ),
          ),
        ),
        monthCenter(display),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: monthSide(
              label: monthName(next),
              onTap: () => jumptToMonth(next),
              alignLeft: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget monthCenter(DateTime display) {
    final bool glass = isGlass;

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "${monthName(display)} ${display.year}",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: Dimensions.text14,
            color:
                glass ? Colors.white.withOpacity(0.92) : AppColors.onSurface(),
          ),
        ),
      ],
    );

    if (glass) {
      return GlassContainer(
        blur: Dimensions.size15,
        borderRadius: Dimensions.size100,
        opacity: 0.10,
        borderOpacity: 0.18,
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.size15,
          vertical: Dimensions.size10,
        ),
        child: content,
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size10,
      ),
      decoration: ShapeDecoration(
        color: AppColors.surfaceContainerLowest(),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size100),
          smoothness: Dimensions.size1,
          side: BorderSide(color: AppColors.outline().withValues(alpha: 0.22)),
        ),
      ),
      child: content,
    );
  }

  Widget monthSide({
    required String label,
    required VoidCallback onTap,
    required bool alignLeft,
  }) {
    final bool glass = isGlass;
    final Color iconColor = glass
        ? Colors.white.withOpacity(0.75)
        : AppColors.onSurface().withValues(alpha: 0.55);
    final Color textColor = glass
        ? Colors.white.withOpacity(0.82)
        : AppColors.onSurface().withValues(alpha: 0.65);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.size100),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.size5,
            vertical: Dimensions.size5,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: alignLeft
                ? [
                    Icon(
                      Icons.chevron_left_rounded,
                      size: Dimensions.size20,
                      color: iconColor,
                    ),
                    SizedBox(width: Dimensions.size2),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ]
                : [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    SizedBox(width: Dimensions.size2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: Dimensions.size20,
                      color: iconColor,
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  void jumptToMonth(DateTime month) {
    final DateTime d = DateTime(month.year, month.month, 1);

    setState(() {
      selectedDate = d;
    });

    calendarController.displayDate = d;

    refresh();
  }

  Widget agendaList() {
    final bool glass = isGlass;
    final List<Item> dayItems = itemForDay(selectedDate);

    if (dayItems.isEmpty) {
      final Widget emptyContent = Row(
        children: [
          Icon(
            Icons.event_busy,
            color: glass
                ? Colors.white.withOpacity(0.70)
                : AppColors.onSurface().withValues(alpha: 0.55),
          ),
          SizedBox(width: Dimensions.size10),
          Expanded(
            child: Text(
              trSafe("no_data", "no_data".tr()),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: glass
                    ? Colors.white.withOpacity(0.85)
                    : AppColors.onSurface().withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      );

      return Padding(
        padding: EdgeInsets.fromLTRB(
          Dimensions.size15,
          Dimensions.size15,
          Dimensions.size15,
          Dimensions.size15,
        ),
        child: glass
            ? GlassContainer(
                blur: Dimensions.size15,
                borderRadius: Dimensions.size20,
                opacity: 0.10,
                borderOpacity: 0.18,
                padding: EdgeInsets.all(Dimensions.size15),
                child: SizedBox(width: double.infinity, child: emptyContent),
              )
            : Container(
                width: double.infinity,
                padding: EdgeInsets.all(Dimensions.size15),
                decoration: ShapeDecoration(
                  color: AppColors.surfaceContainerLowest(),
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size20),
                    smoothness: Dimensions.size1,
                    side: BorderSide(
                      color: AppColors.outline().withValues(alpha: 0.22),
                    ),
                  ),
                ),
                child: emptyContent,
              ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        Dimensions.size15,
        Dimensions.size10,
        Dimensions.size15,
        Dimensions.size15,
      ),
      itemCount: dayItems.length,
      separatorBuilder: (_, __) => SizedBox(height: Dimensions.size10),
      itemBuilder: (context, i) => agenda(dayItems[i]),
    );
  }

  Widget agenda(Item it) {
    final bool glass = isGlass;
    final DateTime begin = it.begin.dateTime;
    final DateTime until = it.until.dateTime;

    final bool isAllDay = allDay(begin, until);
    final String title = it.title;
    final String desc = it.description.trim();

    final String dow = weekdayById(begin).toUpperCase();
    final String day = "${begin.day}";
    final String time = isAllDay ? "Seharian" : timeRange(begin, until);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openItemMenu(it),
        customBorder: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: 1,
        ),
        child: glass
            ? GlassContainer(
                blur: Dimensions.size15,
                borderRadius: Dimensions.size20,
                opacity: 0.10,
                borderOpacity: 0.18,
                padding: EdgeInsets.all(Dimensions.size15),
                child: Row(
                  children: [
                    dateBadgeRed(dow: dow, day: day),
                    SizedBox(width: Dimensions.size10),
                    Container(
                      width: Dimensions.size1,
                      height: Dimensions.size45,
                      color: Colors.white.withOpacity(0.18),
                    ),
                    SizedBox(width: Dimensions.size10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: Dimensions.text14,
                              color: Colors.white.withOpacity(0.92),
                            ),
                          ),
                          SizedBox(height: Dimensions.size2),
                          Text(
                            desc.isNotEmpty ? desc : time,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: Dimensions.text12,
                              color: Colors.white.withOpacity(0.70),
                            ),
                          ),
                          if (!isAllDay) ...[
                            SizedBox(height: Dimensions.size2),
                            Text(
                              time,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: Dimensions.text11,
                                color: Colors.white.withOpacity(0.60),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: Dimensions.size10),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ],
                ),
              )
            : Ink(
                padding: EdgeInsets.all(Dimensions.size15),
                decoration: ShapeDecoration(
                  color: AppColors.surfaceContainerLowest(),
                  shadows: [
                    BoxShadow(
                      blurRadius: Dimensions.size20,
                      offset: Offset(0, Dimensions.size10),
                      color: Colors.black.withValues(alpha: 0.07),
                    ),
                  ],
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size20),
                    smoothness: Dimensions.size1,
                    side: BorderSide(
                      color: AppColors.outline().withValues(alpha: 0.22),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    dateBadgeRed(dow: dow, day: day),
                    SizedBox(width: Dimensions.size10),
                    Container(
                      width: Dimensions.size1,
                      height: Dimensions.size45,
                      color: AppColors.outline().withValues(alpha: 0.25),
                    ),
                    SizedBox(width: Dimensions.size10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: Dimensions.text14,
                              color: AppColors.onSurface(),
                            ),
                          ),
                          SizedBox(height: Dimensions.size2),
                          Text(
                            desc.isNotEmpty ? desc : time,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: Dimensions.text12,
                              color:
                                  AppColors.onSurface().withValues(alpha: 0.65),
                            ),
                          ),
                          if (!isAllDay) ...[
                            SizedBox(height: Dimensions.size2),
                            Text(
                              time,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: Dimensions.text11,
                                color: AppColors.onSurface()
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: Dimensions.size10),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.onSurface().withValues(alpha: 0.55),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void openItemMenu(Item item) {
    final bool glass = isGlass;

    final bool canView = hasViewAccess();
    final bool canEdit = hasEditAccess();

    final DateTime begin = item.begin.dateTime;
    final DateTime until = item.until.dateTime;

    final bool isAllDay = allDay(begin, until);
    final String dow = weekdayById(begin).toUpperCase();
    final String day = "${begin.day}";

    final String whenLine =
        "${weekdayLongId(begin)}, ${begin.day} ${monthById(begin)} ${begin.year}"
        "${isAllDay ? " • Seharian" : " • ${timeRange(begin, until)}"}";

    final List<Widget> actions = <Widget>[];

    if (canView) {
      actions.add(
        bottomSheetAction(
          icon: Icons.visibility_rounded,
          title: trSafe("view_data", "view".tr()),
          subtitle: item.description.trim().isEmpty ? null : item.description,
          enabled: true,
          onTap: () async {
            Navigator.of(context).pop();
            await openForm(item: item, readOnly: true);
          },
        ),
      );
    }

    if (canEdit) {
      actions.add(
        bottomSheetAction(
          icon: Icons.edit_rounded,
          title: trSafe("edit", "edit".tr()),
          enabled: true,
          onTap: () async {
            Navigator.of(context).pop();
            await openForm(item: item, readOnly: false);
          },
        ),
      );
    }

    if (actions.isEmpty) {
      actions.add(
        Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.size15,
            Dimensions.size15,
            Dimensions.size15,
            Dimensions.size15,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(Dimensions.size15),
            decoration: ShapeDecoration(
              color: AppColors.surfaceContainerLowest(),
              shape: SmoothRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.size20),
                smoothness: Dimensions.size1,
                side: BorderSide(
                  color: AppColors.outline().withValues(alpha: 0.22),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.onSurface().withValues(alpha: 0.55),
                ),
                SizedBox(width: Dimensions.size10),
                Expanded(
                  child: Text(
                    trSafe("no_access", "no_action_available".tr()),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface().withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      useSafeArea: false,
      builder: (_) {
        final Widget sheetBody = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: Dimensions.size10),
            Container(
              width: Dimensions.size45,
              height: Dimensions.size5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.size100),
                color: glass
                    ? Colors.white.withOpacity(0.25)
                    : AppColors.outline().withValues(alpha: 0.35),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                Dimensions.size15,
                Dimensions.size15,
                Dimensions.size15,
                Dimensions.size10,
              ),
              child: Row(
                children: [
                  dateBadgeRed(dow: dow, day: day),
                  SizedBox(width: Dimensions.size10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: Dimensions.text16,
                            color: glass
                                ? Colors.white.withOpacity(0.95)
                                : AppColors.onSurface(),
                          ),
                        ),
                        SizedBox(height: Dimensions.size2),
                        Text(
                          whenLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: Dimensions.text12,
                            color: glass
                                ? Colors.white.withOpacity(0.72)
                                : AppColors.onSurface().withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  iconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(
              height: 0,
              color: glass
                  ? Colors.white.withOpacity(0.18)
                  : AppColors.outline().withValues(alpha: 0.20),
            ),
            ...actions,
            SizedBox(height: Dimensions.size10),
          ],
        );

        final Widget sheetCard = glass
            ? GlassContainer(
                blur: Dimensions.size25,
                borderRadius: Dimensions.size25,
                opacity: 0.14,
                borderOpacity: 0.24,
                padding: EdgeInsets.zero,
                child: sheetBody,
              )
            : Container(
                decoration: ShapeDecoration(
                  color: AppColors.surface(),
                  shadows: [
                    BoxShadow(
                      blurRadius: Dimensions.size30,
                      offset: Offset(0, Dimensions.size20),
                      color: Colors.black.withValues(alpha: 0.18),
                    ),
                  ],
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size25),
                    smoothness: Dimensions.size1,
                    side: BorderSide(
                      color: AppColors.outline().withValues(alpha: 0.25),
                    ),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: sheetBody,
              );

        return SafeArea(
          top: false,
          child: Wrap(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Dimensions.size15,
                  0,
                  Dimensions.size15,
                  Dimensions.size15,
                ),
                child: sheetCard,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget dateBadgeRed({required String dow, required String day}) {
    final Color bg = Theme.of(context).colorScheme.error;
    final Color fg = Theme.of(context).colorScheme.onError;

    return Container(
      width: Dimensions.size55,
      padding: EdgeInsets.symmetric(
        vertical: Dimensions.size10,
        horizontal: Dimensions.size10,
      ),
      decoration: ShapeDecoration(
        color: bg,
        shadows: [
          BoxShadow(
            blurRadius: Dimensions.size15,
            offset: Offset(0, Dimensions.size10),
            color: bg.withValues(alpha: 0.30),
          ),
        ],
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: Dimensions.size1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dow,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: Dimensions.text11,
              letterSpacing: 0.6,
              color: fg,
            ),
          ),
          SizedBox(height: Dimensions.size2),
          Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: Dimensions.text18,
              height: 1.0,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomSheetAction({
    required IconData icon,
    required String title,
    required bool enabled,
    required VoidCallback? onTap,
    String? subtitle,
  }) {
    final bool glass = isGlass;

    final Color fg = glass
        ? Colors.white.withOpacity(enabled ? 0.92 : 0.45)
        : enabled
            ? AppColors.onSurface()
            : AppColors.onSurface().withValues(alpha: 0.35);

    final Color iconBg = glass
        ? Colors.white.withOpacity(0.10)
        : AppColors.surfaceContainerLowest();

    final Color iconBorder = glass
        ? Colors.white.withOpacity(0.18)
        : AppColors.outline().withValues(alpha: 0.18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.size15,
            Dimensions.size10,
            Dimensions.size15,
            Dimensions.size10,
          ),
          child: Row(
            children: [
              Container(
                width: Dimensions.size40,
                height: Dimensions.size40,
                decoration: ShapeDecoration(
                  color: iconBg,
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size15),
                    smoothness: Dimensions.size1,
                    side: BorderSide(color: iconBorder),
                  ),
                ),
                child: Icon(icon, color: fg, size: Dimensions.size20),
              ),
              SizedBox(width: Dimensions.size10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: fg,
                      ),
                    ),
                    if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                      SizedBox(height: Dimensions.size2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: Dimensions.text12,
                          color: glass
                              ? Colors.white.withOpacity(enabled ? 0.70 : 0.55)
                              : fg.withValues(alpha: enabled ? 0.70 : 0.60),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: glass
                    ? Colors.white.withOpacity(0.70)
                    : fg.withValues(alpha: 0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> openForm({required Item item, required bool readOnly}) async {
    bool result = false;

    if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
      result = await Navigators.push(
            DynamicFormPage(
              dynamicFormMenuItem: widget.dynamicFormMenuItem,
              readOnly: readOnly,
              dataId: item.id,
              customerId: widget.customerId,
            ),
          ) ??
          false;
    } else {
      result = await context.push(
            "/dynamic-forms",
            extra: {
              "dynamicFormMenuItem": widget.dynamicFormMenuItem,
              "readOnly": readOnly,
              "dataId": item.id,
              "customerId": widget.customerId,
            },
          ) ??
          false;
    }

    if (result) {
      refresh();
    }
  }

  Widget appBar() {
    final String subTitle = (formId == null)
        ? trSafe("all", "Semua")
        : (template?.forms[formId] ?? "");

    final bool glass = isGlass;
    final Color titleColor =
        glass ? Colors.white.withOpacity(0.95) : AppColors.onSurface();
    final Color subColor = glass
        ? Colors.white.withOpacity(0.72)
        : AppColors.onSurface().withValues(alpha: 0.65);

    final Widget content = Row(
      children: [
        iconPill(
          icon: Icons.turn_left_rounded,
          onTap: () {
            if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
              Navigators.pop();
            } else {
              context.pop();
            }
          },
        ),
        SizedBox(width: Dimensions.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.dynamicFormMenuItem.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: Dimensions.text16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                  color: titleColor,
                ),
              ),
              SizedBox(height: Dimensions.size2),
              Text(
                subTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: Dimensions.text12,
                  fontWeight: FontWeight.w700,
                  color: subColor,
                ),
              ),
            ],
          ),
        ),
        if (hasCreateAccess()) ...[
          SizedBox(width: Dimensions.size10),
          pillButton(
            icon: Icons.add,
            label: trSafe("add", "add".tr()),
            onTap: () async {
              bool result = false;

              if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                result = await Navigators.push(
                      DynamicFormPage(
                        dynamicFormMenuItem: widget.dynamicFormMenuItem,
                        customerId: widget.customerId,
                      ),
                    ) ??
                    false;
              } else {
                result = await context.push(
                      "/dynamic-forms",
                      extra: {
                        "dynamicFormMenuItem": widget.dynamicFormMenuItem,
                        "customerId": widget.customerId,
                      },
                    ) ??
                    false;
              }

              if (result) {
                refresh();
              }
            },
          ),
        ],
      ],
    );

    if (glass) {
      return GlassContainer(
        blur: Dimensions.size20,
        borderRadius: Dimensions.size25,
        opacity: 0.12,
        borderOpacity: 0.22,
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.size15,
          vertical: Dimensions.size15,
        ),
        child: content,
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size15,
      ),
      decoration: ShapeDecoration(
        color: AppColors.surface(),
        shadows: [
          BoxShadow(
            blurRadius: Dimensions.size20,
            offset: Offset(0, Dimensions.size10),
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ],
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size25),
          smoothness: Dimensions.size1,
          side: BorderSide(color: AppColors.outline().withValues(alpha: 0.30)),
        ),
      ),
      child: content,
    );
  }

  Widget chipRow() {
    final List<Widget> chips = <Widget>[
      pillChip(
        label: trSafe("all", "All"),
        selected: formId == null,
        onTap: () {
          setState(() => formId = null);
          refresh();
        },
      ),
    ];

    for (final MapEntry<String, String> e in template!.forms.entries) {
      chips.add(
        pillChip(
          label: e.value,
          selected: formId == e.key,
          onTap: () {
            setState(() => formId = e.key);
            refresh();
          },
        ),
      );
    }

    return SizedBox(
      height: Dimensions.size45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: chips.length,
        separatorBuilder: (_, __) => SizedBox(width: Dimensions.size10),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  Widget pillChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final bool glass = isGlass;
    final Color fg = glass
        ? Colors.white.withOpacity(selected ? 0.95 : 0.85)
        : selected
            ? AppColors.onPrimaryContainer()
            : AppColors.onSurface();
    final Color bg = glass
        ? Colors.white.withOpacity(selected ? 0.18 : 0.10)
        : selected
            ? AppColors.primaryContainer()
            : AppColors.surface();
    final Color bd = glass
        ? Colors.white.withOpacity(selected ? 0.30 : 0.18)
        : selected
            ? AppColors.onPrimaryContainer().withValues(alpha: 0.20)
            : AppColors.outline().withValues(alpha: 0.30);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size50),
          smoothness: Dimensions.size1,
        ),
        child: glass
            ? GlassContainer(
                blur: Dimensions.size15,
                borderRadius: Dimensions.size50,
                opacity: selected ? 0.18 : 0.10,
                borderOpacity: selected ? 0.30 : 0.18,
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.size15,
                  vertical: Dimensions.size10,
                ),
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: fg,
                    ),
                  ),
                ),
              )
            : Ink(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.size15,
                  vertical: Dimensions.size10,
                ),
                decoration: ShapeDecoration(
                  color: bg,
                  shadows: selected
                      ? [
                          BoxShadow(
                            blurRadius: Dimensions.size20,
                            offset: Offset(0, Dimensions.size10),
                            color: Colors.black.withValues(alpha: 0.10),
                          ),
                        ]
                      : [],
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size50),
                    smoothness: Dimensions.size1,
                    side: BorderSide(color: bd),
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: fg,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget centerCard({required Widget child}) {
    final bool glass = isGlass;

    if (glass) {
      return GlassContainer(
        blur: Dimensions.size20,
        borderRadius: Dimensions.size25,
        opacity: 0.12,
        borderOpacity: 0.22,
        padding: EdgeInsets.all(Dimensions.size20),
        child: child,
      );
    }

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: EdgeInsets.all(Dimensions.size20),
      decoration: ShapeDecoration(
        color: AppColors.surface(),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size25),
          smoothness: Dimensions.size1,
          side: BorderSide(color: AppColors.outline().withValues(alpha: 0.30)),
        ),
      ),
      child: child,
    );
  }

  Widget iconPill({required IconData icon, required VoidCallback onTap}) {
    final bool glass = isGlass;
    final Color iconColor =
        glass ? Colors.white.withOpacity(0.92) : AppColors.onSurface();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: Dimensions.size1,
        ),
        child: glass
            ? GlassContainer(
                blur: Dimensions.size15,
                borderRadius: Dimensions.size15,
                opacity: 0.10,
                borderOpacity: 0.18,
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: Dimensions.size40,
                  height: Dimensions.size40,
                  child: Icon(icon, color: iconColor, size: Dimensions.size25),
                ),
              )
            : Ink(
                width: Dimensions.size40,
                height: Dimensions.size40,
                decoration: ShapeDecoration(
                  color: AppColors.surfaceContainerLowest(),
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size15),
                    smoothness: Dimensions.size1,
                    side: BorderSide(
                      color: AppColors.outline().withValues(alpha: 0.22),
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppColors.onSurface(),
                  size: Dimensions.size25,
                ),
              ),
      ),
    );
  }

  Widget pillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final bool glass = isGlass;
    final Color fg =
        glass ? Colors.white.withOpacity(0.95) : AppColors.onPrimaryContainer();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size50),
          smoothness: Dimensions.size1,
        ),
        child: glass
            ? GlassContainer(
                blur: Dimensions.size15,
                borderRadius: Dimensions.size50,
                opacity: 0.18,
                borderOpacity: 0.30,
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.size15,
                  vertical: Dimensions.size10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: Dimensions.size20, color: fg),
                    SizedBox(width: Dimensions.size5),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              )
            : Ink(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.size15,
                  vertical: Dimensions.size10,
                ),
                decoration: ShapeDecoration(
                  color: AppColors.primaryContainer(),
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size50),
                    smoothness: Dimensions.size1,
                    side: BorderSide(
                      color: AppColors.onPrimaryContainer()
                          .withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: Dimensions.size20,
                      color: AppColors.onPrimaryContainer(),
                    ),
                    SizedBox(width: Dimensions.size5),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.onPrimaryContainer(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget iconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool glass = isGlass;
    final Color iconColor =
        glass ? Colors.white.withOpacity(0.90) : AppColors.onSurface();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: 1,
        ),
        child: glass
            ? GlassContainer(
                blur: Dimensions.size15,
                borderRadius: Dimensions.size15,
                opacity: 0.10,
                borderOpacity: 0.18,
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: Dimensions.size35,
                  height: Dimensions.size35,
                  child: Icon(icon, color: iconColor, size: Dimensions.size20),
                ),
              )
            : Ink(
                width: Dimensions.size35,
                height: Dimensions.size35,
                decoration: ShapeDecoration(
                  color: AppColors.surfaceContainerLowest(),
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.size15),
                    smoothness: Dimensions.size1,
                    side: BorderSide(
                      color: AppColors.outline().withValues(alpha: 0.22),
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppColors.onSurface(),
                  size: Dimensions.size20,
                ),
              ),
      ),
    );
  }

  Widget dotIndicator(int count) {
    final int n = count.clamp(1, 4);
    final Color dot =
        Theme.of(context).colorScheme.error.withValues(alpha: 0.90);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(n, (i) {
        return Container(
          width: Dimensions.size5,
          height: Dimensions.size5,
          margin: EdgeInsets.symmetric(horizontal: Dimensions.size2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dot,
          ),
        );
      }),
    );
  }

  Widget badge(String text) {
    final bool glass = isGlass;

    if (glass) {
      return GlassContainer(
        blur: Dimensions.size15,
        borderRadius: Dimensions.size50,
        opacity: 0.12,
        borderOpacity: 0.22,
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.size10,
          vertical: Dimensions.size5,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: Dimensions.text12,
            color: Colors.white.withOpacity(0.92),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size10,
        vertical: Dimensions.size5,
      ),
      decoration: ShapeDecoration(
        color: AppColors.surfaceContainerLowest(),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size50),
          smoothness: Dimensions.size1,
          side: BorderSide(color: AppColors.outline().withValues(alpha: 0.22)),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: Dimensions.text12,
          color: AppColors.onSurface().withValues(alpha: 0.85),
        ),
      ),
    );
  }

  String trSafe(String key, String fallback) {
    final String v = key.tr();
    if (v == key) {
      return fallback;
    }
    return v;
  }

  String agendaTitle(DateTime d) {
    final String tabName = (formId == null)
        ? trSafe("all", "Semua")
        : (template?.forms[formId] ?? "");

    final String dayLong = weekdayLongId(d);
    final String monthAbbrev = monthById(d);
    return "$tabName • $dayLong, ${d.day} $monthAbbrev";
  }

  bool allDay(DateTime begin, DateTime until) {
    if (begin.isAtSameMomentAs(until)) {
      return true;
    }
    final Duration diff = until.difference(begin);
    if (begin.hour == 0 &&
        begin.minute == 0 &&
        until.hour == 0 &&
        until.minute == 0 &&
        diff.inHours >= 23) {
      return true;
    }
    return false;
  }

  String timeRange(DateTime begin, DateTime until) {
    if (allDay(begin, until)) {
      return "Seharian";
    }
    final String a = Jiffy.parseFromDateTime(begin).format(pattern: "HH:mm");
    final String b = Jiffy.parseFromDateTime(until).format(pattern: "HH:mm");
    return "$a-$b";
  }

  List<Item> itemForDay(DateTime day) {
    final DateTime start = DateTime(day.year, day.month, day.day);
    final DateTime end = start.add(const Duration(days: 1));

    final List<Item> out = <Item>[];

    for (final Item it in items) {
      final DateTime b = it.begin.dateTime;
      final DateTime u = it.until.dateTime;

      final bool overlap = b.isBefore(end) && !u.isBefore(start);
      if (overlap) {
        out.add(it);
      }
    }

    out.sort((a, b) => a.begin.dateTime.compareTo(b.begin.dateTime));
    return out;
  }

  String weekdayLongId(DateTime d) {
    switch (d.weekday) {
      case DateTime.monday:
        return "Senin";
      case DateTime.tuesday:
        return "Selasa";
      case DateTime.wednesday:
        return "Rabu";
      case DateTime.thursday:
        return "Kamis";
      case DateTime.friday:
        return "Jumat";
      case DateTime.saturday:
        return "Sabtu";
      case DateTime.sunday:
        return "Minggu";
    }
    return "Hari";
  }

  String weekdayById(DateTime d) {
    switch (d.weekday) {
      case DateTime.monday:
        return "Sen";
      case DateTime.tuesday:
        return "Sel";
      case DateTime.wednesday:
        return "Rab";
      case DateTime.thursday:
        return "Kam";
      case DateTime.friday:
        return "Jum";
      case DateTime.saturday:
        return "Sab";
      case DateTime.sunday:
        return "Min";
    }
    return "Hari";
  }

  String monthById(DateTime d) {
    switch (d.month) {
      case 1:
        return "Jan";
      case 2:
        return "Feb";
      case 3:
        return "Mar";
      case 4:
        return "Apr";
      case 5:
        return "Mei";
      case 6:
        return "Jun";
      case 7:
        return "Jul";
      case 8:
        return "Agu";
      case 9:
        return "Sep";
      case 10:
        return "Okt";
      case 11:
        return "Nov";
      case 12:
        return "Des";
    }
    return "Bln";
  }

  String monthName(DateTime d) {
    switch (d.month) {
      case 1:
        return "Januari";
      case 2:
        return "Februari";
      case 3:
        return "Maret";
      case 4:
        return "April";
      case 5:
        return "Mei";
      case 6:
        return "Juni";
      case 7:
        return "Juli";
      case 8:
        return "Agustus";
      case 9:
        return "September";
      case 10:
        return "Oktober";
      case 11:
        return "November";
      case 12:
        return "Desember";
    }
    return "Bulan";
  }
}

class ItemDataSource extends CalendarDataSource {
  final List<Color> colors = <Color>[
    ...Colors.primaries,
    ...Colors.accents,
  ];

  ItemDataSource(List<Item> source) {
    appointments = source;
  }

  @override
  Object? getId(int index) => getItemData(index).id;

  @override
  DateTime getStartTime(int index) => getItemData(index).begin.dateTime;

  @override
  DateTime getEndTime(int index) => getItemData(index).until.dateTime;

  @override
  String getSubject(int index) => getItemData(index).title;

  @override
  String getNotes(int index) => getItemData(index).description;

  @override
  Color getColor(int index) => colors[index % colors.length];

  Item getItemData(int index) => appointments![index] as Item;
}
