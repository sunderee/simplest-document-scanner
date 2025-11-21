import 'dart:typed_data';

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
  final List<Uint8List> _images = [];
  bool _isScanning = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Example'),
          actions: [
            IconButton(
              onPressed: _isScanning ? null : _beginDocumentScanning,
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
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
              },
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    }

    if (_images.isEmpty) {
      return const Center(child: Text('Tap the camera icon to scan documents'));
    }

    return ListView.builder(
      itemCount: _images.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.memory(_images[index]),
      ),
    );
  }

  Future<void> _beginDocumentScanning() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      final images = await SimplestDocumentScanner.instance.scanDocuments();
      if (images != null && images.isNotEmpty) {
        setState(() {
          _images.clear();
          _images.addAll(images);
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
}
