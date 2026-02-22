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
  // User model doesn't have createdAt yet, using a placeholder if needed
  String? get userType => 'Kullanıcı';

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url =
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');

      http.Response? response;
      bool isBackendSuccess = false;

      try {
        response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        );
        if (response.statusCode == 200) {
          isBackendSuccess = true;
          final data = jsonDecode(response.body);
          _token = data['access'];
          await _fetchUserDetails();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', _token!);
          await prefs.setString('refresh_token', data['refresh']);
        }
      } catch (e) {
        debugPrint('Backend login error: $e');
      }

      // KULLANICI İSTEĞİ: Demo giriş başarısız olursa sisteme çevrimdışı / dummy modda girmesine izin ver.
      if (!isBackendSuccess) {
        if (username.toLowerCase() == 'demo' && password == '123456') {
          _token = 'offline_demo_token';
          _user = User(id: 0, username: 'demo', email: 'demo@finans.app', firstName: 'Önizleme', lastName: 'Modu');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', _token!);
        } else {
          throw Exception('Login failed: ${response?.body ?? 'Connection Error'}');
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String email, String password, {String firstName = '', String lastName = ''}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
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
        Uri.parse('${ApiConstants.baseUrl}/auth/user/'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        _user = User.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching user details: $e');
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
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('access_token')) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      _token = prefs.getString('access_token');

      await _fetchUserDetails();

      if (_user == null) {
        await logout();
      }
    } catch (e) {
      debugPrint('AuthProvider: Error during auto-login: $e');
      await logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
