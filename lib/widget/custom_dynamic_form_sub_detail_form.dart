import "package:base/base.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:smooth_corner/smooth_corner.dart";

class CustomDynamicFormSubDetailForm extends StatefulWidget {
  final String? customerId;
  final bool readOnly;
  final HeaderForm headerForm;
  final DetailForm detailForm;
  final SubDetailForm subDetailForm;
  final Map<String, dynamic> data;

  const CustomDynamicFormSubDetailForm({
    super.key,
    required this.customerId,
    required this.readOnly,
    required this.headerForm,
    required this.detailForm,
    required this.subDetailForm,
    required this.data,
  });

  @override
  State<CustomDynamicFormSubDetailForm> createState() =>
      CustomDynamicFormSubDetailFormState();
}

class CustomDynamicFormSubDetailFormState
    extends State<CustomDynamicFormSubDetailForm> with WidgetsBindingObserver {
  GlobalKey<FormState> formState = GlobalKey<FormState>();

  late Map<String, dynamic> data;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    data = widget.data;
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: _bg(context),
      body: Stack(
        children: [
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
                child: _topBar(context),
              ),
              Expanded(child: body()),
              SizedBox(height: safe.bottom),
            ],
          ),
          Positioned(
            right: Dimensions.size15,
            bottom: safe.bottom + Dimensions.size10,
            child: _floatingSaveFab(),
          ),
        ],
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

  Color _bg(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _card(BuildContext context) => AppColors.surface();
  Color _soft(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _fg(BuildContext context) => AppColors.onSurface();
  Color _outline(BuildContext context) => AppColors.outline();

  Widget _topBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size10,
      ),
      decoration: ShapeDecoration(
        color: _card(context),
        shadows: [
          BoxShadow(
            blurRadius: Dimensions.size20,
            offset: Offset(0, Dimensions.size10),
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ],
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: _outline(context).withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          _iconPill(
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
            child: Text(
              widget.subDetailForm.template.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Dimensions.text16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                color: _fg(context),
              ),
            ),
          ),
          if (widget.readOnly)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.size10,
                vertical: Dimensions.size5,
              ),
              decoration: BoxDecoration(
                color: _soft(context),
                borderRadius: BorderRadius.circular(Dimensions.size100),
                border: Border.all(
                  color: _outline(context).withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_rounded,
                    size: Dimensions.size15,
                    color: _fg(context).withValues(alpha: 0.75),
                  ),
                  SizedBox(width: Dimensions.size5),
                  Text(
                    "read_only".tr(),
                    style: TextStyle(
                      fontSize: Dimensions.text11,
                      fontWeight: FontWeight.w900,
                      color: _fg(context).withValues(alpha: 0.75),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconPill({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size15),
          smoothness: Dimensions.size1,
        ),
        child: Ink(
          width: Dimensions.size40,
          height: Dimensions.size40,
          decoration: ShapeDecoration(
            color: _soft(context),
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size15),
              smoothness: Dimensions.size1,
              side: BorderSide(
                color: _outline(context).withValues(alpha: 0.25),
              ),
            ),
          ),
          child: Icon(
            icon,
            color: _fg(context),
            size: Dimensions.size25,
          ),
        ),
      ),
    );
  }

  Widget _floatingSaveFab() {
    if (widget.readOnly) {
      return const SizedBox.shrink();
    }

    final Color primary = Theme.of(context).colorScheme.primary;
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          save();
        },
        borderRadius: BorderRadius.circular(Dimensions.size30),
        child: Ink(
          height: Dimensions.size55,
          padding: EdgeInsets.symmetric(horizontal: Dimensions.size20),
          decoration: ShapeDecoration(
            color: primary,
            shadows: [
              BoxShadow(
                blurRadius: Dimensions.size25,
                offset: Offset(0, Dimensions.size15),
                color: Colors.black.withValues(alpha: 0.18),
              ),
            ],
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size30),
              smoothness: Dimensions.size1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: Dimensions.size35,
                height: Dimensions.size35,
                decoration: BoxDecoration(
                  color: onPrimary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.save_rounded,
                  color: onPrimary,
                  size: Dimensions.size20,
                ),
              ),
              SizedBox(width: Dimensions.size10),
              Text(
                "save".tr(),
                style: TextStyle(
                  color: onPrimary,
                  fontSize: Dimensions.text14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(width: Dimensions.size2),
            ],
          ),
        ),
      ),
    );
  }

  Widget body() {
    return Form(
      key: formState,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Dimensions.size15,
          Dimensions.size10,
          Dimensions.size15,
          Dimensions.size20 + MediaQuery.of(context).padding.bottom,
        ),
        child: Container(
          padding: EdgeInsets.all(Dimensions.size10),
          decoration: ShapeDecoration(
            color: _card(context),
            shadows: [
              BoxShadow(
                blurRadius: Dimensions.size20,
                offset: Offset(0, Dimensions.size10),
                color: Colors.black.withValues(alpha: 0.10),
              ),
            ],
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.size20),
              smoothness: Dimensions.size1,
              side: BorderSide(
                color: _outline(context).withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Column(
            children: [
              CustomDynamicForm(
                key: ValueKey("SubDetail-${widget.subDetailForm.template.id}"),
                readOnly: widget.readOnly,
                customerId: widget.customerId,
                headerForm: widget.headerForm,
                template: widget.subDetailForm.template,
                data: data,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget bottomBar() {
    if (!widget.readOnly) {
      return BaseBottomBar(
        children: [
          FilledButton.icon(
            onPressed: () async {
              save();
            },
            icon: const Icon(Icons.save),
            label: Text("save".tr()),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void save() async {
    if (formState.currentState != null) {
      if (formState.currentState!.validate()) {
        formState.currentState!.save();

        BaseDialogs.confirmation(
          title: "are_you_sure_want_to_proceed".tr(),
          positiveCallback: () {
            if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
              Navigators.pop(result: data);
            } else {
              context.pop(data);
            }
          },
        );
      }
    }
  }
}
