import 'package:battleships/views/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/sessionmanager.dart';
import 'dart:convert';

class Newgame extends StatefulWidget {
  final int gameType;

  const Newgame({super.key, required this.gameType});

  @override
  State<Newgame> createState() => _NewgameState();
}

class _NewgameState extends State<Newgame> {
  List<String> selectedPositions = [];
  String baseUrl = "http://165.227.117.48";

  void onCellTap(String pos) {
    setState(() {
      if (selectedPositions.contains(pos)) {
        selectedPositions.remove(pos);
      } else if (selectedPositions.length < 5) {
        selectedPositions.add(pos);
      }
    });
  }

  Future<void> _redirectToLogin() async {
    await SessionManager.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> startNewGame() async {
    var url = Uri.parse('$baseUrl/games');
    String? token = await SessionManager.getSessionToken();

    if (token == '') {
      print('Authorization token is missing.');
      return;
    }

    var response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode({
        "ships": selectedPositions,
      }),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      print('Game started: ${data['id']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Game created: ${data['id']}'),
            duration: const Duration(milliseconds: 500)),
      );
    } else if (response.statusCode == 401) {
      // Token expired, redirect to login
      await _redirectToLogin();
    } else {
      print('Error starting game: ${response.body}');
    }
  }

  Future<void> startNewGameAI(String ai) async {
    var url = Uri.parse('$baseUrl/games');
    String? token = await SessionManager.getSessionToken();

    if (token == '') {
      print('Authorization token is missing.');
      return;
    }

    var response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode({
        "ships": selectedPositions,
        "ai": ai,
      }),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      print('Game started: ${data['id']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Game created: ${data['id']}'),
            duration: const Duration(milliseconds: 500)),
      );
    } else if (response.statusCode == 401) {
      // Token expired, redirect to login
      await _redirectToLogin();
    } else {
      print('Error starting game: ${response.body}');
    }
  }

  Future<void> submitGameAndNavigateBack(int gameType) async {
    if (selectedPositions.length == 5) {
      if (gameType == 0) {
        await startNewGame(); // This is your existing method to start a new game
      } else if (gameType == 1) {
        await startNewGameAI('random');
      } else if (gameType == 2) {
        await startNewGameAI('perfect');
      } else if (gameType == 3) {
        await startNewGameAI('oneship');
      }
      // Navigate back to the games page
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Ships'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final aspectRatio = constraints.maxWidth / constraints.maxHeight;

          return Padding(
            padding: const EdgeInsets.only(right: 30.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: aspectRatio,
              ),
              itemCount: 36,
              itemBuilder: (context, index) {
                if (index < 6) {
                  return Center(child: Text(index == 0 ? '' : '$index'));
                } else if (index % 6 == 0) {
                  int row = (index / 6).floor();
                  return Center(
                      child: Text(
                          String.fromCharCode('A'.codeUnitAt(0) + row - 1)));
                }

                int row = (index / 6).floor();
                int col = index % 6;
                String pos =
                    '${String.fromCharCode('A'.codeUnitAt(0) + row - 1)}$col';

                return InkWell(
                  onTap: () => onCellTap(pos),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                      color: selectedPositions.contains(pos)
                          ? Colors.lightGreen
                          : null,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: selectedPositions.length == 5
                  ? () async {
                      await submitGameAndNavigateBack(widget.gameType);
                    }
                  : null,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
