// file_service.dart
// ✅ Bridge الوسيط
//
// الملفات المطلوبة في نفس الـ directory:
//   file_service_web.dart    ← dart:html (web)
//   file_service_mobile.dart ← path_provider + open_filex (mobile)
//   file_service_stub.dart   ← fallback
//
// pubspec.yaml:
//   printing: ^5.x.x
//   path_provider: ^2.1.2
//   open_filex: ^1.3.2

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'file_service_stub.dart'
    if (dart.library.html) 'file_service_web.dart'
    if (dart.library.io)   'file_service_mobile.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  /// نفس الـ API القديمة بالظبط
  Future<void> saveAndOpen({
    required List<int> bytes,
    required String fileName,
    required BuildContext ctx,
  }) async {
    try {
      await platformDownload(bytes: bytes, fileName: fileName, ctx: ctx);
    } catch (_) {
      // Fallback
      try {
        if (kIsWeb) {
          await Printing.layoutPdf(
            onLayout: (_) async => Uint8List.fromList(bytes),
            name: fileName,
          );
        } else {
          await Printing.sharePdf(
            bytes: Uint8List.fromList(bytes),
            filename: fileName,
          );
        }
      } catch (e2) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            backgroundColor: const Color(0xFF0A1628),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFFE53E3E)),
            ),
            duration: const Duration(seconds: 4),
            content: Row(children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFFE53E3E), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Save failed: $e2',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12)),
              ),
            ]),
          ));
        }
      }
    }
  }
}