import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _isUploading = false;
  String? _uploadProgress;
  double _progressValue = 0.0;

  Future<void> _uploadFile() async {
    debugPrint('🚀 === UPLOAD DEBUG START ===');
    setState(() => _uploadProgress = 'Selecting file...');

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: false,
    );

    if (result == null) {
      debugPrint('❌ File selection cancelled by user');
      setState(() => _uploadProgress = null);
      return;
    }

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;
    final fileSize = result.files.single.size;
    final fileType = fileName.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image';

    debugPrint('📁 Selected file details:');
    debugPrint('   - Name: $fileName');
    debugPrint('   - Size: $fileSize bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');
    debugPrint('   - Type: $fileType');
    debugPrint('   - Path: ${file.path}');

    // Check file size (limit to 10MB)
    if (fileSize > 10 * 1024 * 1024) {
      debugPrint('❌ File too large: $fileSize bytes');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File size must be less than 10MB'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _uploadProgress = null);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 'Preparing upload...';
      _progressValue = 0.1;
    });

    try {
      // Check authentication
      final user = SupabaseService.client.auth.currentUser;
      final guestId = await SupabaseService.getGuestId();

      debugPrint('👤 User authentication:');
      debugPrint('   - User ID: ${user?.id ?? 'null'}');
      debugPrint('   - User email: ${user?.email ?? 'null'}');
      debugPrint('   - Guest ID: $guestId');
      debugPrint('   - Is authenticated: ${user != null}');

      // Create unique filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';
      final path = 'uploads/${user?.id ?? guestId}/$uniqueFileName';

      debugPrint('📍 Upload path: $path');

      setState(() {
        _uploadProgress = 'Uploading to storage...';
        _progressValue = 0.3;
      });

      // Test Supabase connection first
      debugPrint('🔗 Testing Supabase connection...');
      try {
        final buckets = await SupabaseService.client.storage.listBuckets();
        debugPrint('✅ Supabase connection OK. Found ${buckets.length} buckets');
        
        final notesBucket = buckets.where((b) => b.id == 'notes').firstOrNull;
        if (notesBucket != null) {
          debugPrint('✅ Notes bucket found: ${notesBucket.name} (public: ${notesBucket.public})');
        } else {
          debugPrint('❌ Notes bucket NOT found!');
        }
      } catch (e) {
        debugPrint('❌ Supabase connection test failed: $e');
        throw Exception('Connection test failed: $e');
      }

      // Upload file to Supabase Storage
      debugPrint('⬆️ Starting storage upload...');
      await SupabaseService.client.storage
          .from('notes')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      debugPrint('✅ Storage upload completed successfully');

      setState(() {
        _uploadProgress = 'Getting file URL...';
        _progressValue = 0.7;
      });

      final fileUrl = SupabaseService.client.storage.from('notes').getPublicUrl(path);
      debugPrint('🔗 Generated file URL: $fileUrl');

      setState(() {
        _uploadProgress = 'Saving file record...';
        _progressValue = 0.9;
      });

      // Prepare database record
      final fileRecord = {
        'file_name': fileName,
        'file_url': fileUrl,
        'file_path': path,
        'file_type': fileType,
        'file_size': fileSize,
        'user_id': user?.id,
        'guest_id': user == null ? guestId : null,
        'created_at': DateTime.now().toIso8601String(),
      };

      debugPrint('💾 Saving to database:');
      debugPrint('   - Record: $fileRecord');

      // Save file metadata to database
      final dbResponse = await SupabaseService.client.from('files').insert(fileRecord).select();
      
      debugPrint('✅ Database insert completed');
      debugPrint('   - Response: $dbResponse');

      setState(() {
        _uploadProgress = 'Upload complete!';
        _progressValue = 1.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fileName uploaded successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        debugPrint('✅ Success message shown, waiting before navigation...');
        
        // Wait a moment to show completion, then return
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          debugPrint('🔄 Navigating back to home screen with result: true');
          Navigator.pop(context, true);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Upload error occurred:');
      debugPrint('   - Error: $e');
      debugPrint('   - Type: ${e.runtimeType}');
      debugPrint('   - Stack trace: $stackTrace');
      
      if (e is StorageException) {
        debugPrint('   - Storage error message: ${e.message}');
        debugPrint('   - Storage error statusCode: ${e.statusCode}');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      debugPrint('🔄 === UPLOAD DEBUG END ===');
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = null;
          _progressValue = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isUploading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Upload Note'),
          automaticallyImplyLeading: !_isUploading,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isUploading ? Icons.cloud_upload : Icons.cloud_upload_outlined,
                  size: 80,
                  color: _isUploading ? Colors.blue : Colors.grey,
                ),
                const SizedBox(height: 20),
                Text(
                  _isUploading ? 'Uploading...' : 'Upload Your Study Notes',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (!_isUploading) ...[
                  const Text(
                    'Supported formats: PDF, PNG, JPG, JPEG\nMax size: 10MB',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 40),
                
                if (_isUploading) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: _progressValue,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        const SizedBox(height: 16),
                        if (_uploadProgress != null)
                          Text(
                            _uploadProgress!,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_progressValue * 100).toInt()}%',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Please wait while your file is being uploaded...',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _uploadFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text(
                        'Select & Upload File',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}