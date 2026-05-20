import "package:base/base.dart";
import "package:dynamic_of_things/helper/dynamic_chart_data_helper.dart";

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
    final MapEntry<String, num>? topVariable =
        compositionByVariable.isEmpty ? null : compositionByVariable.first;
    final MapEntry<String, num>? topCategory =
        compositionByCategory.isEmpty ? null : compositionByCategory.first;
    final num average = rows <= 0 ? 0 : total / rows;

    final Color primaryText = isGlass
        ? Colors.white.withOpacity(0.92)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.92);
    final Color secondaryText = isGlass
        ? Colors.white.withOpacity(0.72)
        : Theme.of(context)
            .colorScheme
            .onSurfaceVariant
            .withValues(alpha: 0.84);
    final Color highlightBg = isGlass
        ? Colors.white.withOpacity(0.08)
        : Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.34);
    final Color highlightBorder = isGlass
        ? Colors.white.withOpacity(0.12)
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.16);

    String shareText(num value) {
      if (total <= 0) {
        return "";
      }

      final double pct = (value / total) * 100;
      if (!pct.isFinite) {
        return "";
      }

      return pct >= 10
          ? "${pct.toStringAsFixed(0)}%"
          : "${pct.toStringAsFixed(1)}%";
    }

    String summaryText() {
      final List<String> parts = <String>[
        "Ada ${formatChartNumber(total)} nilai dari $rows data pada periode ini.",
      ];

      if (topVariable != null) {
        final String pct = shareText(topVariable.value);
        parts.add(
          "Kontributor terbesar adalah ${topVariable.key} dengan ${formatChartNumber(topVariable.value)}${pct.isEmpty ? "" : " ($pct dari total)"}.",
        );
      }

      if (topCategory != null) {
        parts.add(
          "Kategori tertinggi: ${topCategory.key} (${formatChartNumber(topCategory.value)}).",
        );
      }

      return parts.join(" ");
    }

    final Widget inner = Container(
      padding: EdgeInsets.all(Dimensions.size20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Insight",
            style: TextStyle(
              fontSize: Dimensions.text16,
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
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(Dimensions.size15),
            decoration: BoxDecoration(
              color: highlightBg,
              borderRadius: BorderRadius.circular(Dimensions.size15),
              border: Border.all(color: highlightBorder, width: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: Dimensions.size20,
                  color: primaryText,
                ),
                SizedBox(width: Dimensions.size10),
                Expanded(
                  child: Text(
                    summaryText(),
                    style: TextStyle(
                      fontSize: Dimensions.text12,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Dimensions.size15),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  isGlass: isGlass,
                  icon: Icons.summarize_rounded,
                  label: "Total nilai",
                  value: formatChartNumber(total),
                  hint: "Akumulasi semua baris data",
                ),
              ),
              SizedBox(width: Dimensions.size10),
              Expanded(
                child: MetricCard(
                  isGlass: isGlass,
                  icon: Icons.table_rows_rounded,
                  label: "Jumlah data",
                  value: rows.toString(),
                  hint: "Banyaknya baris yang dihitung",
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.size10),
          MetricCard(
            isGlass: isGlass,
            icon: Icons.functions_rounded,
            label: "Rata-rata per data",
            value: formatChartNumber(average),
            hint: "Total nilai dibagi jumlah data",
          ),
          SizedBox(height: Dimensions.size15),
          InsightSection(
            isGlass: isGlass,
            title: "Kontribusi berdasarkan jenis",
            total: total,
            items: compositionByVariable,
          ),
          SizedBox(height: Dimensions.size10),
          InsightSection(
            isGlass: isGlass,
            title: "Kategori dengan nilai tertinggi",
            total: total,
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

class MetricCard extends StatelessWidget {
  final bool isGlass;
  final IconData icon;
  final String label;
  final String value;
  final String hint;

  const MetricCard({
    required this.isGlass,
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    super.key,
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
    final Color iconColor = isGlass
        ? Colors.white.withOpacity(0.86)
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.86);

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
          Row(
            children: [
              Icon(icon, size: Dimensions.size15, color: iconColor),
              SizedBox(width: Dimensions.size5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Dimensions.text11,
                    fontWeight: FontWeight.w800,
                    color: labelColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.size5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Dimensions.text18,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
          SizedBox(height: Dimensions.size4),
          Text(
            hint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Dimensions.text10,
              fontWeight: FontWeight.w600,
              color: labelColor,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class InsightSection extends StatelessWidget {
  final bool isGlass;
  final String title;
  final num total;
  final List<MapEntry<String, num>> items;

  const InsightSection({
    required this.isGlass,
    required this.title,
    required this.total,
    required this.items,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final Color titleColor = isGlass
        ? Colors.white.withOpacity(0.88)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.88);
    final Color itemColor = isGlass
        ? Colors.white.withOpacity(0.72)
        : Theme.of(context)
            .colorScheme
            .onSurfaceVariant
            .withValues(alpha: 0.82);
    final Color trackColor = isGlass
        ? Colors.white.withOpacity(0.10)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final Color fillColor = isGlass
        ? Colors.white.withOpacity(0.60)
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.70);

    String percentageLabel(num value) {
      if (total <= 0) {
        return "";
      }

      final double percentage = (value / total) * 100;
      if (!percentage.isFinite) {
        return "";
      }

      return percentage >= 10
          ? "${percentage.toStringAsFixed(0)}%"
          : "${percentage.toStringAsFixed(1)}%";
    }

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
          final double ratio =
              total <= 0 ? 0 : (entry.value / total).clamp(0, 1).toDouble();
          final String pct = percentageLabel(entry.value);

          return Padding(
            padding: EdgeInsets.only(bottom: Dimensions.size15),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Dimensions.text12,
                          fontWeight: FontWeight.w800,
                          color: itemColor,
                        ),
                      ),
                    ),
                    SizedBox(width: Dimensions.size10),
                    Text(
                      pct.isEmpty
                          ? formatChartNumber(entry.value)
                          : "${formatChartNumber(entry.value)} • $pct",
                      style: TextStyle(
                        fontSize: Dimensions.text12,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Dimensions.size5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.size100),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: Dimensions.size5,
                    backgroundColor: trackColor,
                    valueColor: AlwaysStoppedAnimation<Color>(fillColor),
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
