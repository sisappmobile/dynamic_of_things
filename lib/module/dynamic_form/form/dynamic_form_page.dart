
// ignore_for_file: always_specify_types, cascade_invocations, always_put_required_named_parameters_first, empty_catches, use_build_context_synchronously

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
import "package:dynamic_of_things/widget/simple_bottom_bar.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:loader_overlay/loader_overlay.dart";

class DynamicFormPage extends StatefulWidget {
  final DynamicFormMenuItem dynamicFormMenuItem;
  final bool readOnly;
  final String? dataId;
  final String? customerId;
  final HeaderForm? headerForm;

  const DynamicFormPage({
    required this.dynamicFormMenuItem,
    this.readOnly = false,
    this.dataId,
    required this.customerId,
    this.headerForm,
    super.key,
  });

  @override
  DynamicFormPageState createState() => DynamicFormPageState();
}

class DynamicFormPageState extends State<DynamicFormPage> with WidgetsBindingObserver, TickerProviderStateMixin {
  TabController? tabController;

  HeaderForm? headerForm;

  GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  bool loading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    if (widget.headerForm != null) {
      headerForm = widget.headerForm;

      WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) async {
        await DynamicForms.decode(headerForm: headerForm!);

        loading = false;

        if (headerForm!.detailForms.isNotEmpty) {
          tabController = TabController(
            length: headerForm!.detailForms.length + 1,
            vsync: this,
            initialIndex: 0,
          );
        }

        setState(() {});
      });
    } else {
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DynamicFormBloc, DynamicFormState>(
      listener: (context, state) async {
        if (state is DynamicFormCreateLoading) {
          loading = true;
          headerForm = null;
          tabController = null;

          setState(() {});
        } else if (state is DynamicFormCreateSuccess) {
          headerForm = state.headerForm;

          await DynamicForms.decode(headerForm: headerForm!);

          loading = false;

          if (headerForm!.detailForms.isNotEmpty) {
            tabController = TabController(
              length: headerForm!.detailForms.length + 1,
              vsync: this,
              initialIndex: 0,
            );
          }

          setState(() {});
        } else if (state is DynamicFormCreateFinished) {

        } else if (state is DynamicFormViewLoading) {
          loading = true;
          headerForm = null;
          tabController = null;

          setState(() {});
        } else if (state is DynamicFormViewSuccess) {
          headerForm = state.headerForm;

          await DynamicForms.decode(headerForm: headerForm!);

          loading = false;

          if (headerForm!.detailForms.isNotEmpty) {
            tabController = TabController(
              length: headerForm!.detailForms.length + 1,
              vsync: this,
              initialIndex: 0,
            );
          }

          setState(() {});
        } else if (state is DynamicFormViewFinished) {

        } else if (state is DynamicFormEditLoading) {
          setState(() {
            loading = true;
            headerForm = null;
            tabController = null;
          });
        } else if (state is DynamicFormEditSuccess) {
          headerForm = state.headerForm;

          await DynamicForms.decode(headerForm: headerForm!);

          loading = false;

          if (headerForm!.detailForms.isNotEmpty) {
            tabController = TabController(
              length: headerForm!.detailForms.length + 1,
              vsync: this,
              initialIndex: 0,
            );
          }

          setState(() {});
        } else if (state is DynamicFormEditFinished) {

        } else if (state is DynamicFormSaveLoading) {
          context.loaderOverlay.show();
        } else if (state is DynamicFormSaveSuccess) {
          await BaseOverlays.success(message: "data_has_been_successfully_saved".tr());

          Navigators.pop();
        } else if (state is DynamicFormSaveFinished) {
          context.loaderOverlay.hide();
        } else if (state is DynamicFormRefreshLoading) {
          loading = true;
          headerForm = null;
          tabController = null;

          setState(() {});
        } else if (state is DynamicFormRefreshSuccess) {
          headerForm = state.headerForm;

          await DynamicForms.decode(headerForm: headerForm!);

          loading = false;

          if (headerForm!.detailForms.isNotEmpty) {
            tabController = TabController(
              length: headerForm!.detailForms.length + 1,
              vsync: this,
              initialIndex: 0,
            );
          }

          setState(() {});
        } else if (state is DynamicFormRefreshFinished) {

        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: AppColors.surfaceContainerLowest(),
          statusBarIconBrightness: AppColors.brightnessInverse(),
          systemNavigationBarColor: AppColors.surfaceContainerLowest(),
          systemNavigationBarIconBrightness: AppColors.brightnessInverse(),
        ),
        child: SafeArea(
          child: Scaffold(
            body: Column(
              children: [
                appBar(),
                body(),
                bottomBar(),
              ],
            ),
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
          ),
        );
      }
    }
  }

  Widget appBar() {
    Widget topWidget() {
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

      Widget subtitle() {
        String label() {
          if (StringUtils.isNotNullOrEmpty(widget.dataId) || widget.headerForm != null) {
            if (widget.readOnly) {
              return "view".tr();
            } else {
              return "edit".tr();
            }
          } else {
            return "add".tr();
          }
        }

        return Text(
          label(),
          style: TextStyle(
            fontSize: Dimensions.text12,
            fontWeight: FontWeight.w500,
          ),
        );
      }

      return Container(
        padding: EdgeInsets.all(Dimensions.size15),
        child: Row(
          children: [
            backButton(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headerForm?.template.title ?? "",
                    style: TextStyle(
                      fontSize: Dimensions.text16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget bottomWidget() {
      if (tabController != null) {
        return TabBar(
          controller: tabController!,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              text: "main".tr().toUpperCase(),
            ),
            ...headerForm!.detailForms.map((e) {
              return Tab(
                text: e.template.title.toUpperCase(),
              );
            }),
          ],
        );
      }

      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest(),
        border: Border(
          bottom: BorderSide(
            color: AppColors.outline(),
          ),
        ),
      ),
      child: Column(
        children: [
          topWidget(),
          bottomWidget(),
        ],
      ),
    );
  }

  Widget body() {
    if (loading) {
      return Expanded(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: CustomShimmer(),
        ),
      );
    } else {
      if (headerForm != null) {
        if (tabController != null) {
          return Expanded(
            child: Form(
              key: globalKey,
              child: TabBarView(
                controller: tabController,
                children: [
                  CustomDynamicForm(
                    readOnly: widget.readOnly,
                    customerId: widget.customerId,
                    headerForm: headerForm!,
                    template: headerForm!.template,
                    data: headerForm!.data,
                  ),
                  ...headerForm!.detailForms.map((detailForm) {
                    return CustomDynamicFormDetailList(
                      readOnly: widget.readOnly,
                      customerId: widget.customerId,
                      headerForm: headerForm!,
                      detailForm: detailForm,
                    );
                  }),
                ],
              ),
            ),
          );
        } else {
          return Expanded(
            child: Form(
              key: globalKey,
              child: CustomDynamicForm(
                readOnly: widget.readOnly,
                customerId: widget.customerId,
                headerForm: headerForm!,
                template: headerForm!.template,
                data: headerForm!.data,
              ),
            ),
          );
        }
      } else {
        return Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              refresh();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: BaseWidgets.loadingFail(),
            ),
          ),
        );
      }
    }
  }

  Widget bottomBar() {
    if (headerForm != null && !widget.readOnly) {
      return SimpleBottomBar(
        children: [
          FilledButton.icon(
            onPressed: () async {
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
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
