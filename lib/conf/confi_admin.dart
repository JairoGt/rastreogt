import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rastreogt/providers/themenoti.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Cliente/sol_nego.dart';

class ConfiguracionAdmin extends StatefulWidget {
  const ConfiguracionAdmin({super.key});

  @override
  State<ConfiguracionAdmin> createState() => _ConfiguracionAdminState();
}

class _ConfiguracionAdminState extends State<ConfiguracionAdmin> {
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Configuración',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: themeNotifier.currentTheme.brightness == Brightness.dark
                    ? [const Color(0xFF172948), const Color(0xFF121E37)]
                    : [const Color(0xFF8EAAFF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: ListTile(
                        leading: Icon(
                          themeNotifier.isDarkMode
                              ? Icons.nightlight_round
                              : Icons.wb_sunny_outlined,
                          color: themeNotifier.isDarkMode
                              ? Colors.yellowAccent
                              : Colors.orangeAccent,
                          size: 28,
                        ),
                        title: const Text(
                          'Cambiar Tema',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Switch(
                          value: themeNotifier.isDarkMode,
                          onChanged: (value) {
                            themeNotifier.toggleTheme();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: ListTile(
                        leading: const Icon(Icons.business,
                            size: 28, color: Colors.blueAccent),
                        title: const Text(
                          'Solicitar negocio',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyHomePage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Desbloqueo con huellas'),
                              value: _isBiometricEnabled,
                              onChanged: (bool value) {
                                _setBiometricPreference(value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => SecondScreen()),
                          // );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Ir a otra pantalla',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadBiometricPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBiometricEnabled = prefs.getBool('biometricEnabled') ?? false;
    });
  }

  Future<void> _setBiometricPreference(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometricEnabled', value);
    setState(() {
      _isBiometricEnabled = value;
    });
  }
}
