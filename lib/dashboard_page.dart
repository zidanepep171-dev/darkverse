// dashboard_page.dart — DarkVerse v6.0 QUANTUM DARK
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as wsStatus;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dv_theme.dart';
import 'admin_page.dart';
import 'owner_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'change_password_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'bug_sender.dart';
import 'contact_page.dart';
import 'profile_page.dart';
import 'riwayat_page.dart';
import 'info_page.dart';
import 'zyhrx_paranel.dart';
import 'zyhrx_controller.dart';

class DashboardPage extends StatefulWidget {
  final String username, password, role, expiredDate, sessionKey;
  final List<Map<String, dynamic>> listBug, listDoos;
  final List<dynamic> news;
  const DashboardPage({super.key,
    required this.username, required this.password, required this.role,
    required this.expiredDate, required this.listBug, required this.listDoos,
    required this.sessionKey, required this.news});
  @override State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl, _pulseCtrl, _scanCtrl, _orbCtrl, _dataCtrl;
  late Animation<double> _fadeAnim, _pulseAnim, _orbAnim, _dataAnim;
  WebSocketChannel? _channel;

  late String sessionKey, username, password, role, expiredDate;
  late List<Map<String, dynamic>> listBug, listDoos;
  late List<dynamic> newsList;

  String androidId = 'unknown';
  File? _profileImage;
  VideoPlayerController? _bannerCtrl;
  int _navIdx = 0;
  Widget _body = const _LoadingBody();
  int onlineUsers = 0, activeConns = 0;
  bool _wsConnected = false;
  int _newsPage = 0;

