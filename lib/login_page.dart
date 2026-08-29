// login_page.dart — DarkVerse v6.0 QUANTUM DARK
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dv_theme.dart';
import 'splash.dart';

const String baseUrl = 'http://127.0.0.1:3500';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  bool _loading = false, _obscure = true;
  String? _androidId;

  late AnimationController _entry, _pulse, _scan, _orb, _ring;
  late Animation<double> _fade, _pulseVal, _orbAnim, _ringAnim;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
    _scan  = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _orb   = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500))..repeat(reverse: true);
    _ring  = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

    _fade     = CurvedAnimation(parent: _entry, curve: Curves.easeOut);
    _slide    = Tween<Offset>(begin: const Offset(0, 0.28), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));
    _pulseVal = Tween<double>(begin: 0.0, end: 1.0).animate(_pulse);
    _orbAnim  = Tween<double>(begin: 0.0, end: 1.0).animate(_orb);
    _ringAnim = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(_ring);
    _initDevice();
  }

  Future<void> _initDevice() async {
    try {
      final a = await DeviceInfoPlugin().androidInfo;
      if (mounted) setState(() => _androidId = a.id);
    } catch (_) {
      if (mounted) setState(() => _androidId = 'unk_${DateTime.now().millisecondsSinceEpoch}');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _userCtrl.text.trim(), pass = _passCtrl.text.trim();
    setState(() => _loading = true);
    try {
      _androidId ??= 'unk_${DateTime.now().millisecondsSinceEpoch}';
      final res = await http.post(Uri.parse('$baseUrl/validate'),
        body: {'username': user, 'password': pass, 'androidId': _androidId!},
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final d = jsonDecode(res.body);
      if (d['expired'] == true) {
        _popup('⏳ Expired', 'Masa akses habis. Silakan perpanjang.', contact: true);
      } else if (d['valid'] != true) {
        final msg = (d['message'] ?? '').toLowerCase();
        if (msg.contains('perangkat') || msg.contains('device') || msg.contains('another')) {
          _popup('⚠️ Device Conflict', 'Akun aktif di perangkat lain.');
        } else {
          _popup('❌ Auth Failed', d['message'] ?? 'Username/password salah.');
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', user);
        await prefs.setString('password', pass);
        await prefs.setString('key', d['key'] ?? '');
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SplashScreen(
          username: user, password: pass, role: d['role'] ?? '',
          sessionKey: d['key'] ?? '', expiredDate: d['expiredDate'] ?? '',
          listBug:  (d['listBug']  as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
          listDoos: (d['listDDoS'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
          news:     (d['news']     as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        )));
      }
    } on TimeoutException { _popup('⏱️ Timeout', 'Server tidak merespon.');
    } on SocketException catch (e) { _popup('📡 Network Error', e.message);
    } catch (e) { dev.log('Login err: $e'); _popup('⚠️ Error', 'Terjadi kesalahan. Coba lagi.');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  void _popup(String title, String msg, {bool contact = false}) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: DV.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: DV.borderHi)),
      title: Text(title, style: const TextStyle(color: DV.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
      content: Text(msg, style: const TextStyle(color: DV.textSecondary, fontSize: 13, height: 1.6)),
      actions: [
        if (contact) TextButton(
          style: TextButton.styleFrom(foregroundColor: DV.holo),
          onPressed: () => launchUrl(Uri.parse('https://t.me/InfoChDarkness'), mode: LaunchMode.externalApplication),
          child: const Text('Hubungi Admin')),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: DV.textSecondary),
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup')),
      ]));
  }

  @override
  void dispose() {
    _entry.dispose(); _pulse.dispose(); _scan.dispose(); _orb.dispose(); _ring.dispose();
    _userCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DV.bg0,
      body: Stack(children: [
        _bg(),
        SafeArea(child: FadeTransition(opacity: _fade,
          child: Center(child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: SlideTransition(position: _slide, child: Column(children: [
              _logoArea(),
              const SizedBox(height: 36),
              _card(),
              const SizedBox(height: 22),
              _footer(),
            ])))))),
      ]),
    );
  }

  Widget _bg() => Stack(children: [
    Container(decoration: BoxDecoration(gradient: DV.bgGradient)),
    Positioned.fill(child: CustomPaint(painter: _LoginBgPainter())),
    // Main plasma orb
    AnimatedBuilder(animation: _orbAnim, builder: (_, __) => Positioned(
      top: -120 + _orbAnim.value * 24, right: -90,
      child: Container(width: 360, height: 360, decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          DV.plasma.withOpacity(0.22 + _orbAnim.value * 0.08), Colors.transparent]))))),
    // Holo accent orb
    AnimatedBuilder(animation: _pulseVal, builder: (_, __) => Positioned(
      bottom: -70, left: -50,
      child: Container(width: 260, height: 260, decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          DV.holo.withOpacity((1-_pulseVal.value) * 0.12), Colors.transparent]))))),
    // Rotating ring decoration
    AnimatedBuilder(animation: _ringAnim, builder: (_, __) => Positioned(
      top: -80, right: -80,
      child: Transform.rotate(angle: _ringAnim.value,
        child: Container(width: 280, height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: DV.plasma.withOpacity(0.06), width: 1)),
          child: CustomPaint(painter: _DashedRingPainter(color: DV.holo.withOpacity(0.08))))))),
    // Scan
    AnimatedBuilder(animation: _scan, builder: (_, __) => Positioned(
      top: MediaQuery.of(context).size.height * _scan.value,
      left: 0, right: 0,
      child: Container(height: 1, decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.transparent, DV.plasma.withOpacity(0.18),
          DV.holo.withOpacity(0.10), Colors.transparent]))))),
  ]);

  Widget _logoArea() => Column(children: [
    AnimatedBuilder(animation: _pulseVal, builder: (_, __) => Stack(
      alignment: Alignment.center,
      children: [
        // Outer ring
        Container(width: 110, height: 110,
          decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(color: DV.plasma.withOpacity(0.15 + _pulseVal.value * 0.1), width: 1))),
        // Inner ring
        Container(width: 95, height: 95,
          decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(color: DV.holo.withOpacity(0.20 + _pulseVal.value * 0.12), width: 1))),
        // Logo
        Container(width: 80, height: 80, padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: DV.fireGradient,
            boxShadow: [
              BoxShadow(color: DV.plasma.withOpacity(0.55 + _pulseVal.value * 0.3), blurRadius: 30, spreadRadius: -4),
              BoxShadow(color: DV.holo.withOpacity(0.2), blurRadius: 44, spreadRadius: -8),
            ]),
          child: ClipOval(child: Image.asset('assets/images/logo.png', fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.hub_rounded, color: Colors.white, size: 40)))),
      ])),
    const SizedBox(height: 18),
    ShaderMask(shaderCallback: (b) => DV.fireGradient.createShader(b),
      child: const Text('DarkVerse', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900,
          color: Colors.white, letterSpacing: 5, fontFamily: 'Orbitron'))),
    const SizedBox(height: 8),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 40, height: 1,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, DV.holo.withOpacity(0.4)]))),
      const SizedBox(width: 12),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: DV.holo.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
          color: DV.holo.withOpacity(0.04)),
        child: const Text('QUANTUM DARK v6.0', style: TextStyle(color: DV.textHolo, fontSize: 9, letterSpacing: 2.5))),
      const SizedBox(width: 12),
      Container(width: 40, height: 1,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [DV.holo.withOpacity(0.4), Colors.transparent]))),
    ]),
  ]);

  Widget _card() => Container(
    decoration: BoxDecoration(
      color: DV.bgCard,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: DV.border),
      boxShadow: [
        BoxShadow(color: DV.glow, blurRadius: 55, offset: const Offset(0, 18), spreadRadius: -8),
        BoxShadow(color: Colors.black.withOpacity(0.65), blurRadius: 32, offset: const Offset(0, 12)),
      ]),
    child: ClipRRect(borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Padding(padding: const EdgeInsets.all(28),
          child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header bar
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: DV.plasma.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DV.borderHi.withOpacity(0.35))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 5, height: 5, decoration: BoxDecoration(
                    shape: BoxShape.circle, color: DV.plasma,
                    boxShadow: [BoxShadow(color: DV.plasma, blurRadius: 6)])),
                  const SizedBox(width: 7),
                  const Text('AUTH // SIGN IN', style: TextStyle(
                    color: DV.textGlow, fontSize: 9, letterSpacing: 2.5, fontFamily: 'Orbitron')),
                ])),
              const Spacer(),
              AnimatedBuilder(animation: _pulseVal, builder: (_, __) =>
                Icon(Icons.security_rounded, color: DV.holo.withOpacity(0.3 + _pulseVal.value * 0.2), size: 20)),
            ]),
            const SizedBox(height: 24),
            TextFormField(
              controller: _userCtrl,
              style: const TextStyle(color: DV.textPrimary, fontSize: 15),
              decoration: DV.input(label: 'Username', icon: Icons.person_outline_rounded),
              validator: (v) => (v == null || v.isEmpty) ? 'Username required' : null),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passCtrl, obscureText: _obscure,
              style: const TextStyle(color: DV.textPrimary, fontSize: 15),
              decoration: DV.input(label: 'Password', icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: DV.textSecondary, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure))),
              validator: (v) => (v == null || v.isEmpty) ? 'Password required' : null),
            const SizedBox(height: 26),
            _loginBtn(),
            const SizedBox(height: 18),
            const DVFireDivider(label: 'OR'),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('https://t.me/InfoChDarkness/292'), mode: LaunchMode.externalApplication),
              child: Container(
                width: double.infinity, height: 48,
                decoration: BoxDecoration(
                  color: DV.bg0, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DV.border)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.shopping_bag_outlined, color: DV.textHint, size: 15),
                  const SizedBox(width: 8),
                  Text('Belum punya akses? Beli di sini',
                    style: TextStyle(color: DV.textHint, fontSize: 12)),
                ]))),
          ]))))));

  Widget _loginBtn() => GestureDetector(
    onTap: _loading ? null : _login,
    child: AnimatedBuilder(animation: _pulseVal, builder: (_, __) => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _loading ? 62 : double.infinity, height: 56,
      decoration: BoxDecoration(
        gradient: _loading ? null : DV.fireGradient,
        color: _loading ? DV.bg2 : null,
        borderRadius: BorderRadius.circular(_loading ? 28 : 14),
        border: Border.all(color: _loading ? DV.border : DV.borderHi),
        boxShadow: _loading ? [] : [
          BoxShadow(color: DV.plasma.withOpacity(0.50 + _pulseVal.value * 0.25), blurRadius: 30, offset: const Offset(0, 8)),
          BoxShadow(color: DV.holo.withOpacity(0.15), blurRadius: 40),
        ]),
      child: Center(child: _loading
        ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: DV.plasma))
        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.fingerprint_rounded, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Text('MASUK', style: TextStyle(color: Colors.white, fontSize: 15,
                fontWeight: FontWeight.w900, letterSpacing: 5, fontFamily: 'Orbitron')),
          ])))));

  Widget _footer() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle,
      color: DV.plasma.withOpacity(0.5),
      boxShadow: [BoxShadow(color: DV.plasma.withOpacity(0.6), blurRadius: 5)])),
    const SizedBox(width: 10),
    const Text('DarkVerse v6.0 — Quantum Dark', style: TextStyle(color: DV.textHint, fontSize: 11)),
    const SizedBox(width: 10),
    Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle,
      color: DV.holo.withOpacity(0.5),
      boxShadow: [BoxShadow(color: DV.holo.withOpacity(0.6), blurRadius: 5)])),
  ]);
}

class _LoginBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFB300FF).withOpacity(0.03)..strokeWidth = 0.5..style = PaintingStyle.stroke;
    for (double x = 0; x < size.width; x += 44) {
      for (double y = 0; y < size.height; y += 44) {
        canvas.drawRect(Rect.fromLTWH(x, y, 44, 44), p);
      }
    }
    // Diagonal
    final p2 = Paint()..color = const Color(0xFF00FFEA).withOpacity(0.02)..strokeWidth = 0.5;
    for (double i = -size.height; i < size.width + size.height; i += 60) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), p2);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  _DashedRingPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashCount = 24;
    const dashAngle = 2 * math.pi / dashCount;
    for (int i = 0; i < dashCount; i += 2) {
      final start = i * dashAngle;
      final end = start + dashAngle * 0.6;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, end, false, paint);
    }
  }
  @override bool shouldRepaint(_) => false;
}
