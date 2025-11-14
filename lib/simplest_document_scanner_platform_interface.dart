import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'simplest_document_scanner_method_channel.dart';

abstract class SimplestDocumentScannerPlatform extends PlatformInterface {
  /// Constructs a SimplestDocumentScannerPlatform.
  SimplestDocumentScannerPlatform() : super(token: _token);

  static final Object _token = Object();

  static SimplestDocumentScannerPlatform _instance = MethodChannelSimplestDocumentScanner();

  /// The default instance of [SimplestDocumentScannerPlatform] to use.
  ///
  /// Defaults to [MethodChannelSimplestDocumentScanner].
  static SimplestDocumentScannerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SimplestDocumentScannerPlatform] when
  /// they register themselves.
  static set instance(SimplestDocumentScannerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
