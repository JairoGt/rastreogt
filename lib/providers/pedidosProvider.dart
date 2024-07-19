import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PedidosProvider extends ChangeNotifier {
  // ...

  // Obtiene la lista de pedidos que coinciden con el negoname
  Future<List<DocumentSnapshot>> getPedidos(String negoname) async {
    // Obtenemos la colección de pedidos
    final firestore = FirebaseFirestore.instance;
    final pedidosCollection = firestore.collection('pedidos');

    // Realizamos la consulta con el filtro por negoname
    final pedidos = await pedidosCollection
        .where('negoname', isEqualTo: negoname)
        .get();

    // Notificamos a los listeners
    notifyListeners();

    // Devolvemos la lista de documentos
    return pedidos.docs;
  }
}

class UsuariosProvider extends ChangeNotifier {
  // Colección de usuarios en Firestore
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  // Lista de usuarios
  List<DocumentSnapshot> _usuarios = [];

  // Lista de motoristas
  List<DocumentSnapshot> _motoristas = [];

  // Obtiene la lista de usuarios
  Future<List<DocumentSnapshot>> getUsuarios() async {
    // Obtenemos la lista de usuarios de Firestore
    _usuarios = await _usersCollection.get().then((querySnapshot) {
      return querySnapshot.docs;
    });

    // Actualizamos la lista de usuarios
    notifyListeners();

    return _usuarios;
  }

  // Actualiza un pedido
  void updatePedido(String id, String campo, String valor) async {
    // Actualizamos el campo 'idMotorista' del pedido
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(id)
        .update({campo: valor});
  }

  // Obtiene la lista de motoristas
  Future<List<DocumentSnapshot>> getMotoristas() async {
    // Obtenemos la lista de motoristas de Firestore
    _motoristas = await _usersCollection
        .where('role', isEqualTo: 'moto')
        .get()
        .then((querySnapshot) {
      return querySnapshot.docs;
    });

    // Actualizamos la lista de motoristas
    notifyListeners();

    return _motoristas;
  }

  static of(BuildContext context) {}
}