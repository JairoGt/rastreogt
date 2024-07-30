import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rastreogt/Cliente/detalle_pedido.dart';
import 'package:rastreogt/Moto/Profile_moto.dart';
import 'package:rastreogt/Moto/motoMaps.dart';

import '../conf/export.dart';

class MotoristaScreen extends StatefulWidget {
  @override
  _MotoristaScreenState createState() => _MotoristaScreenState();
}

class _MotoristaScreenState extends State<MotoristaScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Timer? _timer;

  Future<void> _checkUserInfo() async {
    if (user != null) {
      final userEmail = user!.email ?? '';
      final docSnapshot =
          await firestore.collection('motos').doc(userEmail).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['estadoid'] == 0) {
          _showIncompleteInfoDialog();
        }
      }
    }
  }

  void _showIncompleteInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Información Incompleta'),
          content: const Text(
              'Por favor, completa tu información personal y agrega una ubicación.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserMoto(
                      userEmail: user?.email,
                    ),
                  ),
                );
              },
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inverseSurface,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Verificar y solicitar permisos de ubicación
    verificarPermisosUbicacion();
    // Escuchar cambios de ubicación
    iniciarActualizacionPeriodica();
    verificarEstadoMotoYMostrarDialogo(user!.email!);
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar el timer cuando el widget se destruya
    super.dispose();
  }

  void iniciarActualizacionPeriodica() {
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) async {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      actualizarUbicacionMotorista(position);
    });
  }

  Future<void> verificarPermisosUbicacion() async {
    bool serviciosHabilitados;
    LocationPermission permisos;

    serviciosHabilitados = await Geolocator.isLocationServiceEnabled();
    if (!serviciosHabilitados) {
      return Future.error('Los servicios de ubicación están deshabilitados.');
    }

    permisos = await Geolocator.checkPermission();
    if (permisos == LocationPermission.denied) {
      permisos = await Geolocator.requestPermission();
      if (permisos == LocationPermission.denied) {
        return Future.error('Los permisos de ubicación han sido denegados');
      }
    }

    if (permisos == LocationPermission.deniedForever) {
      return Future.error(
          'Los permisos de ubicación han sido denegados permanentemente, no se pueden solicitar permisos.');
    }
  }

  Future<void> actualizarUbicacionMotorista(Position position) async {
    User? user = _auth.currentUser;
    if (user == null) {
      print('Usuario no autenticado');
      return;
    }

    String userEmail = user.email!;
    DocumentSnapshot userDoc;

    try {
      userDoc = await _db.collection('motos').doc(userEmail).get();
      if (!userDoc.exists) {
        print('Documento de usuario no encontrado');
        return;
      }
    } catch (e) {
      print('Error al obtener el documento del usuario: $e');
      return;
    }

    String idmoto = userDoc['idmoto'];

    // Verificar si el estadoid del motorista es 2
    if (userDoc['estadoid'] != 2) {
      print(
          'El estadoid del motorista no es 2, no se actualizará la ubicación');
      return;
    }

    double latitude = position.latitude;
    double longitude = position.longitude;

    try {
      await _db.collection('motos').doc(userEmail).update({
        'ubicacionM': GeoPoint(latitude, longitude),
      });
    } catch (e) {
      print('Error al actualizar la ubicación: $e');
    }
  }

  Future<void> cerrarSesion() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser!.providerData
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
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'No se encontraron pedidos asignados para este motorista.',
      );
    }

    return pedidosSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<void> actualizarPedidoEnCamino(String pedidoId) async {
    DocumentReference pedidoRef = _db.collection('pedidos').doc(pedidoId);
    DocumentSnapshot pedidoDoc = await pedidoRef.get();

    if (!pedidoDoc.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'El pedido con ID $pedidoId no existe.',
      );
    }

    await pedidoRef.update({'estadoid': 3});
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
        .get();

    if (pedidosSnapshot.docs.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'No se encontraron pedidos asignados para este motorista.',
      );
    }

    if (pedidosSnapshot.docs.length >= 0) {
      WriteBatch batch = _db.batch();
      for (var doc in pedidosSnapshot.docs) {
        batch.update(doc.reference, {'estadoid': 3});
      }
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los pedidos han sido marcados como "En camino"'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {}); // Refresca la lista de pedidos
    } else {
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
          title: const Text('Solicitud para ser Motorista'),
          content: const Text('¿Quieres aceptar la solicitud para ser motorista?'),
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
            icon: const Icon(Icons.update),
            onPressed: () async {
              await actualizarPedidosEnCamino();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: obtenerPedidosAsignados(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error al obtener los pedidos'));
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
                    title: Text(pedido['idpedidos'] ?? 'Sin ID',
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
                                    if (pedido == null ||
                                        pedido['ubicacionCliente'] == null ||
                                        pedido['ubicacionM'] == null ||
                                        pedido['ubicacionNegocio'] == null) {
                                      throw Exception(
                                          'No se ha podido encontrar las ubicaciones del negocio o del cliente');
                                    }

                                    if (pedido['ubicacionCliente'].latitude == null ||
                                        pedido['ubicacionCliente'].longitude ==
                                            null ||
                                        pedido['ubicacionM'].latitude == null ||
                                        pedido['ubicacionM'].longitude ==
                                            null ||
                                        pedido['ubicacionNegocio'].latitude ==
                                            null ||
                                        pedido['ubicacionNegocio'].longitude ==
                                            null) {
                                      throw Exception(
                                          'Latitud o longitud nula en las ubicaciones');
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
                                                ),
                                                ubicacionM: LatLng(
                                                  pedido['ubicacionM'].latitude,
                                                  pedido['ubicacionM']
                                                      .longitude,
                                                )),
                                      ),
                                    );
                                  } catch (e, stackTrace) {
                                

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Error al obtener las ubicaciones: $e'),
                                        backgroundColor: Colors.red,
                                      ),
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
