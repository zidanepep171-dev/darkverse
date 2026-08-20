// info_page.dart — DarkVerse v4.0 CYAN GLASS
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dv_theme.dart';
const String _kApiBase = 'http://rezacloudlegal.sistems.tech:2266';

class InfoPage extends StatefulWidget {
  final String sessionKey;
  const InfoPage({super.key, required this.sessionKey});
  @override State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> with TickerProviderStateMixin {
  List<dynamic> _rules = [], _news = [];
  String _apiStatus = 'Checking...';
  Color _apiColor   = DV.textHint;
  bool _loading = true;
  int _tab = 0;
  late AnimationController _pulse;
  late Animation<double> _pulseVal;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _pulseVal = Tween<double>(begin: 0.3, end: 1.0).animate(_pulse);
    _fetch();
  }
  @override void dispose() { _pulse.dispose(); super.dispose(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_kApiBase/info?key=${widget.sessionKey}')).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        setState(() {
          _rules = d['rules'] ?? [];
          _news  = d['news']  ?? [];
          _apiStatus = d['status'] == 'online' ? 'Server Online' : 'Server Offline';
          _apiColor  = d['status'] == 'online' ? DV.success : DV.error;
          _loading = false;
        });
      } else { _setErr(); }
    } catch (_) { _setErr(); }
  }
  void _setErr() => setState(() { _apiStatus = 'Tidak dapat terhubung'; _apiColor = DV.error; _loading = false; _rules = []; _news = []; });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: Column(children: [
      _statusBar(),
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Row(children: [
          _tabBtn(0, Icons.newspaper_rounded, 'BERITA'),
          const SizedBox(width: 10),
          _tabBtn(1, Icons.gavel_rounded, 'PERATURAN'),
        ])),
      const SizedBox(height: 14),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: DV.cyan))
        : _tab == 0 ? _newsList() : _rulesList()),
    ]),
  );

  Widget _statusBar() => Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: DV.bg1, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _apiColor.withOpacity(0.28)),
      boxShadow: [BoxShadow(color: _apiColor.withOpacity(0.08), blurRadius: 12)]),
    child: Row(children: [
      AnimatedBuilder(animation: _pulseVal, builder: (_, __) => Container(width: 10, height: 10,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: _apiColor.withOpacity(0.5 + _pulseVal.value * 0.5),
          boxShadow: [BoxShadow(color: _apiColor.withOpacity(_pulseVal.value * 0.5), blurRadius: 8)]))),
      const SizedBox(width: 12),
      Expanded(child: Text(_apiStatus, style: TextStyle(color: _apiColor, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'ShareTechMono'))),
      GestureDetector(onTap: _fetch, child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: DV.cyan.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.refresh_rounded, color: DV.cyan, size: 16))),
    ]));

  Widget _tabBtn(int idx, IconData icon, String label) {
    final active = _tab == idx;
    return Expanded(child: GestureDetector(onTap: () => setState(() => _tab = idx),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200), height: 42,
        decoration: BoxDecoration(
          gradient: active ? DV.fireGradient : null,
          color: active ? null : DV.bg1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? DV.cyan : DV.glassBorder),
          boxShadow: active ? [BoxShadow(color: DV.cyanGlow, blurRadius: 10)] : []),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: active ? Colors.white : DV.textSecondary, size: 16),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: active ? Colors.white : DV.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'Orbitron')),
        ]))));
  }

  Widget _newsList() {
    if (_news.isEmpty) return _empty('Belum ada berita terbaru');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: _news.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final n = _news[i];
        return Container(
          decoration: BoxDecoration(color: DV.bg1, borderRadius: BorderRadius.circular(16), border: Border.all(color: DV.glassBorder)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (n['image'] != null && (n['image'] as String).isNotEmpty)
              ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                child: Image.network(n['image'], width: 80, height: 80, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: DV.bg2, child: const Icon(Icons.image_outlined, color: DV.textHint)))),
            Expanded(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: DV.cyan.withOpacity(0.08), borderRadius: BorderRadius.circular(6), border: Border.all(color: DV.cyanBorder.withOpacity(0.3))),
                child: const Text('NEWS', style: TextStyle(color: DV.textCyan, fontSize: 8, letterSpacing: 2, fontFamily: 'Orbitron'))),
              const SizedBox(height: 6),
              Text(n['title'] ?? '', style: const TextStyle(color: DV.textPrimary, fontSize: 13, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(n['desc'] ?? '', style: const TextStyle(color: DV.textSecondary, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]))),
          ]));
      });
  }

  Widget _rulesList() {
    if (_rules.isEmpty) return _empty('Belum ada peraturan');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: _rules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = _rules[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: DV.bg1, borderRadius: BorderRadius.circular(14), border: Border.all(color: DV.glassBorder)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 28, height: 28,
              decoration: BoxDecoration(gradient: DV.fireGradient, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'Orbitron')))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (r['title'] != null) Text(r['title'], style: const TextStyle(color: DV.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              if (r['desc'] != null) Padding(
                padding: EdgeInsets.only(top: r['title'] != null ? 4 : 0),
                child: Text(r['desc'], style: const TextStyle(color: DV.textSecondary, fontSize: 12, height: 1.5))),
              if (r is String) Text(r, style: const TextStyle(color: DV.textSecondary, fontSize: 12, height: 1.5)),
            ])),
          ]));
      });
  }

  Widget _empty(String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.inbox_rounded, color: DV.textHint, size: 48),
    const SizedBox(height: 12),
    Text(msg, style: const TextStyle(color: DV.textHint, fontSize: 14)),
  ]));
}
