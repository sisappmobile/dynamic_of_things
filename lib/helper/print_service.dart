import "dart:io";

import "package:dynamic_of_things/enumeration/constant.dart";
import "package:dynamic_of_things/helper/dynamic_forms.dart";
import "package:dynamic_of_things/helper/preferences.dart";
import "package:dynamic_of_things/model/print_layout.dart";
import "package:esc_pos_utils_plus/esc_pos_utils_plus.dart";
import "package:print_bluetooth_thermal/print_bluetooth_thermal.dart";

enum PrinterConnectionType { bluetooth, network }

enum PrinterPaperWidth { mm58, mm80 }

class PrinterException implements Exception {
  final String message;

  const PrinterException(this.message);

  @override
  String toString() => message;
}

// Read-only mirror of visitqu's PrinterSettings (lib/service/printer_service.dart)
// - same SharedPreferenceKey.PRINTER_* identifiers (see enumeration/constant.dart),
// so load() resolves to whatever the host app already configured. This
// package deliberately has no save()/settings UI of its own: printing here
// assumes the printer was already set up elsewhere (e.g. visitqu's own
// printer settings page, when both are compiled into the same app).
class PrinterSettings {
  final PrinterConnectionType connectionType;
  final String? bluetoothName;
  final String? bluetoothAddress;
  final String? networkIp;
  final int networkPort;
  final PrinterPaperWidth paperWidth;

  const PrinterSettings({
    required this.connectionType,
    this.bluetoothName,
    this.bluetoothAddress,
    this.networkIp,
    this.networkPort = 9100,
    this.paperWidth = PrinterPaperWidth.mm58,
  });

  bool get isConfigured {
    if (connectionType == PrinterConnectionType.bluetooth) {
      return (bluetoothAddress ?? "").trim().isNotEmpty;
    }

    return (networkIp ?? "").trim().isNotEmpty;
  }

  static PrinterSettings load() {
    final Preferences preferences = Preferences.getInstance();
    final String typeName = preferences.getString(
          SharedPreferenceKey.PRINTER_CONNECTION_TYPE,
        ) ??
        PrinterConnectionType.network.name;

    return PrinterSettings(
      connectionType: PrinterConnectionType.values.firstWhere(
        (PrinterConnectionType type) => type.name == typeName,
        orElse: () => PrinterConnectionType.network,
      ),
      bluetoothName:
          preferences.getString(SharedPreferenceKey.PRINTER_BLUETOOTH_NAME),
      bluetoothAddress: preferences
          .getString(SharedPreferenceKey.PRINTER_BLUETOOTH_ADDRESS),
      networkIp:
          preferences.getString(SharedPreferenceKey.PRINTER_NETWORK_IP),
      networkPort:
          preferences.getInt(SharedPreferenceKey.PRINTER_NETWORK_PORT) ??
              9100,
      paperWidth: PrinterPaperWidth.values.firstWhere(
        (PrinterPaperWidth width) =>
            width.name ==
            (preferences.getString(SharedPreferenceKey.PRINTER_PAPER_WIDTH) ??
                PrinterPaperWidth.mm58.name),
        orElse: () => PrinterPaperWidth.mm58,
      ),
    );
  }
}

// Transport only - ported near-verbatim from visitqu's PrinterService, which
// has no visitqu-specific coupling at all (just PrinterSettings + the two
// packages). Receipt CONTENT building is PrintLayoutRenderer below, not
// ReceiptFormatter (that class is tied to visitqu's own sales-report model
// types and isn't reusable as-is).
class PrinterService {
  static const Duration networkTimeout = Duration(seconds: 5);

  static const Duration _bluetoothDrainDelay = Duration(milliseconds: 2000);

  static Future<void> printBytes(List<int> bytes) async {
    final PrinterSettings settings = PrinterSettings.load();

    if (!settings.isConfigured) {
      throw const PrinterException("Printer belum dikonfigurasi.");
    }

    if (settings.connectionType == PrinterConnectionType.bluetooth) {
      await _printViaBluetooth(settings, bytes);
    } else {
      await _printViaNetwork(settings, bytes);
    }
  }

  static Future<void> _printViaBluetooth(
    PrinterSettings settings,
    List<int> bytes,
  ) async {
    final bool connected = await PrintBluetoothThermal.connect(
      macPrinterAddress: settings.bluetoothAddress!,
    );

    if (!connected) {
      throw const PrinterException("Gagal terhubung ke printer Bluetooth.");
    }

    try {
      final bool written = await PrintBluetoothThermal.writeBytes(bytes);

      if (!written) {
        throw const PrinterException("Gagal mengirim data ke printer.");
      }

      await Future.delayed(_bluetoothDrainDelay);
    } finally {
      await PrintBluetoothThermal.disconnect;
    }
  }

  static Future<void> _printViaNetwork(
    PrinterSettings settings,
    List<int> bytes,
  ) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        settings.networkIp,
        settings.networkPort,
        timeout: networkTimeout,
      );
      socket.add(bytes);
      await socket.flush();
    } catch (error) {
      throw PrinterException("Gagal terhubung ke printer jaringan: $error");
    } finally {
      await socket?.close();
    }
  }
}

