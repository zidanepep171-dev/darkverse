import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dv_theme.dart';

class SnakePage extends StatefulWidget {
  const SnakePage({super.key});

  @override
  State<SnakePage> createState() => _SnakePageState();
}

class _SnakePageState extends State<SnakePage> {
  static const int rowSize = 20;
  static const int totalSquares = rowSize * rowSize;

  List<int> snake = [45, 65, 85];
  int food = 100;
  String direction = "down";
  Timer? timer;
  int score = 0;

  void startGame() {
    timer = Timer.periodic(const Duration(milliseconds: 180), (timer) {
      moveSnake();
    });
  }

  void moveSnake() {
    setState(() {
      int newHead;

      switch (direction) {
        case "down":
          newHead = snake.last + rowSize;
          break;
        case "up":
          newHead = snake.last - rowSize;
          break;
        case "left":
          newHead = snake.last - 1;
          break;
        default:
          newHead = snake.last + 1;
      }

      if (newHead >= totalSquares ||
          newHead < 0 ||
          snake.contains(newHead)) {
        timer?.cancel();
        showGameOver();
        return;
      }

      snake.add(newHead);

      if (newHead == food) {
        score++;
        food = Random().nextInt(totalSquares);
      } else {
        snake.removeAt(0);
      }
    });
  }

  void showGameOver() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DV.bg0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "💀 GAME OVER",
          style: TextStyle(color: DV.error),
        ),
        content: Text(
          "Score: $score",
          style: const TextStyle(color: DV.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              resetGame();
            },
            child: const Text(
              "RESTART",
              style: TextStyle(color: DV.orangeLight),
            ),
          )
        ],
      ),
    );
  }

  void resetGame() {
    setState(() {
      snake = [45, 65, 85];
      direction = "down";
      score = 0;
      food = Random().nextInt(totalSquares);
    });
    startGame();
  }

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: DV.bg0,
        child: SafeArea(
          child: Column(
            children: [

              const SizedBox(height: 20),

              /// SCORE CARD
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 25, vertical: 12),
                decoration: BoxDecoration(
                  color: DV.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "🐍 Score: $score",
                  style: const TextStyle(
                      fontSize: 20,
                      color: DV.textPrimary,
                      fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              /// GAME BOARD
              Expanded(
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.delta.dy > 0 &&
                        direction != "up") {
                      direction = "down";
                    } else if (details.delta.dy < 0 &&
                        direction != "down") {
                      direction = "up";
                    }
                  },
                  onHorizontalDragUpdate: (details) {
                    if (details.delta.dx > 0 &&
                        direction != "left") {
                      direction = "right";
                    } else if (details.delta.dx < 0 &&
                        direction != "right") {
                      direction = "left";
                    }
                  },
                  child: GridView.builder(
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: totalSquares,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: rowSize,
                    ),
                    itemBuilder: (context, index) {
                      if (snake.contains(index)) {
                        return Container(
                          margin:
                              const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: index ==
                                    snake.last
                                ? DV.orangeLight
                                : DV.orange,
                            borderRadius:
                                BorderRadius.circular(
                                    4),
                            boxShadow: [
                              BoxShadow(
                                color: DV.orangeLight
                                    .withOpacity(0.7),
                                blurRadius: 6,
                              )
                            ],
                          ),
                        );
                      } else if (index == food) {
                        return Container(
                          margin:
                              const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: DV.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: DV.error
                                    .withOpacity(0.8),
                                blurRadius: 8,
                              )
                            ],
                          ),
                        );
                      } else {
                        return Container(
                          margin:
                              const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: DV.bg1.withOpacity(0.8),
                            borderRadius:
                                BorderRadius.circular(
                                    2),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}