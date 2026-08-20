import 'package:flutter/material.dart';
import 'dv_theme.dart';
import 'tictac_page.dart';
import 'snake_page.dart';
import 'hangman.dart';

class GameAreaPage extends StatelessWidget {
  const GameAreaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final games = [
      {
        "title": "Tic Tac Toe",
        "subtitle": "Classic Strategy Game",
        "icon": Icons.grid_3x3,
        "color": DV.orange,
        "page": const TicTacPage(),
      },      {
        "title": "Snake Game",
        "subtitle": "Retro Arcade Fun",
        "icon": Icons.sports_esports,
        "color": DV.success,
        "page": const SnakePage(),
      },
      {
        "title": "hangman game ",
        "subtitle": "tebak kata",
        "icon": Icons.search,
        "color": DV.orange,
        "page": const HangmanApp(),
      },
    ];

    return Scaffold(
      backgroundColor: DV.bg0,
      appBar: AppBar(backgroundColor: DV.bg0, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: DV.orange), onPressed: () => Navigator.pop(context)), title: ShaderMask(shaderCallback: (b) => DV.fireGradient.createShader(b), child: const Text('GAME ZONE', style: TextStyle(color: Colors.white, fontFamily: 'Orbitron', fontWeight: FontWeight.w800, fontSize: 15))), centerTitle: true),
      body: Container(
        color: DV.bg0,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: games.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    final game = games[index];

                    return InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => game["page"] as Widget,
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: DV.bg1,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  DV.orange.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              game["icon"] as IconData,
                              size: 65,
                              color: DV.textPrimary,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              game["title"].toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: DV.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              game["subtitle"].toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: DV.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}