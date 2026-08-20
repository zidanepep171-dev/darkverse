//JANGAN LU MALING
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dv_theme.dart';
import 'package:http/http.dart' as http;

class SholatToolsPage extends StatefulWidget {
  const SholatToolsPage({super.key});

  @override
  State<SholatToolsPage> createState() => _SholatToolsPageState();
}

class _SholatToolsPageState extends State<SholatToolsPage> {
  // ===== JADWAL SHOLAT =====
  Map<String, String> jadwal = {};
  bool isLoadingJadwal = false;

  // ===== TASBIH =====
  int tasbihCount = 0;

  // ===== KIBLAT =====
  double kiblatDegree = 0;

  @override
  void initState() {
    super.initState();
    fetchJadwalSholat();
    hitungKiblat(-6.200000, 106.816666); // Jakarta (contoh)
  }

  // ================= JADWAL SHOLAT =================
  Future<void> fetchJadwalSholat() async {
    setState(() => isLoadingJadwal = true);

    final now = DateTime.now();
    final url = Uri.parse(
      "https://api.myquran.com/v2/sholat/jadwal/1301/${now.year}/${now.month}/${now.day}",
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final jadwalApi = data["data"]["jadwal"];

        setState(() {
          jadwal = {
            "Subuh": jadwalApi["subuh"],
            "Dzuhur": jadwalApi["dzuhur"],
            "Ashar": jadwalApi["ashar"],
            "Maghrib": jadwalApi["maghrib"],
            "Isya": jadwalApi["isya"],
          };
        });
      }
    } catch (_) {}
    setState(() => isLoadingJadwal = false);
  }

  // ================= KIBLAT =================
  void hitungKiblat(double lat, double lon) {
    const kaabaLat = 21.4225;
    const kaabaLon = 39.8262;

    final dLon = (kaabaLon - lon) * pi / 180;
    final y = sin(dLon);
    final x = cos(lat * pi / 180) * tan(kaabaLat * pi / 180) -
        sin(lat * pi / 180) * cos(dLon);

    final bearing = atan2(y, x) * 180 / pi;
    kiblatDegree = (bearing + 360) % 360;
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DV.bg0,
      appBar: AppBar(
        title: ShaderMask(shaderCallback: (b) => DV.fireGradient.createShader(b), child: const Text("TOOLS SHOLAT", style: TextStyle(color: DV.textPrimary, fontFamily: "Orbitron", fontWeight: FontWeight.w800, fontSize: 15))),
        backgroundColor: DV.bg0, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: DV.orange), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("📅 Jadwal Sholat"),
          isLoadingJadwal
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: jadwal.entries.map<Widget>((e) {
                    return _card("${e.key}", e.value);
                  }).toList(),
                ),

          const SizedBox(height: 24),
          _sectionTitle("🧭 Arah Kiblat"),
          _card("Derajat Kiblat", "${kiblatDegree.toStringAsFixed(2)}°"),

          const SizedBox(height: 24),
          _sectionTitle("📿 Tasbih Digital"),
          Center(
            child: Column(
              children: [
                Text(
                  "$tasbihCount",
                  style: const TextStyle(
                    fontSize: 48,
                    color: DV.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: DV.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => setState(() => tasbihCount++),
                      child: const Text('Tambah'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: DV.bg2, foregroundColor: DV.textPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => setState(() => tasbihCount = 0),
                      child: const Text('Reset'),
                    ),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 24),
          _sectionTitle("🔔 Pengingat Sholat"),
          _card("Status", "Fitur notifikasi bisa ditambahkan"),
        ],
      ),
    );
  }

  // ================= WIDGET BANTU =================
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: DV.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _card(String title, String value) {
    return Card(
      color: DV.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(color: DV.textPrimary),
        ),
        trailing: Text(
          value,
          style: const TextStyle(color: DV.success),
        ),
      ),
    );
  }
}