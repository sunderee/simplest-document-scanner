import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simplest_document_scanner/simplest_document_scanner_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelSimplestDocumentScanner platform = MethodChannelSimplestDocumentScanner();
  const MethodChannel channel = MethodChannel('simplest_document_scanner');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