// Compiles a PrintLayoutTemplate (fetched from
// GET v2/dynamic-forms/{id}/print-layouts/{layoutId}) + a record's field
// data into ESC/POS bytes. Deliberately a thin, direct mapping onto
// esc_pos_utils_plus's own primitives (text/row/hr/feed/cut) - the same
// small vocabulary the admin builder (dmsretail's customformprintlayout.jsp)
// is constrained to, so what the admin designs is exactly what gets
// printed, with no lossy translation step in between.
class PrintLayoutRenderer {
  static Future<List<int>> render({
    required PrintLayoutTemplate template,
    required Map<String, dynamic> data,
  }) async {
    final CapabilityProfile profile = await CapabilityProfile.load();
    // Paper width is a printer setting, not a per-template one - a template
    // is meant to be reusable across whatever paper width the host app's
    // printer is actually configured for (PrinterSettings.load()), not fixed
    // at design time in the web builder.
    final PaperSize paperSize =
        PrinterSettings.load().paperWidth == PrinterPaperWidth.mm80
            ? PaperSize.mm80
            : PaperSize.mm58;
    final Generator generator = Generator(paperSize, profile);

    List<int> bytes = [];

    bytes += generator.reset();

    for (PrintLayoutElement element in template.elements) {
      if (element.type == "HR") {
        bytes += generator.hr();
      } else if (element.type == "FEED") {
        bytes += generator.feed(element.feedLines ?? 1);
      } else {
        bytes += _renderRow(generator, element, data);
      }
    }

    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  static List<int> _renderRow(
    Generator generator,
    PrintLayoutElement element,
    Map<String, dynamic> data,
  ) {
    if (element.cells.isEmpty) {
      return [];
    }

    if (element.cells.length == 1) {
      final PrintLayoutCell cell = element.cells.first;

      return generator.text(
        _resolveCellText(cell, data),
        styles: _stylesFor(cell),
      );
    }

    return generator.row(
      _normalizedWidths(element.cells.map((cell) => cell.width).toList())
          .asMap()
          .entries
          .map(
            (entry) => PosColumn(
              text: _resolveCellText(element.cells[entry.key], data),
              width: entry.value,
              styles: _stylesFor(element.cells[entry.key]),
            ),
          )
          .toList(),
    );
  }

  // generator.row() throws if a row's column widths don't sum to EXACTLY
  // 12 (not just each individually being 1-12) - a layout an admin
  // misconfigures (or edits directly against the DB) would otherwise crash
  // the whole print operation. Proportionally rescale instead, so a
  // misconfigured layout still prints (with slightly off proportions)
  // rather than failing outright; any rounding remainder goes to the last
  // column so the total always lands on exactly 12.
  static List<int> _normalizedWidths(List<int> rawWidths) {
    final List<int> clamped = rawWidths.map((w) => w.clamp(1, 12)).toList();
    final int total = clamped.fold(0, (sum, w) => sum + w);

    if (total == 12) {
      return clamped;
    }

    final List<int> scaled = clamped
        .map((w) => ((w / total) * 12).round().clamp(1, 12))
        .toList();

    // Round-robin the rounding remainder one unit at a time across whichever
    // columns still have room, respecting the same 1-12 clamp per column,
    // until the total lands on exactly 12 (or, if there are more than 12
    // cells - already a nonsensical layout for a receipt row - it does its
    // best within the loop bound below rather than looping forever).
    int diff = 12 - scaled.fold(0, (sum, w) => sum + w);
    int i = 0;

    while (diff != 0 && i < scaled.length * 12) {
      final int idx = i % scaled.length;

      if (diff > 0 && scaled[idx] < 12) {
        scaled[idx]++;
        diff--;
      } else if (diff < 0 && scaled[idx] > 1) {
        scaled[idx]--;
        diff++;
      }

      i++;
    }

    return scaled;
  }

  static PosStyles _stylesFor(PrintLayoutCell cell) {
    final PosTextSize size =
        cell.size == "DOUBLE" ? PosTextSize.size2 : PosTextSize.size1;

    return PosStyles(
      align: switch (cell.align) {
        "CENTER" => PosAlign.center,
        "RIGHT" => PosAlign.right,
        _ => PosAlign.left,
      },
      bold: cell.bold,
      height: size,
      width: size,
    );
  }

  static String _resolveCellText(
    PrintLayoutCell cell,
    Map<String, dynamic> data,
  ) {
    if (cell.sourceType != "FIELD" || cell.fieldName == null) {
      return cell.literalText ?? "";
    }

    final dynamic value = data[cell.fieldName];

    if (value == null) {
      return "";
    }

    // Same formatting DynamicForms.spell() already applies everywhere else
    // in the app (currency for NUMERIC, formatted dates, etc.), so a
    // printed field reads the same as it does on screen.
    return DynamicForms.spell(
      type: DynamicForms.dataType(cell.fieldDataType ?? "STRING"),
      value: value,
    );
  }
}
