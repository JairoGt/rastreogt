import 'package:flutter/services.dart';
import 'package:rastreogt/conf/export.dart';


class MotoristaScreen extends StatefulWidget {
  @override
  _MotoristaScreenState createState() => _MotoristaScreenState();
}

class _MotoristaScreenState extends State<MotoristaScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

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
  Future<List<Map<String, dynamic>>> obtenerPedidosAsignados() async {
    User? user = _auth.currentUser;
    String userEmail = user!.email!;
    DocumentSnapshot userDoc = await _db.collection('users').doc(userEmail).get();
    String idmoto = userDoc['idmoto'];
    QuerySnapshot pedidosSnapshot = await _db.collection('pedidos')
        .where('idMotorista', isEqualTo: idmoto)
        .where('estadoid', isEqualTo: 2)
        .get();
    return pedidosSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  void verificarEstadoMotoYMostrarDialogo(String idMoto) async {
  DocumentSnapshot motoDocument = await firestore.collection('motos').doc(user!.email).get();

  if (motoDocument.exists) {
    Map<String, dynamic> motoData = motoDocument.data() as Map<String, dynamic>;
    // Comprueba si el estado de la moto es 2
    if (motoData['estadoid'] == 2) {
      // El estado de la moto es 2, muestra el AlertDialog
      mostrarDialogoSolicitudMotorista();
    } else {
      // El estado de la moto no es 2, no hagas nada
    }
  } else {
    // El documento de la moto no existe, maneja este caso según sea necesario
  }
}

void mostrarDialogoSolicitudMotorista() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Solicitud para ser Motorista'),
        content: Text('¿Quieres aceptar la solicitud para ser motorista?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              // El usuario seleccionó "No"
              actualizarUsuarioARolCliente();
                Navigator.of(context).pop(); // Cierra el diálogo
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
            
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              // El usuario seleccionó "Sí", simplemente cierra el diálogo
              Navigator.of(context).pop();
            },
            child: const Text('Sí'),
          ),
        ],
      );
    },
  );
}

void actualizarUsuarioARolCliente() async {
  String userId = "${user?.email}"; // Asegúrate de reemplazar esto con el ID del usuario actual
  // Actualiza el rol del usuario a "cliente"
  await firestore.collection('users').doc(userId).update({
    'role': 'client',
  });
  // Cambia el estado en la colección de motoristas a 2
  await firestore.collection('motos').doc(userId).update({
    'estadoid': 2,
  });

}

@override
  void initState() {
    super.initState();
    verificarEstadoMotoYMostrarDialogo(user!.email!);
  }
  @override
  Widget build(BuildContext context) {
    ThemeNotifier themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: ModernDrawer(),
      appBar:  AppBar(
        centerTitle: true,
        title: const Text('Pedidos Asignados'),
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Color.fromARGB(0, 206, 202, 202),
              statusBarIconBrightness: Brightness.light,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                
                  Stack(children: [
                    Builder(builder: (context) {
                      return IconButton(
                        alignment: Alignment.bottomRight,
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      );
                    }),
                  
                  ]),
                ],
              ),
            )),
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
        FutureBuilder<List<Map<String, dynamic>>>(
          future: obtenerPedidosAsignados(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error al obtener los pedidos'));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var pedido = snapshot.data![index];
                 return Card(
          elevation: 4,
          margin: EdgeInsets.all(8),
          child: ListTile(
            leading: Icon(Icons.motorcycle, color: Theme.of(context).colorScheme.inversePrimary),
            title: Text(pedido['idpedidos'] ?? 'Sin ID', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: RichText(
        
        text: TextSpan(
          
          children: [
            TextSpan(
              text: 'Dirección: ',
              style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface,)
            ),
            TextSpan(
              text: '${pedido['direccion']}\n',
              style: GoogleFonts.roboto(fontSize: 20, color: Theme.of(context).colorScheme.onSurface,fontWeight: FontWeight.bold)
            ),
            TextSpan(
              text: 'Cliente: ',
              style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface,)  
            ),
            TextSpan(
              text: '${pedido['nickname']}\n',
              style: GoogleFonts.roboto(fontSize: 16,color: Theme.of(context).colorScheme.onSurface,)
            ),
            TextSpan(
              text: 'Estado: ',
              style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface,)
            ),
            TextSpan(
              text: obtenerDescripcionEstado((pedido['estadoid'])),
              style: GoogleFonts.roboto(fontSize: 16,color: Theme.of(context).colorScheme.onSurface,fontWeight: FontWeight.bold)
            ),
          ],
        ),
            ),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
        // Acción al tocar el pedido, por ejemplo, mostrar detalles
            },
          ),
        );
                },
              );
            }
          },
        ),
      ]),
    );
  }
}
String obtenerDescripcionEstado(int estadoid) {
  switch (estadoid) {
    case 1:
      return 'Creado';
    case 2:
      return 'En proceso';
    case 3:
      return 'En camino';
    case 4:
      return 'Entregado';
    default:
      return 'Estado desconocido';
  }
}