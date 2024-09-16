import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rastreogt/Cliente/detalle_pedido.dart';
import 'package:rastreogt/Moto/motomaps.dart';
import 'package:rastreogt/Moto/segundoplano.dart';
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
  Timer? _timer;
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      debugPrint('Couldn\'t check connectivity status: $e');
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    setState(() {
      _connectionStatus = result;
    });
    // ignore: avoid_print
    if (_connectionStatus.contains(ConnectivityResult.none)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error de Conexión'),
            content: const Text(
                'No hay conexión a internet. Por favor, verifica tu conexión e inténtalo de nuevo.'),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Conexión establecida'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Verificar y solicitar permisos de ubicación
    verificarPermisosUbicacion();
    WidgetsBinding.instance
        .addObserver(this as WidgetsBindingObserver); // Agrega el observador
    iniciarActualizacionPeriodica();
    initConnectivity();
    iniciarEscuchaEstadoMotorista();
    //initializeBackgroundService();
    verificarEstadoMotoYMostrarDialogo(user!.email!);
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar el timer cuando el widget se destruya
    _connectivitySubscription.cancel();
    stopBackgroundService();
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

  Future<void> cerrarSesion() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null &&
          currentUser.providerData
              .any((userInfo) => userInfo.providerId == 'google.com')) {
        await GoogleSignIn().signOut();
      } else {
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
    }

    return pedidosSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<void> actualizarPedidoEnCamino(String pedidoId) async {
    // Obtén el usuario actual
    User? user = _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'No hay un usuario autenticado.',
      );
    }
    String userEmail = user.email!;

    // Obtén la referencia del pedido
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
      const SnackBar(
        content: Text(
            'El pedido ha sido marcado como "En camino" y el estado del motorista ha sido actualizado.'),
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
        .where('estadoid', isNotEqualTo: 4) // Excluir pedidos con estadoid 4
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
    }

    if (pedidosSnapshot.docs.isNotEmpty) {
      WriteBatch batch = _db.batch();
      for (var doc in pedidosSnapshot.docs) {
        batch.update(doc.reference, {'estadoid': 3});
      }
      // Actualizar el estado del motorista en la colección 'moto'
      batch.update(_db.collection('motos').doc(userEmail), {'estadoid': 2});
      await batch.commit();
      if (!mounted) return;
      initializeBackgroundService();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los pedidos han sido marcados como "En camino"'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {}); // Refresca la lista de pedidos
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Debe tener al menos 5 pedidos para marcar todos como "En camino"'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void verificarEstadoMotoYMostrarDialogo(String idMoto) async {
    DocumentSnapshot motoDocument =
        await firestore.collection('motos').doc(user!.email).get();

    if (motoDocument.exists) {
      Map<String, dynamic> motoData =
          motoDocument.data() as Map<String, dynamic>;
      // Comprueba si el estado de la moto es 2
      if (motoData['estadoid'] == 0) {
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
                        future: cerrarSesion(),
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
    String userId =
        "${user?.email}"; // Asegúrate de reemplazar esto con el ID del usuario actual
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
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        tooltip: 'Actualizar todos los pedidos en camino',
        onPressed: () async {
          actualizarPedidosEnCamino();
        },
        child: const Icon(Icons.rotate_left_rounded, color: Colors.white),
      ),
      drawer: const ModernDrawer(),
      appBar: AppBar(
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
        title: const Text('Pedidos Asignados'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.update),
            onPressed: () {
              setState(() {}); // Refresca la lista de pedidos
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: obtenerPedidosAsignados(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.error != null) {
            return const Center(child: Text('Error al obtener los pedidos'));
          } else if (snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay pedidos asignados'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var pedido = snapshot.data![index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Icon(Icons.motorcycle,
                        color: Theme.of(context).colorScheme.inversePrimary),
                    title: Text(pedido['idpedidos'] ?? 'Sin ID Verifica',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    isThreeLine: true,
                    contentPadding: const EdgeInsets.all(8),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                  text: 'Dirección: ',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  )),
                              TextSpan(
                                  text: '${pedido['direccion']}\n',
                                  style: GoogleFonts.roboto(
                                      fontSize: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text: 'Cliente: ',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  )),
                              TextSpan(
                                  text: '${pedido['nickname']}\n',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  )),
                              TextSpan(
                                  text: 'Estado: ',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  )),
                              TextSpan(
                                  text: obtenerDescripcionEstado(
                                      (pedido['estadoid'])),
                                  style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(children: [
                              IconButton(
                                icon: const Icon(Icons.map),
                                onPressed: () async {
                                  try {
                                    if (pedido['ubicacionCliente'] == null ||
                                        pedido['ubicacionNegocio'] == null) {
                                      throw Exception(
                                          'No se ha podido encontrar las ubicaciones del negocio o del cliente');
                                    }

                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MotoristaMapScreen(
                                                ubicacionCliente: LatLng(
                                                  pedido['ubicacionCliente']
                                                      .latitude,
                                                  pedido['ubicacionCliente']
                                                      .longitude,
                                                ),
                                                ubicacionNegocio: LatLng(
                                                  pedido['ubicacionNegocio']
                                                      .latitude,
                                                  pedido['ubicacionNegocio']
                                                      .longitude,
                                                )),
                                      ),
                                    );
                                  } catch (e, stackTrace) {
                                    Fluttertoast.showToast(
                                      msg:
                                          'Error al abrir el mapa: $e y $stackTrace',
                                      toastLength: Toast.LENGTH_LONG,
                                      gravity: ToastGravity.BOTTOM,
                                      timeInSecForIosWeb: 4,
                                      backgroundColor: Colors.red,
                                      textColor: Colors.white,
                                      fontSize: 16.0,
                                    );
                                    return;
                                  }
                                },
                              ),
                              const Text('Ver ubicación'),
                            ]),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return DetalleDialog(
                                          orderId: pedido['idpedidos'],
                                        );
                                      },
                                    );
                                  },
                                ),
                                const Text('Ver información'),
                              ],
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check),
                                  onPressed: () async {
                                    await actualizarPedidoEnCamino(
                                        pedido['idpedidos']);
                                    setState(
                                        () {}); // Refresca la lista de pedidos
                                  },
                                ),
                                const Text('Acción a realizar'),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.done),
                                  onPressed: () async {
                                    await marcarPedidoComoEntregado(
                                        pedido['idpedidos'],
                                        pedido['idMotorista']);
                                    setState(
                                        () {}); // Refresca la lista de pedidos
                                  },
                                ),
                                const Text('Marcar como entregado'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
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
      default:
        return 'Estado desconocido';
    }
  }
}
