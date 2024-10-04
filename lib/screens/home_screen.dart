import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/vpn_config.dart';
import '../models/vpn_status.dart';
import '../services/vpn_engine.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _vpnState = VpnEngine.vpnDisconnected;
  VpnConfig? _vpnConfig;

  @override
  void initState() {
    super.initState();

    VpnEngine.vpnStageSnapshot().listen((event) {
      setState(() => _vpnState = event);
    });

    initVpn();
  }

  void initVpn() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/vpn_config.ovpn');

      if (await file.exists()) {
        _vpnConfig = VpnConfig(
          config: await file.readAsString(),
          country: '',
          username: '',
          password: '',
        );

        SchedulerBinding.instance.addPostFrameCallback((_) {
          setState(() {});
        });
      } else {
        print("VPN config file not found.");
      }
    } catch (e) {
      print("Error loading VPN config: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Localization error')),
        body: Center(child: Text('Localization error')),
      );
    }

    final brightness = MediaQuery.of(context).platformBrightness;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.appTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add the logo image based on the brightness (dark/light mode)
              Image.asset(
                brightness == Brightness.dark ? 'assets/images/Logo.png' : 'assets/images/Logo-black.png',
                height: 55,
              ),
              SizedBox(height: 20),

              TextButton(
                style: TextButton.styleFrom(
                  shape: StadiumBorder(),
                  backgroundColor: Color(0xFF2584BE),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _vpnState == VpnEngine.vpnDisconnected
                      ? localizations.connectVpn
                      : _vpnState.replaceAll("_", " ").toUpperCase(),
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _connectClick,
              ),
              SizedBox(height: 20),

              // VPN status
              StreamBuilder<VpnStatus?>(
                initialData: VpnStatus(),
                stream: VpnEngine.vpnStatusSnapshot(),
                builder: (context, snapshot) =>
                    Text(
                      "${localizations.byteIn}: ${snapshot.data?.byteIn ?? ""}, ${localizations.byteOut}: ${snapshot.data?.byteOut ?? ""}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _connectClick() {
    if (_vpnConfig == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.vpnConfigNotFound ?? 'VPN configuration not found')),
      );
      return;
    }
    if (_vpnState == VpnEngine.vpnDisconnected) {
      VpnEngine.startVpn(_vpnConfig!);
    } else {
      VpnEngine.stopVpn();
    }
  }
}