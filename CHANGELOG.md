## 1.1.2

- For release, on Android, remove the `compileOnly` dependency on `flutter_embedding_debug`, as well as the `maven { url 'https://storage.googleapis.com/download.flutter.io' }` repository.
- Bump Flutter and Dart SDK versions to the latest stable versions.

## 1.1.1

- Changed iOS deployment target from 26.0 to 15.0 in `Podfile`, `project.pbxproj`, and `simplest_document_scanner.podspec` for broader compatibility.

## 1.1.0

- iOS: fix Swift 6 strict concurrency warnings for `FlutterResult` closure and `VNDocumentCameraViewControllerDelegate` conformance.

## 1.0.1

- iOS: annotate `VNDocumentCameraViewControllerDelegate` methods with `@MainActor` to satisfy Swift 6 strict concurrency checking and fix the `ConformanceIsolation` build error.

## 1.0.0

- Breaking: replace the legacy JPEG-only API with `DocumentScannerOptions`, `ScannedDocument`, and `DocumentScanException`.
- Android: align with ML Kit Document Scanner result formats (JPEG/PDF), robust URI handling, structured error codes, and lifecycle-safe `ActivityResult` usage.
- iOS: modern VisionKit pipeline with configurable JPEG quality, optional PDF generation, Swift 6 readiness, and error reporting.
- Dart: add platform interface scaffolding, legacy helper, and unit tests.
- Tooling: add Robolectric tests for the plugin, XCTest coverage for request parsing, and refreshed documentation.

## 0.0.1

* Initial release of the library, supporting default MLKit and VisionKit behavior on Android and iOS respectively.
* Creation of basic configuration steps in the README.md.
