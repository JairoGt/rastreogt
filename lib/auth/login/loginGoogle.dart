import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';

import '../../conf/export.dart';

String generateName(String email) {
  String localPart = email.split('@')[0];
  String firstThreeLetters = localPart.length >= 3 ? localPart.substring(0, 3) : localPart;
  int randomNumber = Random().nextInt(90) + 10;
  return "$firstThreeLetters$randomNumber";
}

Future<void> checkConnectivityAndShowDialog(BuildContext context) async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    // No hay conexión a internet
    showErrorDialog(context, "No hay conexión a internet. Por favor, verifica tu conexión e inténtalo de nuevo.");
    return;
  }
}

class GoogleAuthService {
  
  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    // Verificar conexión a internet
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // No hay conexión a internet
      showErrorDialog(context, "No hay conexión a internet. Por favor, verifica tu conexión e inténtalo de nuevo.");
      return null;
    }else{
          
    // Initialize GoogleSignIn
    final GoogleSignIn googleSignIn = GoogleSignIn();
    // Trigger the sign-in flow
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    // Once signed in, return the UserCredential
    UserCredential? userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    showLoadingDialog(context);

    // Get the user's email
    final String email = userCredential.user!.email!;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference users = firestore.collection('users');
    // Get the document for the current user
    DocumentReference userDocument = users.doc(email);
    // Try to get the document for the current user
    DocumentSnapshot snapshot = await userDocument.get();
    if (snapshot.exists) {
      var role = snapshot['role'];
      String? token = await FirebaseMessaging.instance.getToken();
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
      } else if (role == 'moto') {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => AnimatedSwitcher(
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
    } else {
      // Si la colección 'users' no tiene un documento con el email del usuario, crea uno
      String generatedName = generateName(email);
      String? token = await FirebaseMessaging.instance.getToken();
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        token = newToken;
      });
      userDocument.set({
        'name': userCredential.user!.displayName,
        'email': email.trim(),
        'idBussiness': '',
        'idmoto': '0',
        'estadoid': 0,
        'role': 'client',
        'negoname': 'df',
        'nickname': generatedName,
        'nego': 'df',
        'token': token,
      });
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

    return userCredential;
  }
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
    }

  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
