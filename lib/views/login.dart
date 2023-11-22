// Screen for loggin in or registering a new user
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/sessionmanager.dart';
import 'games.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 32.0),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                TextButton(
                  onPressed: () => _login(context),
                  child: const Text('Log in'),
                ),
                TextButton(
                  onPressed: () => _register(context),
                  child: const Text('Register'),
                ),
              ]),
            ])),
      ),
    );
  }

  bool _isValidCredentials(String username, String password) {
    return username.length >= 3 &&
        password.length >= 3 &&
        !username.contains(' ') &&
        !password.contains(' ');
  }

  Future<void> _login(BuildContext context) async {
    final username = usernameController.text;
    final password = passwordController.text;

    if (!_isValidCredentials(username, password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials')),
      );
      return;
    }

    const baseUrl = 'http://165.227.117.48';
    final loginUrl = Uri.parse('$baseUrl/login');
    final response = await http.post(loginUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }));

    if (!mounted) return;

    if (response.statusCode == 200) {
      // Successful login. Save the session token or user info.

      // parse the session token from the response header
      final responseData = json.decode(response.body);
      final String accessToken = responseData['access_token'];
      final String message = responseData['message'];
      final String username = usernameController.text;
      await SessionManager.setSessionToken(accessToken);
      await SessionManager.setUsername(username);
      print("Username stored: $username");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      // go to main screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const Games(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed')),
      );
    }
  }

  Future<void> _register(BuildContext context) async {
    final username = usernameController.text;
    final password = passwordController.text;

    if (!_isValidCredentials(username, password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials')),
      );
      return;
    }

    const baseUrl = 'http://165.227.117.48';
    final registerUrl = Uri.parse('$baseUrl/register');
    final response = await http.post(registerUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }));

    if (!mounted) return;

    if (response.statusCode == 200) {
      // Successful registration. -> Treated like login

      // parse the session token from the response header
      final responseData = json.decode(response.body);
      final String accessToken = responseData['access_token'];
      final String message = responseData['message'];
      final String username = usernameController.text;
      await SessionManager.setSessionToken(accessToken);
      await SessionManager.setUsername(username);
      print("Username stored: $username");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      // go to main screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const Games(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed')),
      );
    }
  }
}
