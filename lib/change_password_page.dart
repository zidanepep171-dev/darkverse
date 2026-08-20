// change_password_page.dart — DarkVerse v4.0 CYAN GLASS
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dv_theme.dart';
const String _kApiBase = 'http://rezacloudlegal.sistems.tech:2266';

class ChangePasswordPage extends StatefulWidget {
  final String username, sessionKey;
  const ChangePasswordPage({super.key, required this.username, required this.sessionKey});
  @override State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final oldCtrl     = TextEditingController();
  final newCtrl     = TextEditingController();
  final confirmCtrl = TextEditingController();
  final _formKey    = GlobalKey<FormState>();
  bool _loading = false;
  bool _obsOld = true, _obsNew = true, _obsConf = true;
  String? _result;
  bool? _isSuccess;

  @override void dispose() { oldCtrl.dispose(); newCtrl.dispose(); confirmCtrl.dispose(); super.dispose(); }

  Future<void> _change() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _result = null; });
    try {
      final res = await http.post(
        Uri.parse('$_kApiBase/change-password'),
        body: {'key': widget.sessionKey, 'old': oldCtrl.text.trim(), 'new': newCtrl.text.trim()},
      ).timeout(const Duration(seconds: 12));
      final d = jsonDecode(res.body);
      setState(() {
        _isSuccess = d['success'] == true;
        _result = _isSuccess! ? '✅ Password berhasil diubah!' : '❌ ${d['message'] ?? 'Gagal mengubah password'}';
      });
      if (_isSuccess!) { oldCtrl.clear(); newCtrl.clear(); confirmCtrl.clear(); }
    } catch (_) { setState(() { _isSuccess = false; _result = '❌ Koneksi gagal. Coba lagi.'; }); }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DV.bg0,
    appBar: dvAppBar(context, 'GANTI PASSWORD'),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 70, height: 70,
          decoration: BoxDecoration(gradient: DV.fireGradient, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: DV.cyanGlow, blurRadius: 20)]),
          child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 32))),
        const SizedBox(height: 24),
        _field(oldCtrl,     'Password Lama',   Icons.lock_outline_rounded,  _obsOld,  () => setState(() => _obsOld  = !_obsOld),  v: (v) => v!.isEmpty ? 'Wajib diisi' : null),
        const SizedBox(height: 14),
        _field(newCtrl,     'Password Baru',   Icons.lock_rounded,           _obsNew,  () => setState(() => _obsNew  = !_obsNew),  v: (v) => v!.length < 6 ? 'Min. 6 karakter' : null),
        const SizedBox(height: 14),
        _field(confirmCtrl, 'Konfirmasi Baru', Icons.lock_clock_rounded,     _obsConf, () => setState(() => _obsConf = !_obsConf), v: (v) => v != newCtrl.text ? 'Password tidak cocok' : null),
        const SizedBox(height: 28),
        DVButton(label: 'UBAH PASSWORD', icon: Icons.save_rounded, onTap: _change, isLoading: _loading),
        if (_result != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (_isSuccess! ? DV.success : DV.error).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: (_isSuccess! ? DV.success : DV.error).withOpacity(0.32))),
            child: Row(children: [
              Icon(_isSuccess! ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                color: _isSuccess! ? DV.success : DV.error, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(_result!, style: TextStyle(
                color: _isSuccess! ? DV.success : DV.error, fontSize: 13, fontFamily: 'ShareTechMono'))),
            ])),
        ],
      ]))));

  Widget _field(TextEditingController ctrl, String label, IconData icon, bool obs, VoidCallback toggle, {String? Function(String?)? v}) =>
    TextFormField(controller: ctrl, obscureText: obs,
      style: const TextStyle(color: DV.textPrimary, fontSize: 15),
      decoration: DV.input(label: label, icon: icon,
        suffix: IconButton(
          icon: Icon(obs ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: DV.textSecondary, size: 20),
          onPressed: toggle)),
      validator: v);
}
