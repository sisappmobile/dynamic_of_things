// ignore_for_file: constant_identifier_names

import "package:base/base.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";
import "package:mobile_scanner/mobile_scanner.dart";

enum ScannerWordCase {
  UPPER_CASE,
  LOWER_CASE,
  NORMAL_CASE;

  String spell() {
    if (this == ScannerWordCase.NORMAL_CASE) {
      return "Normal Case";
    } else if (this == ScannerWordCase.UPPER_CASE) {
      return "UPPER CASE";
    } else {
      return "lower case";
    }
  }
}

class BarcodeScannerPage extends StatefulWidget {
  final void Function(String data) onSuccess;
  final List<BarcodeFormat>? formats;

  const BarcodeScannerPage({
    required this.onSuccess,
    this.formats,
    super.key,
  });

  @override
  BarcodeScannerPageState createState() => BarcodeScannerPageState();
}

class BarcodeScannerPageState extends State<BarcodeScannerPage> {
  late MobileScannerController cameraController;

  ScannerWordCase scannerWordCase = ScannerWordCase.NORMAL_CASE;

  @override
  void initState() {
    super.initState();

    cameraController = MobileScannerController(formats: widget.formats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            Text("barcode_scanner_title".tr()),
            Text(
              scannerWordCase.spell(),
              style: TextStyle(
                fontSize: Dimensions.text14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              cameraController.stop();

              List<Barcode> barcodes = capture.barcodes;

              if (barcodes.isNotEmpty) {
                String data = barcodes[0].rawValue ?? "";

                if (scannerWordCase == ScannerWordCase.UPPER_CASE) {
                  data = data.toUpperCase();
                } else if (scannerWordCase == ScannerWordCase.LOWER_CASE) {
                  data = data.toLowerCase();
                }

                widget.onSuccess(data);

                Navigators.pop();

                BaseOverlays.success(message: "barcode_scanner_success_dialog".tr());
              }
            },
          ),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: EdgeInsets.only(
                top: Dimensions.size10,
                right: Dimensions.size10,
              ),
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: 1,
                    onPressed: () {
                      if (scannerWordCase == ScannerWordCase.NORMAL_CASE) {
                        scannerWordCase = ScannerWordCase.UPPER_CASE;
                      } else if (scannerWordCase == ScannerWordCase.UPPER_CASE) {
                        scannerWordCase = ScannerWordCase.LOWER_CASE;
                      } else {
                        scannerWordCase = ScannerWordCase.NORMAL_CASE;
                      }

                      setState(() {});
                    },
                    mini: true,
                    child: const Icon(Symbols.match_case),
                  ),
                  FloatingActionButton(
                    heroTag: 2,
                    onPressed: () => cameraController.toggleTorch(),
                    mini: true,
                    child: ValueListenableBuilder(
                      valueListenable: cameraController.torchState,
                      builder: (context, state, child) {
                        if (state == TorchState.off) {
                          return const Icon(Icons.flash_off);
                        } else {
                          return const Icon(Icons.flash_on);
                        }
                      },
                    ),
                  ),
                  FloatingActionButton(
                    heroTag: 3,
                    onPressed: () => cameraController.switchCamera(),
                    mini: true,
                    child: ValueListenableBuilder(
                      valueListenable: cameraController.cameraFacingState,
                      builder: (context, state, child) {
                        if (state == CameraFacing.front) {
                          return const Icon(Icons.camera_front);
                        } else {
                          return const Icon(Icons.camera_rear);
                        }
                      },
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
