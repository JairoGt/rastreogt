import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rastreogt/Cliente/client_page.dart';
import 'package:rastreogt/auth/login/login.dart';
import 'package:rastreogt/conf/export.dart';
import 'package:rastreogt/main.dart';

class AuthService {
  String generateName(String email) {
    String localPart = email.split('@')[0];
    String firstThreeLetters =
        localPart.length >= 3 ? localPart.substring(0, 3) : localPart;
    int randomNumber = Random().nextInt(90) + 10;
    return "$firstThreeLetters$randomNumber";
  }

  // Método para registrarse
  Future<void> signup({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Enviar correo de verificación
      await userCredential.user!.sendEmailVerification();
      Fluttertoast.showToast(
        msg: "Se ha enviado un correo de verificación a $email",
        webPosition: "center",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Generar un nombre automáticamente
      String generatedName = generateName(email);

      // Obtener el token de FCM
      String? token = await FirebaseMessaging.instance.getToken();
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        token = newToken;
        // Actualizar el token en Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(email)
            .update({'token': newToken});
      });

      // Guardar la información del usuario en Firestore
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference users = firestore.collection('users');
      DocumentReference userDocument = users.doc(email);
      Map<String, dynamic> data = {
        'name': generatedName,
        'email': email.trim(),
        'idmoto': '0',
        'estadoid': 0,
        'role': 'client',
        'negoname': 'df',
        'nickname': generatedName,
        'nego': 'df',
        'token': token,
      };

      await userDocument.set(data);

      // Crear una subcolección 'userData' y un documento 'pInfo' dentro de ella
      CollectionReference userData = userDocument.collection('userData');
      DocumentReference pInfoDocument = userData.doc('pInfo');
      Map<String, dynamic> pInfoData = {
        'direccion': '',
        'estadoid': 0,
        'name': generatedName,
        'telefono': 0,
        'ubicacion': '',
        // Agrega más campos según sea necesario
      };

      await pInfoDocument.set(pInfoData);

      // Obtener el valor del campo `role`
      DocumentSnapshot snapshot = await userDocument.get();

      // Asignar rol si no tiene uno
      if (snapshot.exists) {
        var role = snapshot['role'];

        if (role == null) {
          await userDocument.update({'role': 'client'});
        }
      }
      if (context.mounted) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => const AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: Login(),
            ),
          ),
        );
      } else {
        return;
      }
      // Redirigir a la pantalla de inicio de sesión
    } on FirebaseAuthException catch (e) {
      String message = "";
      if (e.code == 'weak-password') {
        message = 'La contraseña proporcionada es demasiado débil.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Ya existe una cuenta con ese correo electrónico.';
      } else if (e.code == 'invalid-email') {
        message = 'El correo electrónico proporcionado no es válido.';
      } else {
        message = e.message ?? 'Error desconocido';
      }
      Fluttertoast.showToast(
        msg: message,
        webPosition: "center",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString(),
        webPosition: "center",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

// Método para iniciar sesión
  Future<void> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Por favor, ingrese su correo y contraseña.',
        webPosition: "center",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await Future.delayed(const Duration(seconds: 1));
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference users = firestore.collection('users');

      // Obtener el documento del usuario actual
      DocumentReference userDocument = users.doc(email);

      // Obtener el token de FCM
      String? token = await FirebaseMessaging.instance.getToken();
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        token = newToken;
        // Actualizar el token en Firestore
        await userDocument.update({'token': newToken});
      });

      // Intentar obtener el documento del usuario actual
      DocumentSnapshot snapshot = await userDocument.get();

      if (snapshot.exists) {
        var role = snapshot['role'];

        // Verifica si el token ha cambiado o no existe
        if (snapshot['token'] != token) {
          // Actualiza el token en la base de datos
          userDocument.update({'token': token});
        }

        if (role == 'admin') {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => const AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child: AdminPage(),
              ),
            ),
          );
        } else if (role == 'adminjr') {
          Navigator.of(context).pushReplacementNamed('/adminjr');
          FirebaseAuth.instance.authStateChanges().listen((User? user) {
            if (user != null && user.email != null) {
              processPendingNotifications(user.email!);
            }
          });
        } else if (role == 'moto') {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => const AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child: MotoristaScreen(),
              ),
            ),
          );
        } else if (role == 'client') {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => const AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child: ClientPage(),
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'invalid-email') {
        message = 'No se encontró un usuario con ese correo electrónico.';
      } else if (e.code == 'invalid-credential') {
        message = 'Contraseña incorrecta proporcionada para ese usuario.';
      } else if (e.code == 'user-not-found') {
        message = 'No se encontró un usuario con ese correo electrónico.';
      } else if (e.code == 'wrong-password') {
        message = 'Contraseña incorrecta proporcionada para ese usuario.';
      } else if (e.code == 'user-disabled') {
        message =
            'El usuario con ese correo electrónico ha sido deshabilitado.';
      } else if (e.code == 'too-many-requests') {
        message =
            'Demasiados intentos de inicio de sesión fallidos. Intente nuevamente más tarde.';
      } else if (e.code == 'operation-not-allowed') {
        message =
            'El inicio de sesión con correo electrónico y contraseña no está habilitado.';
      } else if (e.code == 'network-request-failed') {
        message = 'Error de red. Por favor, inténtelo de nuevo.';
      } else if (e.code == 'user-mismatch') {
        message =
            'Las credenciales proporcionadas no coinciden con las credenciales existentes.';
      } else if (e.code == 'invalid-verification-code') {
        message = 'El código de verificación proporcionado no es válido.';
      } else if (e.code == 'invalid-verification-id') {
        message = 'El ID de verificación proporcionado no es válido.';
      } else if (e.code == 'session-expired') {
        message = 'La sesión ha expirado. Por favor, inicie sesión nuevamente.';
      } else {
        message = e.message ?? 'Error desconocido';
      }
      Fluttertoast.showToast(
        msg: message,
        webPosition: "center",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }
}
