import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ActivationScreen extends StatefulWidget {
  @override
  _ActivationScreenState createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  TextEditingController _activationKeyController = TextEditingController();
  bool isFetching = false;
  String? error;

  @override
  void initState() {
    super.initState();
    checkForExistingKey();
  }

  Future<void> checkForExistingKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedKey = prefs.getString('activation_key');
    if (savedKey != null) {
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    } else {
      // Last page logic
      String activationKey = _activationKeyController.text;
      if (activationKey.isNotEmpty) {
        setState(() {
          isFetching = true;
          error = null;
        });
        fetchOvpnConfig(activationKey);
      } else {
        setState(() {
          error = AppLocalizations.of(context)?.enterValidKey ?? 'Please enter a valid activation key.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildPage(
                  title: localizations?.welcome ?? 'Welcome!',
                  content: localizations?.welcomeMessage ?? "Your secure connection to the internet.",
                  buttonText: localizations?.next ?? 'Next',
                ),
                _buildPage(
                  title: localizations?.getYourActivationKey ?? 'Get Your Activation Key',
                  content: localizations?.activationKeyInstructions ?? "Visit our platform app.aegister.com to obtain your activation key." ,
                  buttonText: localizations?.next ?? 'Next',
                ),
                _buildActivationPage(localizations),
              ],
            ),
          ),
          _buildNavigation()
        ],
      ),
    );
  }

  Widget _buildPage({required String title, required String content, required String buttonText}) {
    // Get the current brightness (light or dark mode)
    final brightness = MediaQuery.of(context).platformBrightness;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Add image based on the brightness
          Image.asset(
            brightness == Brightness.dark ? 'assets/images/Logo.png' : 'assets/images/Logo-black.png',
            height: 55,
          ),
          SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            content,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2584BE), // Accent color for the background
              foregroundColor: Colors.white, // White text color
            ),
            child: Text(buttonText),
            onPressed: _nextPage,
          ),
        ],
      ),
    );
  }

  Widget _buildActivationPage(AppLocalizations? localizations) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isFetching)
            CircularProgressIndicator(),
          if (!isFetching)
            TextField(
              controller: _activationKeyController,
              decoration: InputDecoration(
                labelText: localizations?.enterActivationKey ?? 'Activation Key',
                errorText: error,
              ),
            ),
          SizedBox(height: 20),
          if (!isFetching)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2584BE),
                foregroundColor: Colors.white,
              ),
              child: Text(localizations?.submit ?? 'Submit'),
              onPressed: _nextPage,
            ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) => _buildDot(index)),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index ? Colors.blue : Colors.grey,
      ),
    );
  }

  Future<void> fetchOvpnConfig(String activationKey) async {
    try {
      final response = await http.get(
        Uri.parse('https://app.onefirewall.com/api/v1/vpn/cert/$activationKey'),
      );

      if (response.statusCode == 200) {
        final ovpnFileContent = response.body;
        await saveOvpnFile(ovpnFileContent);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('activation_key', activationKey);

        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        setState(() {
          error = AppLocalizations.of(context)?.errorFetchingConfig ?? 'Invalid activation key or error fetching config.';
          isFetching = false;
        });
      }
    } catch (e) {
      setState(() {
        error = AppLocalizations.of(context)?.errorOccurred ?? 'Error occurred: $e';
        isFetching = false;
      });
    }
  }

  Future<void> saveOvpnFile(String content) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/vpn_config.ovpn');
      await file.writeAsString(content);
    } catch (e) {
      print("Failed to save OVPN file: $e");
    }
  }
}