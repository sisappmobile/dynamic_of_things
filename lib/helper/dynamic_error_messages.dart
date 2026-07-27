import "dart:async";

import "package:dio/dio.dart";
import "package:easy_localization/easy_localization.dart";
import "package:flutter/foundation.dart";

typedef DynamicErrorMessageResolver = FutureOr<String> Function(
  Object error,
  StackTrace? stackTrace,
);

/// Converts errors raised inside this package into messages that are safe to
/// show in the host application's error overlay.
///
/// A host can register its own resolver to keep error wording and diagnostics
/// centralized. When no resolver is registered, the package preserves the
/// existing generic message and appends a deterministic error code.
class DynamicErrorMessages {
  static DynamicErrorMessageResolver? _resolver;

  static void configure({
    DynamicErrorMessageResolver? resolver,
  }) {
    _resolver = resolver;
  }

  static Future<String> fromException(
    Object error, {
    StackTrace? stackTrace,
  }) async {
    final DynamicErrorMessageResolver? resolver = _resolver;
    if (resolver != null) {
      try {
        final String message = (await resolver(error, stackTrace)).trim();
        if (message.isNotEmpty) {
          return message;
        }
      } catch (resolverError, resolverStackTrace) {
        if (kDebugMode) {
          debugPrint(
            "[DynamicErrorMessages] Error resolver failed: $resolverError",
          );
          debugPrint("$resolverStackTrace");
        }
      }
    }

    final String code = codeForException(error);
    if (kDebugMode) {
      debugPrint("[DynamicErrorMessages] $code $error");
      if (stackTrace != null) {
        debugPrint("$stackTrace");
      }
    }

    return "${"common_something_wrong".tr()} ($code)";
  }

  static String codeForException(Object error) {
    if (error is! DioException) {
      return "E000";
    }

    final int? statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return "E$statusCode";
    }

    if (error.type == DioExceptionType.cancel) {
      return "ECANCEL";
    }

    return stableCode(
      "${error.requestOptions.method}|"
      "${error.requestOptions.uri.path}|"
      "${error.type.name}|"
      "${error.message ?? ""}",
    );
  }

  static String stableCode(String value) {
    int hash = 0x811c9dc5;
    for (final int codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }

    return "E${(hash % 900000) + 100000}";
  }
}
