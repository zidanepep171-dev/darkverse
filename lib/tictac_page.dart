import 'package:flutter/material.dart';
import 'dv_theme.dart';

class TicTacPage extends StatefulWidget {
  const TicTacPage({super.key});

  @override
  State<TicTacPage> createState() => _TicTacPageState();
}

class _TicTacPageState extends State<TicTacPage> {
  List<String> board = List.generate(9, (_) => "");
  String currentPlayer = "X";
  String winner = "";

  void tap(int index) {
    if (board[index] != "" || winner != "") return;

    setState(() {
      board[index] = currentPlayer;
      checkWinner();
      if (winner == "") {
        currentPlayer = currentPlayer == "X" ? "O" : "X";
      }
    });
  }

  void checkWinner() {
    List<List<int>> winPatterns = [
      [0,1,2],[3,4,5],[6,7,8],
      [0,3,6],[1,4,7],[2,5,8],
      [0,4,8],[2,4,6],
    ];

    for (var pattern in winPatterns) {
      if (board[pattern[0]] != "" &&
          board[pattern[0]] == board[pattern[1]] &&
          board[pattern[1]] == board[pattern[2]]) {
        winner = board[pattern[0]];
      }
    }
  }

  void reset() {
    setState(() {
      board = List.generate(9, (_) => "");
      currentPlayer = "X";
      winner = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DV.bg0,
      appBar: AppBar(backgroundColor: DV.bg0, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: DV.orange), onPressed: () => Navigator.pop(context)), title: ShaderMask(shaderCallback: (b) => DV.fireGradient.createShader(b), child: const Text('TIC TAC TOE', style: TextStyle(color: Colors.white, fontFamily: 'Orbitron', fontWeight: FontWeight.w800, fontSize: 14))), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              /// TITLE
              const Text(
                "TIC TAC TOE",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 20),

              /// PLAYER TURN / WINNER
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: DV.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  winner != ""
                      ? "🏆 Winner: $winner"
                      : "Turn: $currentPlayer",
                  style: const TextStyle(
                      fontSize: 20,
                      color: DV.textPrimary),
                ),
              ),

              const SizedBox(height: 30),

              /// BOARD
              SizedBox(
                width: 320,
                height: 320,
                child: GridView.builder(
                  itemCount: 9,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => tap(index),
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: DV.bg1,
                          borderRadius:
                              BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: board[index] == "X"
                                  ? DV.orange.withOpacity(0.6)
                                  : board[index] == "O"
                                      ? DV.orangeLight.withOpacity(0.6)
                                      : DV.bg2,
                              blurRadius: 15,
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            board[index],
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: board[index] == "X"
                                  ? Colors.blue
                                  : Colors.pink,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              /// RESET BUTTON
              ElevatedButton(
                onPressed: reset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DV.orange,
                  foregroundColor: DV.bg0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "RESET GAME",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}