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
        body: _images.isEmpty
            ? const SizedBox.shrink()
            : ListView.builder(
                itemCount: _images.length,
                itemBuilder: (context, index) => Image.memory(_images[index]),
              ),
      ),
    );
  }

  Future<void> _beginDocumentScanning() async {
    final images = await SimplestDocumentScanner.instance.scanDocuments();
    if (images != null) {
      setState(() {
        _images.clear();
        _images.addAll(images);
      });
    }
  }
}
