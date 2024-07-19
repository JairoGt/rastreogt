
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rastreogt/Admin/admin_page.dart';
import 'package:rastreogt/Cliente/client_page.dart';
import 'package:rastreogt/Moto/moto_page.dart';
import 'package:rastreogt/auth/login/login.dart';

class AuthService {
  String generateName(String email) {
  String localPart = email.split('@')[0];
  String firstThreeLetters = localPart.length >= 3 ? localPart.substring(0, 3) : localPart;
  int randomNumber = Random().nextInt(90) + 10;
  return "$firstThreeLetters$randomNumber";
}

//metodo para registrarse
  Future<void> signup({
  required String email,
  required String password,
  required BuildContext context,
}) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
      'nickname':generatedName,
      'nego': 'df'
    };

    await userDocument.set(data);

  
// Crear una subcolección 'userData' y un documento 'pInfo' dentro de ella
CollectionReference userData = userDocument.collection('userData');
DocumentReference pInfoDocument = userData.doc('pInfo');
Map<String, dynamic> pInfoData = {
  'direccion': '',
  'estadoid': 0,
  'name':generatedName,
  'telefono': 0,
  'ubicacion': '',
  'token':''
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


    // Redirigir a la pantalla de inicio de sesión
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) =>  AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Login(),
        ),
      ),
    );

  
  } on FirebaseAuthException catch (e) {
    String message = "";
    if (e.code == 'weak-password') {
      message = 'The password provided is too weak.';
    } else if (e.code == 'email-already-in-use') {
      message = 'The account already exists for that email.';
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


//metodo para iniciar sesion


  Future<void> signin({
    required String email,
    required String password,
    required BuildContext context
  }) async {
    
    try {
  
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password
      );
  
      await Future.delayed(const Duration(seconds: 1));
      // final String email = userCredential.user!.email!;
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference users = firestore.collection('users');

      // Get the document for the current user
      DocumentReference userDocument = users.doc(email);

      // Try to get the document for the current user
      DocumentSnapshot snapshot = await userDocument.get();

      if (snapshot.exists) {
        var role = snapshot['role'];
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
              builder: (_) => const AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child: MotoPage(),
             
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
      
    } on FirebaseAuthException catch(e) {
      String message = '';
      if (e.code == 'invalid-email') {
        message = 'No user found for that email.';
      } else if (e.code == 'invalid-credential') {
        message = 'Wrong password provided for that user.';
      } else if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } 
      // Remove the if condition

      
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