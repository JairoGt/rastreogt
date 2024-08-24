import '../Cliente/sol_nego.dart';
import 'export.dart';

class ConfiguracionAdmin extends StatelessWidget {
  const ConfiguracionAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          Lottie.asset(
            'assets/lotties/estelas.json',
            fit: BoxFit.cover,
            animate: true,
            repeat: false,
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
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
                ListTile(
                  leading: const Icon(Icons.business),
                  title: const Text('Solicitar negocio'),
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
        ],
      ),
    );
  }
}