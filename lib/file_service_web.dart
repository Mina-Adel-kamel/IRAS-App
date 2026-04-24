 // file_service_web.dart
// ✅ Web-only — dart:html direct download
// يُستخدم تلقائياً عبر conditional import في file_service.dart

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';

Future<void> platformDownload({
  required List<int> bytes,
  required String fileName,
  required BuildContext ctx,
}) async {
  try {
    final data   = Uint8List.fromList(bytes);
    final blob   = html.Blob([data], 'application/pdf');
    final url    = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href  = url
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body!.append(anchor);
    anchor.click();

    await Future<void>.delayed(const Duration(milliseconds: 300));
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0A1628),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF1A2A3A)),
          ),
          duration: const Duration(seconds: 4),
          content: Row(children: [
            const Icon(Icons.download_done_rounded,
                color: Color(0xFFCAF135), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(fileName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  const Text('Downloaded to your browser Downloads folder',
                      style: TextStyle(
                          color: Color(0xFF6B8299), fontSize: 11)),
                ],
              ),
            ),
          ]),
        ),
      );
    }
  } catch (e) {
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
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
              child: Text('Download failed: $e',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12)),
            ),
          ]),
        ),
      );
    }
    rethrow;
  }
}