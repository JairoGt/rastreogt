import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:rastreogt/Admin/reasignar_moto.dart';
import 'package:rastreogt/Cliente/pInfo.dart';
import 'package:rastreogt/Cliente/sol_nego.dart';
import 'package:rastreogt/conf/configuracion.dart';

class ModernDrawer extends StatefulWidget {
  const ModernDrawer({super.key});

  @override
  _ModernDrawerState createState() => _ModernDrawerState();
}

class _ModernDrawerState extends State<ModernDrawer> {
  String nombreUsuario = 'Mister';
  String imagenPerfil = 'https://via.placeholder.com/150'; // URL de imagen de perfil por defecto
  String role = 'cliente'; // Valor por defecto
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    obtenerDatosUsuario();
  }

  Future<void> obtenerDatosUsuario() async {
    DocumentSnapshot usuario = await FirebaseFirestore.instance.collection('users').doc(user?.email).get();
    setState(() {
      nombreUsuario = usuario['nickname'];
      role = usuario['role']; // Asegúrate de tener este campo en Firestore
      //imagenPerfil = usuario['imagenPerfil']; // Asegúrate de tener este campo en Firestore
    });
  }
Future<void> cerrarSesion() async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser!.providerData.any((userInfo) => userInfo.providerId == 'google.com')) {
      // User is signed in with Google
      await GoogleSignIn().signOut();
    } else {
      // User is signed in with email and password
      await FirebaseAuth.instance.signOut();
    }
  } catch (e) {
      if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al cerrar sesión: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).cardColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Stack(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                 user?.displayName?? nombreUsuario,
                  style: GoogleFonts.roboto(fontSize: 20, color: Theme.of(context).colorScheme.onSecondary),
                ),
                accountEmail: Text(
                  user?.email ?? nombreUsuario,
                  style: GoogleFonts.roboto(fontSize: 15, color: Theme.of(context).colorScheme.onSecondary),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: NetworkImage(user?.photoURL ?? imagenPerfil),
                ),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(84, 47, 66, 81),
                ),
              ),
              Positioned.fill(
                child: Lottie.asset(
                  'assets/lotties/estelas.json', // Asegúrate de que el archivo Lottie esté en la carpeta assets
                  fit: BoxFit.fill,
                ),
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil'),
            onTap: () {
              Navigator.pop(context);
            Navigator.push(context, 
        
              MaterialPageRoute(builder: (context) =>  UserInfoScreen(userEmail: user?.email))
          
            );
            },
          ),
          if (role == 'admin') ...[
            ListTile(
              leading: const Icon(Icons.motorcycle),
              title: const Text('Asignar moto'),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.pushNamed(context, '/asignacion');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delivery_dining_outlined),
              title: const Text('Reasignar motorista'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReasignarPedidos()),
                );
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push( 
                context,
                MaterialPageRoute(
                  builder: (context) => const ConfiguracionAll(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Solicitar negocio'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push( 
                context,
                MaterialPageRoute(
                  builder: (context) => const MyHomePage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión'),
            onTap: () async{
              try {
             Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FutureBuilder(
          future: cerrarSesion(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // Una vez que se complete el cierre de sesión, navega a la pantalla de inicio
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.popUntil(context, ModalRoute.withName('/'));
              });
              return Container(); // Pantalla vacía mientras se navega
            } else {
              // Muestra un indicador de carga mientras se cierra la sesión
              return const Scaffold(
               // backgroundColor: Color.fromARGB(125, 255, 255, 255),
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          },
        ),
      ),
    );
              } catch (e) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('Error al cerrar sesión: $e'),
                 backgroundColor: Colors.red,
               ),
             ); 
            }
  }),
        ],
      ),
    );
  }
}