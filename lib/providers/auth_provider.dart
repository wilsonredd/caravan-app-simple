import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AppAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated {
    final isAuth = _auth.currentUser != null;
    print('Auth check: ${isAuth ? 'YES' : 'NO'}, currentUser: ${_auth.currentUser?.uid}');
    return isAuth;
  }
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Login with email and password
  Future<bool> login(String email, String password) async {
    print('LOGIN START: email=$email');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Sign in with Firebase
      print('Attempting Firebase signIn...');
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Firebase signIn completed: ${userCredential.user?.uid}');

      final user = userCredential.user;
      if (user == null) {
        print('LOGIN ERROR: user is null after signIn');
        _error = "Unknown error occurred";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get user data from Firestore
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (docSnapshot.exists) {
        // User exists in Firestore
        _currentUser = UserModel.fromMap(docSnapshot.data()!);
      } else {
        // Create user document if it doesn't exist
        _currentUser = UserModel(
          id: user.uid,
          name: user.displayName ?? email.split('@')[0],
          email: email,
        );

        // Save to Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(_currentUser!.toMap());
      }

      _isLoading = false;
      print('LOGIN SUCCESS: User logged in successfully, currentUser=${_currentUser?.id}, Firebase user=${_auth.currentUser?.uid}');
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print('LOGIN FIREBASE ERROR: ${e.code}');
      _error = _getMessageFromErrorCode(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('LOGIN ERROR: ${e.toString()}');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register with email and password
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create user with Firebase
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        _error = "Unknown error occurred";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update display name
      await user.updateDisplayName(name);

      // Create user model
      _currentUser = UserModel(id: user.uid, name: name, email: email);

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(_currentUser!.toMap());

      _isLoading = false;
      print('REGISTER SUCCESS: User registered, currentUser=${_currentUser?.id}');
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print('REGISTER FIREBASE ERROR: ${e.code}');
      _error = _getMessageFromErrorCode(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('REGISTER ERROR: ${e.toString()}');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Check current user and load data
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    final currentUser = _auth.currentUser;
    print('Checking current auth state: ${currentUser?.uid ?? 'No user'}');

    if (currentUser != null) {
      try {
        // Get user data from Firestore
        final docSnapshot =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (docSnapshot.exists) {
          _currentUser = UserModel.fromMap(docSnapshot.data()!);
          print('User data loaded from Firestore: ${_currentUser?.id}');
        } else {
          // Create user document if it doesn't exist
          _currentUser = UserModel(
            id: currentUser.uid,
            name:
                currentUser.displayName ??
                currentUser.email?.split('@')[0] ??
                'User',
            email: currentUser.email ?? '',
          );

          print('Creating new user document in Firestore: ${_currentUser?.id}');
          // Save to Firestore
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .set(_currentUser!.toMap());
        }
      } catch (e) {
        print('Error checking auth: $e');
        _error = e.toString();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Listen for auth state changes
  void setupAuthListener() {
    print('Setting up Firebase auth state listener');
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        print('AUTH LISTENER: User signed out or null');
        _currentUser = null;
        notifyListeners();
      } else {
        print('AUTH LISTENER: User signed in: ${user.uid}');
        // Get user data from Firestore
        try {
          final docSnapshot =
              await _firestore.collection('users').doc(user.uid).get();

          if (docSnapshot.exists) {
            print('AUTH LISTENER: Found user in Firestore');
            _currentUser = UserModel.fromMap(docSnapshot.data()!);
          } else {
            print('AUTH LISTENER: User not in Firestore, creating document');
            // Create user document if it doesn't exist
            _currentUser = UserModel(
              id: user.uid,
              name: user.displayName ?? user.email?.split('@')[0] ?? 'User',
              email: user.email ?? '',
            );

            // Save to Firestore
            await _firestore
                .collection('users')
                .doc(user.uid)
                .set(_currentUser!.toMap());
          }

          print('AUTH LISTENER: Updated _currentUser = ${_currentUser?.id}');
          notifyListeners();
        } catch (e) {
          print('AUTH LISTENER ERROR: ${e.toString()}');
          _error = e.toString();
          notifyListeners();
        }
      }
    });
  }

  // Helper method to get user-friendly error messages
  String _getMessageFromErrorCode(String errorCode) {
    print('Error code received: $errorCode');
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The email address is already in use.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'configuration-not-found':
        return 'Firebase configuration error. Please check your project settings.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-api-key':
        return 'Invalid Firebase API key.';
      case 'app-not-authorized':
        return 'App not authorized to use Firebase Authentication.';
      default:
        return 'Error: $errorCode - Please try again later.';
    }
  }
}