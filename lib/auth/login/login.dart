import 'dart:async';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:rastreogt/auth/auth_service.dart';
import 'package:rastreogt/auth/login/logingoogle.dart';
import 'package:rastreogt/auth/password/resetpassword.dart';
import 'package:rastreogt/auth/signup/signup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final GoogleAuthService _googleAuthService = GoogleAuthService();
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isPrivacyPolicyAccepted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _checkPrivacyPolicyAccepted();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      debugPrint('Couldn\'t check connectivity status: $e');
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    setState(() {
      _connectionStatus = result;
    });
    if (_connectionStatus.contains(ConnectivityResult.none)) {
      showErrorDialog(context,
          "No hay conexión a internet. Por favor, verifica tu conexión e inténtalo de nuevo.");
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _showLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  void _hideLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkPrivacyPolicyAccepted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isAccepted = prefs.getBool('privacyPolicyAccepted');
    if (isAccepted == null || !isAccepted) {
      _showPrivacyPolicyDialog();
    } else {
      setState(() {
        _isPrivacyPolicyAccepted = true;
      });
    }
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool isChecked = false;

        return PopScope(
          canPop: false, // Deshabilitar el botón de retroceso
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  'Política de Privacidad',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Lottie.asset(
                        'assets/lotties/politi.json', // Asegúrate de tener este archivo en tu carpeta de assets
                        width: 150,
                        height: 150,
                        animate: true,
                        repeat: false,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Por favor, lee nuestra política de privacidad en el siguiente enlace:',
                        style: GoogleFonts.poppins(),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Abre la política de privacidad en el navegador
                          launchUrl(Uri(
                            scheme: 'https',
                            host: 'rastreogt.com',
                            path: '/politicas.html',
                          ));
                        },
                        child: const Text(
                          'Política de Privacidad',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: <Widget>[
                          Checkbox(
                            value: isChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                isChecked = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              'He leído y acepto la política de privacidad.',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: isChecked
                        ? () async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            await prefs.setBool('privacyPolicyAccepted', true);
                            setState(() {
                              _isPrivacyPolicyAccepted = true;
                            });
                            Navigator.of(context).pop();
                          }
                        : null,
                    child: Text(
                      'Aceptar',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 20,
      ),
      body: Stack(
        children: [
          // Background color based on image blue
          Container(
            color:
                const Color(0xFF141C2E), // A blue color similar to your image
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  // Replacing the icon with your image
                  SizedBox(
                    height: 120, // Adjust the height if necessary
                    child: Image.asset(
                      'assets/images/oficial2.png', // Path to your image
                      fit: BoxFit.contain, // Make sure it fits nicely
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Bienvenido de Nuevo!',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        color: Colors
                            .white, // Changed to white for better contrast
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  _buildTextField(
                    'Email',
                    _emailController,
                    false,
                    Icon(Icons.email,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black // Change to white for consistency
                        ),
                    TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    'Password',
                    _passwordController,
                    true,
                    Icon(Icons.lock_outline,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black),
                    TextInputType.visiblePassword,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RecuperarContrasenaScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Olvidaste tu contraseña?',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            color: Colors.white, // Text in white for contrast
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _signin(context),
                  const SizedBox(height: 20),
                  const Text(
                    'O inicia sesión con',
                    style: TextStyle(
                      color: Colors.white, // Change text to white
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () async {
                          _showLoading();
                          await _googleAuthService.signInWithGoogle(context);
                          _hideLoading();
                        },
                        icon: SizedBox(
                          width: 60, // Adjust width of icon
                          height: 60, // Adjust height of icon
                          child: Image.asset('assets/images/google.png'),
                        ),
                        iconSize: 20, // Adjust icon size
                      ),
                    ],
                  ),
                  const SizedBox(height: 90),
                  _signup(context),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Stack(
              children: <Widget>[
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: Lottie.asset(
                          'assets/lotties/loading.json',
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _signin(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(double.infinity, 50),
        elevation: 0,
      ),
      onPressed: () async {
        _showLoading();
        await AuthService().signin(
          email: _emailController.text,
          password: _passwordController.text,
          context: context,
        );
        _hideLoading();
      },
      child: Text(
        "Ingresar",
        style: GoogleFonts.poppins(
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _signup(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            const TextSpan(
              text: "No estas registrado? ",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.normal,
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: "Registrate aqui",
              style: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Signup(),
                    ),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      bool obscureText, Icon ico, TextInputType keyboardType) {
    return TextField(
      keyboardType: keyboardType,
      controller: controller,
      obscureText: obscureText,
      //style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        prefixIcon: ico,
        labelText: label,
        labelStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black),
        filled: true,
        // fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
