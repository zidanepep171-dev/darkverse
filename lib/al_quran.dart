import 'dart:convert';
import 'package:flutter/material.dart';
import 'dv_theme.dart';
import 'package:http/http.dart' as http;


class Ayat {
  final int nomor;
  final String arab;
  final String arti;

  Ayat({
    required this.nomor,
    required this.arab,
    required this.arti,
  });
}

class Surat {
  final int nomor;
  final String nama;
  final String latin;
  final List<Ayat> ayat;

  Surat({
    required this.nomor,
    required this.nama,
    required this.latin,
    required this.ayat,
  });
}


class AlQuranPage extends StatefulWidget {
  const AlQuranPage({super.key});

  @override
  State<AlQuranPage> createState() => _AlQuranPageState();
}

class _AlQuranPageState extends State<AlQuranPage> {
  bool loading = true;
  List<Surat> suratList = [];

  @override
  void initState() {
    super.initState();
    _loadQuran();
  }


  Future<void> _loadQuran() async {
    try {
      final arabRes = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/quran/quran-uthmani'),
      );
      final indoRes = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/quran/id.indonesian'),
      );

      final arabData = jsonDecode(arabRes.body);
      final indoData = jsonDecode(indoRes.body);

      final List arabSurah = arabData['data']['surahs'];
      final List indoSurah = indoData['data']['surahs'];

      List<Surat> result = [];

      for (int i = 0; i < arabSurah.length; i++) {
        final List arabAyat = arabSurah[i]['ayahs'];
        final List indoAyat = indoSurah[i]['ayahs'];

        List<Ayat> ayatList = [];

        for (int j = 0; j < arabAyat.length; j++) {
          ayatList.add(
            Ayat(
              nomor: arabAyat[j]['numberInSurah'],
              arab: arabAyat[j]['text'],
              arti: indoAyat[j]['text'],
            ),
          );
        }

        result.add(
          Surat(
            nomor: arabSurah[i]['number'],
            nama: arabSurah[i]['name'],
            latin: arabSurah[i]['englishName'],
            ayat: ayatList,
          ),
        );
      }

      setState(() {
        suratList = result;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DV.bg0,
      appBar: AppBar(
        backgroundColor: DV.bg0,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'AL-QUR\'AN',
          style: TextStyle(
            fontFamily: 'Orbitron',
            letterSpacing: 2,
            color: DV.orange,
          ),
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: DV.orange), onPressed: () => Navigator.pop(context)),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: DV.orange,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: suratList.length,
              itemBuilder: (context, index) {
                return _suratCard(suratList[index]);
              },
            ),
    );
  }


  Widget _suratCard(Surat surat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: DV.bg1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DV.orange),
        boxShadow: [
          BoxShadow(
            color: DV.orangeGlow,
            blurRadius: 16,
          ),
        ],
      ),
      child: ExpansionTile(
        iconColor: DV.orange,
        collapsedIconColor: DV.orange,
        title: Text(
          '${surat.nomor}. ${surat.latin}',
          style: const TextStyle(
            fontFamily: 'Orbitron',
            color: DV.orange,
            letterSpacing: 1.5,
          ),
        ),
        subtitle: Text(
          surat.nama,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 18,
            color: DV.textPrimary,
          ),
        ),
        children: surat.ayat.map<Widget>(_ayatTile).toList(),
      ),
    );
  }


  Widget _ayatTile(Ayat ayat) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${ayat.nomor}',
            style: const TextStyle(
              fontFamily: 'Orbitron',
              color: DV.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ayat.arab,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 24,
              height: 1.9,
              color: DV.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              ayat.arti,
              style: const TextStyle(
                fontSize: 14,
                color: DV.orange,
              ),
            ),
          ),
          const Divider(color: DV.orange),
        ],
      ),
    );
  }
}