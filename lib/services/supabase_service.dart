import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      debug: true,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Sign up with email + password
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

  // Sign in with email + password
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

  // Resend confirmation email
  static Future<String?> resendConfirmation(String email) async {
    try {
      await client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
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

  static User? get currentUser => client.auth.currentUser;
}