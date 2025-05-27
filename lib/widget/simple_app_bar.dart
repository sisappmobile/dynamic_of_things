import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:smooth_corner/smooth_corner.dart";

class SimpleAppBar extends StatefulWidget {
  final String title;
  String? subtitle;
  List<Widget>? trailing;
  TextEditingController? tecSearch;
  ValueChanged<String>? onChanged;

  SimpleAppBar({
    required this.title,
    this.subtitle,
    this.trailing,
    this.tecSearch,
    this.onChanged,
    super.key,
  });

  @override
  State<SimpleAppBar> createState() => _SimpleAppBarState();
}

class _SimpleAppBarState extends State<SimpleAppBar> {
  bool searchMode = false;

  @override
  Widget build(BuildContext context) {
    if (searchMode) {
      return Container(
        padding: EdgeInsets.all(
          Dimensions.size15,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest(),
          border: Border(
            bottom: BorderSide(
              color: AppColors.outline(),
            ),
          ),
        ),
        child: Container(
          decoration: ShapeDecoration(
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size10),
              smoothness: 1,
              side: BorderSide(color: AppColors.outline()),
            ),
            color: AppColors.surfaceBright(),
          ),
          child: TextField(
            controller: widget.tecSearch!,
            decoration: InputDecoration(
              isDense: true,
              hintText: "search".tr(),
              hintStyle: TextStyle(
                color: AppColors.onSurface().withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.onSurface().withValues(alpha: 0.5),
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    widget.tecSearch!.clear();
                    searchMode = false;
                  });
                },
                icon: const Icon(Icons.close),
              ),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
              ),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
              ),
            ),
            onChanged: widget.onChanged,
          ),
        ),
      );
    } else {
      Widget backButton() {
        if (context.canPop()) {
          return Container(
            margin: EdgeInsets.only(
              right: Dimensions.size5,
            ),
            child: IconButton(
              onPressed: () {
                context.pop();
              },
              icon: const Icon(
                Icons.turn_left,
              ),
            ),
          );
        }

        return Container(
          margin: EdgeInsets.only(
            right: Dimensions.size10,
          ),
        );
      }

      Widget subtitleWidget() {
        if (StringUtils.isNotNullOrEmpty(widget.subtitle)) {
          return Text(
            widget.subtitle!,
            style: TextStyle(
              fontSize: Dimensions.text12,
              fontWeight: FontWeight.w500,
            ),
          );
        }

        return const SizedBox.shrink();
      }

      Widget searchButton() {
        if (widget.onChanged != null) {
          return IconButton(
            onPressed: () {
              setState(() {
                searchMode = true;
              });
            },
            icon: Icon(Icons.search),
          );
        }

        return const SizedBox.shrink();
      }

      List<Widget> trailing = widget.trailing ?? []
        ..add(searchButton());

      return Container(
        padding: EdgeInsets.all(
          Dimensions.size15,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest(),
          border: Border(
            bottom: BorderSide(
              color: AppColors.outline(),
            ),
          ),
        ),
        child: Row(
          children: [
            backButton(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: Dimensions.text16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitleWidget(),
                ],
              ),
            ),
            ...trailing,
          ],
        ),
      );
    }
  }
}