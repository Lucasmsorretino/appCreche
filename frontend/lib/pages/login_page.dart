import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
// Original import for login functionality (commented out for MVP)
// import '../services/login_service.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String userType = 'responsavel';
  bool _isLoading = false;
  bool _rememberMe = false;
  final _formKey = GlobalKey<FormState>();

  void _login() async {
    // MVP: bypass de login (mantido apenas para MVP)
    Navigator.pushReplacementNamed(context, '/home');
  }
  
  // Código original de login (comentado para futura recuperação):
  /*
  void _login() async {
    // Validate the form
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      setState(() {
        _isLoading = true;
      });

      try {
        // Create login service with the appropriate base URL
        final loginService = LoginService.withBaseUrl(baseUrl: 'http://localhost:8000');
        // Call the login service
        final token = await loginService.login(email, password);

        if (token != null) {
          // Save credentials if "Remember Me" is checked
          if (_rememberMe) {
            // Here you would typically use shared_preferences or secure_storage
            // to save the login credentials or token securely
            print('Saving credentials for future use');
          }
          // Successfully logged in
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Login failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login falhou. Verifique suas credenciais.')),
          );
        }
      } catch (e) {
        // Handle any errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao conectar ao servidor: \\${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.school, size: 48, color: Colors.white),
                ),
                SizedBox(height: 16),
                Text('CMEI App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 24),
                // Opções de usuário responsivas
                Wrap(
                  spacing: 16,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 160),
                      child: RadioListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text('Responsável'),
                        value: 'responsavel',
                        groupValue: userType,
                        onChanged: (val) => setState(() => userType = val.toString()),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 160),
                      child: RadioListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text('Funcionário'),
                        value: 'funcionario',
                        groupValue: userType,
                        onChanged: (val) => setState(() => userType = val.toString()),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua senha';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                CheckboxListTile(
                  title: Text('Lembrar-me'),
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value!;
                    });
                  },
                ),
                SizedBox(height: 24),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        child: Text('Entrar'),
                        style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
                      ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    // For development only - use public methods instead of private fields
                    final authService = Provider.of<AuthService>(context, listen: false);
                    // Simulate a successful login
                    authService.devLogin();
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: Text('Skip Login (Dev Only)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
