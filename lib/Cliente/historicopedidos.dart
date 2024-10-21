import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:rastreogt/Cliente/exportPDF.dart';
import 'package:rastreogt/Cliente/seguimiento.dart';
import 'package:rastreogt/conf/export.dart';

class Pedido {
  final String numeroSeguimiento;
  final DateTime fecha;
  final double cantidadTotal;
  final int? estado;

  Pedido({
    required this.numeroSeguimiento,
    required this.fecha,
    required this.cantidadTotal,
    required this.estado,
  });

  factory Pedido.fromFirestore(
      Map<String, dynamic> data, double cantidadTotal) {
    return Pedido(
      estado: data['estadoid'] ?? 'Desconocido',
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

class _HistoricoPedidosScreenState extends State<HistoricoPedidosScreen> {
  late Future<List<Pedido>> _futurePedidos;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();

  String getEstadoDescripcion(int? estado) {
    switch (estado) {
      case 1:
        return 'Creado';
      case 2:
        return 'Despachado';
      case 3:
        return 'En camino';
      case 4:
        return 'Entregado';
      case 5:
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  @override
  void initState() {
    super.initState();
    _futurePedidos = obtenerPedidos(widget.email);
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
        cantidadTotal +=
            (subDoc.data()['precioTotal'] as num?)?.toDouble() ?? 0.0;
      }

      pedidos.add(Pedido.fromFirestore(doc.data(), cantidadTotal));
    }

    return pedidos;
  }

  List<Pedido> filtrarPedidosPorFecha(
      List<Pedido> pedidos, DateTime fechaInicio, DateTime fechaFin) {
    return pedidos.where((pedido) {
      return pedido.fecha
              .isAfter(fechaInicio.subtract(const Duration(days: 1))) &&
          pedido.fecha.isBefore(fechaFin.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> _selectFecha(BuildContext context, bool esInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: esInicio
          ? _fechaInicio ?? DateTime.now()
          : _fechaFin ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = picked;
          _fechaInicioController.text = DateFormat('dd/MM/yyyy').format(picked);
        } else {
          _fechaFin = picked;
          _fechaFinController.text = DateFormat('dd/MM/yyyy').format(picked);
        }
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

  Future<Map<String, dynamic>> _fetchProductDetails(String orderId) async {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final pedidos = await _futurePedidos;
              await PdfExporter.exportarPedidosAPdf(pedidos);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtrar por fecha',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fechaInicioController,
                            decoration: InputDecoration(
                              labelText: 'Fecha Inicio',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () => _selectFecha(context, true),
                              ),
                            ),
                            readOnly: true,
                            onTap: () => _selectFecha(context, true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _fechaFinController,
                            decoration: InputDecoration(
                              labelText: 'Fecha Fin',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () => _selectFecha(context, false),
                              ),
                            ),
                            readOnly: true,
                            onTap: () => _selectFecha(context, false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.search),
                        label: const Text('Buscar'),
                        onPressed: _filtrarPedidos,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Pedido>>(
              future: _futurePedidos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text(
                          'No hay pedidos disponibles para las fechas seleccionadas.'));
                } else {
                  final pedidos = snapshot.data!;
                  return ListView.builder(
                    itemCount: pedidos.length,
                    itemBuilder: (context, index) {
                      final pedido = pedidos[index];
                      return InteractiveCard(
                        pedido: pedido,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProcessTimelinePage(
                                idPedidos: pedido.numeroSeguimiento,
                              ),
                            ),
                          );
                        },
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

String getEstadoDescripcion(int? estado) {
  switch (estado) {
    case 1:
      return 'Creado';
    case 2:
      return 'Despachado';
    case 3:
      return 'En camino';
    case 4:
      return 'Entregado';
    case 5:
      return 'Cancelado';
    default:
      return 'Desconocido';
  }
}

class InteractiveCard extends StatefulWidget {
  final Pedido pedido;
  final VoidCallback onTap;

  const InteractiveCard({
    super.key,
    required this.pedido,
    required this.onTap,
  });

  @override
  _InteractiveCardState createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Definimos los colores para el modo claro y oscuro
    final lightGrey = Colors.grey[100]!;
    final darkGrey = const Color.fromARGB(162, 66, 66, 66);
    final cardColor = isDarkMode ? darkGrey : lightGrey;
    final isCancelled = widget.pedido.estado == 5;
    final estadoDescripcion = getEstadoDescripcion(widget.pedido.estado);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.2 : 0.1),
              blurRadius: _isHovered ? 8 : 4,
              spreadRadius: _isHovered ? 2 : 0,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Material(
          color: isCancelled ? Colors.red[300] : cardColor,
          elevation: 3,
          borderRadius: BorderRadius.circular(12.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(12.0),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${widget.pedido.numeroSeguimiento}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy').format(widget.pedido.fecha)}',
                    style: TextStyle(
                        color:
                            isDarkMode ? Colors.grey[300] : Colors.grey[700]),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Total: Q${widget.pedido.cantidadTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Estado: $estadoDescripcion',
                    style: TextStyle(
                      color: isCancelled ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
