// zyhrx_paranel.dart — DarkVerse v4.0 NEON PURPLE EDITION
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dv_theme.dart';

const String _baseUrl = 'http://rezacloudlegal.sistems.tech:2266';

class ZyhrxParanelPage extends StatefulWidget {
  final String sessionKey;
  const ZyhrxParanelPage({super.key, required this.sessionKey});

  @override
  State<ZyhrxParanelPage> createState() => _ZyhrxParanelPageState();
}

class _ZyhrxParanelPageState extends State<ZyhrxParanelPage> with TickerProviderStateMixin {
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _loopController   = TextEditingController(text: '1');

  late AnimationController _pulseCtrl;

  bool _isSending  = false;
  bool _isLoading  = false;
  String? _result;
  List<Map<String, dynamic>> _senderList = [];
  List<String> _selectedSenders = [];

  String _selectedMode = 'single'; // single | multi | auto

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _fetchSenders();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _targetController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  Future<void> _fetchSenders() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/senders?key=${widget.sessionKey}'));
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['senders'] != null) {
        setState(() => _senderList = List<Map<String, dynamic>>.from(data['senders']));
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _sendParanel() async {
    final target = _targetController.text.trim();
    final loop   = int.tryParse(_loopController.text.trim()) ?? 1;

    if (target.isEmpty) {
      _setResult('❌ Target tidak boleh kosong.');
      return;
    }
    if (_selectedMode != 'auto' && _selectedSenders.isEmpty) {
      _setResult('❌ Pilih minimal 1 sender.');
      return;
    }

    setState(() { _isSending = true; _result = null; });

    try {
      final senderParam = _selectedSenders.join(',');
      final uri = Uri.parse(
        '$_baseUrl/zyhrx_paranel?key=${widget.sessionKey}'
        '&target=$target&loop=$loop'
        '&mode=$_selectedMode'
        '${_selectedMode != "auto" ? "&senders=$senderParam" : ""}',
      );
      final res  = await http.get(uri);
      final data = jsonDecode(res.body);

      if (data['cooldown'] == true)       _setResult('⏳ Cooldown aktif. Tunggu sebentar.');
      else if (data['valid'] == false)    _setResult('❌ Key tidak valid. Login ulang.');
      else if (data['sender'] == false)   _setResult('❌ Sender kosong atau offline.');
      else if (data['sended'] == false)   _setResult('⚠️ Gagal kirim. Server maintenance.');
      else                                _setResult('✅ Paranel berhasil dikirim ke $target!');
    } catch (_) {
      _setResult('❌ Koneksi gagal. Coba lagi.');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _setResult(String msg) => setState(() => _result = msg);

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Disalin ke clipboard', style: TextStyle(color: Colors.white, fontFamily: 'ShareTechMono')),
      backgroundColor: DV.bg2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DV.bg0,
      appBar: AppBar(
        backgroundColor: DV.bg0,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: DV.orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (b) => DV.fireGradient.createShader(b),
          child: const Text('ZYHRX PARANEL',
              style: TextStyle(color: Colors.white, fontFamily: 'Orbitron', fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.5)),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // ── Info Card ──────────────────────────────────────────────────
          DVCard(glow: true, fire: true, padding: const EdgeInsets.all(16), child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: DV.fireGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: DV.orangeGlow, blurRadius: 12)],
              ),
              child: const Icon(Icons.electric_bolt_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ZYHRX PARANEL', style: TextStyle(color: DV.textPrimary, fontFamily: 'Orbitron', fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
              const SizedBox(height: 3),
              Text('Multi-sender parallel blast engine', style: TextStyle(color: DV.textSecondary, fontSize: 11)),
            ])),
          ])),
          const SizedBox(height: 20),

          // ── Mode Selector ──────────────────────────────────────────────
          _sectionLabel('MODE SERANGAN'),
          const SizedBox(height: 10),
          Row(children: [
            _modeChip('single', Icons.person_rounded,     'Single'),
            const SizedBox(width: 8),
            _modeChip('multi',  Icons.people_rounded,     'Multi'),
            const SizedBox(width: 8),
            _modeChip('auto',   Icons.auto_mode_rounded,  'Auto'),
          ]),
          const SizedBox(height: 20),

          // ── Target Input ───────────────────────────────────────────────
          _sectionLabel('NOMOR TARGET'),
          const SizedBox(height: 10),
          _dvTextField(
            controller: _targetController,
            hint: 'Contoh: +62xxxxxxxxxx',
            icon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // ── Loop Input ─────────────────────────────────────────────────
          _sectionLabel('JUMLAH LOOP'),
          const SizedBox(height: 10),
          _dvTextField(
            controller: _loopController,
            hint: 'Masukkan jumlah loop (maks: 99)',
            icon: Icons.repeat_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),

          // ── Sender Selector (hidden for auto mode) ─────────────────────
          if (_selectedMode != 'auto') ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _sectionLabel('PILIH SENDER'),
              if (_isLoading)
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: DV.orange, strokeWidth: 2))
              else
                GestureDetector(
                  onTap: _fetchSenders,
                  child: Icon(Icons.refresh_rounded, color: DV.orange, size: 18),
                ),
            ]),
            const SizedBox(height: 10),
            _buildSenderGrid(),
            const SizedBox(height: 20),
          ],

          // ── Send Button ────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: _isSending ? null : DV.fireGradient,
                color: _isSending ? DV.bg2 : null,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _isSending ? [] : [BoxShadow(color: DV.orange.withOpacity(0.35 + _pulseCtrl.value * 0.2), blurRadius: 20 + _pulseCtrl.value * 12)],
              ),
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendParanel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0,
                ),
                child: _isSending
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.electric_bolt_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text('LAUNCH PARANEL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 2, fontFamily: 'Orbitron')),
                      ]),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Result ─────────────────────────────────────────────────────
          if (_result != null) _buildResult(),
        ]),
      ),
    );
  }

  Widget _modeChip(String mode, IconData icon, String label) {
    final active = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _selectedMode = mode; _selectedSenders.clear(); }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? DV.orange.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? DV.orange : DV.orange.withOpacity(0.25), width: active ? 1.5 : 1),
            boxShadow: active ? [BoxShadow(color: DV.orangeGlow, blurRadius: 10)] : [],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: active ? DV.orangeLight : DV.textHint, size: 18),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: active ? DV.orangeLight : DV.textHint, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
          ]),
        ),
      ),
    );
  }

  Widget _buildSenderGrid() {
    if (_isLoading) {
      return DVCard(padding: const EdgeInsets.all(24), child: const Center(child: CircularProgressIndicator(color: DV.orange)));
    }
    if (_senderList.isEmpty) {
      return DVCard(padding: const EdgeInsets.all(20), child: Column(children: [
        Icon(Icons.signal_wifi_off_rounded, color: DV.textHint, size: 40),
        const SizedBox(height: 10),
        Text('Tidak ada sender aktif', style: TextStyle(color: DV.textSecondary, fontFamily: 'ShareTechMono')),
      ]));
    }
    return DVCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: _senderList.map<Widget>((sender) {
          final id       = sender['id']?.toString() ?? '';
          final name     = sender['name']?.toString() ?? 'Sender';
          final status   = sender['status']?.toString() ?? 'offline';
          final isOnline = status == 'online' || status == 'active';
          final selected = _selectedSenders.contains(id);
          return GestureDetector(
            onTap: () => setState(() {
              if (_selectedMode == 'single') {
                _selectedSenders = selected ? [] : [id];
              } else {
                selected ? _selectedSenders.remove(id) : _selectedSenders.add(id);
              }
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? DV.orange.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? DV.orange : DV.orange.withOpacity(0.2), width: selected ? 1.5 : 1),
              ),
              child: Row(children: [
                Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: selected ? DV.orangeLight : DV.textHint, size: 20),
                const SizedBox(width: 12),
                Container(width: 8, height: 8, decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? DV.success : DV.error,
                    boxShadow: [BoxShadow(color: (isOnline ? DV.success : DV.error).withOpacity(0.6), blurRadius: 4)])),
                const SizedBox(width: 10),
                Expanded(child: Text(name, style: const TextStyle(color: DV.textPrimary, fontFamily: 'ShareTechMono', fontSize: 13))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isOnline ? DV.success : DV.error).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: (isOnline ? DV.success : DV.error).withOpacity(0.35)),
                  ),
                  child: Text(status.toUpperCase(), style: TextStyle(color: isOnline ? DV.success : DV.error, fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'Orbitron')),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResult() {
    final isOk  = _result!.startsWith('✅');
    final isWarn = _result!.startsWith('⏳') || _result!.startsWith('⚠️');
    final color = isOk ? DV.success : (isWarn ? DV.warning : DV.error);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12)],
      ),
      child: Row(children: [
        Icon(isOk ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(_result!, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'ShareTechMono'))),
        GestureDetector(onTap: () => _copyToClipboard(_result!), child: Icon(Icons.copy_rounded, color: color.withOpacity(0.7), size: 16)),
      ]),
    );
  }

  Widget _sectionLabel(String t) => Text(t,
      style: const TextStyle(color: DV.textOrange, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, fontFamily: 'Orbitron'));

  Widget _dvTextField({required TextEditingController controller, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: DV.textPrimary, fontFamily: 'ShareTechMono', fontSize: 14),
      cursorColor: DV.orange,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: DV.textHint.withOpacity(0.6), fontSize: 13),
        prefixIcon: Icon(icon, color: DV.orange, size: 20),
        filled: true,
        fillColor: DV.bg1,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: DV.orange.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: DV.orange, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
    );
  }
}
