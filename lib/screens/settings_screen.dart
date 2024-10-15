import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/background.dart';


class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextEditingController _activationKeyController = TextEditingController();
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
      _activationKeyController.text = savedKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final brightness = MediaQuery.of(context).platformBrightness;

    return Scaffold(
      appBar: AppBar(title: Text(localizations?.settingsTitle ?? 'Settings')),
    body: BackgroundLogo(
    logoPath: 'assets/images/Aegister.png',
    opacity: 0.5,
    blurStrength: 10.0,
    offsetX: 175.0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              brightness == Brightness.dark ? 'assets/images/Logo.png' : 'assets/images/Logo-black.png',
              height: 55,
            ),
            SizedBox(height: 20),

            TextField(
              controller: _activationKeyController,
              decoration: InputDecoration(
                labelText: localizations?.enterActivationKey ??
                    'Activation Key',
                errorText: error,
              ),
            ),
            SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2584BE),
                foregroundColor: Colors.white,
              ),
              child: Text(localizations?.submit ?? 'Submit'),
              onPressed: () async {
                String activationKey = _activationKeyController.text;
                if (activationKey.isNotEmpty) {
                  await fetchOvpnConfig(activationKey);
                } else {
                  setState(() {
                    error = localizations?.enterValidKey ?? 'Please enter a valid activation key.';
                  });
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Icon(
                Icons.delete_forever,
                color: Colors.red,
              ),
              onPressed: () async {
                bool confirm = await _showDeleteConfirmationDialog();
                if (confirm) {
                  await deleteVpnConfig();
                  _showConfirmationDialog(localizations?.vpnConfigDeleted ??
                      'VPN configuration deleted successfully.');
                }
              },
            ),
          ],
        ),
      ),
    )
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

        _showConfirmationDialog(AppLocalizations.of(context)?.vpnProfileAdded ?? 'VPN profile added successfully.');
      } else {
        setState(() {
          error = AppLocalizations.of(context)?.errorFetchingConfig ?? 'Invalid activation key or error fetching config.';
        });
      }
    } catch (e) {
      setState(() {
        error = AppLocalizations.of(context)?.errorOccurred ?? 'Error occurred: $e';
      });
    }
  }

  Future<void> deleteVpnConfig() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/vpn_config.ovpn');

      if (await file.exists()) {
        await file.delete();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('activation_key');
        setState(() {
          _activationKeyController.clear();
        });
      } else {
        _showConfirmationDialog(AppLocalizations.of(context)?.vpnConfigNotFound ?? 'No VPN configuration file found.');
      }
    } catch (e) {
      _showConfirmationDialog(AppLocalizations.of(context)?.errorOccurred ?? 'Error deleting VPN configuration: $e');
    }
  }

  Future<void> saveOvpnFile(String content) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/vpn_config.ovpn');
      await file.writeAsString(content);
    } catch (e) {
      _showConfirmationDialog(AppLocalizations.of(context)?.errorOccurred ?? 'Failed to save OVPN file: $e');
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    final localizations = AppLocalizations.of(context); // Get it again here
    return (await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations?.confirmDeletion ?? 'Confirm Deletion'),
          content: Text(localizations?.deleteVpnConfig ?? 'Are you sure you want to delete the current VPN configuration?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(localizations?.delete ?? 'Delete'),
            ),
          ],
        );
      },
    )) ?? false;
  }

  Future<void> _showConfirmationDialog(String message) async {
    final localizations = AppLocalizations.of(context); // Fetch localizations here

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations?.confirmation ?? 'Confirmation'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations?.ok ?? 'OK'),
            ),
          ],
        );
      },
    );
  }

}