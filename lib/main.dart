import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/activation_screen.dart';
import 'screens/settings_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

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
          title: Text("AegisterVPN"),
          actions: [
            IconButton(
              icon: Icon(Icons.help_outline),
              onPressed: () {
                _showContactDialog(context);
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.vpn_key), text: AppLocalizations.of(context)?.connect ?? "Connect"),
              Tab(icon: Icon(Icons.settings), text: AppLocalizations.of(context)?.settingsTitle ?? "Settings"),
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

  // Function to show the contact dialog
  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Need Help?'),
          content: Text('If you need assistance, contact us at info@aegister.com'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Contact Us'),
              onPressed: () {
                _launchEmail();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to launch the email
  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'info@aegister.com',
      query: 'subject=Help Needed&body=Please describe your issue here.',
    );
    try {
      await launch(emailLaunchUri.toString());
    } catch (e) {
      // Handle error if email app is not available
    }
  }
}
