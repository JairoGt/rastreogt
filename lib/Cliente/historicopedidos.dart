import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Pedido {
  final String numeroSeguimiento;
  final DateTime fecha;
  final double cantidadTotal;

  Pedido({
    required this.numeroSeguimiento,
    required this.fecha,
    required this.cantidadTotal,
  });

  factory Pedido.fromFirestore(Map<String, dynamic> data, double cantidadTotal) {
    return Pedido(
      numeroSeguimiento: data['idpedidos'] ?? 'Desconocido',
      fecha: (data['fechadespacho'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cantidadTotal: cantidadTotal,
    );
  }
}

class HistoricoPedidosScreen extends StatefulWidget {
  final String email;

  const HistoricoPedidosScreen({super.key, required this.email});

  @override
  _HistoricoPedidosScreenState createState() => _HistoricoPedidosScreenState();
}

Future<List<Pedido>> obtenerPedidos(String email) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('pedidos')
      .where('idcliente', isEqualTo: email)
      .get();

  List<Pedido> pedidos = [];

  for (var doc in querySnapshot.docs) {
    final subCollectionSnapshot = await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(doc.id)
        .collection('Productos')
        .get();

    double cantidadTotal = 0.0;
    for (var subDoc in subCollectionSnapshot.docs) {
      cantidadTotal += (subDoc.data()['precioTotal'] as num?)?.toDouble() ?? 0.0;
    }

    pedidos.add(Pedido.fromFirestore(doc.data(), cantidadTotal));
  }

  return pedidos;
}

List<Pedido> filtrarPedidosPorFecha(List<Pedido> pedidos, DateTime fechaInicio, DateTime fechaFin) {
  return pedidos.where((pedido) {
    return pedido.fecha.isAfter(fechaInicio) && pedido.fecha.isBefore(fechaFin);
  }).toList();
}

class _HistoricoPedidosScreenState extends State<HistoricoPedidosScreen> {
  late Future<List<Pedido>> _futurePedidos;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _futurePedidos = obtenerPedidos(widget.email);
  }

  Future<void> _selectFechaInicio(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _fechaInicio) {
      setState(() {
        _fechaInicio = picked;
      });
    }
  }

  Future<void> _selectFechaFin(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _fechaFin) {
      setState(() {
        _fechaFin = picked;
      });
    }
  }

  void _filtrarPedidos() {
    setState(() {
      _futurePedidos = obtenerPedidos(widget.email).then((pedidos) {
        if (_fechaInicio != null && _fechaFin != null) {
          return filtrarPedidosPorFecha(pedidos, _fechaInicio!, _fechaFin!);
        }
        return pedidos;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Pedidos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectFechaInicio(context),
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: _fechaInicio != null
                              ? '${_fechaInicio!}'.split(' ')[0]
                              : 'Selecciona Fecha Inicio',
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectFechaFin(context),
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: _fechaFin != null
                              ? '${_fechaFin!}'
                              : 'Selecciona Fecha Fin',
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _filtrarPedidos,
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Pedido>>(
              future: _futurePedidos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay pedidos disponibles.'));
                } else {
                  final pedidos = snapshot.data!;
                  return ListView.builder(
                    itemCount: pedidos.length,
                    itemBuilder: (context, index) {
                      final pedido = pedidos[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 5,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                          title: Text(
                            'Número de Seguimiento: ${pedido.numeroSeguimiento}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 5.0),
                              Text('Fecha: ${pedido.fecha}'),
                              Text('Cantidad Total: Q${pedido.cantidadTotal.toStringAsFixed(2)}'),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Acción al presionar sobre el pedido
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
