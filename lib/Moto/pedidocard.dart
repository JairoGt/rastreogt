import 'package:fluttertoast/fluttertoast.dart';
import 'package:rastreogt/Moto/segundoplano.dart';
import 'package:rastreogt/conf/export.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rastreogt/Cliente/detalle_pedido.dart';
import 'package:rastreogt/Moto/motomaps.dart';

class PedidoCard extends StatefulWidget {
  final Map<String, dynamic> pedido;
  final VoidCallback onEstadoChanged;

  const PedidoCard({
    super.key,
    required this.pedido,
    required this.onEstadoChanged,
  });

  @override
  _PedidoCardState createState() => _PedidoCardState();
}

class _PedidoCardState extends State<PedidoCard> {
  bool _enCamino = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _enCamino = widget.pedido['estadoid'] == 3;
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        leading: const Icon(
          Icons.motorcycle,
        ),
        title: Text(widget.pedido['idpedidos'] ?? 'Sin ID',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        subtitle: Text(obtenerDescripcionEstado(widget.pedido['estadoid']),
            style: GoogleFonts.poppins()),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Dirección', widget.pedido['direccion']),
                _buildInfoRow('Cliente', widget.pedido['nickname']),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.map,
                      label: 'Ver ubicación',
                      onPressed: () => _abrirMapa(context),
                    ),
                    _buildActionButton(
                      icon: Icons.info,
                      label: 'Ver información',
                      onPressed: () => _mostrarDetalles(context),
                    ),
                    _buildActionButton(
                      icon: Icons.directions_bike,
                      label: 'En camino',
                      onPressed:
                          _enCamino ? null : () => _marcarEnCamino(context),
                    ),
                    _buildActionButton(
                      icon: Icons.done_all,
                      label: 'Entregado',
                      onPressed:
                          _enCamino ? () => _marcarEntregado(context) : null,
                    ),
                    _buildActionButton(
                      icon: Icons.cancel,
                      label: 'Cancelar',
                      onPressed: () => _mostrarDialogoCancelacion(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: GoogleFonts.poppins(),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  void _abrirMapa(BuildContext context) async {
    try {
      if (widget.pedido['ubicacionCliente'] == null ||
          widget.pedido['ubicacionNegocio'] == null) {
        throw Exception(
            'No se ha podido encontrar las ubicaciones del negocio o del cliente');
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MotoristaMapScreen(
            ubicacionCliente: LatLng(
              widget.pedido['ubicacionCliente'].latitude,
              widget.pedido['ubicacionCliente'].longitude,
            ),
            ubicacionNegocio: LatLng(
              widget.pedido['ubicacionNegocio'].latitude,
              widget.pedido['ubicacionNegocio'].longitude,
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      Fluttertoast.showToast(
        msg: 'Error al abrir el mapa: $e y $stackTrace',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 4,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _mostrarDetalles(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DetalleDialog(
          orderId: widget.pedido['idpedidos'],
        );
      },
    );
  }

  void _marcarEnCamino(BuildContext context) async {
    // lógica para marcar como en camino
    await actualizarPedidoEnCamino(widget.pedido['idpedidos']);
    setState(() {
      _enCamino = true;
    });
    widget.onEstadoChanged();
  }

  void _marcarEntregado(BuildContext context) async {
    //lógica para marcar como entregado
    await marcarPedidoComoEntregado(
        widget.pedido['idpedidos'], widget.pedido['idMotorista']);
    widget.onEstadoChanged();
  }

  void _mostrarDialogoCancelacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String razon = '';
        return AlertDialog(
          title: Text('Cancelar Pedido',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Por favor, indique la razón de la cancelación:',
                  style: GoogleFonts.poppins()),
              TextField(
                onChanged: (value) => razon = value,
                decoration: const InputDecoration(
                  hintText: 'Razón de cancelación',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar', style: GoogleFonts.poppins()),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Confirmar', style: GoogleFonts.poppins()),
              onPressed: () {
                // Implementar lógica para cancelar el pedido
                _cancelarPedido(razon);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _cancelarPedido(String razon) async {
    // logica para cancelar el pedido en Firestore
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(widget.pedido['idpedidos'])
        .update({
      'estadoid': 5, // Asumiendo que 5 es el estado para "Cancelado"
      'observaciones': razon,
    });
    widget.onEstadoChanged();
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
