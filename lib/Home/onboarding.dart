import 'package:rastreogt/conf/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<Widget> _buildPages() {
    return [
      _buildPage(
        title: "Bienvenido",
        description:
            "En la aplicación de Rastreo GT, puedes hacer muchas cosas.",
        lottiePath: "assets/lotties/rider1.json",
      ),
      _buildPage(
        title: "Explora",
        description:
            "Desde rastrear tus envíos hasta ver el historial de tus pedidos.",
        lottiePath: "assets/lotties/rider2.json",
      ),
      _buildPage(
        title: "Emprendimiento",
        description:
            "Si tienes un negocio, puedes rastrear tus pedidos y ver el historial de tus envíos. y mas.",
        lottiePath: "assets/lotties/rider3.json",
      ),
    ];
  }

  Widget _buildPage(
      {required String title,
      required String description,
      required String lottiePath}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(lottiePath),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: _buildPages(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _buildPages().length,
              (index) => _buildDot(index: index),
            ),
          ),
          const SizedBox(height: 20),
          _currentPage == _buildPages().length - 1
              ? ElevatedButton(
                  onPressed: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setBool('seenOnboarding', true);
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: const Text("Empezar"),
                )
              : TextButton(
                  onPressed: () {
                    _pageController.jumpToPage(_buildPages().length - 1);
                  },
                  child: const Text("Saltar"),
                ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDot({required int index}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 10,
      width: 10,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.blue : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}
