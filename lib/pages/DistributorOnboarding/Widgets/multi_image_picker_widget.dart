import 'dart:io';
import 'package:flutter/material.dart';
import '../Widgets/file_picker_service.dart';

class MultiImagePickerWidget extends StatelessWidget {
  final String title;
  final List<File> images;
  final int max;
  final Function(File) onAdd;
  final Function(File) onRemove;

  const MultiImagePickerWidget({
    super.key,
    required this.title,
    required this.images,
    required this.max,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          children: [
            ...images.map(
              (img) => Stack(
                children: [
                  Image.file(img, width: 80, height: 80, fit: BoxFit.cover),

                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () => onRemove(img),
                      child: const Icon(Icons.close, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

            if (images.length < max)
              GestureDetector(
                onTap: () async {
                  final file =
                      await FilePickerService.pickImage(context);
                  if (file != null) {
                    onAdd(file);
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.add),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}