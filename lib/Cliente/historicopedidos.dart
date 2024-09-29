// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class Pedido {
  final String numeroSeguimiento;
  final DateTime fecha;
  final double cantidadTotal;

  Pedido({
    required this.numeroSeguimiento,
    required this.fecha,
    required this.cantidadTotal,
  });

  factory Pedido.fromFirestore(
      Map<String, dynamic> data, double cantidadTotal) {
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
    return (pedido.fecha.isAfter(fechaInicio) ||
            pedido.fecha.isAtSameMomentAs(fechaInicio)) &&
        (pedido.fecha.isBefore(fechaFin) ||
            pedido.fecha.isAtSameMomentAs(fechaFin));
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
          // Ajustar horas de las fechas
          final inicio = DateTime(
              _fechaInicio!.day, _fechaInicio!.month, _fechaInicio!.year);
          final fin = DateTime(
              _fechaInicio!.day, _fechaInicio!.month, _fechaInicio!.year);

          return filtrarPedidosPorFecha(pedidos, inicio, fin);
        }
        return pedidos;
      });
    });
  }

  Future<void> exportarPedidosAPdf(List<Pedido> pedidos) async {
    final pdf = pw.Document();

    final themeColor = PdfColor.fromHex("#4a148c"); // Color morado oscuro
    final accentColor = PdfColor.fromHex("#7c43bd"); // Color morado más claro
    final imageData = await rootBundle.load('assets/images/oficial2.png');
    final image = pw.MemoryImage(imageData.buffer.asUint8List());

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
                      color: themeColor,
                    ),
                  ),
                  pw.Container(
                    width: 50,
                    height: 50,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: accentColor,
                    ),
                    child: pw.Center(child: pw.Image(image)),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Paragraph(
              text: 'Resumen de pedidos realizados',
              style: const pw.TextStyle(
                fontSize: 14,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 20),
            _buildPedidosTable(pedidos),
            pw.SizedBox(height: 20),
            _buildResumenFinanciero(pedidos),
          ];
        },
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey),
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPedidosTable(List<Pedido> pedidos) {
    return pw.TableHelper.fromTextArray(
      border: null,
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: pw.BoxDecoration(
        color: PdfColor.fromHex("#4a148c"),
      ),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
      },
      headerPadding: const pw.EdgeInsets.all(5),
      cellPadding: const pw.EdgeInsets.all(5),
      data: [
        ['Número de Seguimiento', 'Fecha', 'Cantidad Total'],
        ...pedidos.map((pedido) => [
              pedido.numeroSeguimiento,
              DateFormat('dd/MM/yyyy').format(pedido.fecha),
              'Q${pedido.cantidadTotal.toStringAsFixed(2)}',
            ]),
      ],
    );
  }

  pw.Widget _buildResumenFinanciero(List<Pedido> pedidos) {
    final totalPedidos = pedidos.length;
    final montoTotal =
        pedidos.fold(0.0, (sum, pedido) => sum + pedido.cantidadTotal);
    final promedioMonto = montoTotal / totalPedidos;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex("#4a148c"), width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resumen Financiero',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex("#4a148c"),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total de Pedidos:'),
              pw.Text('$totalPedidos',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Monto Total:'),
              pw.Text('Q${montoTotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Promedio por Pedido:'),
              pw.Text('Q${promedioMonto.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
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
                              : 'Fecha Inicio',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectFechaFin(context),
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: _fechaFin != null
                              ? '${_fechaFin!}'.split(' ')[0]
                              : 'Fecha Fin',
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
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
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No hay pedidos disponibles.'));
                } else {
                  final pedidos = snapshot.data!;
                  return ListView.builder(
                    itemCount: pedidos.length,
                    itemBuilder: (context, index) {
                      final pedido = pedidos[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 5,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 10.0),
                          title: Text(
                            'Número de Seguimiento: ${pedido.numeroSeguimiento}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5.0),
                              Text('Fecha: ${pedido.fecha}'),
                              Text(
                                  'Cantidad Total: Q${pedido.cantidadTotal.toStringAsFixed(2)}'),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
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
