# simplest_document_scanner

Simplest document scanning plugin powered by VisionKit on iOS and MLKit on Android.

## Usage

Once the package is added, you'll need to perform the following changes:

1. Your `MainActivity.kt` should extend `FlutterFragmentActivity`:
```kt
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```

2. Make sure you have necessary 