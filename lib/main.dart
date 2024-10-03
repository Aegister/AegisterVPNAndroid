import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/activation_screen.dart';
import 'screens/settings_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? activationKey = await getStoredActivationKey();
  runApp(MyApp(activationKey: activationKey));
}

class MyApp extends StatelessWidget {
  final String? activationKey;

  const MyApp({Key? key, this.activationKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AegisterVPN',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Color(0xFF2C4D75)),
      ),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', ''),
        const Locale('it', ''),
      ],
      initialRoute: activationKey == null ? '/activation' : '/main',
      routes: {
        '/activation': (context) => ActivationScreen(),
        '/main': (context) => MainTabController(),
      },
      onGenerateRoute: (settings) {
        // Handle unknown routes
        if (settings.name == '/settings') {
          return MaterialPageRoute(builder: (context) => SettingsScreen());
        }
        return null;
      },
    );
  }
}

Future<String?> getStoredActivationKey() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('activation_key');
}

class MainTabController extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Image.asset(
            'assets/images/Logo.png',
            height: 40,
          ),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.vpn_key), text: "Connect"),
              Tab(icon: Icon(Icons.settings), text: "Settings"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            HomeScreen(),
            SettingsScreen(),
          ],
        ),
      ),
    );
  }
}