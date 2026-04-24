// file_service_mobile.dart
// ✅ Mobile-only — path_provider + open_filex
// يُستخدم تلقائياً عبر conditional import في file_service.dart
//
// pubspec.yaml:
//   path_provider: ^2.1.2
//   open_filex: ^1.3.2

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

Future<void> platformDownload({
  required List<int> bytes,
  required String fileName,
  required BuildContext ctx,
}) async {
  Directory? dir;

  if (Platform.isAndroid) {
    try {
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } catch (_) {
      dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    }
  } else if (Platform.isIOS) {
    dir = await getApplicationDocumentsDirectory();
  } else {
    dir = await getApplicationDocumentsDirectory();
  }

  final filePath = '${dir!.path}/$fileName';
  final file     = File(filePath);
  await file.writeAsBytes(Uint8List.fromList(bytes));

  final result  = await OpenFilex.open(filePath, type: 'application/pdf');
  final success = result.type == ResultType.done;

  if (ctx.mounted) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0A1628),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: success
                ? const Color(0xFF1A2A3A)
                : const Color(0xFFED8936),
          ),
        ),
        duration: const Duration(seconds: 5),
        content: Row(children: [
          Icon(
            success
                ? Icons.download_done_rounded
                : Icons.folder_open_outlined,
            color: success
                ? const Color(0xFFCAF135)
                : const Color(0xFFED8936),
            size: 20,
          ),
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
                Text(
                  success ? 'Saved to Downloads' : 'Saved: $filePath',
                  style: const TextStyle(
                      color: Color(0xFF6B8299), fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}