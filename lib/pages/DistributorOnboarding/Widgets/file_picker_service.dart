import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// IMAGE ONLY (Camera + Gallery)
  static Future<File?> pickImage(BuildContext context) async {
    return await showModalBottomSheet<File?>(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Take Photo"),
            onTap: () async {
              final img = await _picker.pickImage(
                source: ImageSource.camera,
                imageQuality: 70,
              );
              Navigator.pop(context, img != null ? File(img.path) : null);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text("Gallery"),
            onTap: () async {
              final img = await _picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 70,
              );
              Navigator.pop(context, img != null ? File(img.path) : null);
            },
          ),
        ],
      ),
    );
  }

  /// IMAGE + PDF
  static Future<File?> pickFile(BuildContext context) async {
    return await showModalBottomSheet<File?>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take Photo"),
              onTap: () async {
                final picked = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );
                Navigator.pop(
                  context,
                  picked != null ? File(picked.path) : null,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Gallery"),
              onTap: () async {
                final picked = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                Navigator.pop(
                  context,
                  picked != null ? File(picked.path) : null,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text("Upload PDF"),
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );

                if (result != null &&
                    result.files.single.path != null) {
                  Navigator.pop(
                    context,
                    File(result.files.single.path!),
                  );
                } else {
                  Navigator.pop(context, null);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ONLY PDF (without bottom sheet)
  static Future<File?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }
}