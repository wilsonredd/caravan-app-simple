import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Simulated login function
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Simple validation
      if (email.isEmpty || !email.contains('@') || password.isEmpty) {
        _error = "Invalid email or password";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Hardcoded user for demo
      if (email == "demo@example.com" && password == "password") {
        _currentUser = UserModel(
          id: "user123",
          name: "Demo User",
          email: email,
        );
        _isAuthenticated = true;
        _saveUserToPrefs();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Demo: any email/password combo works
      _currentUser = UserModel(name: email.split('@')[0], email: email);
      _isAuthenticated = true;
      _saveUserToPrefs();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Simulated registration
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Simple validation
      if (name.isEmpty ||
          email.isEmpty ||
          !email.contains('@') ||
          password.isEmpty) {
        _error = "Please fill all fields with valid data";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create new user
      _currentUser = UserModel(name: name, email: email);
      _isAuthenticated = true;
      _saveUserToPrefs();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Simulated logout
  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');

    notifyListeners();
  }

  // Save user to SharedPreferences (for persistence)
  Future<void> _saveUserToPrefs() async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', _currentUser!.toMap().toString());
    }
  }

  // Check if user is already logged in
  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');

    if (userStr != null && userStr.isNotEmpty) {
      // In a real app, you'd parse the user data and restore the user
      // This is simplified for demo purposes
      _isAuthenticated = true;
      _currentUser = UserModel(
        id: "user123",
        name: "Demo User",
        email: "demo@example.com",
      );
    }

    notifyListeners();
  }
}
