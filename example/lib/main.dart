import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simplest_document_scanner/simplest_document_scanner.dart';

void main() {
  runApp(const ExampleApplication());
}

final class ExampleApplication extends StatefulWidget {
  const ExampleApplication({super.key});

  @override
  State<ExampleApplication> createState() => _ExampleApplicationState();
}

final class _ExampleApplicationState extends State<ExampleApplication> {
  final List<ScannedPage> _pages = [];

  Uint8List? _pdfBytes;
  bool _isScanning = false;
  String? _errorMessage;

  bool _returnJpegs = true;
  bool _returnPdf = true;
  double _jpegQuality = 0.9;
  bool _allowGalleryImport = true;
  bool _enforceIosLimit = true;
  DocumentScannerMode _androidScannerMode = DocumentScannerMode.full;
  int? _maxPages = 4;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Scanner Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Document Scanner Example'),
          actions: [
            IconButton(
              tooltip: 'Scan documents',
              onPressed: _isScanning ? null : _beginDocumentScanning,
              icon: _isScanning
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.document_scanner_outlined),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildConfigurationCard(),
        const SizedBox(height: 16),
        _buildResultCard(),
        if (_pages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Page previews', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final page in _pages) _buildPagePreview(page),
        ],
      ],
    );
  }

  Widget _buildConfigurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Scan configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Return JPEG pages'),
              subtitle: const Text('Receive Uint8List bytes per page'),
              value: _returnJpegs,
              onChanged: (value) {
                setState(() {
                  _returnJpegs = value;
                  if (!_returnJpegs && !_returnPdf) {
                    _returnPdf = true;
                  }
                });
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Return consolidated PDF'),
              subtitle: const Text('Requires VisionKit or ML Kit PDF output'),
              value: _returnPdf,
              onChanged: (value) {
                setState(() {
                  _returnPdf = value;
                  if (!_returnJpegs && !_returnPdf) {
                    _returnJpegs = true;
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              'JPEG quality ${(_jpegQuality * 100).round()}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _jpegQuality,
              onChanged: (value) {
                setState(() {
                  _jpegQuality = value;
                });
              },
              min: 0.3,
              max: 1,
              divisions: 7,
              label: '${(_jpegQuality * 100).round()}%',
            ),
            const SizedBox(height: 8),
            Text(
              'Maximum pages',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            DropdownButton<int?>(
              value: _maxPages,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: null, child: Text('Unlimited')),
                DropdownMenuItem(value: 1, child: Text('1 page')),
                DropdownMenuItem(value: 2, child: Text('2 pages')),
                DropdownMenuItem(value: 4, child: Text('4 pages')),
                DropdownMenuItem(value: 8, child: Text('8 pages')),
                DropdownMenuItem(value: 12, child: Text('12 pages')),
              ],
              onChanged: (value) => setState(() {
                _maxPages = value;
              }),
            ),
            if (_isAndroid) ...[
              const Divider(height: 24),
              Text(
                'Android (ML Kit)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow gallery import'),
                subtitle: const Text('GmsDocumentScannerOptions.galleryImport'),
                value: _allowGalleryImport,
                onChanged: (value) {
                  setState(() {
                    _allowGalleryImport = value;
                  });
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Scanner mode'),
                subtitle: const Text('Only available on Android'),
                trailing: DropdownButton<DocumentScannerMode>(
                  value: _androidScannerMode,
                  items: DocumentScannerMode.values
                      .map(
                        (mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(mode.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _androidScannerMode = value;
                    });
                  },
                ),
              ),
            ],
            if (_isIOS) ...[
              const Divider(height: 24),
              Text(
                'iOS (VisionKit)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enforce max page limit on device'),
                value: _enforceIosLimit,
                onChanged: (value) {
                  setState(() {
                    _enforceIosLimit = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    if (_errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => setState(() => _errorMessage = null),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isScanning) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Expanded(child: Text('Launching native scanner...')),
            ],
          ),
        ),
      );
    }

    if (_pages.isEmpty && _pdfBytes == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'No scans yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Use the camera button to try different combinations of '
                'JPEG/PDF outputs and platform-specific options.',
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Last scan summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Pages captured: ${_pages.length}'),
            if (_pdfBytes != null) ...[
              const SizedBox(height: 4),
              Text('PDF size: ${_formatBytes(_pdfBytes!.lengthInBytes)}'),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(_returnJpegs ? 'JPEG enabled' : 'JPEG disabled'),
                ),
                Chip(label: Text(_returnPdf ? 'PDF enabled' : 'PDF disabled')),
                if (_maxPages != null)
                  Chip(label: Text('Page limit $_maxPages')),
                if (_isAndroid)
                  Chip(label: Text('Mode ${_androidScannerMode.name}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagePreview(ScannedPage page) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text('Page ${page.index + 1}'),
            subtitle: Text(_formatBytes(page.bytes.length)),
          ),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Image.memory(page.bytes, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  Future<void> _beginDocumentScanning() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      final options = DocumentScannerOptions(
        maxPages: _maxPages,
        returnJpegs: _returnJpegs,
        returnPdf: _returnPdf,
        jpegQuality: _jpegQuality,
        allowGalleryImport: _allowGalleryImport,
        android: AndroidScannerOptions(scannerMode: _androidScannerMode),
        ios: IosScannerOptions(enforceMaxPageLimit: _enforceIosLimit),
      );

      final document = await SimplestDocumentScanner.scanDocuments(
        options: options,
      );

      if (document == null) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'Document scanning was cancelled.';
        });
        return;
      }

      if (document.pages.isEmpty && !document.hasPdf) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'No content was captured.';
        });
        return;
      }

      setState(() {
        _pages
          ..clear()
          ..addAll(document.pages);
        _pdfBytes = document.pdfBytes;
        _isScanning = false;
      });
    } on DocumentScanException catch (error) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Scan failed (${error.reason.name}): ${error.message}';
      });
    } catch (error) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Unexpected error: $error';
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}