  @override
  void initState() {
    super.initState();
    sessionKey  = widget.sessionKey; username = widget.username;
    password    = widget.password;  role     = widget.role;
    expiredDate = widget.expiredDate; listBug = widget.listBug;
    listDoos    = widget.listDoos;   newsList = widget.news;

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
    _scanCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _orbCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat(reverse: true);
    _dataCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);

    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_pulseCtrl);
    _orbAnim   = Tween<double>(begin: 0.0, end: 1.0).animate(_orbCtrl);
    _dataAnim  = Tween<double>(begin: 0.0, end: 1.0).animate(_dataCtrl);
    _fadeCtrl.forward();

    _body = _homeDash();
    _initDevice();
    _loadProfile();
    _initBanner();
  }

  Future<void> _loadProfile() async {
    final p = await SharedPreferences.getInstance();
    final path = p.getString('profile_image_$username');
    if (path != null && path.isNotEmpty && mounted) setState(() => _profileImage = File(path));
  }

  void _initBanner() {
    _bannerCtrl = VideoPlayerController.asset('assets/videos/banner.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _bannerCtrl?.setLooping(true); _bannerCtrl?.setVolume(0); _bannerCtrl?.play();
      }).catchError((_) {});
  }

  Future<void> _initDevice() async {
    try { final d = await DeviceInfoPlugin().androidInfo; androidId = d.id; }
    catch (_) { androidId = 'unknown'; }
    _connectWS();
  }

  void _connectWS() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('wss://ws-rezacloundlegal.sistems.tech'));
      _channel!.sink.add(jsonEncode({'type': 'validate', 'key': sessionKey, 'androidId': androidId}));
      _channel!.sink.add(jsonEncode({'type': 'stats'}));
      _channel!.stream.listen((event) {
        final d = jsonDecode(event as String);
        if (d['type'] == 'myInfo' && d['valid'] == false) {
          _kickSession(d['reason'] == 'androidIdMismatch' ? 'Akun login di perangkat lain.' : 'Key tidak valid.');
        }
        if (d['type'] == 'stats' && mounted) setState(() {
          onlineUsers = d['onlineUsers'] ?? 0; activeConns = d['activeConnections'] ?? 0; _wsConnected = true;
        });
      }, onError: (_) { if (mounted) setState(() => _wsConnected = false); });
    } catch (_) { if (mounted) setState(() => _wsConnected = false); }
  }

  void _kickSession(String msg) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final p = await SharedPreferences.getInstance(); await p.clear();
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      backgroundColor: DV.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: DV.borderHi)),
      title: const Text('⚠️ Session Terminated', style: TextStyle(color: DV.textPrimary, fontWeight: FontWeight.bold)),
      content: Text(msg, style: const TextStyle(color: DV.textSecondary)),
      actions: [TextButton(
        onPressed: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false),
        child: const Text('OK', style: TextStyle(color: DV.plasma)))],
    ));
  }

  void _go(Widget page) => setState(() { _fadeCtrl.reset(); _fadeCtrl.forward(); _body = page; _navIdx = -1; });

  void _switchTab(int i) => setState(() {
    _navIdx = i; _fadeCtrl.reset(); _fadeCtrl.forward();
    _body = switch (i) {
      0 => _homeDash(),
      1 => HomePage(username: username, password: password, listBug: listBug, role: role, expiredDate: expiredDate, sessionKey: sessionKey),
      2 => InfoPage(sessionKey: sessionKey),
      3 => ToolsPage(sessionKey: sessionKey, userRole: role, listDoos: listDoos),
      _ => _homeDash(),
    };
  });

  void _openUrl(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  void dispose() {
    try { _channel?.sink.close(wsStatus.goingAway); } catch (_) {}
    _fadeCtrl.dispose(); _pulseCtrl.dispose(); _scanCtrl.dispose(); _orbCtrl.dispose(); _dataCtrl.dispose();
    _bannerCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DV.bg0,
      body: Stack(children: [
        Container(decoration: BoxDecoration(gradient: DV.bgGradient)),
        // Quantum mesh
        Positioned.fill(child: Opacity(opacity: 0.4, child: CustomPaint(painter: _DashBgPainter()))),
        // Plasma orb
        AnimatedBuilder(animation: _orbAnim, builder: (_, __) => Positioned(
          top: -80 + _orbAnim.value * 18, right: -70,
          child: Container(width: 280, height: 280, decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [DV.plasma.withOpacity(0.14 + _orbAnim.value * 0.05), Colors.transparent]))))),
        // Holo orb
        AnimatedBuilder(animation: _pulseAnim, builder: (_, __) => Positioned(
          bottom: 80, left: -50,
          child: Container(width: 200, height: 200, decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [DV.holo.withOpacity(0.06 + _pulseAnim.value * 0.04), Colors.transparent]))))),
        // Scan
        AnimatedBuilder(animation: _scanCtrl, builder: (_, __) => Positioned(
          top: MediaQuery.of(context).size.height * _scanCtrl.value,
          left: 0, right: 0,
          child: Container(height: 1, decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.transparent, DV.plasma.withOpacity(0.10), DV.holo.withOpacity(0.06), Colors.transparent]))))),
        // Layout
        Column(children: [
          _topBar(),
          Expanded(child: FadeTransition(opacity: _fadeAnim, child: _body)),
        ]),
        Positioned(bottom: 0, left: 0, right: 0, child: _bottomNav()),
      ]),
      drawer: _drawer(),
    );
  }

  Widget _topBar() => SafeArea(bottom: false, child: Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
    decoration: BoxDecoration(
      color: DV.bg0.withOpacity(0.88),
      border: Border(bottom: BorderSide(color: DV.borderHi.withOpacity(0.12)))),
    child: ClipRect(child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Row(children: [
        Builder(builder: (ctx) => GestureDetector(
          onTap: () => Scaffold.of(ctx).openDrawer(),
          child: AnimatedBuilder(animation: _pulseAnim, builder: (_, __) => Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: DV.fireGradient,
              boxShadow: [
                BoxShadow(color: DV.plasma.withOpacity(0.45 + _pulseAnim.value * 0.2), blurRadius: 14),
                BoxShadow(color: DV.holo.withOpacity(0.12), blurRadius: 20),
              ]),
            child: _profileImage != null
              ? ClipOval(child: Image.file(_profileImage!, fit: BoxFit.cover))
              : const Icon(FontAwesomeIcons.userAstronaut, color: Colors.white, size: 16))))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ShaderMask(shaderCallback: (b) => DV.fireGradient.createShader(b),
              child: Text(username, style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 14, fontFamily: 'Orbitron'))),
            const SizedBox(width: 8),
            _roleBadge(),
          ]),
          Row(children: [
            Icon(Icons.schedule_rounded, size: 10, color: DV.textHint),
            const SizedBox(width: 3),
            Text('EXP: $expiredDate', style: TextStyle(color: DV.textHint, fontSize: 9, letterSpacing: 0.5)),
          ]),
        ])),
        // Status indicator
        AnimatedBuilder(animation: _dataAnim, builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: (_wsConnected ? DV.success : DV.error).withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (_wsConnected ? DV.success : DV.error).withOpacity(0.22))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 5, height: 5, decoration: BoxDecoration(
              shape: BoxShape.circle, color: _wsConnected ? DV.success : DV.error,
              boxShadow: [BoxShadow(color: (_wsConnected ? DV.success : DV.error).withOpacity(0.8), blurRadius: 6)])),
            const SizedBox(width: 5),
            Text('$onlineUsers', style: TextStyle(
              color: _wsConnected ? DV.success : DV.error, fontSize: 11, fontWeight: FontWeight.w700)),
          ]))),
        const SizedBox(width: 4),
        _iconBtn(Icons.headset_mic_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactPage()))),
        _iconBtn(Icons.person_outline_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(
          username: username, password: password, role: role, expiredDate: expiredDate, sessionKey: sessionKey)))),
      ])))));

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 36, height: 36, margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: DV.surface, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DV.border)),
      child: Icon(icon, color: DV.textSecondary, size: 18)));

  Widget _roleBadge() {
    final c = {'owner': DV.acid, 'admin': DV.plasma, 'reseller': DV.holo, 'member': DV.textSecondary}[role.toLowerCase()] ?? DV.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: c.withOpacity(0.4))),
      child: Text(role.toUpperCase(), style: TextStyle(color: c, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontFamily: 'Orbitron')));
  }

  Widget _homeDash() => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _statsRow(),
      const SizedBox(height: 22),
      _sHead('📡', 'SIGNAL FEED', DV.holo),
      const SizedBox(height: 12),
      _newsCarousel(),
      const SizedBox(height: 22),
      _sHead('⚡', 'QUICK ACCESS', DV.plasma),
      const SizedBox(height: 12),
      _actionGrid(),
      const SizedBox(height: 22),
      if (role == 'reseller' || role == 'admin' || role == 'owner') ...[
        _sHead('🔑', 'CONTROL PANEL', DV.acid),
        const SizedBox(height: 12),
        _specialPanel(),
        const SizedBox(height: 22),
      ],
      _sHead('🧩', 'ACTIVE MODULES', DV.neonM),
      const SizedBox(height: 12),
      _moduleList(),
    ]),
  );

  Widget _sHead(String emoji, String title, Color color) => Row(children: [
    Container(width: 3, height: 16,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8)])),
    const SizedBox(width: 10),
    Text(emoji, style: const TextStyle(fontSize: 13)),
    const SizedBox(width: 7),
    ShaderMask(shaderCallback: (b) => LinearGradient(
      colors: [color, color.withOpacity(0.7)]).createShader(b),
      child: Text(title, style: const TextStyle(color: Colors.white,
          fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 3, fontFamily: 'Orbitron'))),
  ]);

  Widget _statsRow() => Row(children: [
    _statCard('$onlineUsers', 'ONLINE', Icons.people_rounded, DV.plasma),
    const SizedBox(width: 10),
    _statCard('$activeConns', 'CONNS', Icons.hub_rounded, DV.holo),
    const SizedBox(width: 10),
    _statCard(_daysLeft(), 'DAYS LEFT', Icons.timer_rounded, DV.acid),
  ]);

  Widget _statCard(String val, String label, IconData icon, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    decoration: BoxDecoration(
      color: DV.bgCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.22)),
      boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 14)]),
    child: Column(children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25))),
        child: Icon(icon, color: color, size: 16)),
      const SizedBox(height: 8),
      Text(val, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Orbitron')),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: DV.textHint, fontSize: 7, letterSpacing: 1.5)),
    ])));

  Widget _newsCarousel() {
    if (newsList.isEmpty) return Container(height: 130,
      decoration: BoxDecoration(color: DV.bgCard, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DV.border)),
      child: const Center(child: Text('No feed available', style: TextStyle(color: DV.textHint))));

    return Column(children: [
      SizedBox(height: 180, child: PageView.builder(
        controller: PageController(viewportFraction: 0.92),
        itemCount: newsList.length,
        onPageChanged: (i) => setState(() => _newsPage = i),
        itemBuilder: (_, i) {
          final item = newsList[i];
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DV.borderHi.withOpacity(0.35)),
                boxShadow: [BoxShadow(color: DV.glow.withOpacity(0.18), blurRadius: 18)]),
              child: ClipRRect(borderRadius: BorderRadius.circular(19),
                child: Stack(fit: StackFit.expand, children: [
                  if (item['image'] != null && (item['image'] as String).isNotEmpty)
                    _NewsMedia(url: item['image'] as String),
                  DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.96), Colors.transparent]))),
                  // HUD corners
                  Positioned(top: 10, left: 10, child: _hCorner(false, false)),
                  Positioned(top: 10, right: 10, child: _hCorner(false, true)),
                  Positioned(bottom: 50, left: 16, right: 16, child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: DV.plasma.withOpacity(0.15), borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: DV.borderHi.withOpacity(0.4))),
                      child: const Text(':: FEED', style: TextStyle(color: DV.textGlow, fontSize: 8, letterSpacing: 2.5, fontFamily: 'Orbitron'))),
                    const SizedBox(height: 6),
                    Text(item['title'] ?? '', style: const TextStyle(color: DV.textPrimary, fontSize: 13,
                        fontWeight: FontWeight.bold, fontFamily: 'Orbitron'), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(item['desc'] ?? '', style: const TextStyle(color: DV.textSecondary, fontSize: 9),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                ]))));
        })),
      if (newsList.length > 1) ...[
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(
          newsList.length > 5 ? 5 : newsList.length, (i) =>
          AnimatedContainer(duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _newsPage == i ? 20 : 5, height: 3,
            decoration: BoxDecoration(
              color: _newsPage == i ? DV.holo : DV.textHint.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
              boxShadow: _newsPage == i ? [BoxShadow(color: DV.glowHolo, blurRadius: 6)] : [])))),
      ],
    ]);
  }

  Widget _hCorner(bool bottom, bool right) => SizedBox(width: 14, height: 14,
    child: CustomPaint(painter: _HUDCornerPainter(bottom: bottom, right: right)));

  Widget _actionGrid() {
    final List<Widget> tiles = <Widget>[];
    final List<_Ac> actions = <_Ac>[
      _Ac(Icons.local_fire_department_rounded, 'ATTACK',     DV.error,   DV.hotGradient,  true,  () => _switchTab(1)),
      _Ac(Icons.terminal_rounded,              'TOOLS',      DV.holo,    DV.holoGradient, false, () => _switchTab(3)),
      _Ac(Icons.electric_bolt_rounded,         'PARANEL',    DV.plasma,  DV.fireGradient, false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ZyhrxParanelPage(sessionKey: sessionKey)))),
      _Ac(Icons.settings_remote_rounded,       'CTRL',       DV.ion,     DV.coldGradient, false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ZyhrxControllerPage(sessionKey: sessionKey)))),
      _Ac(FontAwesomeIcons.whatsapp,           'BUG',        DV.neonG,   DV.cyanGradient, false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => BugSenderPage(sessionKey: sessionKey, username: username, role: role)))),
      _Ac(Icons.campaign_rounded,              'TG',         DV.xray,    DV.coldGradient, false, () => _openUrl('https://t.me/InfoChDarkness')),
    ];
    for (final _Ac a in actions) {
      tiles.add(GestureDetector(
        onTap: a.onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: a.primary ? a.gradient : null,
            color: a.primary ? null : DV.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: a.primary ? Colors.transparent : a.color.withOpacity(0.25)),
            boxShadow: a.primary ? [
              BoxShadow(color: a.color.withOpacity(0.5), blurRadius: 20),
              BoxShadow(color: a.color.withOpacity(0.2), blurRadius: 40),
            ] : [BoxShadow(color: a.color.withOpacity(0.04), blurRadius: 10)]),
          child: Stack(children: [
            if (!a.primary) Positioned(top: -6, right: -6, child: Container(width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [a.color.withOpacity(0.12), Colors.transparent])))),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(a.icon, color: a.primary ? Colors.white : a.color, size: 22),
              const SizedBox(height: 6),
              Text(a.label, style: TextStyle(color: a.primary ? Colors.white : DV.textPrimary,
                fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8, fontFamily: 'Orbitron'),
                textAlign: TextAlign.center),
            ]),
          ]))));
    }
    return GridView.count(crossAxisCount: 3, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.05,
      children: tiles);
  }

  Widget _specialPanel() => Column(children: [
    if (role == 'reseller') _specBtn(Icons.storefront_rounded,          'SELLER PANEL', DV.neonG,  () => _go(SellerPage(keyToken: sessionKey))),
    if (role == 'admin')    _specBtn(Icons.admin_panel_settings_rounded, 'ADMIN PANEL',  DV.plasma, () => _go(AdminPage(sessionKey: sessionKey))),
    if (role == 'owner')    _specBtn(Icons.workspace_premium_rounded,    'OWNER PANEL',  DV.acid,   () => _go(OwnerPage(sessionKey: sessionKey, username: username))),
  ]);

  Widget _specBtn(IconData icon, String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10), height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 16)]),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 2, fontFamily: 'Orbitron')),
        const SizedBox(width: 10),
        Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 12),
      ])));

  Widget _moduleList() {
    final List<_Mod> modules = <_Mod>[
      _Mod(Icons.login_rounded,           DV.success,  'Login Active',      'Session authenticated'),
      _Mod(Icons.bug_report_rounded,      DV.plasma,   'Bug Sender',        'WA crasher module online'),
      _Mod(Icons.bolt_rounded,            DV.neonM,    'DDoS Panel',        'Stress test engine ready'),
      _Mod(Icons.electric_bolt_rounded,   DV.holo,     'Zyhrx Paranel',     'Multi-sender blast engine'),
      _Mod(Icons.settings_remote_rounded, DV.ion,      'Zyhrx Controller',  'Session management active'),
      _Mod(Icons.developer_mode_rounded,  DV.xray,     'RAT Control',       'Remote access interface'),
      _Mod(Icons.manage_search_rounded,   DV.neonC,    'OSINT Tools',       'NIK, domain & IP lookup'),
      _Mod(Icons.wifi_off_rounded,        DV.warning,  'Wifi Tools',        'Network scanner ready'),
      _Mod(Icons.menu_book_rounded,       DV.neonG,    'Al-Qur\'an',        'Quran & translation'),
      _Mod(Icons.music_note_rounded,      DV.acid,     'Spotify Player',    'Music stream interface'),
      _Mod(Icons.sports_esports_rounded,  DV.holo,     'Game Zone',         '3 games available'),
      _Mod(Icons.web_rounded,             DV.neonC,    'Create Website',    'Deploy HTML to Vercel'),
    ];
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < modules.length; i++) {
      final _Mod m = modules[i];
      final isFirst = i == 0;
      rows.add(Column(children: <Widget>[
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: <Widget>[
            Container(width: 38, height: 38,
              decoration: BoxDecoration(
                color: m.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: m.color.withOpacity(0.28)),
                boxShadow: isFirst ? [BoxShadow(color: m.color.withOpacity(0.15), blurRadius: 10)] : []),
              child: Icon(m.icon, color: m.color, size: 17)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(m.title, style: TextStyle(color: isFirst ? DV.textPrimary : DV.textPrimary.withOpacity(0.85),
                  fontSize: 13, fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500)),
              Text(m.sub, style: const TextStyle(color: DV.textSecondary, fontSize: 9, height: 1.4),
                overflow: TextOverflow.ellipsis),
            ])),
            if (isFirst) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: DV.success.withOpacity(0.08), borderRadius: BorderRadius.circular(6),
                border: Border.all(color: DV.success.withOpacity(0.35))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 4, height: 4, decoration: BoxDecoration(
                  shape: BoxShape.circle, color: DV.success,
                  boxShadow: [BoxShadow(color: DV.success.withOpacity(0.8), blurRadius: 4)])),
                const SizedBox(width: 5),
                const Text('ONLINE', style: TextStyle(color: DV.success, fontSize: 8,
                    fontWeight: FontWeight.w800, letterSpacing: 1, fontFamily: 'Orbitron')),
              ])),
          ])),
        if (i < modules.length - 1) Container(height: 1, margin: const EdgeInsets.only(left: 68),
          decoration: BoxDecoration(gradient: LinearGradient(
            colors: [DV.borderHi.withOpacity(0.2), DV.border, Colors.transparent]))),
      ]));
    }
    return Container(
      decoration: BoxDecoration(
        color: DV.bgCard, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DV.border),
        boxShadow: [BoxShadow(color: DV.glow.withOpacity(0.04), blurRadius: 20)]),
      child: Column(children: rows));
  }

  String _daysLeft() {
    try {
      final p = expiredDate.split('-');
      if (p.length == 3) {
        final exp = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
        final d = exp.difference(DateTime.now()).inDays;
        return d <= 0 ? 'EXP' : '${d}d';
      }
    } catch (_) {}
    return '--';
  }

  Widget _drawer() => Drawer(
    backgroundColor: DV.bg0,
    width: MediaQuery.of(context).size.width * 0.78,
    child: Column(children: [
      _drawerHeader(),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(12, 10, 12, 0), children: [
        _dItem(Icons.home_rounded,            'Dashboard',        () { Navigator.pop(context); _switchTab(0); }),
        _dItem(FontAwesomeIcons.whatsapp,     'Bug Sender',       () { Navigator.pop(context); _switchTab(1); }),
        _dItem(Icons.notifications_rounded,   'Info & Feed',      () { Navigator.pop(context); _switchTab(2); }),
        _dItem(Icons.terminal_rounded,        'Tools Hub',        () { Navigator.pop(context); _switchTab(3); }),
        _dItem(Icons.electric_bolt_rounded,   'Zyhrx Paranel',   () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ZyhrxParanelPage(sessionKey: sessionKey))); }),
        _dItem(Icons.settings_remote_rounded, 'Zyhrx Controller',() { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ZyhrxControllerPage(sessionKey: sessionKey))); }),
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Container(height: 1,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, DV.border, Colors.transparent])))),
        if (role == 'reseller') _dItem(Icons.storefront_rounded,           'Seller Panel', () { Navigator.pop(context); _go(SellerPage(keyToken: sessionKey)); }),
        if (role == 'admin')    _dItem(Icons.admin_panel_settings_rounded,  'Admin Panel',  () { Navigator.pop(context); _go(AdminPage(sessionKey: sessionKey)); }),
        if (role == 'owner')    _dItem(Icons.workspace_premium_rounded,     'Owner Panel',  () { Navigator.pop(context); _go(OwnerPage(sessionKey: sessionKey, username: username)); }),
        _dItem(Icons.history_rounded,         'Riwayat',          () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => RiwayatPage(sessionKey: sessionKey, role: role))); }),
        _dItem(Icons.person_outline_rounded,  'Profile',          () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(username: username, password: password, role: role, expiredDate: expiredDate, sessionKey: sessionKey))); }),
        _dItem(Icons.lock_outline_rounded,    'Change Password',  () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordPage(username: username, sessionKey: sessionKey))); }),
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Container(height: 1,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, DV.border, Colors.transparent])))),
        _dItem(Icons.logout_rounded, 'Logout', () async {
          Navigator.pop(context);
          final p = await SharedPreferences.getInstance(); await p.clear();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
        }, isLogout: true),
        const SizedBox(height: 24),
      ])),
    ]),
  );

  Widget _drawerHeader() => Container(
    height: 220,
    decoration: BoxDecoration(color: DV.bg1, border: Border(bottom: BorderSide(color: DV.border))),
    child: Stack(children: [
      if (_bannerCtrl != null && _bannerCtrl!.value.isInitialized)
        Opacity(opacity: 0.25, child: SizedBox.expand(child: FittedBox(fit: BoxFit.cover,
          child: SizedBox(width: _bannerCtrl!.value.size.width, height: _bannerCtrl!.value.size.height, child: VideoPlayer(_bannerCtrl!))))),
      Container(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [DV.bg0.withOpacity(0.15), DV.bg1.withOpacity(0.95)]))),
      // Quantum mesh
      Positioned.fill(child: Opacity(opacity: 0.3, child: CustomPaint(painter: _DashBgPainter()))),
      Positioned(top: -40, right: -40, child: Container(width: 140, height: 140,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [DV.plasma.withOpacity(0.14), Colors.transparent])))),
      SafeArea(bottom: false, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(animation: _pulseAnim, builder: (_, __) => Stack(
          alignment: Alignment.center, children: [
          Container(width: 82, height: 82, decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: DV.holo.withOpacity(0.15 + _pulseAnim.value * 0.1), width: 1))),
          Container(width: 74, height: 74, padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: DV.fireGradient,
              boxShadow: [
                BoxShadow(color: DV.plasma.withOpacity(0.5 + _pulseAnim.value * 0.3), blurRadius: 22),
                BoxShadow(color: DV.holo.withOpacity(0.15), blurRadius: 32),
              ]),
            child: ClipOval(child: _profileImage != null
              ? Image.file(_profileImage!, fit: BoxFit.cover)
              : Container(color: DV.bg0, child: const Icon(FontAwesomeIcons.userAstronaut, size: 28, color: DV.plasma)))),
        ])),
        const SizedBox(height: 10),
        ShaderMask(shaderCallback: (b) => DV.fireGradient.createShader(b),
          child: Text(username, style: const TextStyle(color: Colors.white, fontSize: 18,
              fontWeight: FontWeight.w900, fontFamily: 'Orbitron'))),
        const SizedBox(height: 5),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _roleBadge(),
          const SizedBox(width: 8),
          Text('// $expiredDate', style: TextStyle(color: DV.textHint, fontSize: 9, fontFamily: 'ShareTechMono')),
        ]),
      ]))),
    ]),
  );

  Widget _dItem(IconData icon, String label, VoidCallback onTap, {bool isLogout = false}) {
    final color = isLogout ? DV.error : DV.plasma;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        leading: Container(width: 34, height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.18))),
          child: Icon(icon, color: color, size: 15)),
        title: Text(label, style: TextStyle(
          color: isLogout ? DV.error : DV.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right_rounded, color: DV.textHint, size: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap));
  }

  Widget _bottomNav() => ClipRect(child: BackdropFilter(
    filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
    child: Container(
      decoration: BoxDecoration(
        color: DV.bg0.withOpacity(0.92),
        border: Border(top: BorderSide(color: DV.borderHi.withOpacity(0.15))),
        boxShadow: [BoxShadow(color: DV.glow.withOpacity(0.10), blurRadius: 28, offset: const Offset(0, -6))]),
      child: SafeArea(top: false, child: Row(children: [
        _navItem(0, Icons.home_outlined,          Icons.home_rounded,          'HOME',   DV.plasma),
        _navItem(1, FontAwesomeIcons.whatsapp,    FontAwesomeIcons.whatsapp,   'BUG',    DV.neonG),
        _navItem(2, Icons.notifications_outlined, Icons.notifications_rounded, 'FEED',   DV.holo),
        _navItem(3, Icons.terminal_outlined,      Icons.terminal_rounded,      'TOOLS',  DV.neonM),
      ])))));

  Widget _navItem(int idx, IconData inactiveIcon, IconData activeIcon, String label, Color color) {
    final active = _navIdx == idx;
    return Expanded(child: GestureDetector(
      onTap: () => _switchTab(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: active ? color : Colors.transparent, width: 2))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(active ? 6.0 : 0.0),
            decoration: BoxDecoration(
              color: active ? color.withOpacity(0.10) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: active ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12)] : []),
            child: Icon(active ? activeIcon : inactiveIcon, color: active ? color : DV.textHint, size: 19)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: active ? color : DV.textHint,
            fontSize: 8, fontWeight: active ? FontWeight.w900 : FontWeight.normal,
            fontFamily: active ? 'Orbitron' : null, letterSpacing: active ? 0.5 : 0)),
        ]))));
  }
}

