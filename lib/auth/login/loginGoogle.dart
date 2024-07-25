import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:rastreogt/conf/export.dart';

// Función para generar un nombre de usuario basado en el email
String generateName(String email) {
  String localPart = email.split('@')[0];
  String firstThreeLetters = localPart.length >= 3 ? localPart.substring(0, 3) : localPart;
  int randomNumber = Random().nextInt(90) + 10;
  return "$firstThreeLetters$randomNumber";
}

class GoogleAuthService {
  // Método para iniciar sesión con Google
  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // Si el usuario cancela el inicio de sesión

      final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      UserCredential? userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      await _handlePostLoginTasks(userCredential, context);

      return userCredential;
    } catch (e) {
      print("Error during Google sign-in: $e");
      return null;
    }
  }

  // Método para manejar tareas después del inicio de sesión
  Future<void> _handlePostLoginTasks(UserCredential? userCredential, BuildContext context) async {
    if (userCredential?.user == null) return;

    final String email = userCredential!.user!.email!;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference users = firestore.collection('users');
    final DocumentReference userDocument = users.doc(email);
    final DocumentSnapshot snapshot = await userDocument.get();

    if (snapshot.exists) {
      await _handleExistingUser(snapshot, context, userDocument);
    } else {
      await _handleNewUser(userCredential, userDocument);
    }
  }

  // Método para manejar usuarios existentes
  Future<void> _handleExistingUser(DocumentSnapshot snapshot, BuildContext context, DocumentReference userDocument) async {
    var role = snapshot['role'];
    String? token = await FirebaseMessaging.instance.getToken();

    if (snapshot['token'] != token) {
      userDocument.update({'token': token});
    }

    _navigateToRoleBasedScreen(role, context);
  }

  // Método para manejar nuevos usuarios
  Future<void> _handleNewUser(UserCredential userCredential, DocumentReference userDocument) async {
    final String email = userCredential.user!.email!;
    String generatedName = generateName(email);
    String? token = await FirebaseMessaging.instance.getToken();

    await userDocument.set({
      'name': userCredential.user!.displayName ?? email,
      'email': email.trim(),
      // Agrega más campos según sea necesario
      'nickname': generatedName,
      'token': token,
      'role': 'client', // Asigna un rol predeterminado
    });

    // Opcional: Crear subcolecciones o documentos adicionales
  }

  // Método para navegar a la pantalla basada en el rol del usuario
  void _navigateToRoleBasedScreen(String role, BuildContext context) {
    switch (role) {
      case 'admin':
        Navigator.push(context, CupertinoPageRoute(builder: (_) => const AdminPage()));
        break;
      case 'moto':
        Navigator.push(context, CupertinoPageRoute(builder: (_) => MotoristaScreen()));
        break;
      case 'client':
        Navigator.push(context, CupertinoPageRoute(builder: (_) => ClientPage()));
        break;
      default:
        print("Rol no reconocido");
    }
  }
}

// Asegúrate de tener las clases AdminPage, MotoristaScreen y ClientPage definidas en tu proyecto