import "package:base/base.dart";
import "package:basic_utils/basic_utils.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/model/dynamic_form_menu_response.dart";
import "package:dynamic_of_things/model/header_form.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_bloc.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_event.dart";
import "package:dynamic_of_things/module/dynamic_form/form/dynamic_form_state.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form.dart";
import "package:dynamic_of_things/widget/custom_dynamic_form_detail_list.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:loader_overlay/loader_overlay.dart";
import "package:smooth_corner/smooth_corner.dart";

class DynamicFormPage extends StatefulWidget {
  final DynamicFormMenuItem dynamicFormMenuItem;
  final bool readOnly;
  final String? dataId;
  final String? customerId;
  final HeaderForm? headerForm;
  final String? extra;
  final String? referenceId;

  const DynamicFormPage({
    required this.dynamicFormMenuItem,
    required this.customerId,
    this.readOnly = false,
    this.dataId,
    this.headerForm,
    this.extra,
    this.referenceId,
    super.key,
  });

  @override
  DynamicFormPageState createState() => DynamicFormPageState();
}

class DynamicFormPageState extends State<DynamicFormPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  HeaderForm? headerForm;

  GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  bool loading = true;

  static const double _gapCard = 12;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    if (widget.headerForm != null) {
      headerForm = widget.headerForm;

      WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) async {
        await DynamicForms.decode(headerForm!);

        loading = false;

        setState(() {});
      });
    } else {
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;

    return BlocListener<DynamicFormBloc, DynamicFormState>(
      listener: (context, state) async {
        if (state is DynamicFormCreateLoading) {
          loading = true;
          headerForm = null;

          setState(() {});
        } else if (state is DynamicFormCreateSuccess) {
          headerForm = state.headerForm;

          await DynamicForms.decode(headerForm!);

          loading = false;

          setState(() {});
        } else if (state is DynamicFormCreateFinished) {
        } else if (state is DynamicFormViewLoading) {
          loading = true;
          headerForm = null;

          setState(() {});
        } else if (state is DynamicFormViewSuccess) {
          headerForm = state.headerForm;

          await DynamicForms.decode(headerForm!);

          loading = false;

          setState(() {});
        } else if (state is DynamicFormViewFinished) {
        } else if (state is DynamicFormEditLoading) {
          setState(() {
            loading = true;
            headerForm = null;
          });
        } else if (state is DynamicFormEditSuccess) {
          headerForm = state.headerForm;

          await DynamicForms.decode(headerForm!);

          loading = false;

          setState(() {});
        } else if (state is DynamicFormEditFinished) {
        } else if (state is DynamicFormSaveLoading) {
          context.loaderOverlay.show();
        } else if (state is DynamicFormSaveSuccess) {
          await BaseOverlays.success(
            message: "data_has_been_successfully_saved".tr(),
          );

          if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
            Navigators.pop(result: true);
          } else {
            context.pop(true);
          }
        } else if (state is DynamicFormSaveFinished) {
          context.loaderOverlay.hide();
        } else if (state is DynamicFormRefreshLoading) {
          loading = true;
          headerForm = null;

          setState(() {});
        } else if (state is DynamicFormRefreshSuccess) {
          headerForm = state.headerForm;

          await DynamicForms.decode(headerForm!);

          loading = false;

          setState(() {});
        } else if (state is DynamicFormRefreshFinished) {}
      },
      child: Scaffold(
        backgroundColor: _bg(context),
        body: SafeArea(
          top: true,
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      Dimensions.size15,
                      Dimensions.size10,
                      Dimensions.size15,
                      Dimensions.size10,
                    ),
                    child: _topBar(),
                  ),
                  Expanded(child: _bodyHost()),
                  SizedBox(height: safe.bottom + Dimensions.size85),
                ],
              ),
              Positioned(
                left: Dimensions.size15,
                right: Dimensions.size15,
                bottom: safe.bottom + Dimensions.size10,
                child: _bottomFloatingBar(),
              ),
            ],
          ),
        ),
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
    if (widget.headerForm == null) {
      if (widget.dataId != null) {
        if (widget.readOnly) {
          context.read<DynamicFormBloc>().add(
                DynamicFormView(
                  formId: widget.dynamicFormMenuItem.id,
                  dataId: widget.dataId!,
                  customerId: widget.customerId,
                ),
              );
        } else {
          context.read<DynamicFormBloc>().add(
                DynamicFormEdit(
                  formId: widget.dynamicFormMenuItem.id,
                  dataId: widget.dataId!,
                  customerId: widget.customerId,
                ),
              );
        }
      } else {
        context.read<DynamicFormBloc>().add(
              DynamicFormCreate(
                formId: widget.dynamicFormMenuItem.id,
                customerId: widget.customerId,
                extra: widget.extra,
                referenceId: widget.referenceId,
              ),
            );
      }
    }
  }

  String label() {
    if (StringUtils.isNotNullOrEmpty(widget.dataId) ||
        widget.headerForm != null) {
      if (widget.readOnly) {
        return "view".tr();
      } else {
        return "edit".tr();
      }
    } else {
      return "add".tr();
    }
  }

  Widget body() {
    return Form(
      key: globalKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            CustomDynamicForm(
              key: ValueKey("Header-${headerForm!.template.id}"),
              readOnly: widget.readOnly,
              customerId: widget.customerId,
              headerForm: headerForm!,
              template: headerForm!.template,
              data: headerForm!.data,
            ),
            ...headerForm!.detailForms.map((detailForm) {
              if (detailForm.single) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        Dimensions.size15,
                        Dimensions.size10,
                        Dimensions.size15,
                        Dimensions.size10,
                      ),
                      child: _sectionHeader(title: detailForm.template.title),
                    ),
                    CustomDynamicForm(
                      key: ValueKey("DetailForm-${headerForm!.template.id}"),
                      readOnly: widget.readOnly,
                      customerId: widget.customerId,
                      headerForm: headerForm!,
                      template: detailForm.template,
                      data: detailForm.getData(headerForm!),
                    ),
                  ],
                );
              } else {
                return CustomDynamicFormDetailList(
                  key: ValueKey("DetailList-${detailForm.template.id}"),
                  readOnly: widget.readOnly,
                  customerId: widget.customerId,
                  headerForm: headerForm!,
                  detailForm: detailForm,
                  onRefresh: () {
                    context.read<DynamicFormBloc>().add(
                          DynamicFormRefresh(
                            formId: headerForm!.template.id,
                            customerId: widget.customerId,
                            headerForm: headerForm!,
                          ),
                        );
                  },
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget bottomBar() {
    if (headerForm != null && !widget.readOnly) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () async {
                if (!locationValid()) {
                  BaseOverlays.error(message: "location_required".tr());
                  return;
                }

                if (globalKey.currentState != null) {
                  if (globalKey.currentState!.validate()) {
                    BaseDialogs.confirmation(
                      title: "are_you_sure_want_to_proceed".tr(),
                      positiveCallback: () {
                        globalKey.currentState!.save();

                        context.read<DynamicFormBloc>().add(
                              DynamicFormSave(
                                formId: widget.dynamicFormMenuItem.id,
                                customerId: widget.customerId,
                                headerForm: headerForm!,
                              ),
                            );
                      },
                    );
                  }
                }
              },
              icon: const Icon(Icons.save),
              label: Text("save".tr()),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  bool locationValid() {
    bool hasLocationField = false;

    for (Section section in headerForm!.template.sections) {
      bool hasLatitudeField = false;
      bool hasLongitudeField = false;

      for (Field field in section.fields) {
        if (field.name == "latitude") {
          hasLatitudeField = true;
        } else if (StringUtils.inList(
            field.name, ["longitude", "longtitude"])) {
          hasLongitudeField = true;
        }
      }

      hasLocationField = hasLatitudeField && hasLongitudeField;

      if (hasLocationField) {
        break;
      }
    }

    if (hasLocationField) {
      bool hasLatitudeValue = false;
      bool hasLongitudeValue = false;

      for (Section section in headerForm!.template.sections) {
        for (Field field in section.fields) {
          if (field.name == "latitude") {
            hasLatitudeValue = field.getValue(headerForm!.data) != null;
          } else if (StringUtils.inList(
              field.name, ["longitude", "longtitude"])) {
            hasLongitudeValue = field.getValue(headerForm!.data) != null;
          }
        }

        if (hasLatitudeValue && hasLongitudeValue) {
          return true;
        }
      }
    } else {
      return true;
    }

    return false;
  }

  Widget _sectionHeader({required String title}) {
    final Color primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Container(
          width: Dimensions.size30,
          height: Dimensions.size30,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            border: Border.all(color: primary.withValues(alpha: 0.18)),
          ),
          child: Icon(Icons.segment_rounded,
              color: primary, size: Dimensions.size20),
        ),
        SizedBox(width: Dimensions.size10),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: _fg(context),
              fontSize: Dimensions.text14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _topBar() {
    final String title = (headerForm?.template.title.isNotEmpty ?? false)
        ? headerForm!.template.title
        : widget.dynamicFormMenuItem.name;

    final String subtitle = label();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size10,
      ),
      decoration: ShapeDecoration(
        color: _card(context),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: _outline(context).withValues(alpha: 0.22),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Dimensions.text16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    color: _fg(context),
                  ),
                ),
                SizedBox(height: Dimensions.size2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Dimensions.text12,
                    fontWeight: FontWeight.w700,
                    color: _fg(context).withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: Dimensions.size10),
          _iconPill(
            icon: Icons.cloud_sync,
            onTap: () {
              if (headerForm == null) {
                refresh();
                return;
              }

              context.read<DynamicFormBloc>().add(
                    DynamicFormRefresh(
                      formId: headerForm!.template.id,
                      customerId: widget.customerId,
                      headerForm: headerForm!,
                    ),
                  );
            },
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
                color: _outline(context).withValues(alpha: 0.18),
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

  Widget _bodyHost() {
    if (loading) {
      return BaseWidgets.shimmer();
    }

    if (headerForm == null) {
      return ListView(
        padding: EdgeInsets.all(Dimensions.size15),
        children: [
          _failState(),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (headerForm == null) {
          refresh();
          return;
        }

        context.read<DynamicFormBloc>().add(
              DynamicFormRefresh(
                formId: headerForm!.template.id,
                customerId: widget.customerId,
                headerForm: headerForm!,
              ),
            );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Dimensions.size15,
          Dimensions.size10,
          Dimensions.size15,
          Dimensions.size10,
        ),
        children: [
          body(),
          if (headerForm!.detailForms.isNotEmpty) ...[
            const SizedBox(height: _gapCard),
          ],
        ],
      ),
    );
  }

  Widget _failState() {
    return Container(
      padding: EdgeInsets.all(Dimensions.size20),
      decoration: ShapeDecoration(
        color: _card(context),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: _outline(context).withValues(alpha: 0.22),
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: Dimensions.size45,
            color: _fg(context).withValues(alpha: 0.65),
          ),
          SizedBox(height: Dimensions.size10),
          Text(
            "common_something_wrong".tr(),
            style: TextStyle(
              fontSize: Dimensions.text16,
              fontWeight: FontWeight.w900,
              color: _fg(context),
            ),
          ),
          SizedBox(height: Dimensions.size5),
          Text(
            "pull_to_refresh_or_try_again".tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _fg(context).withValues(alpha: 0.70),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: Dimensions.size15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => refresh(),
                  icon: const Icon(Icons.refresh),
                  label: Text("refresh".tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomFloatingBar() {
    final Widget action = bottomBar();

    if (action is SizedBox) {
      return const SizedBox.shrink();
    }

    if (headerForm == null || widget.readOnly) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.size15,
        vertical: Dimensions.size10,
      ),
      decoration: ShapeDecoration(
        color: _card(context),
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: _outline(context).withValues(alpha: 0.22),
          ),
        ),
      ),
      child: action,
    );
  }

  Color _bg(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _card(BuildContext context) => AppColors.surface();
  Color _soft(BuildContext context) => AppColors.surfaceContainerLowest();
  Color _fg(BuildContext context) => AppColors.onSurface();
  Color _outline(BuildContext context) => AppColors.outline();
}
