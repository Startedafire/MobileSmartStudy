import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      debug: true,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // 🧩 GUEST ID HANDLER
  static Future<String> getGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    String? guestId = prefs.getString('guest_id');

    if (guestId == null) {
      guestId = const Uuid().v4(); // Using UUID instead of timestamp for better uniqueness
      await prefs.setString('guest_id', guestId);
    }

    return guestId;
  }

  static Future<void> clearGuestData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guest_id');
  }

  // 🔑 AUTH METHODS

  static Future<String?> signUp(String email, String password) async {
    try {
      final response = await client.auth.signUp(email: email, password: password);
      if (response.user != null && response.user!.emailConfirmedAt == null) {
        return 'Please check your email and click the confirmation link before signing in.';
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Network error: $e';
    }
  }

  static Future<String?> signIn(String email, String password) async {
    try {
      await client.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      if (e.message.contains('Email not confirmed')) {
        return 'Please check your email and click the confirmation link first.';
      }
      return e.message;
    } catch (e) {
      return 'Network error: $e';
    }
  }

  static Future<String?> resendConfirmation(String email) async {
    try {
      await client.auth.resend(type: OtpType.signup, email: email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Network error: $e';
    }
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // 👤 USER GETTERS
  static User? get currentUser => client.auth.currentUser;
  
  static bool get isLoggedIn => currentUser != null;

  // Get current user display name
  static String? get currentUserDisplayName {
    final user = currentUser;
    if (user == null) return null;
    return user.userMetadata?['display_name'] ?? 
           user.userMetadata?['full_name'] ?? 
           user.email?.split('@')[0];
  }

  // Check if user is guest
  static Future<bool> isGuest() async {
    return currentUser == null;
  }

  // Get current user email
  static String? get currentUserEmail => currentUser?.email;

  // Get current user ID
  static String? get currentUserId => currentUser?.id;

  // 📁 FILE METHODS

  // Get files for current user or guest
  static Future<List<Map<String, dynamic>>> getUserFiles() async {
    try {
      final user = currentUser;
      final guestId = await getGuestId();

      final response = await client
          .from('files')
          .select()
          .eq(user != null ? 'user_id' : 'guest_id', user?.id ?? guestId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load files: $e');
    }
  }

  // Delete file from storage and database
  static Future<void> deleteFile(Map<String, dynamic> file) async {
    try {
      // Delete from storage if file_path exists
      if (file['file_path'] != null) {
        await client.storage
            .from('notes')
            .remove([file['file_path']]);
      }

      // Delete from database
      await client
          .from('files')
          .delete()
          .eq('id', file['id']);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Upload file to storage
  static Future<String> uploadFile(String path, dynamic file) async {
    try {
      await client.storage
          .from('notes')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      return client.storage.from('notes').getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Save file metadata to database
  static Future<void> saveFileMetadata({
    required String fileName,
    required String fileUrl,
    required String filePath,
    required String fileType,
    required int fileSize,
    String? category,
  }) async {
    try {
      final user = currentUser;
      final guestId = await getGuestId();

      await client.from('files').insert({
        'file_name': fileName,
        'file_url': fileUrl,
        'file_path': filePath,
        'file_type': fileType,
        'file_size': fileSize,
        'category': category,
        'user_id': user?.id,
        'guest_id': user == null ? guestId : null,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save file metadata: $e');
    }
  }

  // 🔧 UTILITY METHODS

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Check if file type is supported
  static bool isSupportedFileType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return ['pdf', 'png', 'jpg', 'jpeg'].contains(extension);
  }

  // Get file type from filename
  static String getFileType(String fileName) {
    return fileName.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image';
  }

  // Generate unique filename
  static String generateUniqueFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${timestamp}_$originalName';
  }

  // Get storage path for user/guest
  static Future<String> getStoragePath(String fileName) async {
    final user = currentUser;
    final guestId = await getGuestId();
    final uniqueFileName = generateUniqueFileName(fileName);
    
    return 'uploads/${user?.id ?? guestId}/$uniqueFileName';
  }

  // 🎯 PROFILE METHODS

  // Update user profile
  static Future<void> updateProfile({
    String? displayName,
    String? fullName,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (fullName != null) updates['full_name'] = fullName;

      if (updates.isNotEmpty) {
        await client.auth.updateUser(UserAttributes(data: updates));
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // 📊 STATS METHODS

  // Get file count for current user/guest
  static Future<int> getFileCount() async {
    try {
      final user = currentUser;
      final guestId = await getGuestId();

      final response = await client
          .from('files')
          .select()
          .eq(user != null ? 'user_id' : 'guest_id', user?.id ?? guestId);

      final files = List<Map<String, dynamic>>.from(response);
      return files.length;
    } catch (e) {
      return 0;
    }
  }

  // Get total storage used
  static Future<int> getTotalStorageUsed() async {
    try {
      final user = currentUser;
      final guestId = await getGuestId();

      final response = await client
          .from('files')
          .select('file_size')
          .eq(user != null ? 'user_id' : 'guest_id', user?.id ?? guestId);

      final files = List<Map<String, dynamic>>.from(response);
      return files.fold<int>(0, (sum, file) => sum + (file['file_size'] as int? ?? 0));
    } catch (e) {
      return 0;
    }
  }
}