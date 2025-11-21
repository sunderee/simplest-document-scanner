import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simplest_document_scanner/simplest_document_scanner.dart';

class _FakeScannerPlatform extends SimplestDocumentScannerPlatform {
  DocumentScannerOptions? lastOptions;
  ScannedDocument? nextResult;

  @override
  Future<ScannedDocument?> scanDocuments(DocumentScannerOptions options) async {
    lastOptions = options;
    return nextResult;
  }
}

void main() {
  final defaultPlatform = SimplestDocumentScannerPlatform.instance;

  tearDown(() {
    SimplestDocumentScannerPlatform.instance = defaultPlatform;
  });

  group('DocumentScannerOptions', () {
    test('serializes to json with nested platform options', () {
      const options = DocumentScannerOptions(
        maxPages: 3,
        returnJpegs: true,
        returnPdf: true,
        jpegQuality: 0.95,
        allowGalleryImport: false,
        android: AndroidScannerOptions(
          scannerMode: DocumentScannerMode.baseWithFilter,
        ),
        ios: IosScannerOptions(enforceMaxPageLimit: false),
      );

      final json = options.toJson();
      expect(json['maxPages'], 3);
      expect(json['returnPdf'], true);
      expect(
        (json['android'] as Map<String, dynamic>)['scannerMode'],
        DocumentScannerMode.baseWithFilter.platformValue,
      );
      expect(
        (json['ios'] as Map<String, dynamic>)['enforceMaxPageLimit'],
        false,
      );
    });
  });

  group('ScannedDocument', () {
    test('parses platform response map', () {
      final pageBytes = Uint8List.fromList([1, 2, 3]);
      final pdfBytes = Uint8List.fromList([9, 8, 7]);
      final document = ScannedDocument.fromPlatformResponse({
        'pages': [
          {'index': 0, 'bytes': pageBytes},
        ],
        'pdf': pdfBytes,
      });

      expect(document.pages.length, 1);
      expect(document.pages.first.index, 0);
      expect(document.pages.first.bytes, pageBytes);
      expect(document.pdfBytes, pdfBytes);
    });
  });

  group('DocumentScanException', () {
    test('maps platform codes to reasons', () {
      final exception = DocumentScanException.fromPlatformException(
        PlatformException(
          code: 'DOCUMENT_SCANNER_UNSUPPORTED',
          message: 'Unsupported',
        ),
      );

      expect(exception.reason, DocumentScanExceptionReason.unsupported);
    });
  });

  group('SimplestDocumentScanner', () {
    test('legacyScanDocuments returns jpeg list when supported', () async {
      final fakePlatform = _FakeScannerPlatform()
        ..nextResult = ScannedDocument(
          pages: [
            ScannedPage(index: 0, bytes: Uint8List.fromList([1, 2, 3])),
            ScannedPage(index: 1, bytes: Uint8List.fromList([4, 5, 6])),
          ],
        );
      SimplestDocumentScannerPlatform.instance = fakePlatform;

      final images = await SimplestDocumentScanner.legacyScanDocuments();

      expect(images, isNotNull);
      expect(images, hasLength(2));
      expect(fakePlatform.lastOptions?.returnJpegs, true);
      expect(fakePlatform.lastOptions?.returnPdf, false);
    });
  });
}
