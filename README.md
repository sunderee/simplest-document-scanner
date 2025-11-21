# simplest_document_scanner

A simple and straightforward document scanning plugin for Flutter, powered by VisionKit on iOS and MLKit on Android.

## Features

- Cross-platform document scanning (iOS and Android)
- Native UI integration using platform-specific document scanners
- Returns scanned images as `Uint8List` (JPEG format)
- Configurable scanner options on Android (scanner mode, gallery import, page limits)
- Simple and easy-to-use API

## Platform Requirements

- **iOS**: iOS 13.0+ (VisionKit)
- **Android**: Android API 31+ (MLKit Document Scanner)
- **Flutter**: >=3.38.1
- **Dart**: >=3.10.0

## Installation

Add `simplest_document_scanner` to your `pubspec.yaml`:

```yaml
dependencies:
  simplest_document_scanner: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Setup

### Android

1. **Update `MainActivity.kt`**: Your `MainActivity` must extend `FlutterFragmentActivity`:

```kotlin
package dev.bizjak.example

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```

2. **Update `AndroidManifest.xml`**: Add the required MLKit metadata:

```xml
<application>
    <!-- ... other configuration ... -->
    
    <meta-data
        android:name="com.google.android.gms.version"
        android:value="@integer/google_play_services_version" />
    
    <meta-data
        android:name="com.google.mlkit.vision.DEPENDENCIES"
        android:value="document_ui" />
</application>
```

3. **Permissions**: The plugin handles camera permissions automatically through the native scanner UI.

### iOS

1. **Add Camera Usage Description**: Add the following to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan documents</string>
```

2. **No additional code changes required**: The plugin automatically integrates with your Flutter app.

## Usage

### Basic Usage

```dart
import 'package:simplest_document_scanner/simplest_document_scanner.dart';

// Scan documents with default settings
final images = await SimplestDocumentScanner.instance.scanDocuments();

if (images != null && images.isNotEmpty) {
  // Process scanned images (List<Uint8List>)
  for (final image in images) {
    // Use the image bytes
    Image.memory(image);
  }
}
```

### Android-Specific Options

```dart
import 'package:simplest_document_scanner/simplest_document_scanner.dart';

final images = await SimplestDocumentScanner.instance.scanDocuments(
  androidOptions: AndroidOptions(
    galleryImportAllowed: true,  // Allow importing from gallery
    scannerMode: 1,               // Scanner mode (see below)
    maxNumberOfPages: 10,         // Limit number of pages (optional)
  ),
);
```

#### Scanner Modes (Android)

- `1` - **FULL**: Full-featured scanner with all MLKit features (default)
- `2` - **BASE_WITH_FILTER**: Base scanner with filtering capabilities
- `3` - **BASE**: Basic scanner mode

### Complete Example

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:simplest_document_scanner/simplest_document_scanner.dart';

class DocumentScannerExample extends StatefulWidget {
  const DocumentScannerExample({super.key});

  @override
  State<DocumentScannerExample> createState() => _DocumentScannerExampleState();
}

class _DocumentScannerExampleState extends State<DocumentScannerExample> {
  final List<Uint8List> _scannedImages = [];
  bool _isScanning = false;
  String? _errorMessage;

  Future<void> _scanDocuments() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      final images = await SimplestDocumentScanner.instance.scanDocuments(
        androidOptions: AndroidOptions(
          galleryImportAllowed: true,
          scannerMode: 1,
        ),
      );

      if (images != null && images.isNotEmpty) {
        setState(() {
          _scannedImages.clear();
          _scannedImages.addAll(images);
          _isScanning = false;
        });
      } else {
        setState(() {
          _isScanning = false;
          _errorMessage = 'No images were scanned';
        });
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Error scanning documents: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Scanner'),
        actions: [
          IconButton(
            onPressed: _isScanning ? null : _scanDocuments,
            icon: _isScanning
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.camera),
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _scannedImages.isEmpty
              ? const Center(child: Text('Tap the camera icon to scan documents'))
              : ListView.builder(
                  itemCount: _scannedImages.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.memory(_scannedImages[index]),
                  ),
                ),
    );
  }
}
```

## API Reference

### `SimplestDocumentScanner`

#### `instance`

Singleton instance of the document scanner.

```dart
SimplestDocumentScanner.instance
```

#### `scanDocuments`

Scans documents using the native scanner UI.

```dart
Future<List<Uint8List>?> scanDocuments({
  AndroidOptions? androidOptions,
})
```

**Parameters:**
- `androidOptions` (optional): Android-specific configuration options. Ignored on iOS.

**Returns:**
- `Future<List<Uint8List>?>`: List of scanned images as JPEG bytes, or `null` if the user cancelled.

**Throws:**
- Platform exceptions if scanning fails (e.g., camera permission denied, scanner not supported).

### `AndroidOptions`

Android-specific configuration for document scanning.

```dart
AndroidOptions({
  bool galleryImportAllowed = false,
  int scannerMode = 1,
  int? maxNumberOfPages,
})
```

**Parameters:**
- `galleryImportAllowed`: Whether to allow importing images from the gallery (default: `false`)
- `scannerMode`: Scanner mode (1 = FULL, 2 = BASE_WITH_FILTER, 3 = BASE) (default: `1`)
- `maxNumberOfPages`: Maximum number of pages to scan (optional, no limit if not specified)

## Error Handling

The plugin may throw `PlatformException` with the following error codes:

### Android

- `NO_ACTIVITY`: No activity is attached to the plugin
- `SCAN_IN_PROGRESS`: Another scan is already in progress
- `INVALID_ARGUMENT`: Invalid argument provided (e.g., invalid scanner mode)
- `SCANNER_ERROR`: Failed to start the document scanner
- `FILE_READ_ERROR`: Failed to read scanned image file
- `NO_DATA`: No data returned from scanner
- `SCAN_FAILED`: Document scanning failed
- `ACTIVITY_DETACHED`: Activity was detached during scan

### iOS

- `DOCUMENT_SCANNER_UNSUPPORTED`: Document scanning is unsupported on this device
- `SCANNER_PRESENTATION_FAILED`: Unable to present the document scanner UI
- `IMAGE_CONVERSION_FAILED`: Captured image could not be converted to JPEG
- `NO_IMAGES_CAPTURED`: No document images were captured

## Notes

- Scanned images are returned as JPEG-encoded `Uint8List` bytes
- On iOS, images are compressed at 90% quality
- The plugin handles camera permissions automatically through the native scanner UI
- Only one scan can be in progress at a time
- On Android, the scanner requires `FlutterFragmentActivity` for proper lifecycle management
- The plugin uses native platform scanners, so the UI and behavior may differ slightly between iOS and Android

## License

See the [LICENSE](LICENSE) file for details.
