// ip_lookup.dart — DarkVerse v4.0 NEW TOOL: IP Lookup & Tracer
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dv_theme.dart';

class IpLookupPage extends StatefulWidget {
  final String sessionKey;
  const IpLookupPage({super.key, required this.sessionKey});
  @override
  State<IpLookupPage> createState() => _IpLookupPageState();
}

class _IpLookupPageState extends State<IpLookupPage> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;
  bool _myIpMode = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _ctrl.dispose(); super.dispose(); }

  Future<void> _lookup({bool myIp = false}) async {
    final ip = myIp ? '' : _ctrl.text.trim();
    if (!myIp && ip.isEmpty) { _showSnack('Masukkan IP address!'); return; }
    setState(() { _loading = true; _result = null; _error = null; _myIpMode = myIp; });
    try {
      final url = myIp ? 'https://ipapi.co/json/' : 'https://ipapi.co/$ip/json/';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        if (d['error'] == true) { setState(() => _error = d['reason'] ?? 'IP tidak valid'); }
        else { setState(() => _result = d); }
      } else { setState(() => _error = 'HTTP ${res.statusCode}'); }
    } catch (e) { setState(() => _error = 'Error: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('✅ Disalin!');
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: DV.textPrimary)),
    backgroundColor: DV.bg2,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: DV.orangeBorder)),
  ));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DV.bg0,
    body: Container(
      decoration: BoxDecoration(gradient: DV.bgGradient),
      child: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // back + title
          Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(padding: const EdgeInsets.all(8), decoration: DV.card(r: 10),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: DV.orange, size: 18))),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShaderMask(shaderCallback: (b) => DV.fireGradient.createShader(b),
                child: const Text('IP LOOKUP', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2, fontFamily: 'Orbitron'))),
              const Text('Trace & Geolocate IP Address', style: TextStyle(color: DV.textSecondary, fontSize: 11)),
            ]),
          ]),
          const SizedBox(height: 22),

          // input
          DVCard(padding: const EdgeInsets.all(16), fire: true, glow: true, child: Column(children: [
            TextFormField(
              controller: _ctrl,
              style: const TextStyle(color: DV.textPrimary, fontFamily: 'ShareTechMono'),
              keyboardType: TextInputType.url,
              decoration: DV.input(label: 'IP Address (cth: 8.8.8.8)', icon: Icons.location_on_rounded,
                suffix: IconButton(icon: const Icon(Icons.clear_rounded, color: DV.textHint, size: 18), onPressed: () => _ctrl.clear())),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: DVButton(label: 'LOOKUP', icon: Icons.search_rounded, isLoading: _loading && !_myIpMode, onTap: () => _lookup())),
              const SizedBox(width: 10),
              Expanded(child: DVButton(label: 'MY IP', icon: Icons.my_location_rounded, outline: true, isLoading: _loading && _myIpMode, onTap: () => _lookup(myIp: true))),
            ]),
          ])),

          if (_error != null) ...[
            const SizedBox(height: 16),
            DVCard(padding: const EdgeInsets.all(14), child: Row(children: [
              const Icon(Icons.error_outline_rounded, color: DV.error, size: 20),
              const SizedBox(width: 10),
              Text(_error!, style: const TextStyle(color: DV.error, fontSize: 13)),
            ])),
          ],

          if (_result != null) ...[
            const SizedBox(height: 20),
            const Text('📍 HASIL LOOKUP', style: TextStyle(color: DV.textOrange, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, fontFamily: 'Orbitron')),
            const SizedBox(height: 10),
            DVCard(glow: true, padding: const EdgeInsets.all(16), child: Column(children: [
              _row('🌐 IP', _result!['ip']),
              _row('📍 Kota', _result!['city']),
              _row('🗺️ Region', _result!['region']),
              _row('🏳️ Negara', '${_result!['country_name']} (${_result!['country_code']})'),
              _row('🏢 Org / ISP', _result!['org']),
              _row('🕐 Timezone', _result!['timezone']),
              _row('📫 Postal', _result!['postal']),
              _row('🧭 Lat/Lng', '${_result!['latitude']}, ${_result!['longitude']}'),
              _row('📡 ASN', _result!['asn']),
            ])),
            const SizedBox(height: 10),
            DVButton(label: 'SALIN SEMUA INFO', icon: Icons.copy_rounded, outline: true, onTap: () {
              final sb = StringBuffer();
              _result!.forEach((k, v) { if (v != null) sb.writeln('$k: $v'); });
              _copy(sb.toString());
            }),
          ],
        ]),
      )),
    ),
  );

  Widget _row(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: DV.textSecondary, fontSize: 12))),
        Expanded(child: GestureDetector(
          onTap: () => _copy(value.toString()),
          child: Text(value.toString(), style: const TextStyle(color: DV.textPrimary, fontSize: 12, fontFamily: 'ShareTechMono')),
        )),
        GestureDetector(onTap: () => _copy(value.toString()),
          child: const Icon(Icons.copy_rounded, color: DV.textHint, size: 14)),
      ]),
    );
  }
}
