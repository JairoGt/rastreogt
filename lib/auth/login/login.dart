import 'dart:async';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:rastreogt/auth/auth_service.dart';
import 'package:rastreogt/auth/login/logingoogle.dart';
import 'package:rastreogt/auth/password/resetpassword.dart';
import 'package:rastreogt/auth/signup/signup.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initConnectivity();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: _signup(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 20,
      ),
      body: Stack(
        children: [
          Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.grey[400]),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  const Icon(
                    EvaIcons.personOutline,
                    size: 100,
                    // color: Colors.black,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Bienvenido de Nuevo!',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        //color: Colors.black,
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
                      const Icon(Icons.email, color: Colors.grey),
                      TextInputType.emailAddress),
                  const SizedBox(height: 20),
                  _buildTextField(
                      'Password',
                      _passwordController,
                      true,
                      const Icon(Icons.lock_outline, color: Colors.grey),
                      TextInputType.visiblePassword),
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
                            textStyle: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color.fromARGB(255, 136, 133, 133)
                                  : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )),
                  const SizedBox(height: 30),
                  _signin(context),
                  const SizedBox(height: 20),
                  Text(
                    'O inicia sesión con',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color.fromARGB(255, 136, 133, 133)
                          : Colors.black,
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
                          width: 60, // Ajusta el ancho del icono
                          height: 60, // Ajusta la altura del icono
                          child: Image.asset('assets/images/google.png'),
                        ),
                        iconSize: 20, // Ajusta el tamaño del icono
                      ),
                    ],
                  ),
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color.fromARGB(155, 0, 0, 0).withOpacity(0.5)
                          : const Color.fromARGB(255, 255, 255, 255)
                              .withOpacity(0.5),
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
