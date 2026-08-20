// tools_gateway.dart — DarkVerse v4.0 CYAN GLASS
import 'package:flutter/material.dart';
import 'dv_theme.dart';
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'qr_gen.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';
import 'ip_lookup.dart';
import 'text_tools.dart';
import 'zyhrx_paranel.dart';
import 'zyhrx_controller.dart';
import 'al_quran.dart';
import 'sholat_tools_page.dart';
import 'ceramah.dart';
import 'spotify.dart';
import 'create_website.dart';
import 'rratt_page.dart';
import 'testfunc.dart';
import 'game_area_page.dart';

class ToolsPage extends StatefulWidget {
  final String sessionKey, userRole;
  final List<Map<String, dynamic>> listDoos;
  const ToolsPage({super.key, required this.sessionKey, required this.userRole, required this.listDoos});
  @override State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  String _cat = 'all';
  static const _cats = ['all','attack','zyhrx','osint','social','islami','game','util'];
  static const _labels = {'all':'SEMUA','attack':'ATTACK','zyhrx':'ZYHRX','osint':'OSINT','social':'MEDIA','islami':'ISLAMI','game':'GAME','util':'TOOLS'};

  @override
  Widget build(BuildContext context) {
    final all      = _buildTools(context);
    final filtered = _cat == 'all' ? all : all.where((t) => t.cat == _cat).toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: _header(all.length)),
        const SizedBox(height: 14),
        SizedBox(height: 36, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _cats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => _catTab(_cats[i]),
        )),
        const SizedBox(height: 14),
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _toolCard(filtered[i]),
        )),
      ]),
    );
  }

  Widget _header(int count) => Row(children: [
    Container(width: 42, height: 42,
      decoration: BoxDecoration(gradient: DV.fireGradient, borderRadius: BorderRadius.circular(13),
        boxShadow: [BoxShadow(color: DV.cyanGlow, blurRadius: 14)]),
      child: const Icon(Icons.terminal_rounded, color: Colors.white, size: 20)),
    const SizedBox(width: 14),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ShaderMask(shaderCallback: (b) => DV.fireGradient.createShader(b),
        child: const Text('TOOLS HUB', style: TextStyle(color: Colors.white, fontSize: 16,
            fontWeight: FontWeight.w900, letterSpacing: 2, fontFamily: 'Orbitron'))),
      Text('$count modules available', style: const TextStyle(color: DV.textSecondary, fontSize: 11)),
    ]),
    const Spacer(),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: DV.cyan.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DV.cyanBorder.withOpacity(0.4))),
      child: Text('$count', style: const TextStyle(color: DV.textCyan, fontSize: 16,
          fontWeight: FontWeight.w900, fontFamily: 'Orbitron'))),
  ]);

  Widget _catTab(String cat) {
    final active = _cat == cat;
    return GestureDetector(
      onTap: () => setState(() => _cat = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: active ? DV.fireGradient : null,
          color: active ? null : DV.bg1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? DV.cyan : DV.glassBorder),
          boxShadow: active ? [BoxShadow(color: DV.cyanGlow, blurRadius: 10)] : []),
        alignment: Alignment.center,
        child: Text(_labels[cat] ?? cat, style: TextStyle(
          color: active ? Colors.white : DV.textSecondary,
          fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, fontFamily: 'Orbitron'))));
  }

  Widget _toolCard(_Tool t) => GestureDetector(
    onTap: t.onTap,
    child: Container(
      decoration: BoxDecoration(
        color: DV.bg1, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DV.glassBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8)]),
      child: Stack(children: [
        Positioned(top: -15, right: -15, child: Container(width: 60, height: 60,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [t.color.withOpacity(0.14), Colors.transparent])))),
        Padding(padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(
                  color: t.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.color.withOpacity(0.3))),
                child: Icon(t.icon, color: t.color, size: 18)),
              const Spacer(),
              Icon(Icons.arrow_forward_rounded, color: t.color.withOpacity(0.45), size: 14),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.title, style: const TextStyle(color: DV.textPrimary, fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(t.desc, style: const TextStyle(color: DV.textHint, fontSize: 9), overflow: TextOverflow.ellipsis),
            ]),
          ])),
      ])));

  List<_Tool> _buildTools(BuildContext ctx) => [
    _Tool(Icons.bolt_rounded,            'DDoS Panel',       'Stress Test Pro',        DV.cyanDeep,   'attack', () => _go(ctx, AttackPanel(sessionKey: widget.sessionKey, listDoos: widget.listDoos))),
    _Tool(Icons.wifi_off_rounded,        'Wifi Internal',    'Local Network Attack',   DV.cyan,       'attack', () => _go(ctx, WifiInternalPage(sessionKey: widget.sessionKey))),
    _Tool(Icons.security_rounded,        'Wifi External',    'Remote Network Scan',    DV.cyanLight,  'attack', () => _go(ctx, const WifiKillerPage())),
    _Tool(Icons.developer_mode_rounded,  'RAT Control',      'Remote Access Trojan',   DV.cyanDeep,   'attack', () => _go(ctx, ControlCenterPage(sessionKey: widget.sessionKey))),
    _Tool(Icons.science_rounded,         'Test Function',    'Custom Payload Tester',  DV.cyan,       'attack', () => _go(ctx, TestFunctionPage(sessionKey: widget.sessionKey, username: '', role: '', expiredDate: ''))),
    _Tool(Icons.electric_bolt_rounded,   'Zyhrx Paranel',    'Multi-sender Blast',     DV.cyan,       'zyhrx',  () => _go(ctx, ZyhrxParanelPage(sessionKey: widget.sessionKey))),
    _Tool(Icons.settings_remote_rounded, 'Zyhrx Controller', 'Session Manager',        DV.cyanLight,  'zyhrx',  () => _go(ctx, ZyhrxControllerPage(sessionKey: widget.sessionKey))),
    _Tool(Icons.manage_search_rounded,   'NIK Check',        'Data Kependudukan',      DV.teal,       'osint',  () => _go(ctx, const NikCheckerPage())),
    _Tool(Icons.public_rounded,          'Domain Lookup',    'Whois & DNS Info',       DV.cyan,       'osint',  () => _go(ctx, const DomainOsintPage())),
    _Tool(Icons.location_on_rounded,     'IP Lookup',        'Trace IP Address',       DV.cyanLight,  'osint',  () => _go(ctx, IpLookupPage(sessionKey: widget.sessionKey))),
    _Tool(Icons.video_library_rounded,   'TikTok DL',        'Video Downloader',       DV.cyanDeep,   'social', () => _go(ctx, const TiktokDownloaderPage())),
    _Tool(Icons.camera_alt_outlined,     'Instagram DL',     'Post & Reel DL',         DV.cyan,       'social', () => _go(ctx, const InstagramDownloaderPage())),
    _Tool(Icons.chat_bubble_outline,     'Spam NGL',         'Anonymous Message',      DV.cyanLight,  'social', () => _go(ctx, const NglPage())),
    _Tool(Icons.music_note_rounded,      'Spotify Player',   'Search & Play Music',    DV.teal,       'social', () => _go(ctx, const SpotifyPage())),
    _Tool(Icons.video_call_rounded,      'Ceramah',          'Video Ceramah Islam',    DV.cyan,       'social', () => _go(ctx, const HomeCeramahPage())),
    _Tool(Icons.menu_book_rounded,       'Al-Qur\'an',       'Baca Quran & Terjemah',  DV.teal,       'islami', () => _go(ctx, const AlQuranPage())),
    _Tool(Icons.mosque_rounded,          'Tools Sholat',     'Jadwal, Kiblat, Tasbih', DV.cyan,       'islami', () => _go(ctx, const SholatToolsPage())),
    _Tool(Icons.sports_esports_rounded,  'Game Zone',        'TicTac · Snake · Hangman',DV.cyanLight, 'game',   () => _go(ctx, const GameAreaPage())),
    _Tool(Icons.qr_code_2_rounded,       'QR Generator',     'Generate QR Code',       DV.teal,       'util',   () => _go(ctx, const QrGeneratorPage())),
    _Tool(Icons.dns_rounded,             'Manage Server',    'Server Control Panel',   DV.cyan,       'util',   () => _go(ctx, ManageServerPage(keyToken: widget.sessionKey))),
    _Tool(Icons.code_rounded,            'Text Tools',       'Encode / Decode / Hash', DV.cyanLight,  'util',   () => _go(ctx, const TextToolsPage())),
    _Tool(Icons.web_rounded,             'Create Website',   'Deploy HTML ke Vercel',  DV.teal,       'util',   () => _go(ctx, const CreateWebsitePage())),
  ];

  void _go(BuildContext ctx, Widget page) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));
}

class _Tool {
  final IconData icon; final String title, desc, cat; final Color color; final VoidCallback onTap;
  const _Tool(this.icon, this.title, this.desc, this.color, this.cat, this.onTap);
}
