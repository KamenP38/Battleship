class Game {
  final int id;
  final String player1;
  final String? player2;
  final int position;
  final int status;
  final int turn;

  Game({
    required this.id, 
    required this.player1, 
    this.player2,
    required this.position, 
    required this.status, 
    required this.turn
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      player1: json['player1'],
      player2: json['player2'] as String?,
      position: json['position'],
      status: json['status'],
      turn: json['turn'],
    );
  }
}