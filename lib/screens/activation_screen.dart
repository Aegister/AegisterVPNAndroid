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
    } else {
      // Handle the case where the key is null, if necessary
      setState(() {
        // Optionally update the UI to show that no key was found
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations?.activateVpn ?? 'Activate VPN')),
      body: Padding(
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
                  labelText: localizations?.enterActivationKey ??
                      'Activation Key',
                  errorText: error,
                ),
              ),
            SizedBox(height: 20),
            if (!isFetching)
              ElevatedButton(
                child: Text(localizations?.submit ?? 'Submit'),
                onPressed: () async {
                  String activationKey = _activationKeyController.text;
                  if (activationKey.isNotEmpty) {
                    setState(() {
                      isFetching = true;
                      error = null;
                    });
                    await fetchOvpnConfig(activationKey);
                  } else {
                    setState(() {
                      error = localizations?.enterValidKey ??
                          'Please enter a valid activation key.';
                    });
                  }
                },
              ),
          ],
        ),
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
