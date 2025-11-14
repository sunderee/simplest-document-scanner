import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class SimplestDocumentScanner extends PlatformInterface {
  static const String _channelName = 'simplest_document_scanner';
  static const String _methodScanDocuments = 'scanDocuments';

  static SimplestDocumentScanner? _instance;
  static SimplestDocumentScanner get instance =>
      _instance ??= SimplestDocumentScanner(token: Object());

  final MethodChannel _channel;

  SimplestDocumentScanner({required super.token})
    : _channel = const MethodChannel(_channelName);

  Future<List<Uint8List>?> scanDocuments() async {
    final images = await _channel.invokeListMethod<Uint8List>(
      _methodScanDocuments,
    );
    return images?.whereType<Uint8List>().toList();
  }
}
