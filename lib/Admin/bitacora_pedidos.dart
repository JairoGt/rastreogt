import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'package:printing/printing.dart';
import 'package:rastreogt/providers/pedidosProvider.dart';

final pedidosProvider = PedidosProvider();

class PedidosPage extends StatefulWidget {
  // ignore: use_key_in_widget_constructors
  const PedidosPage({Key? key});

  @override
  // ignore: library_private_types_in_public_api
  _PedidosPageState createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? nombreNegocio;
  User? user = FirebaseAuth.instance.currentUser;

  int _compareFechas(DocumentSnapshot<Object?> a, DocumentSnapshot<Object?> b) {
    return b['fechaCreacion']!.toDate().millisecondsSinceEpoch -
        a['fechaCreacion']!.toDate().millisecondsSinceEpoch;
  }

Future<void> _fetchNombreNegocio() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.email).get();
    setState(() {
      nombreNegocio = userDoc['negoname'];
    });
  }

Future<double> calcularTotalEntregado(List<DocumentSnapshot> pedidos) async {
  double totalEntregado = 0;

  for (var pedido in pedidos) {
    if (pedido['estadoid'] == 4) {
      totalEntregado += await calcularTotalPedido(pedido);
    }
  }

  return totalEntregado;
}

Future<double> calcularTotalPedido(DocumentSnapshot pedido) async {
  double total = 0;

  // Obtener la subcolección Productos
  final productosSnapshot = await pedido.reference.collection('Productos').get();
  final productos = productosSnapshot.docs;

  // Sumar el precio total de los productos
  for (var producto in productos) {
    total += producto['precioTotal'];
  }

  return total;
}

