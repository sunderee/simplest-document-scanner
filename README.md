# simplest_document_scanner

An opinionated Flutter plugin that exposes the latest ML Kit Document Scanner (Android) and VisionKit document flow (iOS). The new 1.x API returns structured metadata, supports concurrent-safe invocations, and lets you request JPEG, PDF, or both outputs with platform-specific tuning.

## Features

- Cross-platform document capture with native scanners (VisionKit + ML Kit)
- Configurable outputs: JPEG pages, consolidated PDF, or both
- Page limits, gallery import toggles, and ML Kit scanner mode presets
- Unified `DocumentScanException` surface with reason codes
- Legacy helper (`legacyScanDocuments`) to ease migration from the v0 API

## Platform Requirements

- **Android**: API 31+ with Google Play Services (ML Kit document scanner)
- **iOS**: VisionKit-capable devices (iOS 16+ recommended)
- **Flutter**: >= 3.38.1
- **Dart**: >= 3.10.0

## Installation

```yaml
dependencies:
  simplest_document_scanner: ^1.0.0
```

```bash
flutter pub get
```

## Setup

### Android

1. Ensure `MainActivity` extends `FlutterFragmentActivity`.
2. Add ML Kit metadata to `AndroidManifest.xml`:

```xml
    <meta-data
        android:name="com.google.android.gms.version"
        android:value="@integer/google_play_services_version" />
    <meta-data
        android:name="com.google.mlkit.vision.DEPENDENCIES"
        android:value="document_ui" />
```

3. Camera permissions are handled by the ML Kit UI, but you are responsible for declaring them in your manifest.

### iOS

1. Add a camera usage description to `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan documents.</string>
```

2. No other code changes are required; VisionKit UI is wired automatically. The Podspec targets Swift 6 and a VisionKit-capable iOS version.

## Usage

### Basic scan

```dart
import 'package:simplest_document_scanner/simplest_document_scanner.dart';

Future<void> scanDocuments() async {
  try {
    final document = await SimplestDocumentScanner.scanDocuments(
      options: const DocumentScannerOptions(
        maxPages: 8,
        returnJpegs: true,
        returnPdf: false,
        android: AndroidScannerOptions(
          scannerMode: DocumentScannerMode.full,
        ),
      ),
    );

    if (document == null) {
      print('User cancelled the scan.');
      return;
    }

    for (final page in document.pages) {
      // Each page contains index + Uint8List bytes
      processPage(page.bytes);
    }

    if (document.hasPdf) {
      savePdf(document.pdfBytes!);
    }
  } on DocumentScanException catch (error) {
    handleScanFailure(error.reason, error.message);
  }
}
```

### Advanced configuration

```dart
final options = DocumentScannerOptions(
  maxPages: 4,
  returnJpegs: true,
  returnPdf: true,
  allowGalleryImport: false,
  android: const AndroidScannerOptions(
    scannerMode: DocumentScannerMode.baseWithFilter,
  ),
  ios: const IosScannerOptions(
    enforceMaxPageLimit: true,
  ),
);

final document = await SimplestDocumentScanner.scanDocuments(options: options);
```

### Legacy helper

Still need the v0 behavior? Use:

```dart
final images = await SimplestDocumentScanner.legacyScanDocuments();
```

This forces JPEG-only output and returns `List<Uint8List>?`.

## Public API overview

### `DocumentScannerOptions`

| Property | Type | Default | Notes |
| --- | --- | --- | --- |
| `maxPages` | `int?` | `null` | Positive limit, applied on both platforms |
| `returnJpegs` | `bool` | `true` | Controls per-page JPEG payloads |
| `returnPdf` | `bool` | `false` | Requests consolidated PDF output |
| `jpegQuality` | `double` | `0.9` | Applied where platforms support re-encoding |
| `allowGalleryImport` | `bool` | `true` | Android-only toggle |
| `android` | `AndroidScannerOptions` | `DocumentScannerMode.full` | Maps to ML Kit scanner modes |
| `ios` | `IosScannerOptions` | `enforceMaxPageLimit: true` | Allows post-scan trimming |

### Results

`ScannedDocument` contains:

- `pages`: `List<ScannedPage>` (index + `Uint8List bytes`)
- `pdfBytes`: optional `Uint8List`
- Convenience getter `hasPdf`

### Errors

All failures throw `DocumentScanException`, which surfaces:

- `reason`: `DocumentScanExceptionReason`
- `message`, `code`, `details`

Reasons include `unsupported`, `inProgress`, `launcherError`, `ioError`, `platformError`, and `unknown`.

## Error codes surfaced from native layers

| Platform | Code | Meaning |
| --- | --- | --- |
| Both | `DOCUMENT_SCANNER_UNSUPPORTED` | Device does not meet ML Kit/VisionKit requirements |
| Both | `SCAN_IN_PROGRESS` | Another scan is running |
| Android | `NO_ACTIVITY`, `ACTIVITY_DETACHED` | Plugin lost its hosting Activity |
| Android | `SCANNER_ERROR`, `NO_DATA`, `FILE_READ_ERROR` | ML Kit start/result issues |
| Android | `SCAN_FAILED` | Activity returned non-success / non-cancel code |
| iOS | `SCANNER_PRESENTATION_FAILED` | Unable to present VNDocumentCamera UI |
| iOS | `IMAGE_CONVERSION_FAILED`, `PDF_GENERATION_FAILED`, `NO_IMAGES_CAPTURED` | VisionKit capture issues |

## Testing

- **Flutter/Dart**: `flutter test`
- **Android (Robolectric)**: `./gradlew testDebugUnitTest`
- **iOS XCTest**: `pod lib lint --tests` (the Podspec defines a `Tests` spec)

The repository ships with unit tests that cover Dart serialization, Android request parsing, and Swift request validation.

## License

See [LICENSE](LICENSE).
