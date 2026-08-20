// dv_theme.dart — DarkVerse v6.0 QUANTUM DARK EDITION
// Aesthetic: Cyberpunk meets quantum computing — void black, plasma neon, holographic chrome
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class DV {
  // ── Quantum Void Backgrounds ─────────────────────────────────────────────
  static const Color bg0 = Color(0xFF02000A); // absolute void
  static const Color bg1 = Color(0xFF07031A); // deep quantum
  static const Color bg2 = Color(0xFF0E0828); // elevated surface
  static const Color bg3 = Color(0xFF160D38); // highest surface
  static const Color bgCard = Color(0xFF0B0520); // card surface

  // ── Plasma Primary ────────────────────────────────────────────────────────
  static const Color plasma    = Color(0xFFB300FF); // quantum plasma
  static const Color plasmaLt  = Color(0xFFCC44FF); // light plasma
  static const Color plasmaDk  = Color(0xFF7700CC); // dark plasma
  static const Color ion       = Color(0xFF8800EE); // ion blue-violet

  // ── Holographic Accents ───────────────────────────────────────────────────
  static const Color holo      = Color(0xFF00FFEA); // holographic teal
  static const Color holoWarm  = Color(0xFFFF00FF); // magenta holo
  static const Color xray      = Color(0xFF4488FF); // x-ray blue
  static const Color acid      = Color(0xFF39FF14); // acid green

  // ── Neon Spectrum ─────────────────────────────────────────────────────────
  static const Color neonV     = Color(0xFFBF00FF); // neon violet
  static const Color neonM     = Color(0xFFFF00CC); // neon magenta
  static const Color neonC     = Color(0xFF00E5FF); // neon cyan
  static const Color neonG     = Color(0xFF00FF88); // neon green

  // ── Glass / Surface ───────────────────────────────────────────────────────
  static Color surface     = const Color(0xFFB300FF).withOpacity(0.05);
  static Color surfaceHi   = const Color(0xFFB300FF).withOpacity(0.12);
  static Color border      = Colors.white.withOpacity(0.06);
  static Color borderHi    = const Color(0xFFB300FF).withOpacity(0.45);
  static Color glow        = const Color(0xFFB300FF).withOpacity(0.35);
  static Color glowHolo    = const Color(0xFF00FFEA).withOpacity(0.25);
  static Color glowMag     = const Color(0xFFFF00FF).withOpacity(0.20);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF2ECFF); // quantum white
  static const Color textSecondary = Color(0xFF9977BB); // muted violet
  static const Color textHint      = Color(0xFF3A1F55); // deep hint
  static const Color textGlow      = Color(0xFFCC88FF); // glow text
  static const Color textHolo      = Color(0xFF80FFEE); // holo text

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00FF88);
  static const Color error   = Color(0xFFFF1155);
  static const Color warning = Color(0xFFFFBB00);
  static const Color info    = Color(0xFF44AAFF);

  // ── Compatibility aliases (keep all old refs working) ─────────────────────
  static const Color bg_    = bg0;
  static Color get glassCard   => surface;
  static Color get glassHover  => surfaceHi;
  static Color get glassBorder => border;
  static Color get purpleBorder => borderHi;
  static Color get purpleGlow   => glow;
  static Color get pinkGlow     => glowMag;
  static Color get blueGlow     => glowHolo;
  static Color get cyanGlow     => glowHolo;
  static Color get cyanBorder   => borderHi;
  static Color get tealGlow     => glowHolo;
  static Color get orangeBorder => borderHi;
  static Color get orangeGlow   => glow;
  static Color get emberGlow    => glowMag;
  static const Color purple      = plasma;
  static const Color purpleLight = plasmaLt;
  static const Color purpleDark  = plasmaDk;
  static const Color violet      = ion;
  static const Color pink        = neonM;
  static const Color neonGreen   = neonG;
  static const Color neonCyan    = neonC;
  static const Color neonPink    = neonM;
  static const Color cyan        = neonC;
  static const Color cyanLight   = Color(0xFF80FFFF);
  static const Color cyanDark    = Color(0xFF0099BB);
  static const Color cyanDeep    = Color(0xFF006688);
  static const Color teal        = neonG;
  static const Color textNeon    = textGlow;
  static const Color textCyan    = textHolo;
  static const Color orange      = plasma;
  static const Color orangeLight = plasmaLt;
  static const Color orangeDark  = plasmaDk;
  static const Color orangeEmber = ion;
  static const Color amber       = neonG;
  static const Color textOrange  = textGlow;

  // ── Gradients ─────────────────────────────────────────────────────────────
  static LinearGradient bgGradient = const LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF02000A), Color(0xFF07031A), Color(0xFF030010)],
    stops: [0.0, 0.5, 1.0],
  );

  // Quantum gradient — plasma to holo
  static const LinearGradient fireGradient = LinearGradient(
    colors: [Color(0xFF7700CC), Color(0xFFB300FF), Color(0xFF00FFEA)],
    begin: Alignment.centerLeft, end: Alignment.centerRight,
  );

  // Magenta gradient — hot
  static const LinearGradient hotGradient = LinearGradient(
    colors: [Color(0xFFB300FF), Color(0xFFFF00CC), Color(0xFFFF4488)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // Electric gradient — cold
  static const LinearGradient coldGradient = LinearGradient(
    colors: [Color(0xFF0044FF), Color(0xFF8800EE), Color(0xFFB300FF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // Holo gradient
  static const LinearGradient holoGradient = LinearGradient(
    colors: [Color(0xFF00FFEA), Color(0xFF4488FF), Color(0xFFB300FF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static LinearGradient cyanGradient = LinearGradient(
    colors: [neonC, neonG], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static LinearGradient amberGradient = LinearGradient(
    colors: [plasma.withOpacity(0.8), neonG], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const LinearGradient electricGradient = coldGradient;

  // ── Card helper ───────────────────────────────────────────────────────────
  static BoxDecoration card({double r = 20, bool glow = false, bool fire = false, bool holo = false}) => BoxDecoration(
    color: fire ? surfaceHi : surface,
    borderRadius: BorderRadius.circular(r),
    border: Border.all(
      color: holo ? glowHolo.withOpacity(0.5) : (fire ? borderHi : border),
      width: fire || holo ? 1.2 : 1.0),
    boxShadow: glow
        ? [BoxShadow(color: holo ? glowHolo : DV.glow, blurRadius: 36, offset: const Offset(0, 8), spreadRadius: -4)]
        : [BoxShadow(color: Colors.black.withOpacity(0.65), blurRadius: 18, offset: const Offset(0, 6))],
  );

  // ── Input helper ──────────────────────────────────────────────────────────
  static InputDecoration input({required String label, required IconData icon, Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: textSecondary, size: 20),
        suffixIcon: suffix,
        filled: true, fillColor: bgCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _ib(Colors.transparent),
        enabledBorder: _ib(border),
        focusedBorder: _ib(plasma, width: 1.5),
        errorBorder: _ib(error.withOpacity(0.6)),
        focusedErrorBorder: _ib(error, width: 1.5),
      );

  static OutlineInputBorder _ib(Color c, {double width = 1.0}) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: width));

  // ── Theme ─────────────────────────────────────────────────────────────────
  static ThemeData themeData() => ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'ShareTechMono',
    scaffoldBackgroundColor: bg0,
    colorScheme: const ColorScheme.dark().copyWith(primary: plasma, secondary: plasmaLt),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: textPrimary),
    drawerTheme: const DrawerThemeData(backgroundColor: bg0),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: bg0, selectedItemColor: plasma, unselectedItemColor: textHint),
  );
}

// ── DVCard ─────────────────────────────────────────────────────────────────────
class DVCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final bool glow, fire, holo;
  final EdgeInsets? padding;
  const DVCard({super.key, required this.child, this.radius = 18, this.glow = false, this.fire = false, this.holo = false, this.padding});
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: DV.card(r: radius, glow: glow, fire: fire, holo: holo),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: child),
    ),
  );
}

