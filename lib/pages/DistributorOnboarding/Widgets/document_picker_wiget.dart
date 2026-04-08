import 'dart:io';
import 'package:flutter/material.dart';
import '../Widgets/file_picker_service.dart';

class DocumentPickerWidget extends StatelessWidget {
  final String label;
  final File? file;
  final Function(File?) onChanged;

  const DocumentPickerWidget({
    super.key,
    required this.label,
    required this.file,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ext = file?.path.split('.').last.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: () async {
            final picked = await FilePickerService.pickFile(context);
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: file == null
                ? const Center(child: Icon(Icons.upload))
                : Stack(
                    children: [
                      /// IMAGE
                      if (['jpg', 'jpeg', 'png'].contains(ext))
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            file!,
                            width: double.infinity,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )

                      /// PDF
                      else
                        Row(
                          children: [
                            const SizedBox(width: 10),
                            const Icon(Icons.picture_as_pdf,
                                color: Colors.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                file!.path.split('/').last,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                      /// REMOVE BUTTON
                      Positioned(
                        right: 5,
                        top: 5,
                        child: GestureDetector(
                          onTap: () => onChanged(null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}