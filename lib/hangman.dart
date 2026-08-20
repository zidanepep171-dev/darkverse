import 'package:flutter/material.dart';
import 'dv_theme.dart';

class HangmanApp extends StatelessWidget {
  const HangmanApp({super.key});

  @override
  Widget build(BuildContext context) => const HangmanScreen();
}

class HangmanScreen extends StatefulWidget {
  const HangmanScreen({super.key});

  @override
  State<HangmanScreen> createState() => _HangmanScreenState();
}

class _HangmanScreenState extends State<HangmanScreen> {
  late HangmanGame game;
  final List<String> words = [
    'FLUTTER',
    'DART',
    'PROGRAMMING',
    'MOBILE',
    'DEVELOPER',
    'ANDROID',
    'IOS',
    'WIDGET',
  ];

  @override
  void initState() {
    super.initState();
    startNewGame();
  }

  void startNewGame() {
    final randomWord = words[DateTime.now().millisecond % words.length];
    game = HangmanGame(randomWord);
  }

  void handleLetterTap(String letter) {
    if (game.isGameOver) return;

    setState(() {
      game.guessLetter(letter);
    });

    // Cek game over
    if (game.isGameOver) {
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(game.isWin ? '🎉 Kamu Menang!' : '😵 Game Over'),
          content: Text(
            game.isWin 
                ? 'Selamat! Kata: ${game.word}'
                : 'Kata yang benar: ${game.word}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  startNewGame();
                });
              },
              child: const Text('Main Lagi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hangman Game'),
        centerTitle: true,
        backgroundColor: DV.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Gambar Hangman
            HangmanDrawing(wrongAttempts: game.wrongAttempts),
            
            const SizedBox(height: 20),
            
            // Tampilan kata
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              decoration: BoxDecoration(
                color: DV.bg1,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                game.displayWord,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Info huruf yang sudah ditebak
            Text(
              'Huruf salah: ${game.wrongAttempts}/${game.maxAttempts}',
              style: const TextStyle(fontSize: 18),
            ),
            
            const SizedBox(height: 20),
            
            // Keyboard
            Expanded(
              child: Keyboard(
                onLetterTap: handleLetterTap,
                guessedLetters: game.guessedLetters,
                isGameOver: game.isGameOver,
                word: game.word,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget untuk menggambar Hangman
class HangmanDrawing extends StatelessWidget {
  final int wrongAttempts;

  const HangmanDrawing({super.key, required this.wrongAttempts});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: HangmanPainter(wrongAttempts: wrongAttempts),
    );
  }
}

// Painter untuk menggambar Hangman
class HangmanPainter extends CustomPainter {
  final int wrongAttempts;

  HangmanPainter({required this.wrongAttempts});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DV.textPrimary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Tiang gantungan (selalu digambar)
    canvas.drawLine(Offset(centerX - 40, centerY + 60), Offset(centerX + 40, centerY + 60), paint); // dasar
    canvas.drawLine(Offset(centerX, centerY - 60), Offset(centerX, centerY + 60), paint); // tiang tegak
    canvas.drawLine(Offset(centerX, centerY - 60), Offset(centerX + 40, centerY - 60), paint); // tiang atas
    canvas.drawLine(Offset(centerX + 40, centerY - 60), Offset(centerX + 40, centerY - 40), paint); // tali

    // Gambar bagian tubuh berdasarkan jumlah kesalahan
    if (wrongAttempts >= 1) {
      // Kepala
      canvas.drawCircle(Offset(centerX + 40, centerY - 30), 10, paint);
    }
    
    if (wrongAttempts >= 2) {
      // Badan
      canvas.drawLine(Offset(centerX + 40, centerY - 20), Offset(centerX + 40, centerY + 10), paint);
    }
    
    if (wrongAttempts >= 3) {
      // Tangan kiri
      canvas.drawLine(Offset(centerX + 40, centerY - 15), Offset(centerX + 25, centerY), paint);
    }
    
    if (wrongAttempts >= 4) {
      // Tangan kanan
      canvas.drawLine(Offset(centerX + 40, centerY - 15), Offset(centerX + 55, centerY), paint);
    }
    
    if (wrongAttempts >= 5) {
      // Kaki kiri
      canvas.drawLine(Offset(centerX + 40, centerY + 10), Offset(centerX + 25, centerY + 25), paint);
    }
    
    if (wrongAttempts >= 6) {
      // Kaki kanan
      canvas.drawLine(Offset(centerX + 40, centerY + 10), Offset(centerX + 55, centerY + 25), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Widget Keyboard
class Keyboard extends StatelessWidget {
  final Function(String) onLetterTap;
  final List<String> guessedLetters;
  final bool isGameOver;
  final String word;

  const Keyboard({
    super.key,
    required this.onLetterTap,
    required this.guessedLetters,
    required this.isGameOver,
    required this.word,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: alphabet.length,
      itemBuilder: (context, index) {
        final letter = alphabet[index];
        final bool isGuessed = guessedLetters.contains(letter);
        final bool isCorrect = word.contains(letter);

        Color buttonColor = DV.orange;
        if (isGuessed) {
          buttonColor = isCorrect ? DV.success : DV.error;
        }

        return ElevatedButton(
          onPressed: (isGameOver || isGuessed) 
              ? null 
              : () => onLetterTap(letter),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

// Model HangmanGame
class HangmanGame {
  late String word;
  late List<String> guessedLetters;
  late int wrongAttempts;
  final int maxAttempts = 6;
  
  HangmanGame(String selectedWord) {
    word = selectedWord.toUpperCase();
    guessedLetters = [];
    wrongAttempts = 0;
  }
  
  // Menampilkan progres kata
  String get displayWord {
    String display = '';
    for (int i = 0; i < word.length; i++) {
      String letter = word[i];
      if (guessedLetters.contains(letter)) {
        display += '$letter ';
      } else {
        display += '_ ';
      }
    }
    return display.trim();
  }
  
  // Cek apakah huruf sudah ditebak
  bool isLetterGuessed(String letter) {
    return guessedLetters.contains(letter);
  }
  
  // Proses tebakan huruf
  bool guessLetter(String letter) {
    letter = letter.toUpperCase();
    
    if (guessedLetters.contains(letter)) {
      return false;
    }
    
    guessedLetters.add(letter);
    
    if (!word.contains(letter)) {
      wrongAttempts++;
      return false;
    }
    
    return true;
  }
  
  // Cek menang
  bool get isWin {
    for (int i = 0; i < word.length; i++) {
      if (!guessedLetters.contains(word[i])) {
        return false;
      }
    }
    return true;
  }
  
  // Cek kalah
  bool get isLoss {
    return wrongAttempts >= maxAttempts;
  }
  
  // Cek game selesai
  bool get isGameOver {
    return isWin || isLoss;
  }
  
  // Reset game
  void resetGame(String newWord) {
    word = newWord.toUpperCase();
    guessedLetters = [];
    wrongAttempts = 0;
  }
}