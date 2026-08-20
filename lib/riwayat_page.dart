// riwayat_page.dart — DarkVerse v4.0 CYAN GLASS
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dv_theme.dart';
const String _kApiBase = 'http://rezacloudlegal.sistems.tech:2266';

class RiwayatPage extends StatefulWidget {
  final String sessionKey, role;
  const RiwayatPage({super.key, required this.sessionKey, required this.role});
  @override State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List<dynamic> _logs = [];
  bool _loading = true;
  String? _err;

  @override void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _err = null; });
    try {
      final res = await http.get(Uri.parse('$_kApiBase/logs?key=${widget.sessionKey}')).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        setState(() { _logs = d['logs'] ?? []; _loading = false; });
      } else { setState(() { _err = 'Server error ${res.statusCode}'; _loading = false; }); }
    } catch (_) { setState(() { _err = 'Koneksi gagal'; _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DV.bg0,
    appBar: dvAppBar(context, 'RIWAYAT AKTIVITAS', actions: [
      IconButton(icon: const Icon(Icons.refresh_rounded, color: DV.cyan), onPressed: _fetch),
    ]),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: DV.cyan))
      : _err != null ? _errView()
      : _logs.isEmpty ? _emptyView()
      : _list(),
  );

  Widget _list() => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
    itemCount: _logs.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (_, i) {
      final log = _logs[i];
      final type = (log['type'] ?? 'info').toString();
      Color color; IconData icon;
      switch (type) {
        case 'success': color = DV.success; icon = Icons.check_circle_outline_rounded; break;
        case 'error':   color = DV.error;   icon = Icons.error_outline_rounded; break;
        case 'warning': color = DV.warning; icon = Icons.warning_amber_rounded; break;
        default:        color = DV.cyan;    icon = Icons.radio_button_checked_rounded;
      }
      return Container(
        decoration: BoxDecoration(color: DV.bg1, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.18))),
        child: Row(children: [
          Container(width: 4, height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [color, color.withOpacity(0.2)]),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)))),
          const SizedBox(width: 14),
          Container(width: 34, height: 34,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 17)),
          const SizedBox(width: 12),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(log['message'] ?? '-', style: const TextStyle(color: DV.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(log['time'] ?? log['created_at'] ?? '', style: const TextStyle(color: DV.textHint, fontSize: 10, fontFamily: 'ShareTechMono')),
          ]))),
        ]));
    });

  Widget _errView() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 64, height: 64,
      decoration: BoxDecoration(color: DV.error.withOpacity(0.1), borderRadius: BorderRadius.circular(18), border: Border.all(color: DV.error.withOpacity(0.3))),
      child: const Icon(Icons.cloud_off_rounded, color: DV.error, size: 30)),
    const SizedBox(height: 14),
    Text(_err!, style: const TextStyle(color: DV.error, fontSize: 14)),
    const SizedBox(height: 16),
    GestureDetector(onTap: _fetch, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(border: Border.all(color: DV.cyanBorder), borderRadius: BorderRadius.circular(10)),
      child: const Text('Coba Lagi', style: TextStyle(color: DV.textCyan, fontFamily: 'Orbitron', fontSize: 12)))),
  ]));

  Widget _emptyView() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.history_rounded, color: DV.textHint, size: 52),
    SizedBox(height: 12),
    Text('Belum ada aktivitas', style: TextStyle(color: DV.textHint, fontSize: 14)),
  ]));
}
