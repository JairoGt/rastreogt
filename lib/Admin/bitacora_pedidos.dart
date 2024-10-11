import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:rastreogt/conf/export.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

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
  final GlobalKey<_PedidosPageState> myWidgetKey = GlobalKey();

  int _compareFechas(DocumentSnapshot<Object?> a, DocumentSnapshot<Object?> b) {
    return b['fechaCreacion']!.toDate().millisecondsSinceEpoch -
        a['fechaCreacion']!.toDate().millisecondsSinceEpoch;
  }

  Future<void> _fetchNombreNegocio() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.email)
        .get();
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
    final productosSnapshot =
        await pedido.reference.collection('Productos').get();
    final productos = productosSnapshot.docs;

    // Sumar el precio total de los productos
    for (var producto in productos) {
      total += producto['precioTotal'];
    }

    return total;
  }

  Future<void> generateModernPDF(
      BuildContext context, List<DocumentSnapshot<Object?>> data) async {
    final pdf = pw.Document();

    // Filtrar los pedidos según las fechas seleccionadas
    final pedidos = data.where((pedido) {
      final fechaCreacion = pedido['fechaCreacion']?.toDate();
      final negocio = pedido['negoname'] as String?;

      if (fechaCreacion == null ||
          negocio == null ||
          negocio != nombreNegocio) {
        return false;
      }

      bool dentroDeRango = true;

      if (_fechaInicio != null) {
        dentroDeRango = dentroDeRango && fechaCreacion.isAfter(_fechaInicio!);
      }

      if (_fechaFin != null) {
        dentroDeRango = dentroDeRango &&
            fechaCreacion.isBefore(_fechaFin!.add(const Duration(days: 1)));
      }

      return dentroDeRango;
    }).toList();

    // Contar pedidos entregados y cancelados
    int pedidosEntregados = 0;
    int pedidosCancelados = 0;
    double totalEntregado = 0;

    for (var pedido in pedidos) {
      if (pedido['estadoid'] == 4) {
        pedidosEntregados++;
        totalEntregado += await calcularTotalPedido(pedido);
      } else if (pedido['estadoid'] == 5) {
        pedidosCancelados++;
      }
    }

    // Crear las filas de la tabla de manera asíncrona
    final tableRows = await Future.wait(pedidos.map((pedido) async {
      return pw.TableRow(
        children: <pw.Widget>[
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(pedido['idpedidos'].toString()),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(pedido['direccion'] ?? ''),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(
              pedido['estadoid'] == 1
                  ? 'CREADO'
                  : pedido['estadoid'] == 2
                      ? 'DESPACHADO'
                      : pedido['estadoid'] == 3
                          ? 'EN CAMINO'
                          : pedido['estadoid'] == 4
                              ? 'ENTREGADO'
                              : pedido['estadoid'] == 5
                                  ? 'CANCELADO'
                                  : '',
              style: pw.TextStyle(
                color: pedido['estadoid'] == 4
                    ? PdfColors.green
                    : pedido['estadoid'] == 5
                        ? PdfColors.red
                        : pedido['estadoid'] == 3
                            ? PdfColors.orange
                            : pedido['estadoid'] == 2
                                ? PdfColors.yellow
                                : PdfColors.black,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text('Q${await calcularTotalPedido(pedido)}'),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(
                DateFormat('d/M/y').format(pedido['fechaCreacion'].toDate())),
          ),
        ],
      );
    }).toList());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Reporte de Pedidos',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Total de pedidos: ${pedidos.length}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Pedidos entregados: $pedidosEntregados',
                          style: const pw.TextStyle(color: PdfColors.green)),
                      pw.Text('Pedidos cancelados: $pedidosCancelados',
                          style: const pw.TextStyle(color: PdfColors.red)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Total entregado:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Q${totalEntregado.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
              },
              children: <pw.TableRow>[
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: <pw.Widget>[
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Tracking',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Dirección',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Estado',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Fecha',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ...tableRows,
              ],
            ),
          ];
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'El camino hacia el éxito y el camino hacia el fracaso son exactamente el mismo camino',
              style: pw.TextStyle(
                fontSize: 10,
                font: pw.Font.helveticaBold(),
                color: PdfColors.grey700,
              ),
              textAlign: pw.TextAlign.center,
            ),
          );
        },
      ),
    );
    final bytes = await pdf.save();

    // Imprimir el PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
    );

    // Guardar el PDF en la carpeta de descargas
    final downloadsDir = await getExternalStorageDirectory();
    final file = File('${downloadsDir?.path}/reporte_pedidos.pdf');
    await file.writeAsBytes(bytes);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF generado'),
          content: const Text(
              'El reporte se ha guardado en la carpeta de Descargas y se ha abierto para imprimir.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
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
    final productosSnapshot =
        await pedido.reference.collection('Productos').get();
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
              generateModernPDF(context, pedidos);
            },
            icon: const Icon(Icons.picture_as_pdf),
          )
        ],
        title: const Text('Pedidos'),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: pedidosProvider.getPedidos(nombreNegocio ?? ""),
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
                            fechaCreacion.isBefore(
                                _fechaFin!.add(const Duration(days: 1)))));
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
                                        style:
                                            TextStyle(color: Colors.blueGrey))
                                    : pedido['estadoid'] == 2
                                        ? const Text('(DESPACHADO)',
                                            style: TextStyle(
                                                color: Colors.yellow,
                                                fontWeight: FontWeight.bold))
                                        : pedido['estadoid'] == 3
                                            ? const Text('(EN CAMINO)',
                                                style: TextStyle(
                                                    color: Colors.orange))
                                            : pedido['estadoid'] == 4
                                                ? const Text('(ENTREGADO)',
                                                    style: TextStyle(
                                                        color: Color.fromARGB(
                                                            255, 4, 137, 64)))
                                                : pedido['estadoid'] == 5
                                                    ? const Text('(CANCELADO)',
                                                        style: TextStyle(
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    112,
                                                                    2,
                                                                    2)))
                                                    : const Text('')),
                                DataCell(
                                  FutureBuilder<double>(
                                    future: calcularTotalPedido(pedido),
                                    builder: (context, totalSnapshot) {
                                      if (totalSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Text('Cargando...');
                                      }
                                      return Text(
                                          'Q${totalSnapshot.data ?? 0}');
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color.fromARGB(255, 39, 35, 60), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SalomonBottomBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            SalomonBottomBarItem(
              icon: const Icon(Icons.help),
              title: const Text("Ayuda"),
              selectedColor: Colors.green,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.calendar_today),
              title: const Text("Fecha Inicio"),
              selectedColor: Colors.green,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.date_range),
              title: const Text("Fecha Fin"),
              selectedColor: Colors.green,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.refresh),
              title: const Text("Limpiar"),
              selectedColor: Colors.green,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
