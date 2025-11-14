import 'package:flutter_test/flutter_test.dart';
import 'package:simplest_document_scanner/simplest_document_scanner.dart';
import 'package:simplest_document_scanner/simplest_document_scanner_platform_interface.dart';
import 'package:simplest_document_scanner/simplest_document_scanner_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSimplestDocumentScannerPlatform
    with MockPlatformInterfaceMixin
    implements SimplestDocumentScannerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SimplestDocumentScannerPlatform initialPlatform = SimplestDocumentScannerPlatform.instance;

  test('$MethodChannelSimplestDocumentScanner is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSimplestDocumentScanner>());
  });

  test('getPlatformVersion', () async {
    SimplestDocumentScanner simplestDocumentScannerPlugin = SimplestDocumentScanner();
    MockSimplestDocumentScannerPlatform fakePlatform = MockSimplestDocumentScannerPlatform();
    SimplestDocumentScannerPlatform.instance = fakePlatform;

    expect(await simplestDocumentScannerPlugin.getPlatformVersion(), '42');
  });
}
