// contact_page.dart — DarkVerse v4.0 CYAN GLASS
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dv_theme.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _launch(String url) async =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DV.bg0,
    appBar: dvAppBar(context, 'CUSTOMER SERVICE'),
    body: Container(
      decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [DV.bg0, DV.cyan.withOpacity(0.06), DV.bg0])),
      child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: DV.fireGradient, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: DV.cyanGlow, blurRadius: 24)]),
            child: const Icon(Icons.support_agent_rounded, size: 36, color: Colors.white)),
          const SizedBox(height: 18),
          ShaderMask(shaderCallback: (b) => DV.fireGradient.createShader(b),
            child: const Text('Need Help?', style: TextStyle(color: Colors.white, fontSize: 24,
                fontWeight: FontWeight.bold, fontFamily: 'Orbitron'))),
          const SizedBox(height: 8),
          const Text('Contact us through our platforms below.', textAlign: TextAlign.center,
            style: TextStyle(color: DV.textSecondary, fontSize: 13)),
          const SizedBox(height: 36),
          _btn(FontAwesomeIcons.telegram,  'Telegram',  Colors.blue,       'https://t.me/Darkness_Reals1'),
          const SizedBox(height: 14),
          _btn(FontAwesomeIcons.whatsapp,  'WhatsApp',  const Color(0xFF25D366), 'https://wa.me/6283165770011'),
          const SizedBox(height: 14),
          _btn(FontAwesomeIcons.tiktok,    'TikTok',    Colors.white,      'https://www.tiktok.com/@painloggg'),
          const SizedBox(height: 14),
          _btn(FontAwesomeIcons.instagram, 'Instagram', Colors.pinkAccent, 'https://www.instagram.com/darkness_reals'),
        ]),
      )),
    ),
  );

  Widget _btn(IconData icon, String label, Color color, String url) => Builder(
    builder: (ctx) => GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: DV.glassCard, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DV.glassBorder),
            boxShadow: [BoxShadow(color: DV.cyanGlow.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: FaIcon(icon, color: color, size: 22)),
              const SizedBox(width: 18),
              Text(label, style: const TextStyle(color: DV.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
            const Icon(Icons.arrow_forward_ios, color: DV.textHint, size: 14),
          ])))));
}
