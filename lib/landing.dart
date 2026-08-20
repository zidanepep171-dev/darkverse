// landing.dart — DarkVerse v6.0 QUANTUM DARK
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dv_theme.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late AnimationController _entry, _plasma, _scan, _orbit, _glitch, _data;
  late Animation<double> _fade, _plasmaAnim, _orbitAnim, _glitchAnim, _dataAnim;
  late Animation<Offset> _slide;
  int _phraseIdx = 0;
  String _typed = '';
  Timer? _typeTimer, _glitchTimer;
  final _phrases = ['BUG SENDER v6', 'DDOS ENGINE', 'OSINT TOOLS', 'NEURAL HACK', 'QUANTUM DARK'];

  @override
  void initState() {
    super.initState();
    _entry  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
    _plasma = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _scan   = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _orbit  = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _glitch = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _data   = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);

    _fade      = CurvedAnimation(parent: _entry, curve: Curves.easeOut);
    _slide     = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));
    _plasmaAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_plasma);
    _orbitAnim  = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(_orbit);
    _glitchAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_glitch);
    _dataAnim   = Tween<double>(begin: 0.0, end: 1.0).animate(_data);

    _type();
    _glitchTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) { _glitch.reset(); _glitch.forward(); }
    });
  }

  void _type() {
    _typeTimer = Timer.periodic(const Duration(milliseconds: 55), (_) {
      final t = _phrases[_phraseIdx];
      if (_typed.length < t.length) {
        setState(() => _typed = t.substring(0, _typed.length + 1));
      } else {
        _typeTimer?.cancel();
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (!mounted) return;
          setState(() { _typed = ''; _phraseIdx = (_phraseIdx + 1) % _phrases.length; });
          _type();
        });
      }
    });
  }

  @override
  void dispose() {
    _entry.dispose(); _plasma.dispose(); _scan.dispose();
    _orbit.dispose(); _glitch.dispose(); _data.dispose();
    _typeTimer?.cancel(); _glitchTimer?.cancel();
    super.dispose();
  }

  void _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DV.bg0,
      body: Stack(children: [
        _quantumBg(),
        SafeArea(child: FadeTransition(opacity: _fade,
          child: SlideTransition(position: _slide,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(children: [
                _topBar(),
                _hero(),
                _dataStats(),
                _featureGrid(),
                _ctaSection(),
                _socialRow(),
                const SizedBox(height: 48),
              ]))))),
      ]),
    );
  }

  Widget _quantumBg() => Stack(children: [
    Container(color: DV.bg0),
    // Quantum mesh grid
    Positioned.fill(child: CustomPaint(painter: _QuantumMeshPainter())),
    // Primary plasma orb — top right
    AnimatedBuilder(animation: _plasmaAnim, builder: (_, __) => Positioned(
      top: -100 + _plasmaAnim.value * 25, right: -80 + _plasmaAnim.value * 15,
      child: Container(width: 400, height: 400, decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          DV.plasma.withOpacity(0.22 + _plasmaAnim.value * 0.08),
          DV.ion.withOpacity(0.08),
          Colors.transparent,
        ], stops: const [0.0, 0.5, 1.0]))))),
    // Holo orb — mid left
    AnimatedBuilder(animation: _plasmaAnim, builder: (_, __) => Positioned(
      top: MediaQuery.of(context).size.height * 0.35, left: -60,
      child: Container(width: 300, height: 300, decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          DV.holo.withOpacity(0.08 + (1-_plasmaAnim.value) * 0.06),
          Colors.transparent,
        ]))))),
    // Bottom magenta orb
    AnimatedBuilder(animation: _plasmaAnim, builder: (_, __) => Positioned(
      bottom: -80, right: 40,
      child: Container(width: 250, height: 250, decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          DV.neonM.withOpacity(0.10 + _plasmaAnim.value * 0.05),
          Colors.transparent,
        ]))))),
    // Orbiting particle
    AnimatedBuilder(animation: _orbitAnim, builder: (_, __) {
      final cx = MediaQuery.of(context).size.width * 0.8;
      final cy = 180.0;
      final r = 120.0;
      final x = cx + r * math.cos(_orbitAnim.value);
      final y = cy + r * math.sin(_orbitAnim.value);
      return Positioned(left: x - 4, top: y - 4,
        child: Container(width: 8, height: 8, decoration: BoxDecoration(
          shape: BoxShape.circle, color: DV.holo,
          boxShadow: [BoxShadow(color: DV.holo.withOpacity(0.8), blurRadius: 10, spreadRadius: 2)])));
    }),
    // Data stream scan lines
    AnimatedBuilder(animation: _scan, builder: (_, __) => Positioned(
      top: MediaQuery.of(context).size.height * _scan.value - 1,
      left: 0, right: 0,
      child: Container(height: 1, decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.transparent, DV.plasma.withOpacity(0.25),
          DV.holo.withOpacity(0.15), Colors.transparent]))))),
    // Secondary scan
    AnimatedBuilder(animation: _scan, builder: (_, __) {
      final offset = (_scan.value + 0.5) % 1.0;
      return Positioned(
        top: MediaQuery.of(context).size.height * offset - 1,
        left: 0, right: 0,
        child: Container(height: 1, decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent, DV.holo.withOpacity(0.12),
            DV.plasma.withOpacity(0.08), Colors.transparent]))));
    }),
  ]);

  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: Row(children: [
      // Quantum logo
      AnimatedBuilder(animation: _plasmaAnim, builder: (_, __) => Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: DV.fireGradient,
          boxShadow: [
            BoxShadow(color: DV.plasma.withOpacity(0.5 + _plasmaAnim.value * 0.2), blurRadius: 20, spreadRadius: -2),
            BoxShadow(color: DV.holo.withOpacity(0.15), blurRadius: 30),
          ]),
        child: const Icon(Icons.hub_rounded, color: Colors.white, size: 22))),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ShaderMask(shaderCallback: (b) => DV.fireGradient.createShader(b),
          child: const Text('DarkVerse', style: TextStyle(color: Colors.white, fontFamily: 'Orbitron',
              fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 3))),
        Row(children: [
          Container(width: 4, height: 4, decoration: BoxDecoration(
            shape: BoxShape.circle, color: DV.holo,
            boxShadow: [BoxShadow(color: DV.holo.withOpacity(0.8), blurRadius: 4)])),
          const SizedBox(width: 5),
          const Text('QUANTUM DARK v6.0', style: TextStyle(color: DV.textHint, fontSize: 8, letterSpacing: 2)),
        ]),
      ]),
      const Spacer(),
      // Live status
      AnimatedBuilder(animation: _dataAnim, builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: DV.success.withOpacity(0.06),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: DV.success.withOpacity(0.20 + _dataAnim.value * 0.15)),
          boxShadow: [BoxShadow(color: DV.success.withOpacity(0.06 + _dataAnim.value * 0.06), blurRadius: 14)]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(
            shape: BoxShape.circle, color: DV.success,
            boxShadow: [BoxShadow(color: DV.success.withOpacity(0.8), blurRadius: 8, spreadRadius: 1)])),
          const SizedBox(width: 7),
          const Text('LIVE', style: TextStyle(color: DV.success, fontSize: 9,
              fontWeight: FontWeight.w800, letterSpacing: 2.5, fontFamily: 'Orbitron')),
        ]))),
    ]),
  );

  Widget _hero() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
    child: AnimatedBuilder(animation: _glitchAnim, builder: (_, __) {
      final glitch = _glitchAnim.value;
      return Transform.translate(
        offset: Offset(glitch > 0.5 ? (glitch - 0.5) * 6 : 0, 0),
        child: Container(
          width: double.infinity, height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: glitch > 0.3 ? DV.holo.withOpacity(0.8) : DV.borderHi.withOpacity(0.6),
              width: 1.5),
            boxShadow: [
              BoxShadow(color: DV.glow, blurRadius: 40, spreadRadius: -5, offset: const Offset(0, 14)),
              BoxShadow(color: DV.glowHolo.withOpacity(0.2), blurRadius: 60, spreadRadius: -10),
              if (glitch > 0.3) BoxShadow(color: DV.holo.withOpacity(0.3), blurRadius: 20),
            ]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: Stack(children: [
              // Hero image
              Positioned.fill(child: Image.asset('assets/images/reze.png', fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(decoration: const BoxDecoration(gradient: DV.fireGradient)))),
              // Chromatic aberration on glitch
              if (glitch > 0.4) Positioned.fill(child: Transform.translate(
                offset: Offset(glitch * 4, 0),
                child: Opacity(opacity: glitch * 0.3,
                  child: Container(decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [DV.holo.withOpacity(0.2), Colors.transparent, DV.neonM.withOpacity(0.2)])))),
              )),
              // Overlay
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.15), DV.bg0.withOpacity(0.45), DV.bg0.withOpacity(0.97)],
                  stops: const [0.0, 0.5, 1.0])))),
              // Scan lines texture
              Positioned.fill(child: CustomPaint(painter: _ScanlinesPainter())),
              // Corner brackets — HUD style
              Positioned(top: 14, left: 14, child: _cornerBracket(false, false)),
              Positioned(top: 14, right: 14, child: _cornerBracket(false, true)),
              // Content
              Positioned(bottom: 22, left: 22, right: 22, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                // System badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: DV.plasma.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: DV.borderHi.withOpacity(0.5))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 5, height: 5, decoration: BoxDecoration(
                      shape: BoxShape.circle, color: DV.plasma,
                      boxShadow: [BoxShadow(color: DV.plasma.withOpacity(0.9), blurRadius: 6)])),
                    const SizedBox(width: 8),
                    const Text('SYS::QUANTUM_DARK_TOOLKIT', style: TextStyle(
                      color: DV.textGlow, fontSize: 9, letterSpacing: 2.5, fontFamily: 'Orbitron')),
                  ])),
                const SizedBox(height: 10),
                // Typewriter
                Row(children: [
                  Text(_typed, style: const TextStyle(color: DV.textPrimary, fontSize: 22,
                      fontWeight: FontWeight.w900, fontFamily: 'Orbitron', letterSpacing: 1.5)),
                  AnimatedBuilder(animation: _dataAnim, builder: (_, __) =>
                    Opacity(opacity: _dataAnim.value,
                      child: ShaderMask(shaderCallback: (b) => DV.holoGradient.createShader(b),
                        child: const Text('_', style: TextStyle(color: Colors.white, fontSize: 22, fontFamily: 'Orbitron'))))),
                ]),
                const SizedBox(height: 5),
                Text('ELITE HACKING PLATFORM // CLASSIFIED ACCESS ONLY',
                  style: TextStyle(color: DV.textSecondary.withOpacity(0.6), fontSize: 10, letterSpacing: 1)),
              ])),
            ]),
          )),
      );
    }),
  );

  Widget _cornerBracket(bool bottom, bool right) {
    return SizedBox(width: 20, height: 20,
      child: CustomPaint(painter: _CornerBracketPainter(bottom: bottom, right: right)));
  }

  Widget _dataStats() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: Row(children: [
      _statChip(Icons.people_rounded, '1K+', 'USERS', DV.plasma),
      const SizedBox(width: 10),
      _statChip(Icons.terminal_rounded, '22', 'MODULES', DV.holo),
      const SizedBox(width: 10),
      _statChip(Icons.rocket_launch_rounded, 'V6', 'QUANTUM', DV.neonM),
    ]),
  );

  Widget _statChip(IconData icon, String val, String label, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.22)),
      boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 14)]),
    child: Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 5),
      Text(val, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Orbitron')),
      Text(label, style: const TextStyle(color: DV.textHint, fontSize: 8, letterSpacing: 1.5)),
    ])));

  Widget _featureGrid() {
    final items = <(IconData, String, String, Color, LinearGradient)>[
      (Icons.bug_report_rounded,      'Bug Sender',   'WA Crasher',    DV.plasma,  DV.fireGradient),
      (Icons.bolt_rounded,            'DDoS Panel',   'Stress Test',   DV.neonM,   DV.hotGradient),
      (Icons.manage_search_rounded,   'OSINT',        'NIK & Domain',  DV.holo,    DV.holoGradient),
      (Icons.electric_bolt_rounded,   'Zyhrx',        'Paranel Blast', DV.ion,     DV.coldGradient),
      (Icons.music_note_rounded,      'Spotify',      'Play Music',    DV.neonG,   DV.cyanGradient),
      (Icons.sports_esports_rounded,  'Games',        'Mini Games',    DV.xray,    DV.coldGradient),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 3, height: 18,
            decoration: BoxDecoration(gradient: DV.holoGradient, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          ShaderMask(shaderCallback: (b) => DV.holoGradient.createShader(b),
            child: const Text('QUANTUM MODULES', style: TextStyle(color: Colors.white,
                fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 3, fontFamily: 'Orbitron'))),
        ]),
        const SizedBox(height: 14),
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.92,
          children: items.map<Widget>((e) => _featureTile(e.$1, e.$2, e.$3, e.$4, e.$5)).toList()),
      ]),
    );
  }

  Widget _featureTile(IconData icon, String title, String sub, Color color, LinearGradient grad) => Container(
    decoration: BoxDecoration(
      color: DV.bgCard,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withOpacity(0.20)),
      boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 14)]),
    child: Stack(children: [
      Positioned(top: -8, right: -8, child: Container(width: 56, height: 56,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withOpacity(0.16), Colors.transparent])))),
      Padding(padding: const EdgeInsets.all(14), child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: grad,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)]),
            child: Icon(icon, color: Colors.white, size: 20)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: DV.textPrimary, fontSize: 11,
              fontWeight: FontWeight.w800), maxLines: 1),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: color.withOpacity(0.7), fontSize: 9)),
        ])),
    ]));

  Widget _ctaSection() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
    child: Column(children: [
      // Main CTA — holographic button
      GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/login'),
        child: AnimatedBuilder(animation: _plasmaAnim, builder: (_, __) => Container(
          height: 62,
          decoration: BoxDecoration(
            gradient: DV.fireGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: DV.plasma.withOpacity(0.55 + _plasmaAnim.value * 0.2),
                blurRadius: 30 + _plasmaAnim.value * 12, offset: const Offset(0, 10)),
              BoxShadow(color: DV.holo.withOpacity(0.15), blurRadius: 40),
            ]),
          child: Stack(children: [
            Positioned.fill(child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AnimatedBuilder(animation: _orbit, builder: (_, __) =>
                CustomPaint(painter: _HoloShimmerPainter(progress: _orbit.value / (2 * math.pi)))))),
            const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.fingerprint_rounded, color: Colors.white, size: 26),
              SizedBox(width: 12),
              Text('AKSES SISTEM', style: TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w900, letterSpacing: 3.5, fontFamily: 'Orbitron')),
            ])),
          ]))),
      ),
      const SizedBox(height: 12),
      // Secondary — holographic outline
      GestureDetector(
        onTap: () => _open('https://t.me/InfoChDarkness/292'),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DV.holo.withOpacity(0.5), width: 1.5),
            color: DV.holo.withOpacity(0.04),
            boxShadow: [BoxShadow(color: DV.glowHolo.withOpacity(0.12), blurRadius: 16)]),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ShaderMask(shaderCallback: (b) => DV.holoGradient.createShader(b),
              child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20)),
            const SizedBox(width: 10),
            ShaderMask(shaderCallback: (b) => DV.holoGradient.createShader(b),
              child: const Text('BELI AKSES', style: TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w700, letterSpacing: 2.5, fontFamily: 'Orbitron'))),
          ])),
      ),
    ]),
  );

  Widget _socialRow() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    child: Row(children: [
      Expanded(child: _socialBtn(FontAwesomeIcons.telegram, 'Telegram', const Color(0xFF229ED9), 'https://t.me/InfoChDarkness')),
      const SizedBox(width: 12),
      Expanded(child: _socialBtn(FontAwesomeIcons.whatsapp, 'WhatsApp', const Color(0xFF25D366), 'https://wa.me/6283165770011')),
    ]),
  );

  Widget _socialBtn(IconData icon, String label, Color color, String url) => GestureDetector(
    onTap: () => _open(url),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        FaIcon(icon, color: color, size: 15),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ])));
}

