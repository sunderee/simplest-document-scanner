import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Public entry point for performing document scans.
class SimplestDocumentScanner {
  SimplestDocumentScanner._();

  static SimplestDocumentScannerPlatform get _platform =>
      SimplestDocumentScannerPlatform.instance;

  /// Launches the native document scanner with [options].
  ///
  /// Returns `null` when the user cancels the scan flow.
  /// Throws a [DocumentScanException] when the underlying platform fails.
  static Future<ScannedDocument?> scanDocuments({
    DocumentScannerOptions options = const DocumentScannerOptions(),
  }) {
    return _platform.scanDocuments(options);
  }

  /// Legacy helper that mirrors the v0.x API by returning only JPEG bytes.
  ///
  /// This always forces JPEG output and disables PDF generation, regardless
  /// of the provided [options].
  static Future<List<Uint8List>?> legacyScanDocuments({
    DocumentScannerOptions options = const DocumentScannerOptions(),
  }) async {
    final adjusted = options.copyWith(returnJpegs: true, returnPdf: false);
    final result = await scanDocuments(options: adjusted);
    return result?.pages.map((page) => page.bytes).toList(growable: false);
  }
}

/// Options that control how the native scanners behave.
class DocumentScannerOptions {
  const DocumentScannerOptions({
    this.maxPages,
    this.returnJpegs = true,
    this.returnPdf = false,
    this.jpegQuality = 0.9,
    this.allowGalleryImport = true,
    this.android = const AndroidScannerOptions(),
    this.ios = const IosScannerOptions(),
  }) : assert(maxPages == null || maxPages > 0),
       assert(jpegQuality >= 0 && jpegQuality <= 1),
       assert(
         returnJpegs || returnPdf,
         'At least one output format (JPEG or PDF) must be requested.',
       );

  final int? maxPages;
  final bool returnJpegs;
  final bool returnPdf;
  final double jpegQuality;
  final bool allowGalleryImport;
  final AndroidScannerOptions android;
  final IosScannerOptions ios;

  DocumentScannerOptions copyWith({
    int? maxPages,
    bool? returnJpegs,
    bool? returnPdf,
    double? jpegQuality,
    bool? allowGalleryImport,
    AndroidScannerOptions? android,
    IosScannerOptions? ios,
  }) {
    return DocumentScannerOptions(
      maxPages: maxPages ?? this.maxPages,
      returnJpegs: returnJpegs ?? this.returnJpegs,
      returnPdf: returnPdf ?? this.returnPdf,
      jpegQuality: jpegQuality ?? this.jpegQuality,
      allowGalleryImport: allowGalleryImport ?? this.allowGalleryImport,
      android: android ?? this.android,
      ios: ios ?? this.ios,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'maxPages': maxPages,
      'returnJpegs': returnJpegs,
      'returnPdf': returnPdf,
      'jpegQuality': jpegQuality,
      'allowGalleryImport': allowGalleryImport,
      'android': android.toJson(),
      'ios': ios.toJson(),
    }..removeWhere((_, value) => value == null);
  }
}

/// Android-specific document scanner options.
class AndroidScannerOptions {
  const AndroidScannerOptions({this.scannerMode = DocumentScannerMode.full});

  final DocumentScannerMode scannerMode;

  AndroidScannerOptions copyWith({DocumentScannerMode? scannerMode}) {
    return AndroidScannerOptions(scannerMode: scannerMode ?? this.scannerMode);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'scannerMode': scannerMode.platformValue,
  };
}

/// iOS-specific document scanner options.
class IosScannerOptions {
  const IosScannerOptions({this.enforceMaxPageLimit = true});

  final bool enforceMaxPageLimit;

  IosScannerOptions copyWith({bool? enforceMaxPageLimit}) {
    return IosScannerOptions(
      enforceMaxPageLimit: enforceMaxPageLimit ?? this.enforceMaxPageLimit,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'enforceMaxPageLimit': enforceMaxPageLimit,
  };
}

/// Represents the supported ML Kit scanner modes on Android.
enum DocumentScannerMode { full, baseWithFilter, base }

extension DocumentScannerModeX on DocumentScannerMode {
  int get platformValue {
    switch (this) {
      case DocumentScannerMode.full:
        return 1;
      case DocumentScannerMode.baseWithFilter:
        return 2;
      case DocumentScannerMode.base:
        return 3;
    }
  }
}

/// Output of a completed document scan.
class ScannedDocument {
  const ScannedDocument({required this.pages, this.pdfBytes});

  final List<ScannedPage> pages;
  final Uint8List? pdfBytes;

  bool get hasPdf => pdfBytes != null;

