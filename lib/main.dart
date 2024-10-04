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

      // Define light theme
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSwatch(
          accentColor: Color(0xFF2584BE),
          brightness: Brightness.light,
        ),
      ),

      // Define dark theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSwatch(
          accentColor: Color(0xFF2584BE),
          brightness: Brightness.dark,
        ),
      ),

      // Set themeMode to system
      themeMode: ThemeMode.system,

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
          title: Text(""),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.vpn_key), text: AppLocalizations.of(context)?.connect ?? "Connect"),
              Tab(icon: Icon(Icons.settings), text: AppLocalizations.of(context)?.settingsTitle ?? "Settings"),            ],
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
