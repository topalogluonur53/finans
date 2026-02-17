import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finans_app/core/constants/api_constants.dart';
import 'package:finans_app/data/models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  
  // User detail getters
  String? get username => _user?.username;
  String? get email => _user?.email;
  String? get createdAt => 'Kullanıcı'; // TODO: Add created_at to User model if needed


  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.loginEndpoint);
      print('Login attempting URL: $url');
      print('Login body: ${jsonEncode({'username': username, 'password': password})}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        // Ideally fetch user details here
        // For MVP, just assume login success.
        // Or store username in prefs if returned?
        // SimpleJWT returns only tokens normally.
        
        await _fetchUserDetails();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', _token!);
        await prefs.setString('refresh_token', data['refresh']);

      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + '/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Registration successful
        // Optionally auto-login after registration
        // await login(username, password);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData.toString());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> _fetchUserDetails() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + '/auth/user/'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        _user = User.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error fetching user: $e');
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    print('AuthProvider: tryAutoLogin started');
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('access_token')) {
        print('AuthProvider: No token found in prefs');
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      _token = prefs.getString('access_token');
      print('AuthProvider: Token found, verifying...');
      
      await _fetchUserDetails();
      
      if (_user == null) {
        print('AuthProvider: User details fetch failed (user is null), logging out...');
        await logout();
      } else {
        print('AuthProvider: Auto-login successful for ${_user?.username}');
      }
    } catch (e, stack) {
      print('AuthProvider: Error during auto-login: $e');
      print(stack);
      await logout();
    } finally {
      print('AuthProvider: tryAutoLogin finished. isLoading was $_isLoading, setting to false.');
      _isLoading = false;
      notifyListeners();
    }
  }
}
