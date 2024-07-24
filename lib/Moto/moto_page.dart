import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class MotoristaScreen extends StatefulWidget {
  @override
  _MotoristaScreenState createState() => _MotoristaScreenState();
}

class _MotoristaScreenState extends State<MotoristaScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedidos Asignados'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
                    leading: Icon(Icons.motorcycle, color: Theme.of(context).primaryColor),
                    title: Text(pedido['idpedidos'] ?? 'Sin ID', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Dirección: ${pedido['direccion']}'),
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
    );
  }
}