// ignore_for_file: constant_identifier_names

import "dart:typed_data";
import "dart:ui" as ui;

import "package:base/base.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
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

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      context: context,
      appBar: BaseAppBar(
        context: context,
        name: "signature".tr(),
      ),
      contentBuilder: () {
        return Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          color: AppColors.backgroundSurface(),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: Dimensions.size100 * 5,
            ),
            width: double.infinity,
            height: MediaQuery.sizeOf(context).width,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest(),
              border: Border.symmetric(
                vertical: MediaQuery.sizeOf(context).width >= 500 ? BorderSide.none : BorderSide(color: AppColors.outline()),
                horizontal: BorderSide(color: AppColors.outline()),
              ),
            ),
            child: SfSignaturePad(
              key: gkSignaturePadState,
              strokeColor: AppColors.onSurface(),
              backgroundColor: AppColors.surfaceContainerLowest(),
            ),
          ),
        );
      },
      bottomNavigationBar: BaseBottomBar(
        children: [
          FilledButton.icon(
            onPressed: () async {
              ByteData? byteData;

              if (gkSignaturePadState.currentState != null) {
                ui.Image image = await gkSignaturePadState.currentState!.toImage();

                byteData = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
              }

              if (BaseSettings.navigatorType == BaseNavigatorType.legacy) {
                Navigators.pop(result: byteData?.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
              } else {
                context.pop(byteData?.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
              }
            },
            icon: Icon(Icons.save),
            label: Text("save".tr().toUpperCase()),
          ),
        ],
      ),
    );
  }
}
