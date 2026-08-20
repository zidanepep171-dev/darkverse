// main.dart — DarkVerse v4.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dv_theme.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'owner_page.dart';
import 'landing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: DV.bg0,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const DarkVerseApp());
}

class DarkVerseApp extends StatelessWidget {
  const DarkVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DarkVerse',
      theme: DV.themeData(),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _route(const LandingPage());
          case '/login':
            return _route(const LoginPage());
          case '/dashboard':
            final a = settings.arguments as Map<String, dynamic>;
            return _route(DashboardPage(
              username: a['username'], password: a['password'], role: a['role'],
              sessionKey: a['key'], expiredDate: a['expiredDate'],
              listBug:  List<Map<String, dynamic>>.from(a['listBug']  ?? []),
              listDoos: List<Map<String, dynamic>>.from(a['listDoos'] ?? []),
              news:     List<dynamic>.from(a['news'] ?? []),
            ));
          case '/home':
            final a = settings.arguments as Map<String, dynamic>;
            return _route(HomePage(
              username: a['username'], password: a['password'], role: a['role'],
              expiredDate: a['expiredDate'], sessionKey: a['sessionKey'],
              listBug: List<Map<String, dynamic>>.from(a['listBug'] ?? []),
            ));
          case '/seller':
            final a = settings.arguments as Map<String, dynamic>;
            return _route(SellerPage(keyToken: a['keyToken']));
          case '/admin':
            final a = settings.arguments as Map<String, dynamic>;
            return _route(AdminPage(sessionKey: a['sessionKey']));
          case '/owner':
            final a = settings.arguments as Map<String, dynamic>;
            return _route(OwnerPage(sessionKey: a['sessionKey'], username: a['username']));
          default:
            return _route(Scaffold(
              backgroundColor: DV.bg0,
              body: Center(child: Text('404 — Not Found', style: TextStyle(color: DV.textSecondary))),
            ));
        }
      },
    );
  }

  MaterialPageRoute _route(Widget page) => MaterialPageRoute(builder: (_) => page);
}
