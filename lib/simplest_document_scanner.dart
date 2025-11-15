import 'dart:io';

import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class AndroidOptions {
  final bool galleryImportAllowed;
  final int scannerMode;
  final int? maxNumberOfPages;

  AndroidOptions({
    this.galleryImportAllowed = false,
    this.scannerMode = 1,
    this.maxNumberOfPages,
  });

  Map<String, dynamic> toJson() => {
    'galleryImportAllowed': galleryImportAllowed,
    'scannerMode': scannerMode,
    'maxNumberOfPages': maxNumberOfPages,
  };
}

class SimplestDocumentScanner extends PlatformInterface {
  static const String _channelName = 'simplest_document_scanner';
  static const String _methodScanDocuments = 'scanDocuments';

  static SimplestDocumentScanner? _instance;
  static SimplestDocumentScanner get instance =>
      _instance ??= SimplestDocumentScanner(token: Object());

  final MethodChannel _channel;

  SimplestDocumentScanner({required super.token})
    : _channel = const MethodChannel(_channelName);

  Future<List<Uint8List>?> scanDocuments({
    AndroidOptions? androidOptions,
  }) async {
    final arguments = <String, dynamic>{};
    if (androidOptions != null && Platform.isAndroid) {
      arguments.addAll(androidOptions.toJson());
    }

    final images = await _channel.invokeListMethod<Uint8List>(
      _methodScanDocuments,
      arguments,
    );
    return images?.whereType<Uint8List>().toList();
  }
}
