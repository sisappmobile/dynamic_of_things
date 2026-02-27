// ignore_for_file: use_build_context_synchronously

import "dart:typed_data";
import "dart:ui" as ui;
import "dart:ui";

import "package:base/base.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:smooth_corner/smooth_corner.dart";
import "package:syncfusion_flutter_signaturepad/signaturepad.dart";

class SignaturePage extends StatefulWidget {
  const SignaturePage({
    super.key,
  });

  @override
  SignaturePageState createState() => SignaturePageState();
}

class SignaturePageState extends State<SignaturePage> {
  final GlobalKey<SfSignaturePadState> gkSignaturePadState = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  Widget sectionCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding ?? EdgeInsets.all(Dimensions.size15),
      decoration: ShapeDecoration(
        color: AppColors.surface(),
        shadows: [
          BoxShadow(
            blurRadius: Dimensions.size25,
            offset: Offset(0, Dimensions.size15),
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ],
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.size20),
          smoothness: Dimensions.size1,
          side: BorderSide(
            color: AppColors.outline().withValues(alpha: 0.20),
          ),
        ),
      ),
      child: child,
    );
  }

  Widget iconPill({
    required BuildContext context,
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
            size: Dimensions.size25,
            color: AppColors.onSurface(),
          ),
        ),
      ),
    );
  }

  Widget glassTopbar(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Dimensions.size15,
          safe.top > 0 ? Dimensions.size10 : Dimensions.size15,
          Dimensions.size15,
          Dimensions.size10,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.size25),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: Dimensions.size15,
              sigmaY: Dimensions.size15,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.size15,
                vertical: Dimensions.size10,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface().withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(Dimensions.size25),
                border: Border.all(
                  color: AppColors.outline().withValues(alpha: 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: Dimensions.size25,
                    offset: Offset(0, Dimensions.size15),
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  iconPill(
                    context: context,
                    icon: Icons.turn_left_rounded,
                    onTap: () {
                      if (BaseSettings.navigatorType ==
                          BaseNavigatorType.legacy) {
                        Navigators.pop();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  SizedBox(width: Dimensions.size10),
                  Expanded(
                    child: Text(
                      "signature".tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Dimensions.text16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        color: AppColors.onSurface(),
                      ),
                    ),
                  ),
                  SizedBox(width: Dimensions.size10),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.size15,
                      vertical: Dimensions.size10,
                    ),
                    decoration: ShapeDecoration(
                      color: AppColors.surfaceContainerLowest(),
                      shape: SmoothRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.size15),
                        smoothness: Dimensions.size1,
                        side: BorderSide(
                          color: AppColors.outline().withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: Dimensions.size15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: Dimensions.size10),
                        Text(
                          "Tanda Tangan",
                          style: TextStyle(
                            fontSize: Dimensions.text12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                            color: AppColors.onSurface(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget bottomGlassSaveBar(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Dimensions.size15,
          Dimensions.size10,
          Dimensions.size15,
          Dimensions.size10 + safe.bottom,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.size25),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: Dimensions.size15,
              sigmaY: Dimensions.size15,
            ),
            child: Container(
              padding: EdgeInsets.all(Dimensions.size10),
              decoration: BoxDecoration(
                color: AppColors.surface().withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(Dimensions.size25),
                border: Border.all(
                  color: AppColors.outline().withValues(alpha: 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: Dimensions.size25,
                    offset: Offset(0, Dimensions.size15),
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        gkSignaturePadState.currentState?.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.backspace_outlined),
                      label: Text("clear".tr().toUpperCase()),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(0, Dimensions.size50),
                        shape: SmoothRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.size20),
                          smoothness: Dimensions.size1,
                        ),
                        side: BorderSide(
                          color: AppColors.outline().withValues(alpha: 0.30),
                        ),
                        foregroundColor: AppColors.onSurface(),
                        backgroundColor: AppColors.surfaceContainerLowest(),
                      ),
                    ),
                  ),
                  SizedBox(width: Dimensions.size10),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          ByteData? byteData;

                          if (gkSignaturePadState.currentState != null) {
                            ui.Image image = await gkSignaturePadState
                                .currentState!
                                .toImage();

                            byteData = await image.toByteData(
                              format: ui.ImageByteFormat.png,
                            );
                          }

                          if (BaseSettings.navigatorType ==
                              BaseNavigatorType.legacy) {
                            Navigators.pop(
                              result: byteData?.buffer.asUint8List(
                                byteData.offsetInBytes,
                                byteData.lengthInBytes,
                              ),
                            );
                          } else {
                            context.pop(
                              byteData?.buffer.asUint8List(
                                byteData.offsetInBytes,
                                byteData.lengthInBytes,
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(Dimensions.size20),
                        child: Ink(
                          height: Dimensions.size50,
                          decoration: ShapeDecoration(
                            color: primary,
                            shadows: [
                              BoxShadow(
                                blurRadius: Dimensions.size20,
                                offset: Offset(0, Dimensions.size10),
                                color: Colors.black.withValues(alpha: 0.16),
                              ),
                            ],
                            shape: SmoothRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(Dimensions.size20),
                              smoothness: Dimensions.size1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: Dimensions.size30,
                                height: Dimensions.size30,
                                decoration: BoxDecoration(
                                  color: onPrimary.withValues(alpha: 0.16),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.save_rounded,
                                  size: Dimensions.size15,
                                  color: onPrimary,
                                ),
                              ),
                              SizedBox(width: Dimensions.size10),
                              Text(
                                "save".tr().toUpperCase(),
                                style: TextStyle(
                                  color: onPrimary,
                                  fontSize: Dimensions.text13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget signatureCanvas(BuildContext context) {
    final double w = MediaQuery.sizeOf(context).width;

    return sectionCard(
      context: context,
      padding: EdgeInsets.all(Dimensions.size10),
      child: Container(
        width: double.infinity,
        height: w,
        constraints: BoxConstraints(
          maxWidth: Dimensions.size100 * 5,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest(),
          border: Border.all(
            color: AppColors.outline().withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(Dimensions.size15),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: SfSignaturePad(
          key: gkSignaturePadState,
          strokeColor: AppColors.onSurface(),
          backgroundColor: AppColors.surfaceContainerLowest(),
        ),
      ),
    );
  }

  Widget hint(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: Dimensions.size10),
      child: sectionCard(
        context: context,
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.size15,
          vertical: Dimensions.size15,
        ),
        child: Row(
          children: [
            Container(
              width: Dimensions.size30,
              height: Dimensions.size30,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.25),
                ),
              ),
              child: Icon(
                Icons.gesture_rounded,
                size: Dimensions.size20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(width: Dimensions.size10),
            Expanded(
              child: Text(
                "Silakan tanda tangan pada area di bawah, lalu tekan SIMPAN.",
                style: TextStyle(
                  color: AppColors.onSurface().withValues(alpha: 0.75),
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  fontSize: Dimensions.text12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest(),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                Dimensions.size15,
                safe.top + (Dimensions.size10 + Dimensions.size70),
                Dimensions.size15,
                safe.bottom + (Dimensions.size10 + Dimensions.size90),
              ),
              child: Column(
                children: [
                  hint(context),
                  signatureCanvas(context),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: glassTopbar(context),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: bottomGlassSaveBar(context),
          ),
        ],
      ),
    );
  }
}
