import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:rastreogt/auth/auth_service.dart';
import 'package:rastreogt/auth/login/loginGoogle.dart';
import 'package:rastreogt/auth/signup/signUp.dart';


class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

    final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool _isLoading = false;

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
      //backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: _signup(context),
      appBar: AppBar(
        
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 100,
        
      ),
      body: Stack(
        children: [
        SafeArea(
          child: SingleChildScrollView(
           padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    'Hola de nuevo!',
                    style: GoogleFonts.aDLaMDisplay(
                      textStyle: const TextStyle(
                       // color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 32
                      )
                    ),
                  ),
                ),
                const SizedBox(height: 80,),
                  _buildTextField('Correo electrónico', _emailController, false,Icon(Icons.email)),
                 const SizedBox(height: 20,),
                                  _buildTextField('Contraseña', _passwordController, true,Icon(Icons.password_outlined )),

                 const SizedBox(height: 50,),
                 _signin(context),
                  const SizedBox(height: 20,),
                  ElevatedButton(
        
            onPressed: () async {
              _showLoading();
              await _googleAuthService.signInWithGoogle(context);
              _hideLoading();
            },
            child: const Text('Iniciar con Google'),
          ),
         
              ],
              
            ),
          ),
        ),
          if (_isLoading)
         Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.5), // Añade un color de fondo semitransparente
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
     ]
      ),
      
    );
  }


  Widget _password() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contraseña',
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.normal,
              fontSize: 16
            )
          ),
        ),
        const SizedBox(height: 16,),
        TextField(
          obscureText: true,
          controller: _passwordController,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xffF7F7F9) ,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(14)
            )
          ),
        )
      ],
    );
  }

  Widget _signin(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
       // backgroundColor: const Color.fromARGB(255, 59, 76, 100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        minimumSize: const Size(double.infinity, 60),
        elevation: 0,
      ),
      onPressed: () async {
        _showLoading();
        await AuthService().signin(
          email: _emailController.text,
          password: _passwordController.text,
          context: context
        );
        _hideLoading();
      },
      child: const Text("Ingresar", style: TextStyle(
       // color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16
      ),),
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
                text: "Nuevo Usuario? ",
                style: TextStyle(
                  color: Color(0xff6A6A6A),
                  fontWeight: FontWeight.normal,
                  fontSize: 16
                ),
              ),
              TextSpan(
                text: "Crear Cuenta",
                style: const TextStyle(
                   // color: Color(0xff1A1D1E),
                    fontWeight: FontWeight.normal,
                    fontSize: 16
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Signup()
                      ),
                    );
                  }
              ),
          ]
        )
      ),
    );
  }
}

 Widget _buildTextField(String label, TextEditingController controller, bool obscureText,Icon ico) {
    return TextField(
      
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: ico,
        labelText: label,
        
        //labelStyle: GoogleFonts.raleway(color: Colors.white),
        filled: true,
       fillColor: const Color.fromARGB(94, 255, 255, 255).withOpacity(0.2), // Fondo semitransparente
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: BorderSide.none,
          
        ),
      ),
    );
  }