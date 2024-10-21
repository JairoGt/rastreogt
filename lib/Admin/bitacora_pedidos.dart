import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rastreogt/Admin/pdfadmin.dart';
import 'package:rastreogt/conf/export.dart';
import 'package:fl_chart/fl_chart.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({Key? key}) : super(key: key);

  @override
  _PedidosPageState createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  final PDFGenerator pdfGenerator = PDFGenerator();
  final PedidosProvider pedidosProvider = PedidosProvider();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? nombreNegocio;
  User? user = FirebaseAuth.instance.currentUser;
  bool _isGeneratingPDF = false;

  @override
  void initState() {
    super.initState();
    _fetchNombreNegocio();
  }

  Future<void> _generatePDF() async {
    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      final pedidos = await pedidosProvider.getPedidos(nombreNegocio!);
      final pedidosFiltrados = _filtrarPedidos(pedidos);
      await pdfGenerator.generateModernPDF(
          context, pedidosFiltrados, nombreNegocio!, _fechaInicio, _fechaFin);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar el PDF: $e')),
      );
    } finally {
      setState(() {
        _isGeneratingPDF = false;
      });
    }
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

  List<DocumentSnapshot> _filtrarPedidos(List<DocumentSnapshot> pedidos) {
    return pedidos.where((pedido) {
      final fechaCreacion = pedido['fechaCreacion'].toDate();
      bool dentroDeRango = true;

      if (_fechaInicio != null) {
        dentroDeRango = dentroDeRango && fechaCreacion.isAfter(_fechaInicio!);
      }
      if (_fechaFin != null) {
        dentroDeRango = dentroDeRango &&
            fechaCreacion.isBefore(_fechaFin!.add(const Duration(days: 1)));
      }

      return pedido['negoname'] == nombreNegocio && dentroDeRango;
    }).toList();
  }

  Widget _buildEstadisticas(List<DocumentSnapshot> pedidos) {
    int totalPedidos = pedidos.length;
    int pedidosEntregados = pedidos.where((p) => p['estadoid'] == 4).length;
    int pedidosCancelados = pedidos.where((p) => p['estadoid'] == 5).length;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estadísticas', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEstadisticaItem(
                    'Total Pedidos', totalPedidos, Colors.blue),
                _buildEstadisticaItem(
                    'Entregados', pedidosEntregados, Colors.green),
                _buildEstadisticaItem(
                    'Cancelados', pedidosCancelados, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticaItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(),
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Future<Widget> _buildGraficoEstados(List<DocumentSnapshot> pedidos) async {
    Map<int, int> estadosCount = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    double totalEntregado = 0;

    for (var pedido in pedidos) {
      int estadoId = pedido['estadoid'];
      estadosCount[estadoId] = (estadosCount[estadoId] ?? 0) + 1;
      if (estadoId == 4) {
        totalEntregado += await calcularTotalPedido(pedido);
      }
    }

    List<PieChartSectionData> sections = [
      PieChartSectionData(
          value: estadosCount[1]!.toDouble(),
          color: Colors.blue,
          title: '',
          radius: 50),
      PieChartSectionData(
          value: estadosCount[2]!.toDouble(),
          color: Colors.yellow,
          title: '',
          radius: 50),
      PieChartSectionData(
          value: estadosCount[3]!.toDouble(),
          color: Colors.orange,
          title: '',
          radius: 50),
      PieChartSectionData(
          value: estadosCount[4]!.toDouble(),
          color: Colors.green,
          title: '',
          radius: 50),
      PieChartSectionData(
          value: estadosCount[5]!.toDouble(),
          color: Colors.red,
          title: '',
          radius: 50),
    ];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estados de Pedidos',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Creado', Colors.blue, estadosCount[1]!),
                      _buildLegendItem(
                          'Despachado', Colors.yellow, estadosCount[2]!),
                      _buildLegendItem(
                          'En Camino', Colors.orange, estadosCount[3]!),
                      _buildLegendItem(
                          'Entregado', Colors.green, estadosCount[4]!),
                      _buildLegendItem(
                          'Cancelado', Colors.red, estadosCount[5]!),
                      const SizedBox(height: 16),
                      Text(
                        'Total Entregado: Q${totalEntregado.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                    width: 16), // Añadir espacio entre la leyenda y el gráfico
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child:
                Text('$label ($count)', style: const TextStyle(fontSize: 12)),
          ),
          Icon(Icons.arrow_forward, size: 16, color: color),
          const SizedBox(width: 8), // Añadir espacio después de la flecha
        ],
      ),
    );
  }

  Widget _buildTablaPedidos(List<DocumentSnapshot> pedidos) {
    return Card(
      elevation: 4,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Tracking')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Fecha')),
          ],
          rows: pedidos.map((pedido) {
            return DataRow(cells: [
              DataCell(Text(pedido['idpedidos'].toString())),
              DataCell(_buildEstadoChip(pedido['estadoid'])),
              DataCell(FutureBuilder<double>(
                future: calcularTotalPedido(pedido),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Cargando...');
                  }
                  return Text(
                      'Q${snapshot.data?.toStringAsFixed(2) ?? "0.00"}');
                },
              )),
              DataCell(Text(DateFormat('d/M/y')
                  .format(pedido['fechaCreacion'].toDate()))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEstadoChip(int estadoId) {
    String label;
    Color color;
    switch (estadoId) {
      case 1:
        label = 'Creado';
        color = Colors.blue;
        break;
      case 2:
        label = 'Despachado';
        color = Colors.yellow;
        break;
      case 3:
        label = 'En Camino';
        color = Colors.orange;
        break;
      case 4:
        label = 'Entregado';
        color = Colors.green;
        break;
      case 5:
        label = 'Cancelado';
        color = Colors.red;
        break;
      default:
        label = 'Desconocido';
        color = Colors.grey;
    }
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  Future<double> calcularTotalPedido(DocumentSnapshot pedido) async {
    double total = 0;
    final productosSnapshot =
        await pedido.reference.collection('Productos').get();
    for (var producto in productosSnapshot.docs) {
      total += producto['precioTotal'];
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard de Pedidos',
          style: GoogleFonts.poppins(fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              DateTimeRange? dateRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                locale: const Locale('es', ''),
                builder: (BuildContext context, Widget? child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      primaryColor: Colors.blue, // Color principal
                      colorScheme:
                          const ColorScheme.light(primary: Colors.blue),
                      buttonTheme: const ButtonThemeData(
                          textTheme: ButtonTextTheme.primary),
                    ),
                    child: child!,
                  );
                },
              );
              if (dateRange != null) {
                setState(() {
                  _fechaInicio = dateRange.start;
                  _fechaFin = dateRange.end;
                });
              }
            },
          ),
          _isGeneratingPDF
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: _generatePDF,
                ),
        ],
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: pedidosProvider.getPedidos(nombreNegocio ?? ""),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay pedidos disponibles.'));
          }

          final pedidosFiltrados = _filtrarPedidos(snapshot.data!);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (_fechaInicio != null && _fechaFin != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Mostrando pedidos del ${DateFormat('d/M/y').format(_fechaInicio!)} al ${DateFormat('d/M/y').format(_fechaFin!)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              _buildEstadisticas(pedidosFiltrados),
              const SizedBox(height: 16),
              FutureBuilder<Widget>(
                future: _buildGraficoEstados(pedidosFiltrados),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  return snapshot.data ?? Container();
                },
              ),
              const SizedBox(height: 16),
              _buildTablaPedidos(pedidosFiltrados),
            ],
          );
        },
      ),
    );
  }
}
