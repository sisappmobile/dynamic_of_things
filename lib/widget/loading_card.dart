import "package:base/base.dart";
import "package:dynamic_of_things/widget/glass_container.dart";
import "package:flutter/material.dart";
import "package:shimmer/shimmer.dart";

class LoadingCard extends StatelessWidget {
  final bool isGlass;

  const LoadingCard({required this.isGlass, super.key});

  @override
  Widget build(BuildContext context) {
    final Widget inner = Shimmer.fromColors(
      baseColor: isGlass
          ? Colors.white.withOpacity(0.10)
          : (Theme.of(context).brightness == Brightness.dark
              ? Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.10)
              : Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.06)),
      highlightColor: isGlass
          ? Colors.white.withOpacity(0.06)
          : (Theme.of(context).brightness == Brightness.dark
              ? Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.06)
              : Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.02)),
      child: Container(
        height: 380,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isGlass ? 0.06 : 1),
          borderRadius: BorderRadius.circular(Dimensions.size15),
        ),
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: isGlass
            ? GlassContainer(
                blur: Dimensions.size20,
                borderRadius: Dimensions.size20,
                opacity: 0.10,
                borderOpacity: 0.18,
                padding: EdgeInsets.zero,
                child: inner,
              )
            : inner,
      ),
    );
  }
}
