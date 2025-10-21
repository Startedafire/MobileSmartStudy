import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'upload_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _files = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<String> _selectedFiles = <String>{};

  Future<void> logout() async {
    await SupabaseService.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> _loadFiles() async {
    debugPrint('🔄 === LOADING FILES DEBUG START ===');
    setState(() => _isLoading = true);

    try {
      final user = SupabaseService.currentUser;
      final guestId = await SupabaseService.getGuestId();

      debugPrint('👤 Loading files for:');
      debugPrint('   - User ID: ${user?.id ?? 'null'}');
      debugPrint('   - Guest ID: $guestId');
      debugPrint('   - Query field: ${user != null ? 'user_id' : 'guest_id'}');
      debugPrint('   - Query value: ${user?.id ?? guestId}');

      final response = await SupabaseService.client
          .from('files')
          .select()
          .eq(user != null ? 'user_id' : 'guest_id', user?.id ?? guestId)
          .order('created_at', ascending: false);

      debugPrint('✅ Database query completed');
      debugPrint('   - Response type: ${response.runtimeType}');
      debugPrint('   - Response length: ${response.length}');
      debugPrint('   - Response data: $response');

      setState(() {
        _files = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      debugPrint('✅ Files loaded successfully: ${_files.length} files');
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading files:');
      debugPrint('   - Error: $e');
      debugPrint('   - Stack trace: $stackTrace');
      
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading files: ${e.toString()}')),
        );
      }
    }
    
    debugPrint('🔄 === LOADING FILES DEBUG END ===');
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedFiles.clear();
      }
    });
  }

  void _toggleFileSelection(String fileId) {
    setState(() {
      if (_selectedFiles.contains(fileId)) {
        _selectedFiles.remove(fileId);
      } else {
        _selectedFiles.add(fileId);
      }
    });
  }

  void _selectAllFiles() {
    setState(() {
      if (_selectedFiles.length == _files.length) {
        _selectedFiles.clear();
      } else {
        _selectedFiles = _files.map((file) => file['id'] as String).toSet();
      }
    });
  }

  Future<void> _generateQuizFromSingleFile(Map<String, dynamic> file) async {
    // TODO: Implement single file quiz generation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating quiz from "${file['file_name']}"...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _generateQuizFromMultipleFiles() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedFileNames = _files
        .where((file) => _selectedFiles.contains(file['id']))
        .map((file) => file['file_name'])
        .join(', ');

    // TODO: Implement multi-file quiz generation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating quiz from ${_selectedFiles.length} files: $selectedFileNames'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    // Exit selection mode after generating quiz
    _toggleSelectionMode();
  }

  Future<void> _deleteFile(Map<String, dynamic> file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file['file_name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        String? filePath = file['file_path'] as String?;
        
        if (filePath == null || filePath.isEmpty) {
          final fileUrl = file['file_url'] as String;
          final uri = Uri.parse(fileUrl);
          filePath = uri.pathSegments.skip(4).join('/');
        }
        
        if (filePath.isNotEmpty) {
          await SupabaseService.client.storage
              .from('notes')
              .remove([filePath]);
        }

        await SupabaseService.client
            .from('files')
            .delete()
            .eq('id', file['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${file['file_name']} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadFiles();
        }
      } catch (e) {
        debugPrint('Error deleting file: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting file: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _openFile(Map<String, dynamic> file) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file['file_name'] ?? 'File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${file['file_type']?.toUpperCase() ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Size: ${_formatFileSize(file['file_size'])}'),
            const SizedBox(height: 8),
            Text('URL: ${file['file_url']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File opening feature coming soon!')),
              );
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(dynamic bytes) {
    if (bytes == null) return 'Unknown size';
    
    int? sizeInBytes;
    if (bytes is int) {
      sizeInBytes = bytes;
    } else if (bytes is String) {
      sizeInBytes = int.tryParse(bytes);
    }
    
    if (sizeInBytes == null || sizeInBytes == 0) return 'Unknown size';
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode 
            ? '${_selectedFiles.length} selected' 
            : 'SmartStudy AI'),
        automaticallyImplyLeading: false,
        backgroundColor: _isSelectionMode ? Colors.blue.shade100 : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(_selectedFiles.length == _files.length 
                  ? Icons.deselect 
                  : Icons.select_all),
              onPressed: _selectAllFiles,
              tooltip: _selectedFiles.length == _files.length 
                  ? 'Deselect All' 
                  : 'Select All',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
              tooltip: 'Cancel Selection',
            ),
          ] else ...[
            if (_files.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.quiz),
                onPressed: _toggleSelectionMode,
                tooltip: 'Select Multiple for Quiz',
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadFiles,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: logout,
              tooltip: 'Logout',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_add,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No notes uploaded yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload your study materials to get started',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const UploadScreen()),
                          );
                          if (result == true) {
                            _loadFiles();
                          }
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload First Note'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Multi-selection action bar
                    if (_isSelectionMode)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Select files to generate a combined quiz',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _selectedFiles.isNotEmpty 
                                  ? _generateQuizFromMultipleFiles 
                                  : null,
                              icon: const Icon(Icons.quiz, size: 18),
                              label: const Text('Generate Quiz'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // File list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadFiles,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _files.length,
                          itemBuilder: (context, index) {
                            final file = _files[index];
                            final fileId = file['id'] as String;
                            final isSelected = _selectedFiles.contains(fileId);
                            final createdAt = file['created_at'] != null
                                ? DateTime.parse(file['created_at']).toLocal()
                                : null;
                            final formattedDate = createdAt != null
                                ? '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
                                : 'Unknown date';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: isSelected ? Colors.blue.shade50 : null,
                              child: ListTile(
                                leading: _isSelectionMode 
                                    ? Checkbox(
                                        value: isSelected,
                                        onChanged: (bool? value) {
                                          _toggleFileSelection(fileId);
                                        },
                                      )
                                    : CircleAvatar(
                                        backgroundColor: file['file_type'] == 'pdf'
                                            ? Colors.red.shade100
                                            : Colors.blue.shade100,
                                        child: Icon(
                                          file['file_type'] == 'pdf'
                                              ? Icons.picture_as_pdf
                                              : Icons.image,
                                          color: file['file_type'] == 'pdf'
                                              ? Colors.red.shade700
                                              : Colors.blue.shade700,
                                        ),
                                      ),
                                title: Text(
                                  file['file_name'] ?? 'Unknown file',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(formattedDate),
                                    Text(
                                      _formatFileSize(file['file_size']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: _isSelectionMode 
                                    ? null
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Quick Quiz Button
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.quiz,
                                                color: Colors.green.shade700,
                                                size: 20,
                                              ),
                                              onPressed: () => _generateQuizFromSingleFile(file),
                                              tooltip: 'Generate Quiz',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Menu Button
                                          PopupMenuButton(
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'open',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.open_in_new),
                                                    SizedBox(width: 8),
                                                    Text('Open'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'info',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.info_outline),
                                                    SizedBox(width: 8),
                                                    Text('Info'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            onSelected: (value) {
                                              if (value == 'open') {
                                                _openFile(file);
                                              } else if (value == 'info') {
                                                _openFile(file);
                                              } else if (value == 'delete') {
                                                _deleteFile(file);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                onTap: _isSelectionMode 
                                    ? () => _toggleFileSelection(fileId)
                                    : () => _openFile(file),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _isSelectionMode 
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadScreen()),
                );
                if (result == true) {
                  _loadFiles();
                }
              },
              tooltip: 'Upload File',
              child: const Icon(Icons.add),
            ),
    );
  }
}