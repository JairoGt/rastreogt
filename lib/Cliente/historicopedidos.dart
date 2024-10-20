import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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

  Future<void> exportarPedidosAPdf(List<Pedido> pedidos) async {
    final pdf = pw.Document();
    final themeColor = PdfColor.fromHex("#4a148c");
    final accentColor = PdfColor.fromHex("#7c43bd");
    final imageData = await rootBundle.load('assets/images/oficial2.png');
    final image = pw.MemoryImage(imageData.buffer.asUint8List());

    final pedidosConfirmados = pedidos.where((p) => p.estado == 4).toList();
    final pedidosCancelados = pedidos.where((p) => p.estado == 5).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Histórico de Pedidos',
                    style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: themeColor),
                  ),
                  pw.Container(
                    width: 50,
                    height: 50,
                    decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle, color: accentColor),
                    child: pw.Center(child: pw.Image(image)),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Paragraph(
                text: 'Resumen de pedidos realizados',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
            pw.SizedBox(height: 20),
            _buildPedidosTable(pedidosConfirmados, 'Pedidos Confirmados'),
            pw.SizedBox(height: 20),
            _buildPedidosTable(pedidosCancelados, 'Pedidos Cancelados'),
            pw.SizedBox(height: 20),
            _buildResumenFinanciero(pedidosConfirmados, pedidosCancelados),
          ];
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: pw.TextStyle(color: PdfColors.grey),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'El camino hacia el éxito y el camino hacia el fracaso son exactamente el mismo camino.',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPedidosTable(List<Pedido> pedidos, String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          border: null,
          headerStyle: pw.TextStyle(
              color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          headerDecoration:
              pw.BoxDecoration(color: PdfColor.fromHex("#4a148c")),
          cellHeight: 30,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerRight
          },
          headerPadding: const pw.EdgeInsets.all(5),
          cellPadding: const pw.EdgeInsets.all(5),
          data: [
            ['Número de Seguimiento', 'Fecha', 'Cantidad Total', 'Estado'],
            ...pedidos.map((pedido) => [
                  pedido.numeroSeguimiento,
                  DateFormat('dd/MM/yyyy').format(pedido.fecha),
                  'Q${pedido.cantidadTotal.toStringAsFixed(2)}',
                  getEstadoDescripcion(pedido.estado),
                ]),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildResumenFinanciero(
      List<Pedido> pedidosConfirmados, List<Pedido> pedidosCancelados) {
    final totalPedidosConfirmados = pedidosConfirmados.length;
    final montoTotalConfirmados = pedidosConfirmados.fold(
        0.0, (sum, pedido) => sum + pedido.cantidadTotal);
    final promedioMontoConfirmados = totalPedidosConfirmados > 0
        ? montoTotalConfirmados / totalPedidosConfirmados
        : 0.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex("#4a148c"), width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Resumen de Gastos',
              style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex("#4a148c"))),
          pw.SizedBox(height: 10),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total de Pedidos Confirmados:'),
                pw.Text('$totalPedidosConfirmados',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold))
              ]),
          pw.SizedBox(height: 5),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Monto Total Confirmados:'),
                pw.Text('Q${montoTotalConfirmados.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold))
              ]),
          pw.SizedBox(height: 5),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Promedio por Pedido Confirmado:'),
                pw.Text('Q${promedioMontoConfirmados.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold))
              ]),
          pw.SizedBox(height: 10),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total de Pedidos Cancelados:'),
                pw.Text('${pedidosCancelados.length}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold))
              ]),
        ],
      ),
    );
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
              await exportarPedidosAPdf(pedidos);
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
                      final isCancelled = pedido.estado == 5;
                      final estadoDescripcion =
                          getEstadoDescripcion(pedido.estado);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        color: isCancelled ? Colors.red[300] : null,
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Pedido #${pedido.numeroSeguimiento}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.0),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                      text: pedido.numeroSeguimiento));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'ID de pedido copiado al portapapeles')),
                                  );
                                },
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8.0),
                              Text(
                                  'Fecha: ${DateFormat('dd/MM/yyyy').format(pedido.fecha)}',
                                  style: TextStyle(color: Colors.grey[700])),
                              const SizedBox(height: 4.0),
                              Text(
                                  'Total: Q${pedido.cantidadTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4.0),
                              Text('Estado: $estadoDescripcion',
                                  style: TextStyle(
                                      color: isCancelled
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
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