// ── Data classes ───────────────────────────────────────────────────────────────
class _Ac {
  final IconData icon; final String label; final Color color;
  final LinearGradient gradient; final bool primary; final VoidCallback onTap;
  const _Ac(this.icon, this.label, this.color, this.gradient, this.primary, this.onTap);
}
class _Mod { final IconData icon; final Color color; final String title, sub;
  const _Mod(this.icon, this.color, this.title, this.sub); }

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();
  @override Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(width: 48, height: 48, child: CircularProgressIndicator(
        strokeWidth: 2, color: DV.plasma,
        backgroundColor: DV.plasma.withOpacity(0.1))),
      const SizedBox(height: 14),
      const Text('LOADING...', style: TextStyle(color: DV.textHint, fontSize: 9, letterSpacing: 3, fontFamily: 'Orbitron')),
    ]));
}

class _NewsMedia extends StatefulWidget {
  final String url; const _NewsMedia({required this.url});
  @override State<_NewsMedia> createState() => _NewsMediaState();
}
class _NewsMediaState extends State<_NewsMedia> {
  VideoPlayerController? _ctrl;
  bool get _isVid => widget.url.endsWith('.mp4') || widget.url.endsWith('.webm');
  @override void initState() {
    super.initState();
    if (_isVid) {
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (mounted) { setState(() {}); _ctrl?.setLooping(true); _ctrl?.setVolume(0); _ctrl?.play(); }
        });
    }
  }
  @override void dispose() { _ctrl?.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    if (_isVid) {
      if (_ctrl != null && _ctrl!.value.isInitialized)
        return FittedBox(fit: BoxFit.cover, child: SizedBox(
          width: _ctrl!.value.size.width, height: _ctrl!.value.size.height, child: VideoPlayer(_ctrl!)));
      return Container(color: DV.bgCard, child: Center(
        child: CircularProgressIndicator(color: DV.plasma, strokeWidth: 2)));
    }
    return Image.network(widget.url, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: DV.bgCard,
        child: const Icon(Icons.broken_image_rounded, color: DV.textHint)));
  }
}

class _DashBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFB300FF).withOpacity(0.025)..strokeWidth = 0.4;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _HUDCornerPainter extends CustomPainter {
  final bool bottom, right;
  _HUDCornerPainter({required this.bottom, required this.right});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF00FFEA).withOpacity(0.6)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final x = right ? 0.0 : size.width; final y = bottom ? 0.0 : size.height;
    final ex = right ? size.width : 0.0; final ey = bottom ? size.height : 0.0;
    canvas.drawLine(Offset(x, y), Offset(ex, y), p);
    canvas.drawLine(Offset(x, y), Offset(x, ey), p);
  }
  @override bool shouldRepaint(_) => false;
}
