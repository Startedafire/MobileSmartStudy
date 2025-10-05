import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final supabase = Supabase.instance.client;
  bool isUploading = false;

  Future<void> pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
    );

    if (result == null) return;

    Uint8List? fileBytes = result.files.single.bytes;
    final defaultFileName = result.files.single.name;

    if (fileBytes == null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      fileBytes = await file.readAsBytes();
    }

    if (fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to read file bytes')),
      );
      return;
    }

    final titleController = TextEditingController(text: defaultFileName);
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Note Title'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'Enter a title for this note',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, titleController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (title == null || title.isEmpty) return;

    setState(() => isUploading = true);

    final storagePath =
        'uploads/${DateTime.now().millisecondsSinceEpoch}_$defaultFileName';

    try {
      await supabase.storage.from('notes').uploadBinary(storagePath, fileBytes);
      await supabase.from('uploaded_files').insert({
        'file_name': title,
        'storage_path': storagePath,
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Uploaded: $title')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isUploading
          ? const CircularProgressIndicator()
          : ElevatedButton.icon(
              onPressed: pickAndUploadFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select & Upload File'),
            ),
    );
  }
}
