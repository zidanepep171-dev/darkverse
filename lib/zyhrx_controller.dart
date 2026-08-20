// zyhrx_controller.dart — DarkVerse v4.0 NEON PURPLE EDITION
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dv_theme.dart';

const String _baseUrl = 'http://rezacloudlegal.sistems.tech:2266';

class ZyhrxControllerPage extends StatefulWidget {
  final String sessionKey;
  const ZyhrxControllerPage({super.key, required this.sessionKey});

  @override
  State<ZyhrxControllerPage> createState() => _ZyhrxControllerPageState();
}

class _ZyhrxControllerPageState extends State<ZyhrxControllerPage> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _refreshCtrl;

  bool _isLoading   = false;
  bool _isActing    = false;
  String? _result;

  List<Map<String, dynamic>> _sessions    = [];
  Map<String, dynamic>?      _selected;
  String _selectedAction = 'status'; // status | restart | stop | logs

  @override
  void initState() {
    super.initState();
    _pulseCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _refreshCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fetchSessions();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _refreshCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSessions() async {
    setState(() { _isLoading = true; _sessions = []; _selected = null; });
    _refreshCtrl.forward(from: 0);
    try {
      final res  = await http.get(Uri.parse('$_baseUrl/zyhrx_sessions?key=${widget.sessionKey}'));
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['sessions'] != null) {
        setState(() => _sessions = List<Map<String, dynamic>>.from(data['sessions']));
      } else {
        _setResult('❌ Gagal memuat sesi: ${data['message'] ?? 'Unknown error'}');
      }
    } catch (_) {
      _setResult('❌ Koneksi gagal. Periksa jaringan.');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _executeAction() async {
    if (_selected == null) { _setResult('❌ Pilih sesi terlebih dahulu.'); return; }

    setState(() { _isActing = true; _result = null; });

    try {
      final sessionId = _selected!['id']?.toString() ?? '';
      final uri = Uri.parse('$_baseUrl/zyhrx_ctrl?key=${widget.sessionKey}&session=$sessionId&action=$_selectedAction');
      final res  = await http.get(uri);
      final data = jsonDecode(res.body);

      if (data['valid'] == false)    _setResult('❌ Key tidak valid. Login ulang.');
      else if (data['success'] == false) _setResult('⚠️ Aksi gagal: ${data['message'] ?? 'Server error'}');
      else {
        final msg = data['message'] ?? 'Aksi berhasil dijalankan.';
        _setResult('✅ $_selectedAction → $msg');
        if (_selectedAction == 'restart' || _selectedAction == 'stop') await _fetchSessions();
      }
    } catch (_) {
      _setResult('❌ Koneksi gagal. Coba lagi.');
    } finally {
      setState(() => _isActing = false);
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
          child: const Text('ZYHRX CONTROLLER',
              style: TextStyle(color: Colors.white, fontFamily: 'Orbitron', fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 1.5)),
        ),
        centerTitle: true,
        actions: [
          RotationTransition(
            turns: _refreshCtrl,
            child: IconButton(
              icon: Icon(Icons.refresh_rounded, color: DV.orange),
              onPressed: _isLoading ? null : _fetchSessions,
            ),
          ),
        ],
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
              child: const Icon(Icons.settings_remote_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ZYHRX CONTROLLER', style: TextStyle(color: DV.textPrimary, fontFamily: 'Orbitron', fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1)),
              const SizedBox(height: 3),
              Text('Manage & control active zyhrx sessions', style: TextStyle(color: DV.textSecondary, fontSize: 11)),
            ])),
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DV.success.withOpacity(0.4 + _pulseCtrl.value * 0.6),
                  boxShadow: [BoxShadow(color: DV.success.withOpacity(_pulseCtrl.value * 0.5), blurRadius: 8)],
                ),
              ),
            ),
          ])),
          const SizedBox(height: 20),

          // ── Session List ───────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _sectionLabel('SESI AKTIF'),
            if (_sessions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DV.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: DV.orangeBorder),
                ),
                child: Text('${_sessions.length} sesi', style: const TextStyle(color: DV.textOrange, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
              ),
          ]),
          const SizedBox(height: 10),
          _buildSessionList(),
          const SizedBox(height: 20),

          // ── Action Selector ────────────────────────────────────────────
          _sectionLabel('PILIH AKSI'),
          const SizedBox(height: 10),
          _buildActionGrid(),
          const SizedBox(height: 20),

          // ── Execute Button ─────────────────────────────────────────────
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: _isActing ? null : DV.fireGradient,
                color: _isActing ? DV.bg2 : null,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _isActing ? [] : [BoxShadow(color: DV.orange.withOpacity(0.35 + _pulseCtrl.value * 0.2), blurRadius: 20 + _pulseCtrl.value * 12)],
              ),
              child: ElevatedButton(
                onPressed: _isActing ? null : _executeAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0,
                ),
                child: _isActing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(_actionIcon(_selectedAction), color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text('EXECUTE ${_selectedAction.toUpperCase()}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2, fontFamily: 'Orbitron')),
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

  Widget _buildSessionList() {
    if (_isLoading) {
      return DVCard(padding: const EdgeInsets.all(28), child: const Center(child: CircularProgressIndicator(color: DV.orange)));
    }
    if (_sessions.isEmpty) {
      return DVCard(padding: const EdgeInsets.all(24), child: Column(children: [
        Icon(Icons.cloud_off_rounded, color: DV.textHint, size: 40),
        const SizedBox(height: 10),
        Text('Tidak ada sesi aktif', style: TextStyle(color: DV.textSecondary, fontFamily: 'ShareTechMono')),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _fetchSessions,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: DV.orangeBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Refresh', style: TextStyle(color: DV.textOrange, fontFamily: 'Orbitron', fontSize: 12)),
          ),
        ),
      ]));
    }

    return DVCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: _sessions.map<Widget>((s) {
          final id       = s['id']?.toString() ?? '';
          final name     = s['name']?.toString() ?? 'Session';
          final status   = s['status']?.toString() ?? 'unknown';
          final uptime   = s['uptime']?.toString() ?? '-';
          final msgs     = s['messages']?.toString() ?? '0';
          final isOnline = status == 'online' || status == 'running';
          final selected = _selected?['id'] == id;

          return GestureDetector(
            onTap: () => setState(() => _selected = selected ? null : s),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? DV.orange.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? DV.orange : DV.orange.withOpacity(0.2), width: selected ? 1.5 : 1),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: selected ? DV.orangeLight : DV.textHint, size: 18),
                  const SizedBox(width: 10),
                  Container(width: 8, height: 8, decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? DV.success : DV.error,
                      boxShadow: [BoxShadow(color: (isOnline ? DV.success : DV.error).withOpacity(0.6), blurRadius: 5)])),
                  const SizedBox(width: 8),
                  Expanded(child: Text(name, style: const TextStyle(color: DV.textPrimary, fontFamily: 'ShareTechMono', fontWeight: FontWeight.w600, fontSize: 13))),
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
                const SizedBox(height: 8),
                Row(children: [
                  const SizedBox(width: 36),
                  _statPill(Icons.timer_outlined, 'Uptime: $uptime'),
                  const SizedBox(width: 8),
                  _statPill(Icons.message_outlined, '$msgs msg'),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _copyToClipboard(id),
                    child: _statPill(Icons.copy_rounded, 'ID'),
                  ),
                ]),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statPill(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: DV.orange.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: DV.orange.withOpacity(0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: DV.textSecondary, size: 11),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: DV.textSecondary, fontSize: 10, fontFamily: 'ShareTechMono')),
    ]),
  );

  Widget _buildActionGrid() {
    final actions = [
      {'key': 'status',  'icon': Icons.monitor_heart_rounded,   'label': 'Status',  'desc': 'Cek status sesi'},
      {'key': 'restart', 'icon': Icons.restart_alt_rounded,     'label': 'Restart', 'desc': 'Restart sesi'},
      {'key': 'stop',    'icon': Icons.stop_circle_rounded,     'label': 'Stop',    'desc': 'Hentikan sesi'},
      {'key': 'logs',    'icon': Icons.article_outlined,        'label': 'Logs',    'desc': 'Lihat log sesi'},
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10,
      childAspectRatio: 2.8,
      children: actions.map<Widget>((a) {
        final active = _selectedAction == a['key'];
        return GestureDetector(
          onTap: () => setState(() => _selectedAction = a['key'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active ? DV.orange.withOpacity(0.18) : DV.bg1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: active ? DV.orange : DV.orange.withOpacity(0.2), width: active ? 1.5 : 1),
              boxShadow: active ? [BoxShadow(color: DV.orangeGlow, blurRadius: 10)] : [],
            ),
            child: Row(children: [
              Icon(a['icon'] as IconData, color: active ? DV.orangeLight : DV.textHint, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(a['label'] as String, style: TextStyle(color: active ? DV.orangeLight : DV.textPrimary, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Orbitron')),
                Text(a['desc'] as String, style: const TextStyle(color: DV.textHint, fontSize: 9), overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResult() {
    final isOk   = _result!.startsWith('✅');
    final isWarn = _result!.startsWith('⏳') || _result!.startsWith('⚠️');
    final color  = isOk ? DV.success : (isWarn ? DV.warning : DV.error);
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

  IconData _actionIcon(String action) => switch (action) {
    'status'  => Icons.monitor_heart_rounded,
    'restart' => Icons.restart_alt_rounded,
    'stop'    => Icons.stop_circle_rounded,
    'logs'    => Icons.article_outlined,
    _         => Icons.terminal_rounded,
  };

  Widget _sectionLabel(String t) => Text(t,
      style: const TextStyle(color: DV.textOrange, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, fontFamily: 'Orbitron'));
}
