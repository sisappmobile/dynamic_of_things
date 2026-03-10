// ignore_for_file: avoid_escaping_inner_quotes

import "dart:convert";

class DynamicFormTexts {
  static final RegExp _base64Pattern = RegExp(r"^[A-Za-z0-9+/=_\-\s]+$");
  static final RegExp _htmlPattern = RegExp(
    r"</?(?:html|head|body|div|span|p|br|table|thead|tbody|tr|td|th|ul|ol|li|figure|figcaption|strong|em|b|i|u|h[1-6])\b",
    caseSensitive: false,
  );
  static final RegExp _allTagsPattern = RegExp(r"<[^>]+>", dotAll: true);

  static String resolve(dynamic value) {
    if (value == null) {
      return "";
    }

    if (value is! String) {
      return value.toString();
    }

    return _decodeHtmlBase64(value);
  }

  static String _decodeHtmlBase64(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return value;
    }

    final String? decoded = _tryDecodeBase64(trimmed);

    if (decoded == null || !_looksLikeHtml(decoded)) {
      return value;
    }

    final String text = _htmlToText(decoded);
    return text.isEmpty ? decoded : text;
  }

  static String? _tryDecodeBase64(String value) {
    if (!_mightBeBase64(value)) {
      return null;
    }

    try {
      final List<int> bytes = base64.decode(base64.normalize(value));
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  static bool _mightBeBase64(String value) {
    if (value.length < 16 || value.length % 4 == 1) {
      return false;
    }

    return _base64Pattern.hasMatch(value);
  }

  static bool _looksLikeHtml(String value) {
    return _htmlPattern.hasMatch(value);
  }

  static String _htmlToText(String html) {
    return html
        .replaceAll(RegExp(r"<br\s*/?>", caseSensitive: false), "\n")
        .replaceAll(RegExp(r"</(?:p|div|section|article|header|footer|ul|ol|li|h[1-6])>", caseSensitive: false), "\n")
        .replaceAll(RegExp(r"</(?:td|th)>", caseSensitive: false), " | ")
        .replaceAll(RegExp(r"</tr>", caseSensitive: false), "\n")
        .replaceAll(_allTagsPattern, " ")
        .replaceAll("&nbsp;", " ")
        .replaceAll("&amp;", "&")
        .replaceAll("&lt;", "<")
        .replaceAll("&gt;", ">")
        .replaceAll("&quot;", "\"")
        .replaceAll("&#39;", "'")
        .replaceAll(RegExp(r"[ \t]*\|[ \t]*"), " | ")
        .replaceAll(RegExp(r"[ \t]+\n"), "\n")
        .replaceAll(RegExp(r"\n{3,}"), "\n\n")
        .replaceAll(RegExp(r"[ \t]{2,}"), " ")
        .trim();
  }
}
