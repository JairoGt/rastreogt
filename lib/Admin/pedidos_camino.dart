import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rastreogt/Cliente/mapasuy.dart'; // Asegúrate de que esta importación sea correcta

class PedidosCamino extends StatelessWidget {
  final String negoname;

  const PedidosCamino({super.key, required this.negoname});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos en Camino'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .where('estadoid', isEqualTo: 3)
            .where('negoname', isEqualTo: negoname)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay pedidos en camino.'));
          }

          final pedidos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          pedido['nickname'][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        'Pedido ID: ${pedido.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Cliente: ${pedido['nickname']}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetallePedido(pedido: pedido),
                          ),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.map),
                      label: const Text('Ver ubicaciones'),
                      onPressed: () {
                        _abrirMapa(context, pedido);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _abrirMapa(BuildContext context, DocumentSnapshot pedido) async {
    try {
      // Obtener los detalles del motorista
      final motoristaDoc = await FirebaseFirestore.instance
          .collection('motos')
          .doc(pedido['idMotorista'])
          .get();

      if (!motoristaDoc.exists) {
        throw Exception(
            'No se ha podido encontrar la información del motorista');
      }

      final motoristaDetails = motoristaDoc.data()!;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapScreen(
            emailM: motoristaDetails['email'],
            idMotorista: pedido['idMotorista'],
            ubicacionCliente: LatLng(
              pedido['ubicacionCliente'].latitude,
              pedido['ubicacionCliente'].longitude,
            ),
            ubicacionNegocio: LatLng(
              pedido['ubicacionNegocio'].latitude,
              pedido['ubicacionNegocio'].longitude,
            ),
            ubicacionM: LatLng(
              motoristaDetails['latitude'] ?? 0.0,
              motoristaDetails['longitude'] ?? 0.0,
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir el mapa: $e')),
      );
    }
  }
}

class DetallePedido extends StatelessWidget {
  final DocumentSnapshot pedido;

  const DetallePedido({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Pedido'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido ID: ${pedido.id}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cliente: ${pedido['nickname']}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dirección: ${pedido['direccion']}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estado: ${pedido['estadoid']}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text('Ver ubicaciones'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _abrirMapa(context, pedido);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirMapa(BuildContext context, DocumentSnapshot pedido) async {
    try {
      // Obtener los detalles del motorista
      final motoristaDoc = await FirebaseFirestore.instance
          .collection('motos')
          .doc(pedido['idMotorista'])
          .get();

      if (!motoristaDoc.exists) {
        throw Exception(
            'No se ha podido encontrar la información del motorista');
      }

      final motoristaDetails = motoristaDoc.data()!;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapScreen(
            emailM: motoristaDetails['email'],
            idMotorista: pedido['idMotorista'],
            ubicacionCliente: LatLng(
              pedido['ubicacionCliente'].latitude,
              pedido['ubicacionCliente'].longitude,
            ),
            ubicacionNegocio: LatLng(
              pedido['ubicacionNegocio'].latitude,
              pedido['ubicacionNegocio'].longitude,
            ),
            ubicacionM: LatLng(
              motoristaDetails['latitude'] ?? 0.0,
              motoristaDetails['longitude'] ?? 0.0,
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir el mapa: $e')),
      );
    }
  }
}
