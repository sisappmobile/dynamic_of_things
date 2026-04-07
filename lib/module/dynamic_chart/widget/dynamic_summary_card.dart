import "package:base/base.dart";
import "package:dynamic_of_things/model/dynamic_chart_list_response.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_bloc.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_event.dart";
import "package:dynamic_of_things/module/dynamic_chart/dynamic_chart_state.dart";
import "package:dynamic_of_things/module/dynamic_chart/helper/dynamic_chart_data_helper.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:dynamic_of_things/widget/loading_card.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:jiffy/jiffy.dart";

class DynamicSummaryCard extends StatefulWidget {
  final Summary summary;
  final Jiffy begin;
  final Jiffy until;
  final bool isGlass;
  final dynamic initialData;

  const DynamicSummaryCard({
    required this.summary,
    required this.begin,
    required this.until,
    required this.isGlass,
    this.initialData,
    super.key,
  });

  @override
  State<DynamicSummaryCard> createState() => DynamicSummaryCardState();
}

class DynamicSummaryCardState extends State<DynamicSummaryCard> {
  bool loading = true;
  DynamicSummarySnapshot? snapshot;

  @override
  void initState() {
    super.initState();
    snapshot = parseSummarySnapshot(widget.initialData);
    loading = widget.initialData == null;
    if (widget.initialData == null) {
      fetch();
    }
  }

  @override
  void didUpdateWidget(covariant DynamicSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialData != widget.initialData &&
        widget.initialData != null) {
      snapshot = parseSummarySnapshot(widget.initialData);
      loading = false;
    }

    final bool changed =
        !sameCalendarDay(oldWidget.begin.dateTime, widget.begin.dateTime) ||
            !sameCalendarDay(oldWidget.until.dateTime, widget.until.dateTime);

    if (changed) {
      fetch();
    }
  }

  void fetch() {
    context.read<DynamicChartBloc>().add(
          DynamicChartData(
            id: widget.summary.id,
            begin: widget.begin,
            until: widget.until,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DynamicChartBloc, DynamicChartState>(
      listener: (context, state) async {
        if (state is DynamicChartDataLoading && state.id == widget.summary.id) {
          setState(() {
            loading = true;
          });
        } else if (state is DynamicChartDataSuccess &&
            state.id == widget.summary.id) {
          setState(() {
            snapshot = parseSummarySnapshot(state.data);
          });
        } else if (state is DynamicChartDataFinished &&
            state.id == widget.summary.id) {
          setState(() => loading = false);
        }
      },
      child: loading ? LoadingCard(isGlass: widget.isGlass) : content(),
    );
  }

  Widget content() {
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    final Color accent = summaryAccentColor(widget.summary.color);
    final IconData icon = summaryIcon(widget.summary.icon);
    final DynamicSummaryValuePresentation valuePresentation =
        splitDynamicSummaryValue(snapshot!);
    final Color primaryText = widget.isGlass
        ? Colors.white.withOpacity(0.94)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.92);
    final Color secondaryText = widget.isGlass
        ? Colors.white.withOpacity(0.74)
        : Theme.of(context)
            .colorScheme
            .onSurfaceVariant
            .withValues(alpha: 0.86);

    final Widget inner = Container(
      padding: EdgeInsets.all(Dimensions.size20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isGlass
              ? <Color>[
                  accent.withValues(alpha: 0.18),
                  Colors.white.withOpacity(0.03),
                ]
              : <Color>[
                  accent.withValues(alpha: 0.12),
                  Theme.of(context).colorScheme.surface,
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: Dimensions.size40,
                height: Dimensions.size40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(Dimensions.size15),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accent, size: Dimensions.size20),
              ),
              SizedBox(width: Dimensions.size10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.summary.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Dimensions.text12,
                        fontWeight: FontWeight.w800,
                        color: primaryText,
                      ),
                    ),
                    SizedBox(height: Dimensions.size2),
                    Text(
                      buildChartDateRangeLabel(widget.begin, widget.until),
                      style: TextStyle(
                        fontSize: Dimensions.text10,
                        fontWeight: FontWeight.w700,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.size15),
          if (valuePresentation.headline.isNotEmpty) ...[
            Text(
              valuePresentation.headline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Dimensions.text18,
                fontWeight: FontWeight.w800,
                color: primaryText,
                height: 1.08,
              ),
            ),
            SizedBox(height: Dimensions.size4),
          ],
          Text(
            valuePresentation.amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: valuePresentation.headline.isEmpty
                  ? Dimensions.text22
                  : Dimensions.text20,
              fontWeight: FontWeight.w900,
              color: primaryText,
              letterSpacing: -0.3,
              height: 1.0,
            ),
          ),
          SizedBox(height: Dimensions.size4),
          Text(
            snapshot!.label.isEmpty
                ? "Ringkasan cepat siap dipakai untuk sales."
                : snapshot!.label,
            style: TextStyle(
              fontSize: Dimensions.text11,
              fontWeight: FontWeight.w700,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );

    if (widget.isGlass) {
      return GlassContainer(
        blur: Dimensions.size20,
        borderRadius: Dimensions.size20,
        opacity: 0.10,
        borderOpacity: 0.18,
        padding: EdgeInsets.zero,
        child: inner,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(Dimensions.size15),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.35
                    : 0.55,
              ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.size15),
        child: inner,
      ),
    );
  }
}
