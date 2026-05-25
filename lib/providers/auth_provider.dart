import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _emailVerifiedInFirestore = false;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isEmailVerified =>
      _user == null ? false : (_user!.isAnonymous || _emailVerifiedInFirestore);

  Future<void> refreshEmailVerified() async {
    if (_user == null || _user!.isAnonymous) return;
    try {
      final doc = await _db.collection('users').doc(_user!.uid).get();
      _emailVerifiedInFirestore = doc.data()?['emailVerified'] == true;
    } catch (_) {}
    notifyListeners();
  }

  AppAuthProvider() {
    _auth.authStateChanges.listen((user) async {
      _user = user;
      if (user != null && !user.isAnonymous) {
        try {
          final doc =
              await _db.collection('users').doc(user.uid).get();
          _emailVerifiedInFirestore = doc.data()?['emailVerified'] == true;
        } catch (_) {
          _emailVerifiedInFirestore = false;
        }
      } else {
        _emailVerifiedInFirestore = false;
      }
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.login(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.register(name, email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _error =
            'This email is already registered. Use the original password to continue verification, or reset your password.';
      } else {
        _error = _friendlyError(e.code);
      }
      return false;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Email template recipient is not configured')) {
        _error =
            'Email verification is not configured yet. Please ask the admin to finish EmailJS template setup.';
      } else if (msg.contains('recipient address is empty')) {
        _error = 'Verification email failed because recipient email is missing.';
      } else {
        _error = 'Could not complete sign-up right now. Please try again.';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.signInWithGoogle();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      return false;
    } catch (e) {
      final msg = e.toString();
      if (!msg.contains('cancelled')) {
        _error = 'Google sign-in failed. Please try again.';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginAnonymously() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.signInAnonymously();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() => _auth.logout();

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
