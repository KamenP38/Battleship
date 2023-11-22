import 'package:flutter/material.dart';
import '../utils/sessionmanager.dart';
import 'login.dart';
import 'games.dart';

class Battleships extends StatefulWidget {
  const Battleships({super.key});

  @override
  State<Battleships> createState() => _BattleshipsState();
}

class _BattleshipsState extends State<Battleships> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    SessionManager.clearSession;
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await SessionManager.isLoggedIn();
    if (mounted) {
      setState(() {
        isLoggedIn = loggedIn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Battleships',
      // start at either the home or login screen
      home: isLoggedIn ? const Games() : const LoginScreen(),
    );
  }


}