  factory ScannedDocument.fromPlatformResponse(Map<String, dynamic> data) {
    final rawPages = data['pages'] as List<dynamic>? ?? const [];
    final pages = rawPages
        .map(
          (raw) => ScannedPage.fromPlatformResponse(
            Map<String, dynamic>.from(raw as Map),
          ),
        )
        .toList(growable: false);

    final pdf = data['pdf'];
    Uint8List? pdfBytes;
    if (pdf is Uint8List) {
      pdfBytes = pdf;
    }

    return ScannedDocument(pages: pages, pdfBytes: pdfBytes);
  }
}

/// Represents a single page captured by the scanner.
class ScannedPage {
  const ScannedPage({required this.index, required this.bytes});

  final int index;
  final Uint8List bytes;

  factory ScannedPage.fromPlatformResponse(Map<String, dynamic> data) {
    final index = data['index'] as int? ?? 0;
    final bytes = data['bytes'];
    if (bytes is Uint8List) {
      return ScannedPage(index: index, bytes: bytes);
    }

    throw DocumentScanException(
      reason: DocumentScanExceptionReason.platformError,
      message: 'Invalid page payload received from platform.',
      code: 'INVALID_PAGE_PAYLOAD',
      details: data,
    );
  }
}

/// Reason why a document scan failed.
enum DocumentScanExceptionReason {
  unsupported,
  inProgress,
  launcherError,
  ioError,
  platformError,
  unknown,
}

/// Exception thrown when a document scan cannot complete successfully.
class DocumentScanException implements Exception {
  DocumentScanException({
    required this.reason,
    required this.message,
    this.code,
    this.details,
  });

  final DocumentScanExceptionReason reason;
  final String message;
  final String? code;
  final Object? details;

  factory DocumentScanException.fromPlatformException(
    PlatformException exception,
  ) {
    return DocumentScanException(
      reason: _reasonFromPlatformCode(exception.code),
      message: exception.message ?? exception.code,
      code: exception.code,
      details: exception.details,
    );
  }

  @override
  String toString() =>
      'DocumentScanException(reason: $reason, code: $code, message: $message)';
}

DocumentScanExceptionReason _reasonFromPlatformCode(String? code) {
  switch (code) {
    case 'DOCUMENT_SCANNER_UNSUPPORTED':
      return DocumentScanExceptionReason.unsupported;
    case 'SCAN_IN_PROGRESS':
      return DocumentScanExceptionReason.inProgress;
    case 'NO_ACTIVITY':
    case 'ACTIVITY_DETACHED':
    case 'SCANNER_PRESENTATION_FAILED':
      return DocumentScanExceptionReason.launcherError;
    case 'FILE_READ_ERROR':
      return DocumentScanExceptionReason.ioError;
    case 'SCANNER_ERROR':
    case 'PLATFORM_ERROR':
    case 'IMAGE_CONVERSION_FAILED':
    case 'PDF_GENERATION_FAILED':
    case 'NO_IMAGES_CAPTURED':
    case 'INVALID_PAGE_PAYLOAD':
      return DocumentScanExceptionReason.platformError;
    default:
      return DocumentScanExceptionReason.unknown;
  }
}

abstract class SimplestDocumentScannerPlatform extends PlatformInterface {
  SimplestDocumentScannerPlatform() : super(token: _token);

  static final Object _token = Object();
  static SimplestDocumentScannerPlatform _instance =
      MethodChannelSimplestDocumentScanner();

  static SimplestDocumentScannerPlatform get instance => _instance;

  static set instance(SimplestDocumentScannerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<ScannedDocument?> scanDocuments(DocumentScannerOptions options);
}

class MethodChannelSimplestDocumentScanner
    extends SimplestDocumentScannerPlatform {
  static const _channelName = 'simplest_document_scanner';
  static const _methodScanDocuments = 'scanDocuments';

  final MethodChannel _channel = const MethodChannel(_channelName);

  @override
  Future<ScannedDocument?> scanDocuments(DocumentScannerOptions options) async {
    try {
      final response = await _channel.invokeMethod<dynamic>(
        _methodScanDocuments,
        options.toJson(),
      );

      if (response == null) {
        return null;
      }

      if (response is Map<dynamic, dynamic>) {
        final typedMap = Map<String, dynamic>.from(
          response.map(
            (key, value) => MapEntry(key as String, value),
          ),
        );
        return ScannedDocument.fromPlatformResponse(typedMap);
      }

      throw DocumentScanException(
        reason: DocumentScanExceptionReason.platformError,
        message: 'Unexpected response from platform: ${response.runtimeType}',
        code: 'INVALID_RESPONSE_TYPE',
        details: response,
      );
    } on PlatformException catch (exception) {
      throw DocumentScanException.fromPlatformException(exception);
    }
  }
}
