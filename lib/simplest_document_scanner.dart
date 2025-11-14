
import 'simplest_document_scanner_platform_interface.dart';

class SimplestDocumentScanner {
  Future<String?> getPlatformVersion() {
    return SimplestDocumentScannerPlatform.instance.getPlatformVersion();
  }
}
