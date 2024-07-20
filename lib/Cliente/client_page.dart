import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:rastreogt/Admin/drawer.dart';
import 'package:rastreogt/Cliente/seguimiento.dart';
import 'package:rastreogt/providers/themeNoti.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  String nombreUsuario = 'Mister';
  String nombreNegocio = 'Mi Negocio';
  String negoid = '';
  String nickname = '';
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;

  Future<void> obtenerNombreUsuario() async {
    DocumentSnapshot usuario = await FirebaseFirestore.instance.collection('users').doc(user?.email).get();
    setState(() {
      nombreUsuario = user?.displayName ?? usuario['nickname'];
      nickname = usuario['nickname'];
    });
  }

  Future<void> obtenerNego() async {
    DocumentSnapshot usuario = await FirebaseFirestore.instance.collection('users').doc(user?.email).get();
    setState(() {
      nombreNegocio = usuario['nego'];
    });
  }

  Future<void> obtenerNegoid() async {
    DocumentSnapshot usuario = await FirebaseFirestore.instance.collection('users').doc(user?.email).get();
    setState(() {
      negoid = usuario['negoname'];
    });
  }

  String obtenerSaludo() {
    final horaActual = DateTime.now().hour;
    if (horaActual < 12) {
      return 'Buen día';
    } else if (horaActual < 18) {
      return 'Buena tarde';
    } else {
      return 'Buena noche';
    }
  }
 @override
  void initState() {
    super.initState();
    obtenerNombreUsuario();
    obtenerNego();
    obtenerNegoid();
    
  }
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent, // Importante para la transparencia
          elevation: 0, // Quita la sombra del AppBar
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Color.fromARGB(0, 206, 202, 202), // Estado de la barra transparente
            statusBarIconBrightness: Brightness.light, // Iconos oscuros si el fondo es claro
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(10),
            child: Stack(
              children: [
                Builder(
                  builder: (context) {
                    return IconButton(
                      alignment: Alignment.bottomRight,
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    );
                  }
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: themeNotifier.currentTheme.brightness == Brightness.dark
                          ? [const Color.fromARGB(255, 23, 41, 72), Colors.blueGrey]
                          : [const Color.fromARGB(255, 114, 130, 255), Colors.white],
                      begin: Alignment.center,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                ),
              ]
            ),
          )
        ),
        drawer: const ModernDrawer(),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themeNotifier.currentTheme.brightness == Brightness.dark
                      ? [const Color.fromARGB(255, 23, 41, 72), Colors.blueGrey]
                      : [const Color.fromARGB(255, 114, 130, 255), Colors.white],
                  begin: Alignment.center,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
            SizedBox.expand(
              child: Lottie.asset(
                'assets/lotties/estelas.json',
                fit: BoxFit.cover,
                animate: true,
                repeat: false,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.only(top: 100, left: 50), 
                  child: Text(
                    'Bienvenido',
                    style: GoogleFonts.poppins(
                      fontSize: 23,
                      //fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
  padding: const EdgeInsets.only(top: 5, left: 50), 
                    child: Text(
                    nombreUsuario,
                    style: GoogleFonts.poppins(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.only(top: 5, left: 50), 
                  child: Text(
                    obtenerSaludo(),
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(152, 103, 100, 168),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                     BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, ),
                    SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>  ProcessTimelinePage(),
                          ),
                        );
                      },
                      child: Text(
                        'ID PEDIDO',
                        style: GoogleFonts.zillaSlab(
                         // color: Colors.white54,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
                const SizedBox(height: 20),
                // Código de cliente
          
                // Botón de copiar
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Material(
                      color: const Color.fromARGB(106, 0, 0, 0),
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: nickname));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Código de cliente copiado al portapapeles'),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                          //  color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                           'Toca aqui para copiar tu ID de cliente',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Botón de WhatsApp
                const SizedBox(height: 20),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Material(
                      color: const Color.fromARGB(106, 0, 0, 0),
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Abriendo WhatsApp...'),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            //color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/whatsapp.jpg',
                                width: 30,
                                height: 30,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Contactar por WhatsApp',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // "Mis Pedidos en curso"
                // ... lista de pedidos
              ],
            ),
          ]
        ),
      ),
    );
  }
}