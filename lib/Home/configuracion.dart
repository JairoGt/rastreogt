
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:rastreogt/providers/themeNoti.dart';

class ConfiguracionAll extends StatelessWidget {
  const ConfiguracionAll({super.key});

  @override
  Widget build(BuildContext context) {
     final themeNotifier = Provider.of<ThemeNotifier>(context);
 return Scaffold(
  extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
         Switch(
            value: Provider.of<ThemeNotifier>(context).isDarkMode,
            onChanged: (value) {
              Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
           Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themeNotifier.currentTheme.brightness == Brightness.dark
                      ? [const Color.fromARGB(255, 95, 107, 143), const Color.fromARGB(255, 171, 170, 197)]
                      :
                  [const Color.fromARGB(255, 114, 130, 255), Colors.white],
                  begin: Alignment.centerLeft,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          Lottie.asset(
            'assets/lotties/estelas.json',
            fit: BoxFit.fitHeight,
            options: LottieOptions(
             
            ),
            animate: true,
            repeat: false,
          ),
          SafeArea(
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => SecondScreen()),
                  // );
                },
                child: const Text('Ir a otra pantalla'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}