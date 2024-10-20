import 'dart:async';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rastreogt/auth/auth_service.dart';
import 'package:rastreogt/auth/login/logingoogle.dart';
import 'package:rastreogt/auth/password/resetpassword.dart';
import 'package:rastreogt/auth/signup/signup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../conf/export.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final GoogleAuthService _googleAuthService = GoogleAuthService();
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  // ignore: unused_field
  bool _isPrivacyPolicyAccepted = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late FirebaseRemoteConfig _remoteConfig;

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _checkPrivacyPolicyAccepted();
    _initializeRemoteConfig();
    _checkLocationPermission();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  Future<void> _initializeRemoteConfig() async {
    _remoteConfig = FirebaseRemoteConfig.instance;
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval:
          Duration.zero, // Permite obtener valores inmediatamente
    ));
    await _remoteConfig.setDefaults({
      "latest_version": "1.0.0",
      "force_update": false,
    });
    await _remoteConfig.fetchAndActivate();
    _checkAppVersion();
  }

  Future<void> _checkAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;
    String latestVersion = _remoteConfig.getString('latest_version');
    bool forceUpdate = _remoteConfig.getBool('force_update');

    if (_isVersionGreaterThan(latestVersion, currentVersion)) {
      _showUpdateDialog(forceUpdate);
    } else {}
  }

  bool _isVersionGreaterThan(String v1, String v2) {
    List<int> v1Parts = v1.split('.').map(int.parse).toList();
    List<int> v2Parts = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < v1Parts.length && i < v2Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) {
        return true;
      } else if (v1Parts[i] < v2Parts[i]) {
        return false;
      }
    }

    return v1Parts.length > v2Parts.length;
  }

  void _showUpdateDialog(bool forceUpdate) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Actualización disponible',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text(
            forceUpdate
                ? 'Es necesario actualizar la aplicación para continuar.'
                : 'Hay una nueva versión de la aplicación disponible. ¿Deseas actualizar ahora?',
            style: GoogleFonts.poppins(),
          ),
          actions: <Widget>[
            if (!forceUpdate)
              TextButton(
                child: Text('Más tarde',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.normal)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            TextButton(
              child: Text('Actualizar',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              onPressed: () {
                // Aquí deberías abrir la tienda de aplicaciones correspondiente
                launchUrl(Uri.parse(
                    'https://play.google.com/store/apps/details?id=com.misterjd.rastreogt'));
                // Para iOS: launchUrl(Uri.parse('https://apps.apple.com/app/id{tuAppId}'));
                if (forceUpdate) {
                  SystemNavigator
                      .pop(); // Cierra la app si la actualización es forzada
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.status;
    setState(() {});
    if (!status.isGranted) {
      _showLocationPermissionDialog();
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permiso de Ubicación',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text(
            'Esta aplicación necesita acceso a tu ubicación para funcionar correctamente. Por favor, concede el permiso de ubicación.',
            style: GoogleFonts.poppins(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Conceder Permiso',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.requestPermission();
                _checkLocationPermission();
              },
            ),
          ],
        );
      },
    );
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
    _animationController.dispose();
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
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  // Colores degradados para el fondo
                  Color(0xFF1A237E),
                  Color(0xFF0D47A1),
                  Color.fromARGB(255, 2, 66, 115),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 50),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Image.asset(
                      'assets/images/oficial2.png',
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Bienvenido de Nuevo!',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),
                  _buildTextField(
                    'Email',
                    _emailController,
                    false,
                    Icon(Icons.email,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : const Color.fromARGB(255, 7, 1, 1)),
                    TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    'Contraseña',
                    _passwordController,
                    !_isPasswordVisible,
                    Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : const Color.fromARGB(255, 7, 1, 1),
                    ),
                    TextInputType.visiblePassword,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        //Navegar a la pantalla de recuperación de contraseña
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RecuperarContrasenaScreen(),
                          ),
                        );
                      },
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () async {
                      _showLoading();
                      await AuthService().signin(
                        email: _emailController.text.toLowerCase(),
                        password: _passwordController.text,
                        context: context,
                      );
                      _hideLoading();
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A237E),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Iniciar Sesión',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white54)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'O',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () async {
                      _showLoading();
                      await _googleAuthService.signInWithGoogle(context);
                      _hideLoading();
                    },
                    icon: Image.asset('assets/images/google.png', height: 24),
                    label: Text(
                      'Continuar con Google',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes una cuenta?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Signup(),
                            ),
                          );
                        },
                        child: Text(
                          'Regístrate',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isLoading)
            BackdropFilter(
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
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isPassword,
    Icon icon,
    TextInputType keyboardType,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.1)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white30
              : Colors.grey[400]!,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.grey[800],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey[200],
          suffixIcon: label == 'Contraseña'
              ? IconButton(
                  icon: icon,
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}
