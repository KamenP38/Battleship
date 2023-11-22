import 'package:battleships/models/game_list_notifier.dart';
import 'package:battleships/views/login.dart';
import 'package:battleships/views/newgame.dart';
import 'package:battleships/views/playgame.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/sessionmanager.dart';
import '../models/game.dart';
import 'package:provider/provider.dart';

class Games extends StatefulWidget {
  const Games({super.key});

  @override
  State<Games> createState() => _GamesState();
}

class _GamesState extends State<Games> {
  String _username = '';
  bool _showCompletedGames = false;
  // bool _isLoading = true;
  String baseUrl = 'http://165.227.117.48';

  @override
  void initState() {
    super.initState();
    _loadUsername();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _loadGames();
    });
  }

  Future<void> _loadUsername() async {
    final username = await SessionManager.getUsername();
    print("Username retrieved: $username");
    if (mounted) {
      setState(() {
        _username = username ?? 'Guest';
      });
    }
  }

  Future<void> _logout() async {
    await SessionManager.clearSession();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _showAIDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Choose AI Type'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context, 'Random AI');
                // Add your action for Random AI here
                var gameListNotifier =
                    Provider.of<GameListNotifier>(context, listen: false);

                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const Newgame(gameType: 1)),
                );

                // Use the previously fetched notifier to refresh the games
                gameListNotifier.fetchGames();
              },
              child: const Text('Random AI'),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context, 'Perfect AI');
                // Add your action for Perfect AI here
                var gameListNotifier =
                    Provider.of<GameListNotifier>(context, listen: false);

                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const Newgame(gameType: 2)),
                );

                // Use the previously fetched notifier to refresh the games
                gameListNotifier.fetchGames();
              },
              child: const Text('Perfect AI'),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context, 'Oneship AI');
                // Add your action for Oneship AI here
                var gameListNotifier =
                    Provider.of<GameListNotifier>(context, listen: false);

                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const Newgame(gameType: 3)),
                );

                // Use the previously fetched notifier to refresh the games
                gameListNotifier.fetchGames();
              },
              child: const Text('Oneship AI'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameListNotifier = Provider.of<GameListNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battleships'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final gameListNotifier =
                  Provider.of<GameListNotifier>(context, listen: false);
              gameListNotifier.fetchGames();
            },
          ),
        ],
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () =>
                  Scaffold.of(context).openDrawer(), // Now context is correct
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 120.0, // Adjust height as needed
              child: DrawerHeader(
                decoration: const BoxDecoration(color: Colors.blue),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Expanded(
                      flex: 2, // Adjust flex factor as needed
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 30.0, // Be cautious with fixed sizes
                        child: Icon(Icons.person, size: 30.0),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Expanded(
                      flex: 1,
                      child: Text(
                        _username,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16.0),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Adjust the flex factors and other properties as needed
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New game'),
              onTap: () async {
                var gameListNotifier =
                    Provider.of<GameListNotifier>(context, listen: false);

                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const Newgame(gameType: 0)),
                );

                // Use the previously fetched notifier to refresh the games
                gameListNotifier.fetchGames();
              },
            ),
            ListTile(
              leading: const Icon(Icons.computer),
              title: const Text('New game (AI)'),
              onTap: () {
                _showAIDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_sharp),
              title: Text(_showCompletedGames
                  ? 'Show Active Games'
                  : 'Show Completed Games'),
              onTap: () {
                setState(() {
                  _showCompletedGames = !_showCompletedGames;
                });
                _refreshGames(gameListNotifier);
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Log out'),
              onTap: () async {
                _logout();
                const Text('Log out');
              },
            ),
          ],
        ),
      ),
      body: gameListNotifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: gameListNotifier.games.length,
              itemBuilder: (context, index) {
                Game game = gameListNotifier.games[index];

                // Condition to determine whether to show the game based on its status and the _showCompletedGames flag
                if ((_showCompletedGames &&
                        (game.status == 1 || game.status == 2)) ||
                    (!_showCompletedGames &&
                        (game.status == 0 || game.status == 3))) {
                  return _buildGameTile(game, gameListNotifier);
                } else {
                  return Container(); // This will not display anything for non-matching games
                }
              },
            ),
    );
  }

  Widget _buildGameTile(Game game, GameListNotifier gameListNotifier) {
    String status = _getGameStatus(game.status);
    String opponent = game.player2 ?? 'Waiting for opponent';
    String turnMessage = _getTurnMessage(game, opponent);

    // For active games, return a Dismissible widget
    if (game.status == 0 || game.status == 3) {
      return Dismissible(
        key: Key(game.id.toString()),
        background: Container(color: Colors.red),
        onDismissed: (direction) {
          _forfeitGame(game.id, gameListNotifier);
        },
        child: ListTile(
          title: Text('Game ID: ${game.id}'),
          subtitle: Text('Players: ${game.player1} vs $opponent'),
          trailing: Text('Status: $status, Turn: $turnMessage'),
          onTap: () {
            Navigator.of(context)
                .push(MaterialPageRoute(
                  builder: (_) => PlayGame(gameId: game.id),
                ))
                .then((value) => _refreshGames(gameListNotifier));
          },
        ),
      );
    } else {
      // For completed games, return a non-dismissible ListTile
      return ListTile(
        title: Text('Game ID: ${game.id}'),
        subtitle: Text('Players: ${game.player1} vs $opponent'),
        trailing: Text('Status: $status, Turn: $turnMessage'),
        onTap: () {
          Navigator.of(context)
              .push(MaterialPageRoute(
                builder: (_) => PlayGame(gameId: game.id),
              ))
              .then((value) => _refreshGames(gameListNotifier));
        },
      );
    }
  }

  String _getGameStatus(int status) {
    switch (status) {
      case 0:
        return "Matchmaking";
      case 1:
        return "Won by Player 1";
      case 2:
        return "Won by Player 2";
      case 3:
        return "Playing";
      default:
        return "Unknown";
    }
  }

  String _getTurnMessage(Game game, String opponent) {
    if (game.turn == 0) {
      return "Not Active";
    } else if (game.turn == 1) {
      return game.player1;
    } else if (game.turn == 2 && opponent != 'Waiting for opponent') {
      return opponent;
    } else {
      return "Waiting for Turn";
    }
  }

  Future<void> _redirectToLogin() async {
    await SessionManager.clearSession();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _forfeitGame(int id, GameListNotifier gameListNotifier) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/games/$id'),
      headers: {
        'Authorization': 'Bearer ${await SessionManager.getSessionToken()}',

        // need session token to delete a post
      },
    );

    if (response.statusCode == 200) {
      print('Game deleted successfully');
      // Update the state here if necessary
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Game deleted successfully'),
          duration: Duration(milliseconds: 500),
        ));
      }
    } else if (response.statusCode == 401) {
      // Token expired, redirect to login
      await _redirectToLogin();
    } else {
      print('Error deleting game: ${response.body}');
      // Handle errors appropriately
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error deleting game: ${response.body}'),
          duration: const Duration(milliseconds: 500),
        ));
      }
    }

    _refreshGames(gameListNotifier);
  }

  Future<void> _refreshGames(GameListNotifier gameListNotifier) async {
    gameListNotifier.fetchGames();
  }
}
