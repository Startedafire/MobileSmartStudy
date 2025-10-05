import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'quiz_generation_screen.dart';

class ViewUploadedScreen extends StatefulWidget {
  const ViewUploadedScreen({super.key});

  @override
  State<ViewUploadedScreen> createState() => _ViewUploadedScreenState();
}

class _ViewUploadedScreenState extends State<ViewUploadedScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List files = [];

  @override
  void initState() {
    super.initState();
    fetchFiles();
  }

  Future<void> fetchFiles() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('uploaded_files')
          .select()
          .order('created_at', ascending: false);
      setState(() => files = response);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to fetch files: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> downloadAndOpen(String storagePath, String fileName) async {
    try {
      final fileBytes = await supabase.storage.from('notes').download(storagePath);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(fileBytes);
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to open file: $e')));
    }
  }

  Future<void> deleteFile(String storagePath, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete File'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.storage.from('notes').remove([storagePath]);
      await supabase.from('uploaded_files').delete().eq('id', id);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('File deleted')));
      fetchFiles();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete file: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : files.isEmpty
            ? const Center(child: Text('No files uploaded yet.'))
            : RefreshIndicator(
                onRefresh: fetchFiles,
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.description,
                              size: 32, color: Colors.blue),
                        ),
                        title: Text(
                          file['file_name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          file['created_at'],
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.folder_open,
                                  color: Colors.green),
                              onPressed: () => downloadAndOpen(
                                  file['storage_path'], file['file_name']),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.lightbulb, color: Colors.orange),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QuizGenerationScreen(
                                      noteId: file['id'],
                                      noteTitle: file['file_name'],
                                      storagePath: file['storage_path'],
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  deleteFile(file['storage_path'], file['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
  }
}
