import 'package:battleships/views/games.dart';
import 'package:battleships/views/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/sessionmanager.dart';
import 'dart:convert';

class PlayGame extends StatefulWidget {
  final int gameId;

  const PlayGame({super.key, required this.gameId});

  @override
  State<PlayGame> createState() => _PlayGameState();
}

class _PlayGameState extends State<PlayGame> {
  List<String> selectedPositions = [];
  int? _userPosition;
  List<String> _shotsTaken = [];
  bool _isUserTurn = false;
  bool _isGameActive = false;
  String? _pendingShot;

  List<String> myShips = [];
  List<String> myShots = [];
  List<String> myHits = [];
  List<String> mySunkShips = [];

  bool _hasWon = false;
  bool _hasLost = false;

  @override
  void initState() {
    super.initState();
    fetchGameInfo();
  }

  String baseUrl = "http://165.227.117.48";

  Future<void> _redirectToLogin() async {
    await SessionManager.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> fetchGameInfo() async {
    var url = Uri.parse('$baseUrl/games/${widget.gameId}');
    String? token = await SessionManager.getSessionToken();

    if (token == '') {
      print('Authorization token is missing.');
      return;
    }

    var response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        _shotsTaken = List<String>.from(data['shots']);
        _userPosition = data['position'];
        print("User Position: $_userPosition, Turn: ${data['turn']}");

        _isUserTurn = data['turn'] == _userPosition;

        myShips = List<String>.from(data['ships']);
        myShots = List<String>.from(data['shots']);
        myHits = List<String>.from(data['sunk']);
        mySunkShips = List<String>.from(data['wrecks']);

        _hasWon = myHits.length >= 5;
        _hasLost = mySunkShips.length >= 5;

        _isGameActive = data['status'] == 0 || data['status'] == 3;
      });
      if (_hasWon || _hasLost) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _showEndGameDialog());
      }
    } else if (response.statusCode == 401) {
      // Token expired, redirect to login
      await _redirectToLogin();
    } else {
      print('Error fetching game info: ${response.body}');
    }
  }

  void _showEndGameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_hasWon ? 'You won!' : 'You lost!'),
          content: Text(_hasWon
              ? 'Congratulations! You have sunk all enemy ships.'
              : 'All your ships have been sunk.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Okay'),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const Games()),
                  (Route<dynamic> route) =>
                      false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> onCellTap(String pos) async {
    if (!_isGameActive) {
      _showSnackbar(context, "The game is not active.");
      return;
    }

    if (!_isUserTurn) {
      _showSnackbar(context, "It's not your turn.");
      return;
    }

    if (_shotsTaken.contains(pos) || myHits.contains(pos)) {
      _showSnackbar(context, "You already attacked here.");
      return;
    }

    _pendingShot = pos;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasWon || _hasLost) {
        _showEndGameDialog();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Play Game'),
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

                // Game cell logic
                int row = (index / 6).floor();
                int col = index % 6;
                String pos =
                    '${String.fromCharCode('A'.codeUnitAt(0) + row - 1)}$col';

                String cellContent = '';

                if (myShips.contains(pos)) {
                  cellContent += '🚢';
                }
                if (myShots.contains(pos) && !myHits.contains(pos)) {
                  cellContent += '💣';
                }
                if (myHits.contains(pos)) {
                  cellContent += '💥';
                }
                if (mySunkShips.contains(pos)) {
                  cellContent += '💦';
                }

                return InkWell(
                  onTap: (() => onCellTap(pos)),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                      color:
                          selectedPositions.contains(pos) || pos == _pendingShot
                              ? Colors.lightGreen
                              : null,
                    ),
                    child: Text(
                      cellContent,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                      ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pendingShot != null && _isUserTurn
                  ? () => submitShot(_pendingShot!)
                  : null,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> submitShot(String shot) async {
    var url = Uri.parse('$baseUrl/games/${widget.gameId}');
    String? token = await SessionManager.getSessionToken();

    if (token == '') {
      print('Authorization token is missing.');
      return;
    }

    var response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode({"shot": shot}),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      bool won = data['won'];


      fetchGameInfo();

      setState(() {
        _pendingShot = null;
      });

      if (won) {}
    } else if (response.statusCode == 401) {
      // Token expired, redirect to login
      await _redirectToLogin();
    } else {
      print('Error sending shot: ${response.body}');
      _showSnackbar(context, 'Error sending shot');
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    const Duration(milliseconds: 500);
  }
}
