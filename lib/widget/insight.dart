import "package:base/base.dart";
import "package:dynamic_of_things/module/dynamic_chart/helper/dynamic_chart_data_helper.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:flutter/material.dart";

class Insight extends StatelessWidget {
  final bool isGlass;
  final num total;
  final int rows;
  final String rangeLabel;
  final List<MapEntry<String, num>> compositionByVariable;
  final List<MapEntry<String, num>> compositionByCategory;

  const Insight({
    required this.isGlass,
    required this.total,
    required this.rows,
    required this.rangeLabel,
    required this.compositionByVariable,
    required this.compositionByCategory,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryText = isGlass
        ? Colors.white.withOpacity(0.92)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.92);
    final Color secondaryText = isGlass
        ? Colors.white.withOpacity(0.72)
        : Theme.of(context)
            .colorScheme
            .onSurfaceVariant
            .withValues(alpha: 0.84);

    final Widget inner = Container(
      padding: EdgeInsets.all(Dimensions.size20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Insight",
            style: TextStyle(
              fontSize: Dimensions.text13,
              fontWeight: FontWeight.w900,
              color: primaryText,
            ),
          ),
          SizedBox(height: Dimensions.size4),
          Text(
            rangeLabel,
            style: TextStyle(
              fontSize: Dimensions.text11,
              fontWeight: FontWeight.w700,
              color: secondaryText,
            ),
          ),
          SizedBox(height: Dimensions.size15),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  isGlass: isGlass,
                  label: "Total",
                  value: formatChartNumber(total),
                ),
              ),
              SizedBox(width: Dimensions.size10),
              Expanded(
                child: _MetricCard(
                  isGlass: isGlass,
                  label: "Rows",
                  value: rows.toString(),
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.size15),
          _InsightSection(
            isGlass: isGlass,
            title: "By variable",
            items: compositionByVariable,
          ),
          SizedBox(height: Dimensions.size10),
          _InsightSection(
            isGlass: isGlass,
            title: "By category",
            items: compositionByCategory,
          ),
        ],
      ),
    );

    if (isGlass) {
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

class _MetricCard extends StatelessWidget {
  final bool isGlass;
  final String label;
  final String value;

  const _MetricCard({
    required this.isGlass,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = isGlass
        ? Colors.white.withOpacity(0.07)
        : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.45,
            );
    final Color labelColor = isGlass
        ? Colors.white.withOpacity(0.70)
        : Theme.of(context)
            .colorScheme
            .onSurfaceVariant
            .withValues(alpha: 0.84);
    final Color valueColor = isGlass
        ? Colors.white.withOpacity(0.92)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.92);

    return Container(
      padding: EdgeInsets.all(Dimensions.size15),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Dimensions.size15),
        border: Border.all(
          color: isGlass
              ? Colors.white.withOpacity(0.10)
              : Theme.of(context).colorScheme.outlineVariant.withValues(
                    alpha: 0.40,
                  ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: Dimensions.text11,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
          SizedBox(height: Dimensions.size5),
          Text(
            value,
            style: TextStyle(
              fontSize: Dimensions.text18,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  final bool isGlass;
  final String title;
  final List<MapEntry<String, num>> items;

  const _InsightSection({
    required this.isGlass,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final Color titleColor = isGlass
        ? Colors.white.withOpacity(0.88)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.88);
    final Color itemColor = isGlass
        ? Colors.white.withOpacity(0.72)
        : Theme.of(context)
            .colorScheme
            .onSurfaceVariant
            .withValues(alpha: 0.82);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: Dimensions.text11,
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        SizedBox(height: Dimensions.size10),
        ...items.take(5).map((MapEntry<String, num> entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: Dimensions.size10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Dimensions.text11,
                      fontWeight: FontWeight.w700,
                      color: itemColor,
                    ),
                  ),
                ),
                SizedBox(width: Dimensions.size10),
                Text(
                  formatChartNumber(entry.value),
                  style: TextStyle(
                    fontSize: Dimensions.text11,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
