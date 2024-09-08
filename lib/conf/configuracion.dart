import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:rastreogt/providers/themenoti.dart';

class ConfiguracionAll extends StatelessWidget {
  const ConfiguracionAll({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: themeNotifier.currentTheme.brightness == Brightness.dark
                    ? [const Color.fromARGB(255, 23, 41, 72), Colors.blueGrey]
                    : [const Color.fromARGB(255, 114, 130, 255), Colors.white],
                begin: Alignment.centerLeft,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ListTile(
                    leading: Icon(
                      themeNotifier.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                      color: themeNotifier.isDarkMode ? Colors.yellow : Colors.yellowAccent,
                    ),
                    title: const Text('Cambiar Tema'),
                    trailing: Switch(
                      value: themeNotifier.isDarkMode,
                      onChanged: (value) {
                        themeNotifier.toggleTheme();
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(builder: (context) => SecondScreen()),
                      // );
                    },
                    child: const Text('Ir a otra pantalla'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}