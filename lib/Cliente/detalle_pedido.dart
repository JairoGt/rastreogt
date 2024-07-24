import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class DetalleDialog extends StatelessWidget {
  final String orderId;

  const DetalleDialog({super.key, required this.orderId});

  Future<Map<String, dynamic>> _fetchProductDetails() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(orderId)
        .collection('Productos')
        .get();

    double totalPrice = 0;
    List<Map<String, dynamic>> products = [];

    for (var producto in snapshot.docs) {
      final data = producto.data();
      for (int i = 1; i <= 5; i++) {
        final nombreKey = 'producto$i';
        final precioKey = 'precio$i';
        if (data.containsKey(nombreKey) && data.containsKey(precioKey)) {
          final nombre = data[nombreKey]?.toString() ?? '';
          final precio = data[precioKey]?.toString() ?? '';
          if (nombre.isNotEmpty && precio.isNotEmpty) {
            products.add({'nombre': nombre, 'precio': double.parse(precio)});
            totalPrice += double.parse(precio);
          }
        }
      }
    }

    return {'products': products, 'totalPrice': totalPrice};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchProductDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final products = snapshot.data!['products'] as List<Map<String, dynamic>>;
          final totalPrice = snapshot.data!['totalPrice'] as double;

          return AlertDialog(
            title: Text('Detalles de Productos', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...products.map((product) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        '${product['nombre']}: Q${product['precio'].toStringAsFixed(2)}',
                        style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Text(
                    'Precio Total: Q${totalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cerrar', style: GoogleFonts.poppins()),
              ),
            ],
          );
        }
      },
    );
  }
}