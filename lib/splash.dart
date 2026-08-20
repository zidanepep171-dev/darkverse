// splash.dart — DarkVerse v6.0 QUANTUM DARK
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dv_theme.dart';
import 'dashboard_page.dart';

class SplashScreen extends StatefulWidget {
  final String username, password, role, expiredDate, sessionKey;
  final List<Map<String, dynamic>> listBug, listDoos;
  final List<dynamic> news;
  const SplashScreen({super.key,
    required this.username, required this.password, required this.role,
    required this.expiredDate, required this.sessionKey,
    required this.listBug, required this.listDoos, required this.news});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late VideoPlayerController _vid;
  AnimationController? _fade, _text, _ring, _pulse;
  bool _fadeDone = false, _navDone = false;

  @override
  void initState() {
    super.initState();
    _ring  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _vid = VideoPlayerController.asset('assets/videos/splash.mp4');
    _vid.initialize().then((_) {
      if (!mounted) return;
      _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
      _text = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
      setState(() {});
      _vid.setLooping(false);
      _vid.play();
      _vid.addListener(_vidListener);
    }).catchError((_) { if (mounted) Future.delayed(const Duration(seconds: 3), _go); });
  }

  void _vidListener() {
    if (_navDone || !mounted) return;
    final pos = _vid.value.position, dur = _vid.value.duration;
    if (dur > Duration.zero) {
      if (dur - pos <= const Duration(seconds: 1) && !_fadeDone) { _fadeDone = true; _fade?.forward(); }
      if (pos >= dur - const Duration(milliseconds: 100)) _go();
    }
  }

  void _go() {
    if (_navDone || !mounted) return;
    _navDone = true;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, a, __) => DashboardPage(
        username: widget.username, password: widget.password,
        role: widget.role, expiredDate: widget.expiredDate,
        sessionKey: widget.sessionKey, listBug: widget.listBug,
        listDoos: widget.listDoos, news: widget.news),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 700)));
  }

  @override
  void dispose() {
    _navDone = true;
    _vid.removeListener(_vidListener);
    _vid.dispose();
    _fade?.dispose(); _text?.dispose(); _ring?.dispose(); _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DV.bg0,
    body: Stack(children: [
      // Video
      if (_vid.value.isInitialized)
        Positioned.fill(child: FittedBox(fit: BoxFit.cover,
          child: SizedBox(width: _vid.value.size.width, height: _vid.value.size.height, child: VideoPlayer(_vid))))
      else
        Container(decoration: BoxDecoration(gradient: DV.bgGradient)),

      // Overlay
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.black.withOpacity(0.25), DV.bg0.withOpacity(0.35), DV.bg0.withOpacity(0.94)],
        stops: const [0.0, 0.5, 1.0])))),

      // Quantum grid overlay
      Positioned.fill(child: Opacity(opacity: 0.3,
        child: CustomPaint(painter: _QuantumGridPainter()))),

      // Plasma orbs
      Positioned(top: -60, right: -60, child: Container(width: 240, height: 240,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [DV.plasma.withOpacity(0.15), Colors.transparent])))),
      Positioned(bottom: -40, left: -40, child: Container(width: 180, height: 180,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [DV.holo.withOpacity(0.10), Colors.transparent])))),

      // Quantum rings
      if (_ring != null) Positioned.fill(
        child: Center(child: AnimatedBuilder(animation: _ring!, builder: (_, __) =>
          CustomPaint(painter: _QuantumRingsPainter(progress: _ring!.value))))),

      // Branding
      Positioned(bottom: 72, left: 0, right: 0,
        child: AnimatedBuilder(animation: _text ?? const AlwaysStoppedAnimation(1.0), builder: (_, __) {
          final t = _text?.value ?? 1.0;
          return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, (1-t) * 28),
            child: Column(children: [
              ShaderMask(shaderCallback: (b) => DV.fireGradient.createShader(b),
                child: const Text('DarkVerse', style: TextStyle(
                  fontSize: 44, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: 6, fontFamily: 'Orbitron'))),
              const SizedBox(height: 10),
              // Holo badge
              AnimatedBuilder(animation: _pulse ?? const AlwaysStoppedAnimation(0.5), builder: (_, __) {
                final p = _pulse?.value ?? 0.5;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: DV.holo.withOpacity(0.3 + p * 0.2), width: 1.2),
                    color: DV.holo.withOpacity(0.05),
                    boxShadow: [BoxShadow(color: DV.holo.withOpacity(0.12 + p * 0.08), blurRadius: 20)]),
                  child: ShaderMask(shaderCallback: (b) => DV.holoGradient.createShader(b),
                    child: const Text('QUANTUM DARK v6.0', style: TextStyle(
                      color: Colors.white, fontSize: 10, letterSpacing: 4, fontFamily: 'Orbitron'))));
              }),
            ])));
        })),

      if (_fadeDone && _fade != null)
        AnimatedBuilder(animation: _fade!, builder: (_, __) =>
          Opacity(opacity: _fade!.value, child: Container(color: DV.bg0))),
    ]),
  );
}

class _QuantumGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFB300FF).withOpacity(0.04)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _QuantumRingsPainter extends CustomPainter {
  final double progress;
  _QuantumRingsPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..style = PaintingStyle.stroke;
    final rings = [
      (90.0, DV.plasma, 0.10, 1.2),
      (140.0, DV.holo, 0.07, 1.0),
      (190.0, DV.neonM, 0.05, 0.8),
      (240.0, DV.plasma, 0.04, 0.6),
    ];
    for (int i = 0; i < rings.length; i++) {
      final (r, color, opacity, strokeW) = rings[i];
      paint.color = color.withOpacity(opacity);
      paint.strokeWidth = strokeW;
      final startAngle = progress * math.pi * 2 + i * math.pi * 0.5;
      final sweepAngle = math.pi * (1.2 + i * 0.2);
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle, sweepAngle, false, paint);
    }
    // Dot markers
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      final r = 90.0 + i * 50;
      final angle = progress * math.pi * 2 + i * math.pi * 0.7;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      final color = i == 0 ? DV.plasma : (i == 1 ? DV.holo : DV.neonM);
      dotPaint.color = color;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
      dotPaint.color = color.withOpacity(0.3);
      canvas.drawCircle(Offset(x, y), 6, dotPaint);
    }
  }
  @override bool shouldRepaint(_QuantumRingsPainter old) => old.progress != progress;
}
