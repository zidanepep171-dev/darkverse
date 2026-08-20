// profile_page.dart — DarkVerse v4.0 CYAN GLASS
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dv_theme.dart';
import 'riwayat_page.dart';
import 'change_password_page.dart';

class ProfilePage extends StatefulWidget {
  final String username, password, role, expiredDate, sessionKey;
  const ProfilePage({super.key, required this.username, required this.password, required this.role, required this.expiredDate, required this.sessionKey});
  @override State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  File? _img;
  late AnimationController _pulse;
  late Animation<double> _pulseVal;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _pulseVal = Tween<double>(begin: 0.3, end: 1.0).animate(_pulse);
    _loadImg();
  }
  @override void dispose() { _pulse.dispose(); super.dispose(); }

  Future<void> _loadImg() async {
    final p = await SharedPreferences.getInstance();
    final path = p.getString('profile_image_${widget.username}');
    if (path != null && mounted) setState(() => _img = File(path));
  }

  Future<void> _pickImg() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x == null) return;
    final p = await SharedPreferences.getInstance();
    await p.setString('profile_image_${widget.username}', x.path);
    if (mounted) setState(() => _img = File(x.path));
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Disalin!', style: TextStyle(color: Colors.white, fontFamily: 'ShareTechMono')),
      backgroundColor: DV.bg2, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = {'owner': DV.teal, 'admin': DV.cyan, 'reseller': DV.cyanLight, 'member': DV.textSecondary}[widget.role.toLowerCase()] ?? DV.textSecondary;
    return Scaffold(
      backgroundColor: DV.bg0,
      appBar: dvAppBar(context, 'PROFIL SAYA'),
      body: Stack(children: [
        AnimatedBuilder(animation: _pulseVal, builder: (_, __) => Positioned(
          top: -60, right: -60,
          child: Container(width: 200, height: 200, decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [DV.cyan.withOpacity(_pulseVal.value * 0.12), Colors.transparent]))))),
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(children: [
            // Avatar
            Center(child: Column(children: [
              Stack(alignment: Alignment.bottomRight, children: [
                AnimatedBuilder(animation: _pulseVal, builder: (_, __) => Container(
                  width: 100, height: 100, padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, gradient: DV.fireGradient,
                    boxShadow: [BoxShadow(color: DV.cyan.withOpacity(_pulseVal.value * 0.45), blurRadius: 24)]),
                  child: ClipOval(child: _img != null
                    ? Image.file(_img!, fit: BoxFit.cover)
                    : Container(color: DV.bg0, child: const Icon(Icons.person_rounded, size: 44, color: DV.cyan))))),
                GestureDetector(onTap: _pickImg,
                  child: Container(width: 28, height: 28,
                    decoration: BoxDecoration(gradient: DV.fireGradient, shape: BoxShape.circle,
                      border: Border.all(color: DV.bg0, width: 2)),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14))),
              ]),
              const SizedBox(height: 14),
              ShaderMask(shaderCallback: (b) => DV.fireGradient.createShader(b),
                child: Text(widget.username, style: const TextStyle(color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.w900, fontFamily: 'Orbitron', letterSpacing: 1))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: roleColor.withOpacity(0.35))),
                child: Text(widget.role.toUpperCase(), style: TextStyle(color: roleColor, fontSize: 11,
                    fontWeight: FontWeight.w800, letterSpacing: 2, fontFamily: 'Orbitron'))),
            ])),
            const SizedBox(height: 28),
            // Info card
            _infoCard([
              _infoRow(Icons.person_rounded, 'Username', widget.username, copyable: true),
              _divider(),
              _infoRow(Icons.shield_rounded, 'Role', widget.role.toUpperCase()),
              _divider(),
              _infoRow(Icons.calendar_today_rounded, 'Expired', widget.expiredDate),
            ]),
            const SizedBox(height: 14),
            // Session key
            GestureDetector(onTap: () => _copy(widget.sessionKey),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DV.bg1, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DV.cyanBorder.withOpacity(0.3))),
                child: Row(children: [
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: DV.cyan.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: DV.cyanBorder.withOpacity(0.35))),
                    child: const Icon(Icons.key_rounded, color: DV.cyan, size: 18)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Session Key', style: TextStyle(color: DV.textSecondary, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(widget.sessionKey, style: const TextStyle(color: DV.textPrimary, fontSize: 12, fontFamily: 'ShareTechMono'), overflow: TextOverflow.ellipsis),
                  ])),
                  Icon(Icons.copy_rounded, color: DV.cyan.withOpacity(0.55), size: 16),
                ]))),
            const SizedBox(height: 28),
            _actionBtn(Icons.history_rounded, 'Riwayat Aktivitas', DV.cyan,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => RiwayatPage(sessionKey: widget.sessionKey, role: widget.role)))),
            const SizedBox(height: 10),
            _actionBtn(Icons.lock_rounded, 'Ganti Password', DV.cyanLight,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordPage(username: widget.username, sessionKey: widget.sessionKey)))),
          ]),
        ),
      ]),
    );
  }

  Widget _infoCard(List<Widget> children) => Container(
    decoration: BoxDecoration(color: DV.bg1, borderRadius: BorderRadius.circular(18), border: Border.all(color: DV.glassBorder)),
    child: ClipRRect(borderRadius: BorderRadius.circular(18), child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Column(children: children))));

  Widget _infoRow(IconData icon, String label, String value, {bool copyable = false}) => GestureDetector(
    onTap: copyable ? () => _copy(value) : null,
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(children: [
        Container(width: 34, height: 34,
          decoration: BoxDecoration(color: DV.cyan.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: DV.cyan, size: 16)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: DV.textHint, fontSize: 10, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: DV.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ])),
        if (copyable) Icon(Icons.copy_rounded, color: DV.textHint, size: 14),
      ])));

  Widget _divider() => Divider(color: DV.glassBorder, height: 1, indent: 66);

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(height: 52,
      decoration: BoxDecoration(
        color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.28))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Orbitron', letterSpacing: 1)),
      ])));
}