// ── Custom Painters ────────────────────────────────────────────────────────────
class _QuantumMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pDot = Paint()..color = const Color(0xFFB300FF).withOpacity(0.08)..strokeWidth = 1;
    final pLine = Paint()..color = const Color(0xFF00FFEA).withOpacity(0.03)..strokeWidth = 0.5;
    // Dots grid
    for (double x = 0; x < size.width; x += 36) {
      for (double y = 0; y < size.height; y += 36) {
        canvas.drawCircle(Offset(x, y), 1, pDot);
      }
    }
    // Diagonal lines
    for (double i = -size.height; i < size.width + size.height; i += 80) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), pLine);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.black.withOpacity(0.12)..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _CornerBracketPainter extends CustomPainter {
  final bool bottom, right;
  _CornerBracketPainter({required this.bottom, required this.right});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF00FFEA).withOpacity(0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final x = right ? 0.0 : size.width;
    final y = bottom ? 0.0 : size.height;
    final ex = right ? size.width : 0.0;
    final ey = bottom ? size.height : 0.0;
    canvas.drawLine(Offset(x, y), Offset(ex, y), p);
    canvas.drawLine(Offset(x, y), Offset(x, ey), p);
  }
  @override bool shouldRepaint(_) => false;
}

class _HoloShimmerPainter extends CustomPainter {
  final double progress;
  _HoloShimmerPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * progress;
    final gradient = LinearGradient(
      colors: [Colors.transparent, Colors.white.withOpacity(0.12), DV.holo.withOpacity(0.08), Colors.transparent],
      stops: const [0.0, 0.4, 0.6, 1.0]);
    final rect = Rect.fromLTWH(x - 80, 0, 160, size.height);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }
  @override bool shouldRepaint(_HoloShimmerPainter old) => old.progress != progress;
}
