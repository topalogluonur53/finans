import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/data/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await Provider.of<AuthProvider>(context, listen: false).login(
          _usernameController.text,
          _passwordController.text,
        );
        // Navigation is handled by FutureBuilder or Consumer in main.dart
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Hata: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _demoLogin() {
    _usernameController.text = 'demo';
    _passwordController.text = 'demo123';
    _login();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo/Icon
                        Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),

                        // Title
                        const Text(
                          'Finans',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hoş Geldiniz',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Username Field
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Kullanıcı Adı',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                          validator: (value) => 
                              value!.isEmpty ? 'Kullanıcı adı gerekli' : null,
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                          validator: (value) => 
                              value!.isEmpty ? 'Şifre gerekli' : null,
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        ElevatedButton(
                          onPressed: isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Giriş Yap',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                        const SizedBox(height: 12),

                        // Demo Login Button
                        OutlinedButton.icon(
                          onPressed: isLoading ? null : _demoLogin,
                          icon: const Icon(Icons.rocket_launch),
                          label: const Text('Demo Giriş (Test)'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[400])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'veya',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[400])),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Register Button
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const Text('Hesabın yok mu? Kayıt Ol'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