Future<void> generatePDF(
    BuildContext context, List<DocumentSnapshot<Object?>> data) async {
  final pdf = pw.Document();

  // Filtrar los pedidos según las fechas seleccionadas
  final pedidos = data.where((pedido) {
      final fechaCreacion = pedido['fechaCreacion'].toDate();
      return pedido['negoname'] == nombreNegocio &&
          (_fechaInicio == null || fechaCreacion.isAfter(_fechaInicio!)) &&
          (_fechaFin == null ||
              fechaCreacion.isBefore(_fechaFin!.add(const Duration(days: 1)))) &&
          (_fechaInicio != null ||
              _fechaFin != null ||
              fechaCreacion.isAtSameMomentAs(_fechaFin!));
    }).toList();

  // Sumar el precio total de los pedidos entregados
  double totalEntregado = 0;
  for (var pedido in pedidos) {
    if (pedido['estadoid'] == 4) {
      totalEntregado += await calcularTotalPedido(pedido);
    }
  }

  // Crear las filas de la tabla de manera asíncrona
  final tableRows = await Future.wait(pedidos.map((pedido) async {
    return pw.TableRow(
      children: <pw.Widget>[
        pw.Text(pedido['idpedidos'].toString()),
        pw.Text(pedido['direccion'] ?? ''),
        pw.Text(pedido['estadoid'] == 1
            ? ' CREADO '
            : pedido['estadoid'] == 2
                ? ' DESPACHADO '
                : pedido['estadoid'] == 3
                    ? ' EN CAMINO '
                    : pedido['estadoid'] == 4
                        ? ' ENTREGADO '
                        : ''),
        pw.Text('Q${await calcularTotalPedido(pedido)}'),
        pw.Text(DateFormat('d/M/y').format(pedido['fechaCreacion'].toDate())),
      ],
    );
  }).toList());

  pdf.addPage(
    pw.MultiPage(
      build: (context) {
        return [
          pw.Container(
            child: pw.Paragraph(
              text: '   Lista de pedidos      ',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
            ),
          ),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.IntrinsicColumnWidth(),
              1: const pw.IntrinsicColumnWidth(),
              2: const pw.IntrinsicColumnWidth(),
              3: const pw.IntrinsicColumnWidth(),
              4: const pw.IntrinsicColumnWidth(),
            },
            children: <pw.TableRow>[
              pw.TableRow(
                children: <pw.Widget>[
                  pw.Text('Tracking '),
                  pw.Text('Dirección'),
                  pw.Text('Estado'),
                  pw.Text('Total a pagar'),
                  pw.Text('Fecha de Pedido'),
                ],
              ),
              ...tableRows,
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Total entregado: Q$totalEntregado'),
        ];
      },
    ),
  );

  final bytes = await pdf.save();

  await Printing.sharePdf(bytes: bytes);

  // Obtener la ubicación de la carpeta de almacenamiento externo compartido
  final externalDir = await getExternalStorageDirectory();

  if (externalDir != null) {
    final pdfFile = File('${externalDir.path}/archivo.pdf');

    // Guardar el PDF en la carpeta de almacenamiento externo compartido
    await pdfFile.writeAsBytes(bytes);

    // Verificar si el archivo se ha guardado correctamente
    if (await pdfFile.exists()) {
      // Mostrar un cuadro de diálogo de éxito
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Éxito'),
            content: const Text('PDF guardado en la carpeta de Descargas'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar el cuadro de diálogo
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // Mostrar un cuadro de diálogo de error
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Error al guardar el PDF'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar el cuadro de diálogo
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  } else {
    // Manejar el caso en el que la carpeta de almacenamiento externo no esté disponible
    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text('No se pudo acceder a la carpeta de almacenamiento externo'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el cuadro de diálogo
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
@override
  void initState() {
    super.initState();
    _fetchNombreNegocio();
  }
Future<double> calcularTotalPedidos(DocumentSnapshot pedido) async {
  double total = 0;

  // Obtener la subcolección Productos
  final productosSnapshot = await pedido.reference.collection('Productos').get();
  final productos = productosSnapshot.docs;

  // Sumar el precio total de los productos
  for (var producto in productos) {
    total += producto['precioTotal'];
  }

  return total;
}
  int _selectedIndex = 0; // Índice del ítem seleccionado

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index; // Actualiza el ítem seleccionado
    });

    switch (index) {
      case 0:
        // Tu código aquí
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Aqui podras ver todos los pedidos que se han realizado, puedes ver el estado de cada uno de ellos, y tambien puedes generar un PDF con todos los pedidos que se han realizado hasta el momento\n'),
          ),
        );
        break;
      case 1:
        final fecha = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (fecha != null) {
          setState(() {
            _fechaInicio = fecha;
          });
        }
        break;
      case 2:
        // ignore: use_build_context_synchronously
        final fecha = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (fecha != null) {
          setState(() {
            _fechaFin = fecha;
          });
        }
        break;
      case 3:
        setState(() {
          _fechaInicio = null;
          _fechaFin = null;
        });
        break;
    }
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () async {
            final pedidos = await pedidosProvider.getPedidos(nombreNegocio!);
            // ignore: use_build_context_synchronously
            generatePDF(context, pedidos);
          },
          icon: const Icon(Icons.picture_as_pdf),
        )
      ],
      title: const Text('Pedidos'),
    ),
    body: FutureBuilder<List<DocumentSnapshot>>(
      future: pedidosProvider.getPedidos(nombreNegocio??""),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final pedidos = snapshot.data!;
          pedidos.sort(_compareFechas);

          // Filtrar los pedidos según las fechas seleccionadas y el nombre del negocio
          if (_fechaInicio != null && _fechaFin != null) {
            pedidos.retainWhere((pedido) {
              final fechaCreacion = pedido['fechaCreacion'].toDate();
              // Asegúrate de que 'nombreNegocio' esté definido y coincida con el campo 'negoname'
              return pedido['negoname'] == nombreNegocio &&
                  (fechaCreacion.isAtSameMomentAs(_fechaInicio!) ||
                      (fechaCreacion.isAfter(_fechaInicio!) &&
                          fechaCreacion.isBefore(_fechaFin!.add(const Duration(days: 1)))));
            });
          }

          return FutureBuilder<double>(
            future: calcularTotalEntregado(pedidos),
            builder: (context, totalSnapshot) {
              if (totalSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final totalEntregado = totalSnapshot.data ?? 0;

              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Tracking')),
                      DataColumn(label: Text('Dirección')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Total a pagar')),
                      DataColumn(label: Text('Fecha de Pedido')),
                    ],
                    rows: [
                      ...pedidos.map((pedido) => DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  pedido['idpedidos'].toString(),
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataCell(Text(pedido['direccion'] ?? '')),
                              DataCell(pedido['estadoid'] == 1
                                  ? const Text('(CREADO)',
                                      style: TextStyle(color: Colors.green))
                                  : pedido['estadoid'] == 2
                                      ? const Text('(DESPACHADO)',
                                          style: TextStyle(
                                              color: Colors.yellow,
                                              fontWeight: FontWeight.bold))
                                      : pedido['estadoid'] == 3
                                          ? const Text('(EN CAMINO)',
                                              style: TextStyle(color: Colors.orange))
                                          : pedido['estadoid'] == 4
                                              ? const Text('(ENTREGADO)',
                                                  style: TextStyle(color: Colors.red))
                                              : const Text('')),
                              DataCell(
                                FutureBuilder<double>(
                                  future: calcularTotalPedido(pedido),
                                  builder: (context, totalSnapshot) {
                                    if (totalSnapshot.connectionState == ConnectionState.waiting) {
                                      return const Text('Cargando...');
                                    }
                                    return Text('Q${totalSnapshot.data ?? 0}');
                                  },
                                ),
                              ),
                              DataCell(Text(DateFormat('d/M/y')
                                  .format(pedido['fechaCreacion'].toDate()))),
                            ],
                          )),
                      DataRow(
                        cells: [
                          const DataCell(Text('')),
                          const DataCell(Text('')),
                          const DataCell(Text('')),
                          DataCell(Text(
                              'Total de pedidos \nEntregados: ----> Q$totalEntregado',
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                          const DataCell(Text('')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    ),
    bottomNavigationBar: ConvexAppBar(
      style: TabStyle.react,
      backgroundColor: Colors.black,
      gradient: const LinearGradient(
        colors: [Colors.green, Colors.black],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      items: const [
        TabItem(icon: Icons.help, title: 'Ayuda'),
        TabItem(
          icon: Icons.calendar_today,
          title: 'Fecha Inicio',
        ),
        TabItem(icon: Icons.date_range, title: 'Fecha Fin'),
        TabItem(icon: Icons.refresh, title: 'Limpiar'),
        //TabItem(icon: Icons.home, title: 'Inicio'),
      ],
      initialActiveIndex: _selectedIndex, //optional, default as 0
      onTap: _onItemTapped,
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
  );
}
}