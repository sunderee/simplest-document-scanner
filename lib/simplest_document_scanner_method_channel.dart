import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'simplest_document_scanner_platform_interface.dart';

/// An implementation of [SimplestDocumentScannerPlatform] that uses method channels.
class MethodChannelSimplestDocumentScanner extends SimplestDocumentScannerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('simplest_document_scanner');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
