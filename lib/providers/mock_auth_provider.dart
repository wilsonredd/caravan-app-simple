import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/user_model.dart';

// Mock AppAuthProvider that doesn't rely on Firebase
class MockAuthProvider with ChangeNotifier {
  // Mock user database
  final Map<String, _MockUser> _users = {
    'demo@example.com': _MockUser(
      email: 'demo@example.com',
      password: 'password',
      displayName: 'Demo User',
      uid: 'demo-user-123',
    ),
  };
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated {
    final isAuth = _currentUser != null;
    print('MOCK: isAuthenticated check: ${isAuth ? 'YES' : 'NO'}, currentUser: ${_currentUser?.id}');
    return isAuth;
  }
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Login with email and password
  Future<bool> login(String email, String password) async {
    print('MOCK: LOGIN START: email=$email');
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 800));

    try {
      // Check if user exists
      final user = _users[email.toLowerCase()];
      if (user == null) {
        print('MOCK: LOGIN ERROR: User not found');
        _error = "No user found with this email.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check password
      if (user.password != password) {
        print('MOCK: LOGIN ERROR: Wrong password');
        _error = "Wrong password provided.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create user model
      _currentUser = UserModel(
        id: user.uid,
        name: user.displayName ?? email.split('@')[0],
        email: email,
      );

      _isLoading = false;
      print('MOCK: LOGIN SUCCESS: User logged in successfully, currentUser=${_currentUser?.id}');
      notifyListeners();
      return true;
    } catch (e) {
      print('MOCK: LOGIN ERROR: ${e.toString()}');
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

    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 800));

    try {
      // Check if user already exists
      if (_users.containsKey(email.toLowerCase())) {
        _error = "The email address is already in use.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Generate random user ID
      final uid = 'user-${Random().nextInt(10000)}-${DateTime.now().millisecondsSinceEpoch}';
      
      // Create new user
      final newUser = _MockUser(
        email: email.toLowerCase(),
        password: password,
        displayName: name,
        uid: uid,
      );
      
      // Add to "database"
      _users[email.toLowerCase()] = newUser;

      // Create user model
      _currentUser = UserModel(id: uid, name: name, email: email);

      _isLoading = false;
      print('MOCK: REGISTER SUCCESS: User registered, currentUser=${_currentUser?.id}');
      notifyListeners();
      return true;
    } catch (e) {
      print('MOCK: REGISTER ERROR: ${e.toString()}');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 500));
    
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
    print('MOCK: LOGOUT: User logged out');
  }

  // Check current user state (always no user in this mock version)
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();
    
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 300));
    
    // We're mocking, so no persistent user
    _currentUser = null;
    
    _isLoading = false;
    notifyListeners();
    print('MOCK: CHECK AUTH: No persisted user found');
  }

  // Auth listener setup - does nothing in mock version
  void setupAuthListener() {
    print('MOCK: AUTH LISTENER: Setting up mock auth state listener (no-op)');
    // Nothing to do in mock version
  }
}

// Mock user class for in-memory storage
class _MockUser {
  final String email;
  final String password;
  final String? displayName;
  final String uid;
  
  _MockUser({
    required this.email,
    required this.password,
    required this.uid,
    this.displayName,
  });
}