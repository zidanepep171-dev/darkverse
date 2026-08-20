import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dv_theme.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class TestFunctionPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;
  final String expiredDate;

  const TestFunctionPage({
    Key? key,
    required this.sessionKey,
    required this.username,
    required this.role,
    required this.expiredDate,
  }) : super(key: key);

  @override
  State<TestFunctionPage> createState() => _TestFunctionPageState();
}

class _TestFunctionPageState extends State<TestFunctionPage> with TickerProviderStateMixin {
  final TextEditingController targetController = TextEditingController();
  final TextEditingController functionController = TextEditingController();
  final TextEditingController jumlahController = TextEditingController(text: '1');
  
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  bool _isTesting = false;
  String? _testResponseMessage;
  
  int _successCount = 0;
  int _failCount = 0;
  final List<String> _errorMessages = <String>[];
  String _currentStatus = '';

  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _fadeController.repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseController.repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController.forward();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.asset('assets/videos/banner.mp4');
    
    _videoController.initialize().then((_) {
      if (mounted) {
        setState(() {
          _videoController.setVolume(0.1);
          _videoController.setLooping(true);
          _videoController.play();
          
          _chewieController = ChewieController(
            videoPlayerController: _videoController,
            autoPlay: true,
            looping: true,
            showControls: false,
            autoInitialize: true,
            errorBuilder: (BuildContext context, String errorMessage) {
              return Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      DV.orange.withOpacity(0.3), 
                      DV.orangeLight.withOpacity(0.3)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_arrow, 
                    color: DV.orangeLight, 
                    size: 40
                  ),
                ),
              );
            },
          );
          _isVideoInitialized = true;
        });
      }
    }).catchError((dynamic error) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    targetController.dispose();
    functionController.dispose();
    jumlahController.dispose();
    _videoController.dispose();
    if (_isVideoInitialized) {
      _chewieController.dispose();
    }
    super.dispose();
  }

  String? formatPhoneNumber(String input) {
    final String cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 8) {
      return null;
    }
    return cleaned;
  }

  Future<void> _testFunction() async {
    final String rawInput = targetController.text.trim();
    final String? target = formatPhoneNumber(rawInput);
    final int jumlah = int.tryParse(jumlahController.text) ?? 1;

    if (target == null) {
      _showAlert("Invalid Number", "Gunakan nomor internasional (misal: +62)");
      return;
    }

    if (jumlah <= 0 || jumlah > 1000) {
      _showAlert("Invalid Jumlah", "Jumlah harus antara 1 - 1000");
      return;
    }

    if (functionController.text.isEmpty) {
      _showAlert("No Function", "Silakan masukkan function JavaScript");
      return;
    }

    if (mounted) {
      setState(() {
        _isTesting = true;
        _testResponseMessage = null;
        _successCount = 0;
        _failCount = 0;
        _errorMessages.clear();
        _currentStatus = 'Menganalisis function...';
      });
    }

    try {
      final http.Response response = await http.post(
        Uri.parse("http://maklu:3314/testFunction"),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'key': widget.sessionKey,
          'target': target,
          'jumlah': jumlah,
          'functionCode': functionController.text,
          'username': widget.username,
          'role': widget.role,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          if (data['success'] == true) {
            _successCount = data['successCount'] as int? ?? 0;
            _failCount = data['failCount'] as int? ?? 0;
            if (data['errors'] != null) {
              _errorMessages.addAll(List<String>.from(data['errors'] as List));
            }
            _testResponseMessage = data['message'] as String? ?? 'Test function selesai';
            _currentStatus = _failCount == 0 ? 'Berhasil' : 'Selesai dengan error';
          } else {
            _testResponseMessage = data['message'] as String? ?? 'Gagal menjalankan test';
            _currentStatus = 'Gagal';
          }
          _isTesting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResponseMessage = "Error: ${e.toString()}";
          _currentStatus = 'Error';
          _isTesting = false;
        });
      }
    }
  }

  void _showAlert(String title, String msg) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AlertDialog(
            backgroundColor: DV.bg1.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: DV.orange.withOpacity(0.3), width: 1.5),
            ),
            title: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  colors: <Color>[DV.orange, DV.orangeLight],
                ).createShader(bounds);
              },
              child: Text(
                title, 
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: Colors.white
                ),
              ),
            ),
            content: Text(msg, style: const TextStyle(color: DV.textSecondary)),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK", style: TextStyle(color: DV.orangeLight)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            DV.glassCard,
            DV.bg1.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DV.glassBorder,
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: DV.orange.withOpacity(0.15),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeaderPanel() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: DV.orange.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (_isVideoInitialized)
                Chewie(controller: _chewieController)
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        DV.orange.withOpacity(0.3), 
                        DV.orangeLight.withOpacity(0.3)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.play_arrow, color: DV.orangeLight, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          "Loading Video...",
                          style: TextStyle(color: DV.orangeLight),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      DV.bg0.withOpacity(0.8),
                      Colors.transparent,
                      DV.bg0.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const <double>[0.0, 0.5, 1.0],
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DV.glassCard,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      FadeTransition(
                        opacity: Tween<double>(begin: 0.6, end: 1.0).animate(_fadeController),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: <Color>[
                                DV.orange.withOpacity(0.4), 
                                DV.orangeLight.withOpacity(0.4)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: DV.orange.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 35,
                            backgroundImage: AssetImage('assets/images/logo.jpg'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            colors: <Color>[DV.orange, Colors.white],
                          ).createShader(bounds);
                        },
                        child: const Text(
                          "TEST FUNCTION",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: DV.orange.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: DV.orange.withOpacity(0.6)),
                            ),
                            child: Text(
                              widget.role.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: DV.glassCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: DV.glassBorder),
                            ),
                            child: Text(
                              "Exp: ${widget.expiredDate}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputPanel() {
    return SlideTransition(
      position: _slideAnimation,
      child: _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.phone_android, color: DV.orangeLight),
                const SizedBox(width: 8),
                Text(
                  "Nomor Target",
                  style: TextStyle(
                    color: DV.orangeLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: <Color>[
                    DV.glassCard,
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: TextField(
                controller: targetController,
                style: const TextStyle(color: DV.textPrimary),
                cursorColor: DV.orangeLight,
                decoration: InputDecoration(
                  hintText: "Contoh: +62xxxxxxxxxx",
                  hintStyle: const TextStyle(color: DV.textHint),
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: DV.orange.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: DV.orangeLight, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: DV.glassBorder),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Icon(Icons.functions, color: DV.orangeLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Function JavaScript",
                    style: TextStyle(
                      color: DV.orangeLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DV.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DV.orangeLight.withOpacity(0.5)),
                  ),
                  child: const Text(
                    "async function",
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: <Color>[
                    DV.glassCard,
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: TextField(
                controller: functionController,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                cursorColor: DV.orangeLight,
                maxLines: 10,
                minLines: 6,
                decoration: InputDecoration(
                  hintText: 'async function test(sock, target) {\n  await sock.sendMessage(target, { text: "Hello World" });\n  return true;\n}',
                  hintStyle: const TextStyle(color: Colors.white38, fontFamily: 'monospace'),
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: DV.orange.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: DV.orangeLight, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: DV.glassBorder),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DV.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DV.orangeLight.withOpacity(0.3)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.info_outline, color: DV.orangeLight, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Function harus diawali dengan "async function"',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Icon(Icons.format_list_numbered, color: DV.orangeLight),
                const SizedBox(width: 8),
                Text(
                  "Jumlah Eksekusi",
                  style: TextStyle(
                    color: DV.orangeLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: <Color>[
                    DV.glassCard,
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: TextField(
                controller: jumlahController,
                style: const TextStyle(color: DV.textPrimary),
                cursorColor: DV.orangeLight,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "1 - 1000",
                  hintStyle: const TextStyle(color: DV.textHint),
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: DV.orange.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: DV.orangeLight, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: DV.glassBorder),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton() {
    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (BuildContext context, Widget? child) {
          return Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: <Color>[
                  DV.orange.withOpacity(0.8),
                  DV.orangeLight.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: DV.orange.withOpacity(0.4 * _pulseController.value),
                  blurRadius: 25 * _pulseController.value,
                  spreadRadius: 3 * _pulseController.value,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isTesting ? null : _testFunction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isTesting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _currentStatus,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.play_arrow, color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        const Text(
                          "TEST FUNCTION",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTestResults() {
    if (_testResponseMessage == null && !_isTesting) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _failCount == 0
                ? <Color>[
                    DV.success.withOpacity(0.3), 
                    DV.success.withOpacity(0.1)
                  ]
                : <Color>[
                    DV.error.withOpacity(0.3), 
                    DV.error.withOpacity(0.1)
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _failCount == 0
                ? DV.success.withOpacity(0.5)
                : DV.error.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  _failCount == 0 ? Icons.check_circle : Icons.error,
                  color: _failCount == 0 ? DV.success : DV.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _testResponseMessage ?? '',
                    style: TextStyle(
                      color: _failCount == 0 ? DV.success : DV.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (_successCount > 0 || _failCount > 0) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: DV.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: <Widget>[
                          const Text('Sukses', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(
                            '$_successCount',
                            style: const TextStyle(color: DV.success, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: DV.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: <Widget>[
                          const Text('Gagal', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(
                            '$_failCount',
                            style: const TextStyle(color: DV.error, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_errorMessages.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DV.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Error Details:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 8),
                      ..._errorMessages.map((String err) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $err',
                            style: const TextStyle(color: DV.error, fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DV.bg0,
      body: Stack(
        children: <Widget>[
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    DV.orange.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    DV.orangeLight.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    _buildHeaderPanel(),
                    const SizedBox(height: 24),
                    _buildInputPanel(),
                    _buildTestButton(),
                    _buildTestResults(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}