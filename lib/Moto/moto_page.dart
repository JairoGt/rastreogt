import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rastreogt/Moto/pedidocard.dart';
import 'package:rastreogt/Moto/segundoplano.dart';
import '../auth/login/login.dart';
import '../conf/export.dart';

class MotoristaScreen extends StatefulWidget {
  const MotoristaScreen({super.key});

  @override
  _MotoristaScreenState createState() => _MotoristaScreenState();
}

class _MotoristaScreenState extends State<MotoristaScreen>
    with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _motoristaSubscription;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Verificar y solicitar permisos de ubicación
    verificarPermisosUbicacion();
    WidgetsBinding.instance
        .addObserver(this as WidgetsBindingObserver); // Agrega el observador
    iniciarActualizacionPeriodica();
    iniciarEscuchaEstadoMotorista();
    _initializeMotoristaListener();
    //initializeBackgroundService();
    verificarEstadoMotoYMostrarDialogo(user!.email!);
  }

  void _initializeMotoristaListener() {
    final user = _auth.currentUser;
    if (user != null) {
      _motoristaSubscription = _db
          .collection('motos')
          .doc(user.email)
          .snapshots()
          .listen(_handleMotoristaUpdate);
    }
  }

  void _handleMotoristaUpdate(DocumentSnapshot snapshot) {
    if (snapshot.exists) {
      final motoristaData = snapshot.data() as Map<String, dynamic>?;
      if (motoristaData != null) {
        int estadoId = motoristaData['estadoid'] ?? 0;
        if (estadoId == 2) {
          initializeBackgroundService();
        } else if (estadoId == 1) {
          stopBackgroundService();
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar el timer cuando el widget se destruya
    stopBackgroundService();
    _motoristaSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this as WidgetsBindingObserver);
    // LocatorService.stopLocator();
    super.dispose();
  }

  void stopBackgroundService() {
    FlutterBackgroundService().invoke("stopService");
  }

  Stream<DocumentSnapshot> obtenerMotoristaStream(String motoristaEmail) {
    return _db.collection('motos').doc(user?.email).snapshots();
  }

  void iniciarActualizacionPeriodica() {
    _timer = Timer.periodic(const Duration(seconds: 30), (Timer timer) async {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      actualizarUbicacionMotorista(position);
    });
  }

  void iniciarEscuchaUbicacion() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10, // Cada 10 metros se actualizará la ubicación
      ),
    ).listen((Position position) async {
      await actualizarUbicacionMotorista(position);
    });
  }

  Future<bool> verificarPermisosUbicacion() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(
          msg: 'Permiso de ubicación denegado',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return false;
      }
    }
    return true;
  }

  void iniciarEscuchaEstadoMotorista() {
    obtenerMotoristaStream(user!.email!)
        .listen((DocumentSnapshot motoristaDoc) async {
      if (motoristaDoc.exists) {
        int estadoId = motoristaDoc['estadoid'];
        if (estadoId == 2) {
          // El estado del motorista es 2, inicia el servicio de actualización de ubicación
          initializeBackgroundService();
        } else if (estadoId == 1) {
          // El estado del motorista es 4, detener el servicio
          stopBackgroundService();
        }
      }
    });
  }

  // void iniciarEscuchaEstadoMotorista() {
  //   User? user = _auth.currentUser;
  //   if (user == null) {
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           title: const Text('Error de Autenticación'),
  //           content: const Text('No se ha podido obtener el usuario actual'),
  //           actions: <Widget>[
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //               child: const Text('Ok'),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //     return;
  //   }

  //   String userEmail = user.email!;
  //   obtenerMotoristaStream(userEmail).listen((DocumentSnapshot userDoc) async {
  //     if (userDoc.exists && userDoc['estadoid'] == 2) {
  //       print('El estado de la moto es 2');
  //       // Aquí puedes actualizar la ubicación del motorista
  //       Position position = await Geolocator.getCurrentPosition(
  //           desiredAccuracy: LocationAccuracy.high);
  //       actualizarUbicacionMotorista(position);
  //     } else {
  //       print('El estado de la moto no es 2');
  //     }
  //   });
  // }

  Future<void> actualizarUbicacionMotorista(Position position) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error de Autenticación'),
              content: const Text('No se ha podido obtener el usuario actual'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Ok'),
                ),
              ],
            );
          },
        );
        return;
      }

      String userEmail = user.email!;
      double latitude = position.latitude;
      double longitude = position.longitude;

      await _db.collection('motos').doc(userEmail).update({
        'ubicacionM': GeoPoint(latitude, longitude),
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error al actualizar la ubicación: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 4,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> cerrarSesion(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .terminate(); // Termina todas las conexiones con Firestore
      debugPrint('Conexiones con Firestore terminadas.');
      // Cerrar sesión de Google
      await GoogleSignIn().signOut();
      debugPrint('Usuario de Google ha cerrado sesión.');

      // Cerrar sesión de Firebase
      await FirebaseAuth.instance.signOut();
      debugPrint('Usuario ha cerrado sesión de Firebase.');

      // Navegar a la pantalla de login y limpiar la pila de navegación
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()),
          (Route<dynamic> route) => false,
        );
      });
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
      // Mostrar un SnackBar con el error
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
    DocumentSnapshot userDoc =
        await _db.collection('users').doc(userEmail).get();
    String idmoto = userDoc['idmoto'];
    QuerySnapshot pedidosSnapshot = await _db
        .collection('pedidos')
        .where('idMotorista', isEqualTo: idmoto)
        .where('estadoid', isLessThanOrEqualTo: 3)
        .get();

    if (pedidosSnapshot.docs.isEmpty) {
      Fluttertoast.showToast(
        msg: 'No tienes pedidos asignados',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 4,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      stopBackgroundService();
    }

    return pedidosSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<void> actualizarPedidoEnCamino(String pedidoId) async {
    // Obtiene el usuario actual
    User? user = _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'No hay un usuario autenticado.',
      );
    }
    String userEmail = user.email!;

    // se obtiene la referencia del pedido
    DocumentReference pedidoRef = _db.collection('pedidos').doc(pedidoId);
    DocumentSnapshot pedidoDoc = await pedidoRef.get();

    // Verifica si el pedido existe
    if (!pedidoDoc.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'El pedido con ID $pedidoId no existe.',
      );
    }

    // Actualiza el estado del pedido
    await pedidoRef.update({'estadoid': 3});

    // Actualiza el estado del motorista en la colección 'motos'
    DocumentReference motoristaRef = _db.collection('motos').doc(userEmail);
    await motoristaRef.update({'estadoid': 2});

    // Inicializa el servicio en segundo plano
    initializeBackgroundService();

    // Muestra un mensaje de éxito
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('El pedido ha sido marcado como "En camino"'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> marcarPedidoComoEntregado(
      String idPedido, String motoristaEmail) async {
    try {
      // Actualizar el estado del pedido a "Entregado"
      DocumentReference pedidoDocument =
          _firestore.collection('pedidos').doc(idPedido);
      await pedidoDocument.update({'estadoid': 4});
      User? user = _auth.currentUser;
      String userEmail = user!.email!;
      DocumentSnapshot userDoc =
          await _db.collection('users').doc(userEmail).get();

      if (!userDoc.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'El usuario con email $userEmail no existe.',
        );
      }

      String idmoto = userDoc['idmoto'];
      // Actualizar el estado del motorista a "Disponible"
      QuerySnapshot pedidosSnapshot = await _db
          .collection('pedidos')
          .where('idMotorista', isEqualTo: idmoto)
          .where('estadoid', isNotEqualTo: 4) // Excluir pedidos con estadoid 4
          .get();
      if (pedidosSnapshot.docs.isEmpty) {
        DocumentReference motoristaDocument =
            _firestore.collection('motos').doc(user.email);
        await motoristaDocument.update({'estadoid': 1});
        stopBackgroundService();
      }
    } catch (error) {
      Fluttertoast.showToast(
        msg: 'Error al marcar el pedido como entregado: $error',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 4,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> actualizarPedidosEnCamino() async {
    User? user = _auth.currentUser;
    String userEmail = user!.email!;
    DocumentSnapshot userDoc =
        await _db.collection('users').doc(userEmail).get();

    if (!userDoc.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'El usuario con email $userEmail no existe.',
      );
    }

    String idmoto = userDoc['idmoto'];
    QuerySnapshot pedidosSnapshot = await _db
        .collection('pedidos')
        .where('idMotorista', isEqualTo: idmoto)
        .where('estadoid', isLessThan: 3) // Excluir pedidos con estadoid 3 o 4
        .get();

    if (pedidosSnapshot.docs.isEmpty) {
      stopBackgroundService();
      Fluttertoast.showToast(
        msg: 'No hay pedidos asignados para marcar como "En camino"',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 4,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } else {
      WriteBatch batch = _db.batch();
      for (var doc in pedidosSnapshot.docs) {
        batch.update(doc.reference, {'estadoid': 3});
      }
      // Actualizar el estado del motorista en la colección 'motos'
      batch.update(_db.collection('motos').doc(userEmail), {'estadoid': 2});
      await batch.commit();
      if (!mounted) return;
      initializeBackgroundService();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Todos los pedidos han sido marcados como "En camino"'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
      setState(() {}); // Refresca la lista de pedidos
    }
  }

  void verificarEstadoMotoYMostrarDialogo(String idMoto) async {
    DocumentSnapshot motoDocument =
        await firestore.collection('motos').doc(user!.email).get();

    if (motoDocument.exists) {
      Map<String, dynamic> motoData =
          motoDocument.data() as Map<String, dynamic>;
      // Comprueba si el dialogid de la moto es 1
      if (motoData['dialogid'] == 1) {
        // El estado el dialogid es 1, muestra el AlertDialog
        mostrarDialogoSolicitudMotorista();
      } else {
        // El estado del dialog no es 1, no muestra nada
      }
    } else {
      // El documento de la moto no existe, maneja este caso según sea necesario
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido encontrar la moto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void mostrarDialogoSolicitudMotorista() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Solicitud para ser Motorista'),
          content:
              const Text('¿Quieres aceptar la solicitud para ser motorista?'),
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
                        future: cerrarSesion(context),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            // Una vez que se complete el cierre de sesión, navega a la pantalla de inicio
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Navigator.popUntil(
                                  context, ModalRoute.withName('/'));
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
                quitardialog();
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
    String userId = "${user?.email}";
    // Actualiza el rol del usuario a "cliente"
    await firestore.collection('users').doc(userId).update({
      'role': 'client',
    });
    // Cambia el estado en la colección de motoristas a 2
    await firestore.collection('motos').doc(userId).update({
      'dialogid': 0,
    });
  }

  void quitardialog() async {
    String userId = "${user?.email}";
    // Cambia el estado en la colección de motoristas a 0
    await firestore.collection('motos').doc(userId).update({
      'dialogid': 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        drawer: const ModernDrawer(),
        appBar: AppBar(
          title: Text('Pedidos Asignados',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: obtenerPedidosAsignados(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay pedidos asignados'));
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) => PedidoCard(
                pedido: snapshot.data![index],
                onEstadoChanged: () => setState(() {}),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: actualizarPedidosEnCamino,
          label: const Text('Actualizar todos'),
          icon: const Icon(Icons.update),
        ),
      ),
    );
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
      case 5:
        return 'Cancelado';
      default:
        return 'Estado desconocido';
    }
  }
}