// ── DVButton ───────────────────────────────────────────────────────────────────
class DVButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading, outline, holo;
  const DVButton({super.key, required this.label, this.icon, this.onTap, this.isLoading = false, this.outline = false, this.holo = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 54,
      decoration: BoxDecoration(
        gradient: outline ? null : (holo ? DV.holoGradient : DV.fireGradient),
        color: outline ? DV.surface : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: holo ? DV.glowHolo : DV.borderHi),
        boxShadow: outline ? [] : [BoxShadow(color: holo ? DV.glowHolo : DV.glow, blurRadius: 22, offset: const Offset(0, 6))],
      ),
      child: Center(child: isLoading
        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: DV.plasmaLt))
        : Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8)],
            Text(label, style: TextStyle(
              color: outline ? DV.textGlow : Colors.white,
              fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 2, fontFamily: 'Orbitron')),
          ])),
    ),
  );
}

// ── DVDivider ──────────────────────────────────────────────────────────────────
class DVFireDivider extends StatelessWidget {
  final String? label;
  const DVFireDivider({super.key, this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Container(height: 1, decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Colors.transparent, DV.border, DV.borderHi.withOpacity(0.3)])))),
    if (label != null) ...[
      Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: DV.borderHi.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(20),
            color: DV.surface),
          child: Text(label!, style: const TextStyle(color: DV.textHint, fontSize: 10, letterSpacing: 2)))),
      Expanded(child: Container(height: 1, decoration: BoxDecoration(
        gradient: LinearGradient(colors: [DV.borderHi.withOpacity(0.3), DV.border, Colors.transparent])))),
    ],
  ]);
}

// ── Shared AppBar ──────────────────────────────────────────────────────────────
PreferredSizeWidget dvAppBar(BuildContext context, String title, {List<Widget>? actions}) => AppBar(
  backgroundColor: DV.bg0.withOpacity(0.92),
  elevation: 0,
  leading: Container(
    margin: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: DV.surface, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: DV.border)),
    child: IconButton(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.arrow_back_ios_rounded, color: DV.plasma, size: 18),
      onPressed: () => Navigator.pop(context))),
  title: ShaderMask(
    shaderCallback: (b) => DV.fireGradient.createShader(b),
    child: Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'Orbitron',
        fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 2))),
  centerTitle: true,
  actions: actions,
  flexibleSpace: Container(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: DV.borderHi.withOpacity(0.2))),
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [DV.bg0, DV.bg0.withOpacity(0)]))),
);
