import "package:base/base.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:flutter/material.dart";

class AppBarDynamicChart extends StatelessWidget {
  final String title;
  final String rangeLabel;
  final VoidCallback onPickRange;
  final VoidCallback onBack;
  final bool isGlass;
  final bool useWhiteForeground;
  final bool showBackButton;
  final bool isMobile;

  const AppBarDynamicChart({
    required this.title,
    required this.rangeLabel,
    required this.onPickRange,
    required this.onBack,
    required this.isGlass,
    required this.useWhiteForeground,
    required this.showBackButton,
    required this.isMobile,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isGlass) {
      return Container(
        height: Dimensions.size50,
        padding: EdgeInsets.symmetric(horizontal: Dimensions.size15),
        child: Row(
          children: [
            if (showBackButton) ...[
              GlassContainer(
                blur: Dimensions.size20,
                borderRadius: Dimensions.size20,
                opacity: 0.12,
                borderOpacity: 0.22,
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: Dimensions.size45,
                  height: Dimensions.size45,
                  child: IconButton(
                    onPressed: onBack,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isMobile
                          ? Icons.arrow_back_ios_new_rounded
                          : Icons.arrow_back_rounded,
                      color: useWhiteForeground
                          ? Colors.white.withOpacity(0.95)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.90),
                      size: Dimensions.size20,
                    ),
                  ),
                ),
              ),
              SizedBox(width: Dimensions.size10),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: Dimensions.text14,
                  fontWeight: FontWeight.w900,
                  color: useWhiteForeground
                      ? Colors.white.withOpacity(0.95)
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: Dimensions.size10),
            InkWell(
              borderRadius: BorderRadius.circular(Dimensions.size15),
              onTap: onPickRange,
              child: GlassContainer(
                blur: Dimensions.size20,
                borderRadius: Dimensions.size15,
                opacity: 0.12,
                borderOpacity: 0.22,
                padding: EdgeInsets.symmetric(horizontal: Dimensions.size10),
                child: SizedBox(
                  height: Dimensions.size40,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: Dimensions.size20,
                        color: Colors.white.withOpacity(0.92),
                      ),
                      SizedBox(width: Dimensions.size10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          rangeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: Dimensions.text12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withOpacity(0.92),
                          ),
                        ),
                      ),
                      SizedBox(width: Dimensions.size5),
                      Icon(
                        Icons.expand_more_rounded,
                        size: Dimensions.size20,
                        color: Colors.white.withOpacity(0.90),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: Dimensions.size55,
      padding: EdgeInsets.symmetric(horizontal: Dimensions.size15),
      child: Row(
        children: [
          if (showBackButton) ...[
            InkWell(
              borderRadius: BorderRadius.circular(Dimensions.size100),
              onTap: onBack,
              child: Padding(
                padding: EdgeInsets.all(Dimensions.size10),
                child: Icon(
                  isMobile
                      ? Icons.arrow_back_ios_new_rounded
                      : Icons.arrow_back_rounded,
                  size: Dimensions.size20,
                  color: useWhiteForeground
                      ? Colors.white.withOpacity(0.95)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.90),
                ),
              ),
            ),
            SizedBox(width: Dimensions.size5),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: Dimensions.text14,
                fontWeight: FontWeight.w900,
                color: useWhiteForeground
                    ? Colors.white.withOpacity(0.95)
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: Dimensions.size10),
          InkWell(
            borderRadius: BorderRadius.circular(Dimensions.size10),
            onTap: onPickRange,
            child: Container(
              height: Dimensions.size35,
              padding: EdgeInsets.symmetric(horizontal: Dimensions.size10),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(Dimensions.size10),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.35
                            : 0.55,
                      ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range_rounded,
                    size: Dimensions.size15,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.88),
                  ),
                  SizedBox(width: Dimensions.size5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      rangeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Dimensions.text12,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
