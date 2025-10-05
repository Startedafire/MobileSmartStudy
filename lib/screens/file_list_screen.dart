import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FileListScreen extends StatefulWidget {
  const FileListScreen({super.key});

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchFiles() async {
    final response = await supabase
        .from('uploaded_files')
        .select()
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<void> deleteFile(String storagePath, String id) async {
    try {
      // 1. Delete from storage
      await supabase.storage.from('notes').remove([storagePath]);

      // 2. Delete from database
      await supabase.from('uploaded_files').delete().eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted successfully')),
        );
        setState(() {}); // refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  void confirmDelete(String fileName, String storagePath, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete \"$fileName\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context); // close dialog
              deleteFile(storagePath, id);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uploaded Files')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchFiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No files uploaded yet'));
          }

          final files = snapshot.data!;

          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(file['file_name']),
                subtitle: Text(file['created_at']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () {
                        final url = supabase.storage
                            .from('notes')
                            .getPublicUrl(file['storage_path']);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Download URL:\n$url')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        confirmDelete(
                          file['file_name'],
                          file['storage_path'],
                          file['id'],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
