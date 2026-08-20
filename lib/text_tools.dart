// text_tools.dart — DarkVerse v4.0 NEW TOOL: Text Encoder / Decoder / Hasher
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dv_theme.dart';

class TextToolsPage extends StatefulWidget {
  const TextToolsPage({super.key});
  @override
  State<TextToolsPage> createState() => _TextToolsPageState();
}

class _TextToolsPageState extends State<TextToolsPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _inputCtrl  = TextEditingController();
  final _outputCtrl = TextEditingController();

  String _mode    = 'base64_enc';
  String _output  = '';
  bool   _copied  = false;

  final Map<String, String> _modes = {
    'base64_enc':  'Base64 Encode',
    'base64_dec':  'Base64 Decode',
    'url_enc':     'URL Encode',
    'url_dec':     'URL Decode',
    'hex_enc':     'Text → HEX',
    'hex_dec':     'HEX → Text',
    'rev':         'Reverse Text',
    'bin':         'Text → Binary',
    'morse':       'Text → Morse',
  };

  static const Map<String, String> _morseMap = {
    'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..', 'E': '.', 'F': '..-.',
    'G': '--.', 'H': '....', 'I': '..', 'J': '.---', 'K': '-.-', 'L': '.-..',
    'M': '--', 'N': '-.', 'O': '---', 'P': '.--.', 'Q': '--.-', 'R': '.-.',
    'S': '...', 'T': '-', 'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-',
    'Y': '-.--', 'Z': '--..',
    '0': '-----', '1': '.----', '2': '..---', '3': '...--', '4': '....-',
    '5': '.....', '6': '-....', '7': '--...', '8': '---..', '9': '----.',
  };

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); _inputCtrl.dispose(); _outputCtrl.dispose(); super.dispose(); }

  void _process() {
    final input = _inputCtrl.text;
    if (input.isEmpty) { _out(''); return; }
    try {
      String result;
      switch (_mode) {
        case 'base64_enc': result = base64.encode(utf8.encode(input)); break;
        case 'base64_dec': result = utf8.decode(base64.decode(input)); break;
        case 'url_enc':    result = Uri.encodeComponent(input); break;
        case 'url_dec':    result = Uri.decodeComponent(input); break;
        case 'hex_enc':    result = input.codeUnits.map((c) => c.toRadixString(16).padLeft(2, '0')).join(' '); break;
        case 'hex_dec':    result = String.fromCharCodes(input.trim().split(RegExp(r'\s+')).map((h) => int.parse(h, radix: 16))); break;
        case 'rev':        result = input.split('').reversed.join(''); break;
        case 'bin':        result = input.codeUnits.map((c) => c.toRadixString(2).padLeft(8, '0')).join(' '); break;
        case 'morse':      result = input.toUpperCase().split('').map((c) => c == ' ' ? '/' : (_morseMap[c] ?? '?')).join(' '); break;
        default:           result = input;
      }
      _out(result);
    } catch (e) { _out('❌ Error: $e'); }
  }

  void _out(String v) { setState(() { _output = v; _outputCtrl.text = v; }); }

  void _copy() {
    if (_output.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _output));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _copied = false); });
  }

  void _swap() {
    if (_output.isEmpty) return;
    setState(() { _inputCtrl.text = _output; _output = ''; _outputCtrl.text = ''; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DV.bg0,
    body: Container(
      decoration: BoxDecoration(gradient: DV.bgGradient),
      child: SafeArea(child: Column(children: [
        // header
        Padding(padding: const EdgeInsets.all(18), child: Row(children: [
          GestureDetector(onTap: () => Navigator.pop(context),
            child: Container(padding: const EdgeInsets.all(8), decoration: DV.card(r: 10),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: DV.orange, size: 18))),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(shaderCallback: (b) => DV.fireGradient.createShader(b),
              child: const Text('TEXT TOOLS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2, fontFamily: 'Orbitron'))),
            const Text('Encode • Decode • Transform', style: TextStyle(color: DV.textSecondary, fontSize: 11)),
          ]),
        ])),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // mode selector
            const Text('⚙️ PILIH MODE', style: TextStyle(color: DV.textOrange, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, fontFamily: 'Orbitron')),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: _modes.entries.map<Widget>((e) => GestureDetector(
              onTap: () { setState(() => _mode = e.key); _process(); },
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: _mode == e.key ? DV.fireGradient : null,
                  color: _mode == e.key ? null : DV.glassCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _mode == e.key ? DV.orange : DV.glassBorder),
                ),
                child: Text(e.value, style: TextStyle(color: _mode == e.key ? Colors.white : DV.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            )).toList()),

            const SizedBox(height: 18),

            // input
            const Text('📝 INPUT', style: TextStyle(color: DV.textOrange, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, fontFamily: 'Orbitron')),
            const SizedBox(height: 8),
            DVCard(padding: const EdgeInsets.all(4), child: TextField(
              controller: _inputCtrl,
              style: const TextStyle(color: DV.textPrimary, fontSize: 13, fontFamily: 'ShareTechMono'),
              maxLines: 5, minLines: 3,
              onChanged: (_) => _process(),
              decoration: const InputDecoration(
                hintText: 'Ketik teks di sini...',
                hintStyle: TextStyle(color: DV.textHint),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            )),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: DVButton(label: 'PROSES', icon: Icons.play_arrow_rounded, onTap: _process)),
              const SizedBox(width: 10),
              Expanded(child: DVButton(label: 'SWAP ⇅', outline: true, onTap: _swap)),
              const SizedBox(width: 10),
              Expanded(child: DVButton(label: 'HAPUS', outline: true, onTap: () { setState(() { _inputCtrl.clear(); _output = ''; _outputCtrl.text = ''; }); })),
            ]),

            const SizedBox(height: 18),

            // output
            const Text('📤 OUTPUT', style: TextStyle(color: DV.textOrange, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, fontFamily: 'Orbitron')),
            const SizedBox(height: 8),
            DVCard(padding: const EdgeInsets.all(4), glow: _output.isNotEmpty, child: TextField(
              controller: _outputCtrl,
              style: const TextStyle(color: DV.textPrimary, fontSize: 13, fontFamily: 'ShareTechMono'),
              maxLines: 5, minLines: 3, readOnly: true,
              decoration: const InputDecoration(
                hintText: 'Hasil akan muncul di sini...',
                hintStyle: TextStyle(color: DV.textHint),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            )),
            const SizedBox(height: 10),
            DVButton(
              label: _copied ? '✅ DISALIN!' : 'SALIN HASIL',
              icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
              onTap: _copy,
              outline: !_copied,
            ),
            const SizedBox(height: 24),

            // info card
            DVCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ℹ️ INFO MODE', style: TextStyle(color: DV.textOrange, fontSize: 10, letterSpacing: 1.5, fontFamily: 'Orbitron')),
              const SizedBox(height: 8),
              Text(_modeInfo(), style: const TextStyle(color: DV.textSecondary, fontSize: 12, height: 1.5)),
            ])),
            const SizedBox(height: 20),
          ]),
        )),
      ])),
    ),
  );

  String _modeInfo() => switch (_mode) {
    'base64_enc' => 'Mengkonversi teks menjadi format Base64. Berguna untuk encoding data biner ke ASCII.',
    'base64_dec' => 'Mendekode string Base64 kembali ke teks asli.',
    'url_enc'    => 'URL encoding untuk karakter spesial (spasi → %20, dll). Dipakai di URL/query string.',
    'url_dec'    => 'Mendekode URL-encoded string kembali ke teks biasa.',
    'hex_enc'    => 'Mengkonversi setiap karakter ke representasi hexadecimal-nya.',
    'hex_dec'    => 'Mengkonversi hex string kembali ke teks. Pisahkan hex dengan spasi.',
    'rev'        => 'Membalik urutan karakter dalam teks.',
    'bin'        => 'Mengkonversi setiap karakter ke 8-bit binary representation.',
    'morse'      => 'Mengkonversi teks ke kode Morse. Spasi antar kata ditandai dengan /.',
    _            => '',
  };
}
