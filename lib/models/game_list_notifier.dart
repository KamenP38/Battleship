import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/game.dart';
import '../utils/sessionmanager.dart';

class GameListNotifier extends ChangeNotifier {
  List<Game> games = [];
  bool isLoading = true;
  final String baseUrl = 'http://165.227.117.48';

  GameListNotifier() {
    fetchGames();
  }

  void removeGame(int gameId) {
    games.removeWhere((game) => game.id == gameId);
    notifyListeners();
  }

  Future<bool> fetchGames() async {
    isLoading = true;
    notifyListeners();

    String? token = await SessionManager.getSessionToken();
    if (token.isEmpty) {
      isLoading = false;
      notifyListeners();
      return false;
    }

    var url = Uri.parse('$baseUrl/games');
    var response =
        await http.get(url, headers: {"Authorization": "Bearer $token"});

    if (response.statusCode == 200) {
      List<dynamic> gamesJson = json.decode(response.body)['games'];
      games = gamesJson.map((json) => Game.fromJson(json)).toList();
      isLoading = false;
      notifyListeners();
      return true;
    } else {
      isLoading = false;
      notifyListeners();
      return response.statusCode == 401;
    }
  }
}
