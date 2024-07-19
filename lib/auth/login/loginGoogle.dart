import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rastreogt/Admin/admin_page.dart';
import 'package:rastreogt/Cliente/client_page.dart';
import 'package:rastreogt/Moto/moto_page.dart';

String generateName(String email) {
  String localPart = email.split('@')[0];
  String firstThreeLetters = localPart.length >= 3 ? localPart.substring(0, 3) : localPart;
  int randomNumber = Random().nextInt(90) + 10;
  return "$firstThreeLetters$randomNumber";
}
class GoogleAuthService {
  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    // Initialize GoogleSignIn
    final GoogleSignIn googleSignIn = GoogleSignIn();

    // Trigger the sign-in flow
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    UserCredential? userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

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
    } else {
      // If the document does not exist, create it with the role of 'client'
      String generatedName = generateName(email);
      userDocument.set({
          'name': userCredential.user!.displayName,
    'email': email.trim(),
    'idmoto': '0',
    'estadoid': 0,
    'role': 'client',
    'negoname': 'df',
    'nickname':generatedName,
    'nego': 'df'
      });
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
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => const AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            child: //ClientScreen(),
            ScaffoldMessenger(child: 
              SnackBar(content: Text('Cliente Screen')))
          ),
        ),
      );
    }
  
    return userCredential;
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