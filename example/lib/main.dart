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
  Uint8List? _image;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Example'),
          actions: [
            IconButton(
              onPressed: _beginDocumentScanning,
              icon: const Icon(Icons.camera),
            ),
          ],
        ),
        body: _image != null ? Image.memory(_image!) : const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _beginDocumentScanning() async {
    final image = await SimplestDocumentScanner.instance.scanDocuments();
    if (image != null) {
      setState(() => _image = image);
    }
  }
}
