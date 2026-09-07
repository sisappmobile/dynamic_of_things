/// Mirrors dmsretail's PrintLayoutItem/PrintLayoutTemplate DTOs
/// (v2/dynamic_form/print_layout) exactly. A layout is an ORDERED LIST of
/// print elements (rows) - not a free X/Y canvas, since ESC/POS has no
/// absolute-position capability, only sequential align/bold/size text and a
/// 12-unit column grid (matching esc_pos_utils_plus's PosColumn). See
/// PrintLayoutRenderer (helper/print_service.dart) for how this gets turned
/// into actual ESC/POS bytes.
class PrintLayoutItem {
  final String id;
  final String caption;

  PrintLayoutItem({required this.id, required this.caption});

  factory PrintLayoutItem.fromJson(Map<String, dynamic> json) =>
      PrintLayoutItem(
        id: json["id"] ?? "",
        caption: json["caption"] ?? "",
      );
}

class PrintLayoutTemplate {
  final String id;
  final String caption;
  final List<PrintLayoutElement> elements;

  PrintLayoutTemplate({
    required this.id,
    required this.caption,
    required this.elements,
  });

  factory PrintLayoutTemplate.fromJson(Map<String, dynamic> json) =>
      PrintLayoutTemplate(
        id: json["id"] ?? "",
        caption: json["caption"] ?? "",
        elements: json["elements"] != null
            ? List<PrintLayoutElement>.from(
                json["elements"].map((e) => PrintLayoutElement.fromJson(e)),
              )
            : [],
      );
}

class PrintLayoutElement {
  // "ROW" | "HR" | "FEED" | "DETAIL_ROW"
  final String type;
  final int? feedLines;
  // Only set when type == "DETAIL_ROW" - the key under which the detail
  // form's rows live in HeaderForm.data (data[detailTableName], a
  // List<Map<String, dynamic>>), resolved server-side via
  // CustomFormView.dynamicTableName() so it always matches whatever key
  // HeaderForm itself uses for that DetailForm.
  final String? detailTableName;
  final List<PrintLayoutCell> cells;

  PrintLayoutElement({
    required this.type,
    required this.feedLines,
    required this.cells,
    this.detailTableName,
  });

  factory PrintLayoutElement.fromJson(Map<String, dynamic> json) =>
      PrintLayoutElement(
        type: json["type"] ?? "ROW",
        feedLines: json["feedLines"],
        detailTableName: json["detailTableName"],
        cells: json["cells"] != null
            ? List<PrintLayoutCell>.from(
                json["cells"].map((e) => PrintLayoutCell.fromJson(e)),
              )
            : [],
      );
}

class PrintLayoutCell {
  final int width;
  // "FIELD" | "LITERAL"
  final String sourceType;
  final String? fieldName;
  final String? fieldCaption;
  final String? fieldDataType;
  final String? literalText;
  // "LEFT" | "CENTER" | "RIGHT"
  final String align;
  final bool bold;
  // "NORMAL" | "DOUBLE"
  final String size;

  PrintLayoutCell({
    required this.width,
    required this.sourceType,
    required this.fieldName,
    required this.fieldCaption,
    required this.fieldDataType,
    required this.literalText,
    required this.align,
    required this.bold,
    required this.size,
  });

  factory PrintLayoutCell.fromJson(Map<String, dynamic> json) =>
      PrintLayoutCell(
        width: json["width"] ?? 12,
        sourceType: json["sourceType"] ?? "LITERAL",
        fieldName: json["fieldName"],
        fieldCaption: json["fieldCaption"],
        fieldDataType: json["fieldDataType"],
        literalText: json["literalText"],
        align: json["align"] ?? "LEFT",
        bold: json["bold"] ?? false,
        size: json["size"] ?? "NORMAL",
      );
}
