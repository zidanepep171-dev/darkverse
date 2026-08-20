import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dv_theme.dart';
const String _homeBaseUrl = 'http://rezacloudlegal.sistems.tech:2266';



class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  Set<String> selectedBugIds = {};
  String _selectedBugMode = "number";

  List<Map<String, dynamic>> _channelList = [];
  Map<String, dynamic>? _selectedChannel;
  bool _isLoadingChannels = false;

  bool _isSending = false;
  String? _responseMessage;

  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.asset('assets/videos/banner.mp4');
    _videoController.initialize().then((_) {
      setState(() {
        _videoController.setVolume(0.5);
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: true,
          showControls: false,
          autoInitialize: true,
        );
        _isVideoInitialized = true;
      });
    }).catchError((error) {
      setState(() => _isVideoInitialized = false);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    targetController.dispose();
    _videoController.dispose();
    if (_isVideoInitialized) _chewieController.dispose();
    super.dispose();
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length < 8) return null;
    return cleaned;
  }

  bool isValidGroupLink(String input) =>
      input.contains('chat.whatsapp.com') && input.contains('https://');

  Future<void> _fetchUserChannels() async {
    setState(() {
      _isLoadingChannels = true;
      _channelList = [];
      _selectedChannel = null;
    });
    try {
      final res = await http.get(Uri.parse("$_homeBaseUrl/mych?key=${widget.sessionKey}"));
      final data = jsonDecode(res.body);
      if (data["valid"] == true && data["sender"] == true && data["channel"] != null) {
        setState(() => _channelList = List<Map<String, dynamic>>.from(data["channel"]));
      } else {
        _showAlert("❌ Gagal Memuat Channel", "Tidak dapat mengambil daftar channel.");
      }
    } catch (e) {
      _showAlert("❌ Error", "Terjadi kesalahan saat memuat channel.");
    } finally {
      setState(() => _isLoadingChannels = false);
    }
  }

  void _showChannelSelectionPopup() {
    if (_channelList.isEmpty) _fetchUserChannels();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: DV.bg2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: DV.orange.withOpacity(0.5), width: 1),
            ),
            title: Row(children: [
              Icon(Icons.campaign, color: DV.orangeLight, size: 24),
              const SizedBox(width: 10),
              const Text("PILIH CHANNEL",
                  style: TextStyle(color: DV.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', fontSize: 18)),
            ]),
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: _isLoadingChannels
                  ? Center(child: CircularProgressIndicator(color: DV.orangeLight))
                  : _channelList.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.info_outline, color: DV.textSecondary, size: 48),
                            const SizedBox(height: 16),
                            Text("Tidak ada channel yang ditemukan", style: TextStyle(color: DV.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () { Navigator.pop(context); _fetchUserChannels(); },
                              style: ElevatedButton.styleFrom(backgroundColor: DV.orange, foregroundColor: Colors.white),
                              child: const Text("Refresh"),
                            ),
                          ]),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _channelList.length,
                          itemBuilder: (context, index) {
                            final channel = _channelList[index];
                            final isSelected = _selectedChannel?['id'] == channel['id'];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? DV.orange.withOpacity(0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? DV.orangeLight : DV.orange.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: isSelected ? DV.orangeLight : DV.textSecondary,
                                ),
                                title: Text(channel['title'] ?? 'Unknown Channel',
                                    style: TextStyle(
                                      color: DV.textPrimary,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontFamily: 'ShareTechMono',
                                    )),
                                subtitle: Text('ID: ${channel['id']}',
                                    style: TextStyle(color: DV.textSecondary, fontSize: 12)),
                                onTap: () => setState(() => _selectedChannel = channel),
                              ),
                            );
                          },
                        ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("CANCEL", style: TextStyle(color: DV.textSecondary, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DV.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _selectedChannel == null
                    ? null
                    : () {
                        setState(() => targetController.text = _selectedChannel!['title'] ?? '');
                        Navigator.pop(context);
                      },
                child: const Text("OK"),
              ),
            ],
          );
        });
      },
    );
  }

  void _showBugSelectionPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: DV.bg2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: DV.orange.withOpacity(0.5), width: 1),
            ),
            title: Row(children: [
              Icon(Icons.bug_report, color: DV.orangeLight, size: 24),
              const SizedBox(width: 10),
              const Text("PILIH BUG",
                  style: TextStyle(color: DV.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', fontSize: 18)),
            ]),
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.listBug.length,
                itemBuilder: (context, index) {
                  final bug = widget.listBug[index];
                  final bugId = bug['bug_id'];
                  final isSelected = selectedBugIds.contains(bugId);
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? DV.orange.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? DV.orangeLight : DV.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? DV.orangeLight : DV.textSecondary,
                      ),
                      title: Text(bug['bug_name'],
                          style: TextStyle(
                            color: DV.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontFamily: 'ShareTechMono',
                          )),
                      subtitle: bug['description'] != null
                          ? Text(bug['description'],
                              style: TextStyle(color: DV.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)
                          : null,
                      onTap: () => setState(() {
                        if (isSelected) selectedBugIds.remove(bugId);
                        else selectedBugIds.add(bugId);
                      }),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => setState(() => selectedBugIds.clear()),
                child: const Text("RESET", style: TextStyle(color: DV.error, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("CANCEL", style: TextStyle(color: DV.textSecondary, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DV.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: selectedBugIds.isEmpty ? null : () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _sendBug() async {
    final rawInput = targetController.text.trim();
    final key = widget.sessionKey;

    if (_selectedBugMode == "number") {
      final target = formatPhoneNumber(rawInput);
      if (target == null || key.isEmpty) {
        _showAlert("❌ Invalid Number", "Gunakan nomor internasional (misal: +62, 1, 44), bukan 08xxx.");
        return;
      }
      if (selectedBugIds.isEmpty) { _showAlert("❌ No Bug Selected", "Pilih minimal 1 bug untuk dikirim."); return; }
    } else if (_selectedBugMode == "group") {
      if (!isValidGroupLink(rawInput)) {
        _showAlert("❌ Invalid Link", "Masukkan link group WA yang valid (contoh: https://chat.whatsapp.com/...).");
        return;
      }
      if (selectedBugIds.isEmpty) { _showAlert("❌ No Bug Selected", "Pilih minimal 1 bug untuk dikirim."); return; }
    } else if (_selectedBugMode == "channel") {
      if (_selectedChannel == null) { _showAlert("❌ No Channel Selected", "Pilih channel tujuan terlebih dahulu."); return; }
    }

    setState(() { _isSending = true; _responseMessage = null; });

    try {
      late http.Response res;
      late Map<String, dynamic> data;

      if (_selectedBugMode == "channel") {
        res = await http.get(Uri.parse("$_homeBaseUrl/raidch?key=$key&id=${_selectedChannel!['id']}"));
        data = jsonDecode(res.body);
        if (data["cooldown"] == true) setState(() => _responseMessage = "⏳ Cooldown: Tunggu beberapa saat.");
        else if (data["valid"] == false) setState(() => _responseMessage = "❌ Key Invalid: Silakan login ulang.");
        else if (data["sender"] == false) setState(() => _responseMessage = "❌ Sender Anda Kosong.");
        else if (data["sended"] == false) setState(() => _responseMessage = "⚠️ Gagal: Server sedang maintenance.");
        else {
          setState(() => _responseMessage = "✅ Berhasil mengirim bug ke channel!");
          targetController.clear();
          _selectedChannel = null;
        }
      } else {
        final bugsParam = selectedBugIds.join(',');
        final apiType = _selectedBugMode == "number" ? "sendBug" : "raidGrouP";
        res = await http.get(Uri.parse("$_homeBaseUrl/$apiType?key=$key&target=$rawInput&bug=$bugsParam"));
        data = jsonDecode(res.body);
        if (data["cooldown"] == true) setState(() => _responseMessage = "⏳ Cooldown: Tunggu beberapa saat.");
        else if (data["valid"] == false) setState(() => _responseMessage = "❌ Key Invalid: Silakan login ulang.");
        else if (data["sender"] == false) setState(() => _responseMessage = "❌ Sender Anda Kosong.");
        else if (data["sended"] == false) setState(() => _responseMessage = "⚠️ Gagal: Server sedang maintenance.");
        else {
          setState(() => _responseMessage = "✅ Berhasil mengirim bug!");
          targetController.clear();
          selectedBugIds.clear();
        }
      }
    } catch (_) {
      setState(() => _responseMessage = "❌ Error: Terjadi kesalahan. Coba lagi.");
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DV.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: DV.orange.withOpacity(0.5)),
        ),
        title: Text(title,
            style: const TextStyle(color: DV.textOrange, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
        content: Text(msg,
            style: const TextStyle(color: DV.textSecondary, fontFamily: 'ShareTechMono')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: DV.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Header Panel ────────────────────────────────────────────────────────
  Widget _buildHeaderPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DV.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DV.orangeBorder, width: 1),
        boxShadow: [BoxShadow(color: DV.orangeGlow, blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: DV.fireGradient,
            boxShadow: [BoxShadow(color: DV.orangeGlow, blurRadius: 15, spreadRadius: 2)],
          ),
          child: const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage('assets/images/logo.png'),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.username,
                style: const TextStyle(
                  color: DV.textPrimary,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 1.0,
                )),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: DV.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DV.orangeBorder),
              ),
              child: Text(
                "Role: ${widget.role.toUpperCase()} • Exp: ${widget.expiredDate}",
                style: const TextStyle(
                  color: DV.textOrange,
                  fontFamily: 'ShareTechMono',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Video Player ────────────────────────────────────────────────────────
  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized) {
      return Container(
        width: double.infinity,
        height: 200,
        margin: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: DV.bg1, borderRadius: BorderRadius.circular(20)),
        child: Center(child: CircularProgressIndicator(color: DV.orange, strokeWidth: 3)),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: DV.orangeGlow, blurRadius: 24, spreadRadius: 2)],
        border: Border.all(color: DV.orangeBorder, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: Stack(children: [
            Chewie(controller: _chewieController),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, DV.orange.withOpacity(0.15)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Mode Selector ───────────────────────────────────────────────────────
  Widget _buildModeSelector() {
    return Row(children: [
      _modeTab("number", Icons.phone_android_rounded, "BUG NOMOR"),
      const SizedBox(width: 10),
      _modeTab("group", Icons.group_add, "BUG GROUP"),
      const SizedBox(width: 10),
      _modeTab("channel", Icons.campaign, "BUG CHANNEL"),
    ]);
  }

  Widget _modeTab(String mode, IconData icon, String label) {
    final isActive = _selectedBugMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedBugMode = mode;
          targetController.clear();
          _selectedChannel = null;
          if (mode == "channel") selectedBugIds.clear();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isActive ? DV.orange.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? DV.orange : DV.orange.withOpacity(0.25),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: isActive ? [BoxShadow(color: DV.orangeGlow, blurRadius: 10)] : [],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: isActive ? DV.orangeLight : DV.textHint, size: 18),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  color: isActive ? DV.orangeLight : DV.textHint,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  fontFamily: 'Orbitron',
                  letterSpacing: 0.5,
                )),
          ]),
        ),
      ),
    );
  }

  // ── Input Panel ─────────────────────────────────────────────────────────
  Widget _buildInputPanel() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _buildModeSelector(),
      const SizedBox(height: 24),

      // Label
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          _selectedBugMode == "number" ? "NOMOR TARGET" :
          _selectedBugMode == "group"  ? "LINK GROUP WA" : "PILIH CHANNEL",
          style: const TextStyle(
            color: DV.textPrimary, fontWeight: FontWeight.w700,
            fontSize: 13, fontFamily: 'Orbitron', letterSpacing: 1.5,
          ),
        ),
      ),

      // Target input or channel picker
      if (_selectedBugMode == "channel")
        GestureDetector(
          onTap: _showChannelSelectionPopup,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: DV.bg1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DV.orange.withOpacity(0.3), width: 1.5),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                child: _selectedChannel == null
                    ? Text("Klik untuk memilih channel", style: TextStyle(color: DV.textHint, fontSize: 14))
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_selectedChannel!['title'] ?? 'Unknown Channel',
                            style: const TextStyle(color: DV.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("ID: ${_selectedChannel!['id']}",
                            style: TextStyle(color: DV.textSecondary, fontSize: 12)),
                      ]),
              ),
              Icon(Icons.arrow_drop_down, color: DV.orange, size: 28),
            ]),
          ),
        )
      else
        TextField(
          controller: targetController,
          style: const TextStyle(color: DV.textPrimary, fontSize: 16, fontFamily: 'ShareTechMono'),
          cursorColor: DV.orange,
          keyboardType: _selectedBugMode == "number" ? TextInputType.phone : TextInputType.url,
          decoration: InputDecoration(
            hintText: _selectedBugMode == "number"
                ? "Contoh: +62xxxxxxxxxx"
                : "Contoh: https://chat.whatsapp.com/...",
            hintStyle: TextStyle(color: DV.textHint.withOpacity(0.6)),
            filled: true,
            fillColor: DV.bg1,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: DV.orange.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: DV.orange, width: 1.5),
            ),
            prefixIcon: Icon(
              _selectedBugMode == "number" ? Icons.phone_android_rounded : Icons.link,
              color: DV.orange,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          ),
        ),

      // Bug selector (hidden for channel mode)
      if (_selectedBugMode != "channel") ...[
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("PILIH BUG",
                style: TextStyle(color: DV.textPrimary, fontWeight: FontWeight.w700,
                    fontSize: 13, fontFamily: 'Orbitron', letterSpacing: 1.5)),
            if (selectedBugIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: DV.fireGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("${selectedBugIds.length} dipilih",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
          ]),
        ),
        GestureDetector(
          onTap: _showBugSelectionPopup,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: DV.bg1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DV.orange.withOpacity(0.3), width: 1.5),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                child: selectedBugIds.isEmpty
                    ? Text("Klik untuk memilih bug", style: TextStyle(color: DV.textHint, fontSize: 14))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: selectedBugIds.map<Widget>((bugId) {
                          final bug = widget.listBug.firstWhere(
                            (b) => b['bug_id'] == bugId,
                            orElse: () => {'bug_name': 'Unknown'},
                          );
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: DV.orange.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: DV.orangeLight.withOpacity(0.5)),
                            ),
                            child: Text(bug['bug_name'],
                                style: const TextStyle(color: DV.textOrange, fontSize: 12)),
                          );
                        }).toList(),
                      ),
              ),
              Icon(Icons.arrow_drop_down, color: DV.orange, size: 28),
            ]),
          ),
        ),
      ],
    ]);
  }

  // ── Send Button ─────────────────────────────────────────────────────────
  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          height: 65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: DV.fireGradient,
            boxShadow: [
              BoxShadow(
                color: DV.orange.withOpacity(0.4),
                blurRadius: _pulseController.value * 28,
                spreadRadius: _pulseController.value * 3,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendBug,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: _isSending
                ? const SizedBox(
                    height: 24, width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 12),
                    Text("SEND BUG ATTACK",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          letterSpacing: 2,
                          fontFamily: 'Orbitron',
                        )),
                  ]),
          ),
        );
      },
    );
  }

  // ── Response Message ────────────────────────────────────────────────────
  Widget _buildResponseMessage() {
    if (_responseMessage == null) return const SizedBox.shrink();

    Color bgColor, borderColor, textColor;
    IconData icon;

    if (_responseMessage!.startsWith('✅')) {
      bgColor = DV.success.withOpacity(0.12);
      borderColor = DV.success;
      textColor = DV.success;
      icon = Icons.check_circle_outline_rounded;
    } else if (_responseMessage!.startsWith('❌')) {
      bgColor = DV.error.withOpacity(0.12);
      borderColor = DV.error;
      textColor = DV.error;
      icon = Icons.error_outline_rounded;
    } else {
      bgColor = DV.orange.withOpacity(0.12);
      borderColor = DV.orangeLight;
      textColor = DV.textOrange;
      icon = Icons.info_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor.withOpacity(0.5), width: 1),
          boxShadow: [BoxShadow(color: borderColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_responseMessage!,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'ShareTechMono')),
          ),
        ]),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DV.bg0,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeaderPanel(),
              _buildVideoPlayer(),
              _buildInputPanel(),
              const SizedBox(height: 40),
              _buildSendButton(),
              _buildResponseMessage(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
