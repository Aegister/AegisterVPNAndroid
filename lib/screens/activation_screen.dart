import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:AegisterVPN/models/background.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

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


  void _launchSignIn() async {
    final url = 'https://app.aegister.com/keycloak/realms/aegister/protocol/openid-connect/auth'
        '?client_id=AegisterVPN'
        '&redirect_uri=aegistervpn://callback'
        '&response_type=code'
        '&scope=openid%20email';

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'aegistervpn',
      );



      final Uri uri = Uri.parse(result);
      final code = uri.queryParameters['code'];

      if (code != null) {
        await _getTokens(code);
      } else {
        print("No authorization code received.");
        setState(() {
          error = "No authorization code received.";
        });
      }
    } catch (e) {
      print("Login was canceled or failed: $e");
      setState(() {
        error = "Login was canceled or failed. Please try again.";
      });
    }
  }


  Future<void> _getTokens(String authorizationCode) async {
    final response = await http.post(
      Uri.parse(
          'https://app.aegister.com/keycloak/realms/aegister/protocol/openid-connect/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': authorizationCode,
        'redirect_uri': 'aegistervpn://callback',
        'client_id': 'AegisterVPN',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String accessToken = data['access_token'];
      _getUserInfo(accessToken);
    } else {
      print('Failed to exchange authorization code for tokens');
    }
  }

  Future<void> _getUserInfo(String accessToken) async {
    final response = await http.get(
      Uri.parse(
          'https://app.aegister.com/keycloak/realms/aegister/protocol/openid-connect/userinfo'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final userInfo = jsonDecode(response.body);
      String userEmail = userInfo['email'];
      print('User email: $userEmail');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', userEmail);

      await sendEmailToApi(context, userEmail);

    } else {
      print('Failed to fetch user info');
    }
  }

  Future<void> sendEmailToApi(BuildContext context, String email) async {
    final localizations = AppLocalizations.of(context);

    final response = await http.get(
      Uri.parse('https://app.aegister.com/api/v1/vpn?email=$email&include_cert=true'),
      headers: {'X-Aegister-Token': ''},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      if (responseData['error'] == 0 && responseData['data'].isNotEmpty) {
        final vpnData = responseData['data'][0];
        final vpnCertContent = vpnData['cert'];

        print('VPN Certificate Content: $vpnCertContent');

        await _useVpnCertificate(vpnCertContent);

      } else {
        print(localizations?.noVpnProfiles ?? 'No VPN profiles found for this email.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations?.noVpnProfiles ?? 'No VPN profiles found for this email.')),
        );
      }
    } else {
      print(localizations?.fetchVpnFailed ?? 'Failed to fetch VPN profiles.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.fetchVpnFailed ?? 'Failed to fetch VPN profiles.')),
      );
    }
  }

  Future<void> _useVpnCertificate(String vpnCertContent) async {
    try {
      // Save the certificate content as an OVPN file
      await saveOvpnFile(vpnCertContent);

      // Optionally, store an indicator in SharedPreferences if needed
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vpn_cert_saved', true);

      Navigator.of(context).pushReplacementNamed('/main');
      print('VPN configured successfully.');
    } catch (e) {
      print('Error configuring VPN with certificate content: $e');
      setState(() {
        error = 'Error configuring VPN. Please try again.';
        isFetching = false;
      });
    }
  }

  Future<void> checkForExistingKey() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File file = File('${appDocDir.path}/vpn_config.ovpn');

      // Check if the file exists
      if (await file.exists()) {
        // If the file exists, navigate to the main screen
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      print('Error checking for VPN profile: $e');
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
          duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    } else {
      String activationKey = _activationKeyController.text;
      if (activationKey.isNotEmpty) {
        setState(() {
          isFetching = true;
          error = null;
        });
        fetchOvpnConfig(activationKey);
      } else {
        setState(() {
          isFetching = false;
          error = AppLocalizations.of(context)?.enterValidKey ??
              'Please enter a valid activation key.';
        });
      }
    }
  }

  Widget _buildPage(
      {required String title,
      required String content,
      required String buttonText}) {
    final brightness = MediaQuery.of(context).platformBrightness;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            brightness == Brightness.dark
                ? 'assets/images/Logo.png'
                : 'assets/images/Logo-black.png',
            height: 55,
          ),
          SizedBox(height: 20),
          Text(title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          SizedBox(height: 20),
          Text(content,
              style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
          SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2584BE),
              foregroundColor: Colors.white,
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
          if (isFetching) CircularProgressIndicator(),
          if (!isFetching)
            TextField(
              controller: _activationKeyController,
              decoration: InputDecoration(
                labelText:
                    localizations?.enterActivationKey ?? 'Activation Key',
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
          SizedBox(height: 20),
          if (!isFetching)
            Row(
              children: [
                Expanded(
                  child: Divider(
                    thickness: 1,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black, // Change divider color based on theme
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    localizations?.or ?? 'or',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black, // Change text color based on theme
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    thickness: 1,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black, // Change divider color based on theme
                  ),
                ),
              ],
            ),
          SizedBox(height: 20),
          if (!isFetching)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: ElevatedButton(
                onPressed: _launchSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2584BE),
                  foregroundColor: Colors.white,
                ),
                child: Text(localizations?.signIn ?? 'Sign In'),
              ),
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
          error = AppLocalizations.of(context)?.errorFetchingConfig ??
              'Invalid activation key or error fetching config.';
          isFetching = false;
        });
      }
    } catch (e) {
      setState(() {
        error = AppLocalizations.of(context)?.errorFetchingConfig ??
            'Error fetching configuration file.';
        isFetching = false;
      });
    }
  }


  Future<void> saveOvpnFile(String content) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File file = File('${appDocDir.path}/vpn_config.ovpn');
      await file.writeAsString(content);
      print('OVPN file saved successfully.');
    } catch (e) {
      print('Failed to save OVPN file: $e');
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      body: BackgroundLogo(
        logoPath: 'assets/images/Aegister.png',
        opacity: 0.5,
        blurStrength: 10.0,
        offsetX: 175.0,
        child: Column(
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
                    content: localizations?.activationKeyInstructions ?? "Visit our platform app.aegister.com to obtain your activation key.",
                    buttonText: localizations?.next ?? 'Next',
                  ),
                  _buildActivationPage(localizations),
                ],
              ),
            ),
            _buildNavigation()
          ],
        ),
      ),
    );
  }
}
