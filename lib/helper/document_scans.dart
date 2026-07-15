import "dart:io";
import "dart:typed_data";

import "package:cunning_document_scanner/cunning_document_scanner.dart";
import "package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart";
import "package:image/image.dart" as img;
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;

class ScannedPdf {
  final String fileName;
  final Uint8List bytes;
  final int pageCount;
  final String recognizedText;

  const ScannedPdf({
    required this.fileName,
    required this.bytes,
    required this.pageCount,
    required this.recognizedText,
  });
}

class DocumentScans {
  static const int defaultMaxPages = 20;
  static const int defaultMaxImageDimension = 2480;
  static const int defaultImageQuality = 85;

  /// Opens the native Android/iOS document scanner and combines all selected
  /// pages into one upload-ready PDF.
  ///
  /// OCR is best-effort: recognition failures never discard a valid scan. The
  /// recognized text is embedded invisibly in each page and in PDF metadata so
  /// supported PDF readers and server-side indexers can search it.
  static Future<ScannedPdf?> scanToPdf({
    int maxPages = defaultMaxPages,
    bool allowGalleryImport = true,
    bool enableOcr = true,
    int maxImageDimension = defaultMaxImageDimension,
    int imageQuality = defaultImageQuality,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError(
        "Document scanning is only available on Android and iOS.",
      );
    }

    final List<String>? scannedPaths = await CunningDocumentScanner.getPictures(
      noOfPages: maxPages,
      isGalleryImportAllowed: allowGalleryImport,
    );

    if (scannedPaths == null || scannedPaths.isEmpty) {
      return null;
    }

    return createPdfFromImages(
      imagePaths: scannedPaths,
      enableOcr: enableOcr,
      maxImageDimension: maxImageDimension,
      imageQuality: imageQuality,
    );
  }

  /// Converts existing image files into the same optimized, multi-page PDF.
  /// This is public so applications can reuse the PDF pipeline for imported
  /// scans without reopening the scanner UI.
  static Future<ScannedPdf> createPdfFromImages({
    required List<String> imagePaths,
    bool enableOcr = true,
    int maxImageDimension = defaultMaxImageDimension,
    int imageQuality = defaultImageQuality,
    String? fileName,
  }) async {
    if (imagePaths.isEmpty) {
      throw ArgumentError.value(imagePaths, "imagePaths", "Cannot be empty");
    }
    if (maxImageDimension <= 0) {
      throw ArgumentError.value(
        maxImageDimension,
        "maxImageDimension",
        "Must be greater than zero",
      );
    }
    if (imageQuality < 1 || imageQuality > 100) {
      throw ArgumentError.value(
        imageQuality,
        "imageQuality",
        "Must be between 1 and 100",
      );
    }

    final List<String> normalizedPaths =
        imagePaths.map(_normalizeFilePath).toList(growable: false);
    final List<_ScannedPage> pages = [];
    final TextRecognizer? recognizer =
        enableOcr ? TextRecognizer(script: TextRecognitionScript.latin) : null;

    try {
      for (final String path in normalizedPaths) {
        final Uint8List originalBytes = await File(path).readAsBytes();
        final Uint8List optimizedBytes = _optimizeImage(
          originalBytes,
          maxImageDimension: maxImageDimension,
          imageQuality: imageQuality,
        );
        final String recognizedText =
            recognizer == null ? "" : await _recognizeText(recognizer, path);

        pages.add(
          _ScannedPage(
            imageBytes: optimizedBytes,
            recognizedText: _pdfSafeText(recognizedText),
          ),
        );
      }
    } finally {
      if (recognizer != null) {
        try {
          await recognizer.close();
        } catch (_) {
          // Closing OCR resources must not invalidate a successfully built PDF.
        }
      }
    }

    final String allRecognizedText = pages
        .map((_ScannedPage page) => page.recognizedText)
        .where((String text) => text.isNotEmpty)
        .join("\n\n");
    final pw.Document document = pw.Document(
      title: "Scanned document",
      creator: "Dynamic of Things",
      subject: "Document scan",
      keywords: _metadataText(allRecognizedText),
    );

    for (final _ScannedPage page in pages) {
      final pw.MemoryImage image = pw.MemoryImage(page.imageBytes);
      final bool landscape = (image.width ?? 0) > (image.height ?? 0);

      document.addPage(
        pw.Page(
          pageFormat: landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Stack(
            fit: pw.StackFit.expand,
            children: [
              pw.Image(image, fit: pw.BoxFit.contain),
              if (page.recognizedText.isNotEmpty)
                pw.Opacity(
                  opacity: 0,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      page.recognizedText,
                      style: const pw.TextStyle(fontSize: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return ScannedPdf(
      fileName: fileName ?? _defaultFileName(),
      bytes: await document.save(),
      pageCount: pages.length,
      recognizedText: allRecognizedText,
    );
  }

  static Future<String> _recognizeText(
    TextRecognizer recognizer,
    String path,
  ) async {
    try {
      final RecognizedText result = await recognizer.processImage(
        InputImage.fromFilePath(path),
      );
      return result.text;
    } catch (_) {
      return "";
    }
  }

  static Uint8List _optimizeImage(
    Uint8List bytes, {
    required int maxImageDimension,
    required int imageQuality,
  }) {
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException("Unsupported scanned image format");
    }

    img.Image result = img.bakeOrientation(decoded);
    final int largestDimension =
        result.width > result.height ? result.width : result.height;

    if (largestDimension > maxImageDimension) {
      if (result.width >= result.height) {
        result = img.copyResize(
          result,
          width: maxImageDimension,
          interpolation: img.Interpolation.average,
        );
      } else {
        result = img.copyResize(
          result,
          height: maxImageDimension,
          interpolation: img.Interpolation.average,
        );
      }
    }

    return Uint8List.fromList(img.encodeJpg(result, quality: imageQuality));
  }

  static String _normalizeFilePath(String value) {
    if (value.startsWith("file://")) {
      return Uri.parse(value).toFilePath();
    }
    return value;
  }

  static String _pdfSafeText(String value) {
    return value
        .replaceAll(RegExp(r"[^\x09\x0A\x0D\x20-\x7E\xA0-\xFF]"), " ")
        .replaceAll(RegExp(r"[ \t]+"), " ")
        .trim();
  }

  static String? _metadataText(String value) {
    if (value.isEmpty) {
      return null;
    }
    return value.length <= 4000 ? value : value.substring(0, 4000);
  }

  static String _defaultFileName() {
    final DateTime now = DateTime.now();
    String twoDigits(int value) => value.toString().padLeft(2, "0");

    return "scan_${now.year}${twoDigits(now.month)}${twoDigits(now.day)}_"
        "${twoDigits(now.hour)}${twoDigits(now.minute)}${twoDigits(now.second)}.pdf";
  }
}

class _ScannedPage {
  final Uint8List imageBytes;
  final String recognizedText;

  const _ScannedPage({
    required this.imageBytes,
    required this.recognizedText,
  });
}
