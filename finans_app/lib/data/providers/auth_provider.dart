import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finans_app/core/constants/api_constants.dart';
import 'package:finans_app/data/models/user.dart';

/// ── Login hata türleri ──────────────────────────────────────────────────────────
enum LoginErrorType { network, wrongCredentials, unknown }

class LoginException implements Exception {
  final String message;
  final LoginErrorType type;
  const LoginException(this.message, this.type);
  @override
  String toString() => message;
}

/// İnaktivite süresi: 1 dakika
const Duration _kInactivityTimeout = Duration(minutes: 1);

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  /// true => oturum açık ama ekran kilitli (şifre tekrar istenecek)
  bool _isLocked = false;
  Timer? _inactivityTimer;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  bool get isLocked => _isLocked;

  // User detail getters
  String? get username => _user?.username;
  String? get email => _user?.email;
  String? get userType => 'Kullanıcı';

  // ─── İnaktivite / Kilit Yönetimi ───────────────────────────────────────────

  /// Kullanıcı etkileşimi gerçekleşince çağrılır — timer'ı sıfırlar.
  void resetInactivityTimer() {
    if (!isAuthenticated || _isLocked) return;
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_kInactivityTimeout, _lockDueToInactivity);
  }

  void _lockDueToInactivity() {
    if (isAuthenticated && !_isLocked) {
      _isLocked = true;
      notifyListeners();
    }
  }

  /// Uygulama arka plana geçince veya çıkış yapılınca kilitle.
  void lockScreen() {
    if (isAuthenticated && !_isLocked) {
      _inactivityTimer?.cancel();
      _isLocked = true;
      notifyListeners();
    }
  }

  /// Kilit ekranında sadece şifreyi doğrula; token/kullanıcıyı kaybetme.
  Future<bool> unlockWithPassword(String password) async {
    if (_user == null) return false;
    final savedUsername = _user!.username;
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': savedUsername, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', _token!);
        await prefs.setString('refresh_token', data['refresh']);
        _isLocked = false;
        resetInactivityTimer();
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Demo modda offline şifre denemesi
      if (_token == 'offline_demo_token' && password == '123456') {
        _isLocked = false;
        resetInactivityTimer();
        notifyListeners();
        return true;
      }
      debugPrint('Unlock error: $e');
    }
    return false;
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');
      debugPrint('Login URL: $url');

      late http.Response response;
      try {
        response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        ).timeout(const Duration(seconds: 15));
      } catch (netErr) {
        // Web: XMLHttpRequest error | Mobil: SocketException | Her platform: TimeoutException
        final errStr = netErr.toString().toLowerCase();
        debugPrint('Network error during login: $netErr');
        if (errStr.contains('timeout') || netErr is TimeoutException) {
          throw const LoginException(
            'Sunucu zaman aşımına uğradı.\nLütfen tekrar deneyin.',
            LoginErrorType.network,
          );
        }
        throw const LoginException(
          'Sunucuya ulaşılamıyor.\nİnternet bağlantınızı kontrol edin.',
          LoginErrorType.network,
        );
      }

      debugPrint('Login response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        await _fetchUserDetails();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', _token!);
        await prefs.setString('refresh_token', data['refresh']);
        resetInactivityTimer();
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        throw const LoginException(
          'Kullanıcı adı veya şifre hatalı.\nLütfen tekrar deneyin.',
          LoginErrorType.wrongCredentials,
        );
      } else if (response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504) {
        if (username.toLowerCase() == 'demo' && password == '123456') {
          _token = 'offline_demo_token';
          _user = User(id: 0, username: 'demo', email: 'demo@finans.app', firstName: 'Önizleme', lastName: 'Modu');
        } else {
          throw const LoginException(
            'Sunucu şu an erişilemiyor.\nLütfen daha sonra tekrar deneyin.',
            LoginErrorType.network,
          );
        }
      } else {
        if (username.toLowerCase() == 'demo' && password == '123456') {
          _token = 'offline_demo_token';
          _user = User(id: 0, username: 'demo', email: 'demo@finans.app', firstName: 'Önizleme', lastName: 'Modu');
        } else {
          throw LoginException(
            'Giriş başarısız (HTTP ${response.statusCode}).\nLütfen daha sonra tekrar deneyin.',
            LoginErrorType.unknown,
          );
        }
      }
    } on LoginException {
      rethrow;
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      if (username.toLowerCase() == 'demo' && password == '123456') {
        _token = 'offline_demo_token';
        _user = User(id: 0, username: 'demo', email: 'demo@finans.app', firstName: 'Önizleme', lastName: 'Modu');
      } else {
        throw LoginException(
          'Bir hata oluştu:\n${e.toString()}',
          LoginErrorType.unknown,
        );
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
    _inactivityTimer?.cancel();
    _isLocked = false;
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
      } else {
        // Uygulama başlangıcında timer'ı başlat
        resetInactivityTimer();
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
