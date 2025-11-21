# Contributing to simplest_document_scanner

Thank you for helping improve the plugin! The notes below explain how to collaborate smoothly.

---

## 1. Before you start

1. **Discuss first** – open an issue or start a GitHub discussion for anything non-trivial so we agree on scope.
2. **Pick an issue** – comment to get assigned before you begin to avoid duplicate work.
3. **Stay emoji-free** – keep code/comments/commits plain text only.

---

## 2. Local development

| Platform | Command |
| --- | --- |
| Install Flutter deps | `flutter pub get` (and `cd example && flutter pub get`) |
| Format Dart | `dart format .` (root + `example/` as needed) |
| Analyze Dart | `flutter analyze` |
| Run Dart tests | `flutter test` |
| Android unit tests | `cd android && ./gradlew testDebugUnitTest` |
| iOS unit tests | `cd ios && pod lib lint --tests` (requires Xcode + CocoaPods) |

Additional expectations:

- Android: use Android Studio/Gradle 8.13+, Kotlin 2.2.2+, Java 17.
- iOS: Xcode 16+, Swift 6, CocoaPods 1.15+.
- Keep the repo clean with `git status` before submitting (no extra files).

---

## 3. Coding standards

- **Formatting & linting**
  - Dart/Flutter: follow the repo’s `analysis_options.yaml`.
  - Kotlin/Swift: keep code ASCII-only, idiomatic for the platform.
  - Project-wide linting/formatting via Biome is planned; respect `.editorconfig` if/when it’s added.

- **Architecture**
  - Structure new Dart APIs through the platform interface (`SimplestDocumentScannerPlatform`).
  - Prefer enums/sealed types instead of raw ints for new platform-specific flags.
  - On Android, use ML Kit Document Scanner APIs; on iOS, stick to VisionKit.

- **Error handling**
  - Surface errors as `DocumentScanException` (Dart) with clear `reason` mapping; keep platform error codes in sync.

- **Testing**
  - Add/extend tests whenever functionality or contracts change:
    - Dart unit tests (`test/`)
    - Android Robolectric tests (`android/src/test/...`)
    - iOS XCTest cases (`ios/Tests/`)
  - Example app updates should still run `flutter test` successfully.

---

## 4. Pull request checklist

1. Issue linked or clearly explained in the PR description.
2. Title follows `type: short summary` (e.g., `fix: handle pdf-only scans`).
3. Includes:
   - Code comments where non-obvious
   - Updated docs (`README`, `CHANGELOG`, inline comments, sample app)
   - Tests (or justification why not applicable)
4. CI expectations (manually run before pushing):
   - `flutter test`
   - `cd android && ./gradlew testDebugUnitTest`
   - `cd ios && pod lib lint --tests` (or at least `xcodebuild test` locally if pods aren’t available)

---

## 5. Release notes

If your change affects the public API, add an entry under the next version heading in `CHANGELOG.md`. Use bullet points and mention breaking changes explicitly.

---

## 6. Contact

Questions? Open a GitHub issue or tag @sunderee in the relevant discussion/PR.

Thanks for contributing!
