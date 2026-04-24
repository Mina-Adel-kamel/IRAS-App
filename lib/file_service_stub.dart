// file_service_stub.dart
// ✅ Stub — fallback for testing / unsupported platforms
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

Future<void> platformDownload({
  required List<int> bytes,
  required String fileName,
  required BuildContext ctx,
}) async {
  await Printing.sharePdf(
    bytes: Uint8List.fromList(bytes),
    filename: fileName,
  );
}