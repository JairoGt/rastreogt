import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:rastreogt/conf/export.dart';
import 'dart:math' show cos, pi, sin;

class PDFGenerator {
  Future<void> generateModernPDF(
      BuildContext context,
      List<DocumentSnapshot<Object?>> data,
      String nombreNegocio,
      DateTime? fechaInicio,
      DateTime? fechaFin) async {
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

      if (fechaInicio != null) {
        dentroDeRango = dentroDeRango && fechaCreacion.isAfter(fechaInicio);
      }

      if (fechaFin != null) {
        dentroDeRango = dentroDeRango &&
            fechaCreacion.isBefore(fechaFin.add(const Duration(days: 1)));
      }

      return dentroDeRango;
    }).toList();

    // Calcular todos los totales de pedidos de antemano
    Map<String, double> totalesPedidos = {};
    for (var pedido in pedidos) {
      totalesPedidos[pedido.id] = await calcularTotalPedido(pedido);
    }

    // Contar pedidos por estado y calcular totales
    Map<int, int> estadosCount = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    double totalEntregado = 0;
    double totalGeneral = 0;

    for (var pedido in pedidos) {
      int estadoId = pedido['estadoid'];
      estadosCount[estadoId] = (estadosCount[estadoId] ?? 0) + 1;
      double total = totalesPedidos[pedido.id]!;
      totalGeneral += total;
      if (estadoId == 4) {
        totalEntregado += total;
      }
    }
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            _buildHeader(nombreNegocio, fechaInicio, fechaFin),
            pw.SizedBox(height: 20),
            _buildResumenEstadistico(pedidos.length, estadosCount[4]!,
                estadosCount[5]!, totalEntregado, totalGeneral),
            pw.SizedBox(height: 20),
            _buildGraficoEstadosConLeyenda(estadosCount),
            pw.SizedBox(height: 20),
            _buildTablaPedidos(pedidos, totalesPedidos),
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

  pw.Widget _buildHeader(
      String nombreNegocio, DateTime? fechaInicio, DateTime? fechaFin) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Reporte de Pedidos',
              style:
                  pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text('Negocio: $nombreNegocio', style: pw.TextStyle(fontSize: 16)),
          if (fechaInicio != null && fechaFin != null)
            pw.Text(
              'Periodo: ${DateFormat('d/M/y').format(fechaInicio)} - ${DateFormat('d/M/y').format(fechaFin)}',
              style: pw.TextStyle(fontSize: 14),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildResumenEstadistico(int totalPedidos, int pedidosEntregados,
      int pedidosCancelados, double totalEntregado, double totalGeneral) {
    return pw.Container(
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
              pw.Text('Total de pedidos: $totalPedidos',
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
              pw.SizedBox(height: 5),
              pw.Text('Total general:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Q${totalGeneral.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildGraficoEstados(Map<int, int> estadosCount) {
    final total = estadosCount.values.reduce((a, b) => a + b);

    // Si no hay pedidos, mostramos un mensaje en lugar del gráfico
    if (total == 0) {
      return pw.Text('No hay datos para mostrar');
    }

    double startAngle = 0;

    final colors = [
      PdfColors.blue,
      PdfColors.yellow,
      PdfColors.orange,
      PdfColors.green,
      PdfColors.red,
    ];

    return pw.Container(
      height: 150,
      width: 150,
      child: pw.CustomPaint(
        painter: (PdfGraphics graphics, PdfPoint size) {
          final centerX = size.x / 2;
          final centerY = size.y / 2;
          final radius = (size.x < size.y ? size.x : size.y) / 2;

          estadosCount.forEach((estado, count) {
            if (count > 0) {
              // Solo dibujamos si hay pedidos en este estado
              final sweepAngle = count / total * 2 * pi;
              final color = colors[(estado - 1) % colors.length];

              graphics.setColor(color);
              graphics.moveTo(centerX, centerY);
              graphics.lineTo(
                centerX + radius * cos(startAngle),
                centerY + radius * sin(startAngle),
              );
              for (double angle = startAngle;
                  angle <= startAngle + sweepAngle;
                  angle += 0.1) {
                graphics.lineTo(
                  centerX + radius * cos(angle),
                  centerY + radius * sin(angle),
                );
              }
              graphics.lineTo(centerX, centerY);
              graphics.fillPath();

              startAngle += sweepAngle;
            }
          });

          // Dibujar el círculo blanco en el centro para el efecto "donut"
          graphics.setColor(PdfColors.white);
          graphics.moveTo(centerX + radius * 0.6, centerY);
          for (double angle = 0; angle < 2 * pi; angle += 0.1) {
            graphics.lineTo(
              centerX + radius * 0.6 * cos(angle),
              centerY + radius * 0.6 * sin(angle),
            );
          }
          graphics.fillPath();
        },
      ),
    );
  }

// Función para agregar la leyenda
  pw.Widget _buildLegend(Map<int, int> estadosCount, List<PdfColor> colors) {
    final estados = [
      'Creado',
      'Despachado',
      'En Camino',
      'Entregado',
      'Cancelado'
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: estados.asMap().entries.map((entry) {
        final index = entry.key;
        final estado = entry.value;
        final count = estadosCount[index + 1] ?? 0;
        return pw.Row(
          children: [
            pw.Container(
              width: 10,
              height: 10,
              color: colors[index % colors.length],
            ),
            pw.SizedBox(width: 5),
            pw.Text('$estado: $count'),
          ],
        );
      }).toList(),
    );
  }

// Función principal que combina el gráfico y la leyenda
  pw.Widget _buildGraficoEstadosConLeyenda(Map<int, int> estadosCount) {
    final colors = [
      PdfColors.blue,
      PdfColors.yellow,
      PdfColors.orange,
      PdfColors.green,
      PdfColors.red,
    ];

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildGraficoEstados(estadosCount),
        pw.SizedBox(width: 20),
        _buildLegend(estadosCount, colors),
      ],
    );
  }

  pw.Widget _buildTablaPedidos(
      List<DocumentSnapshot> pedidos, Map<String, double> totalesPedidos) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableHeader('Tracking'),
            _buildTableHeader('Dirección'),
            _buildTableHeader('Estado'),
            _buildTableHeader('Total'),
            _buildTableHeader('Fecha'),
          ],
        ),
        ...pedidos
            .map((pedido) => _buildTableRow(pedido, totalesPedidos[pedido.id]!))
            .toList(),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.TableRow _buildTableRow(DocumentSnapshot pedido, double total) {
    return pw.TableRow(
      children: [
        pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(pedido['idpedidos'].toString())),
        pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(pedido['direccion'] ?? '')),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            _getEstadoTexto(pedido['estadoid']),
            style: pw.TextStyle(color: _getEstadoColor(pedido['estadoid'])),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text('Q${total.toStringAsFixed(2)}'),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
              DateFormat('d/M/y').format(pedido['fechaCreacion'].toDate())),
        ),
      ],
    );
  }

  String _getEstadoTexto(int estadoId) {
    switch (estadoId) {
      case 1:
        return 'CREADO';
      case 2:
        return 'DESPACHADO';
      case 3:
        return 'EN CAMINO';
      case 4:
        return 'ENTREGADO';
      case 5:
        return 'CANCELADO';
      default:
        return '';
    }
  }

  PdfColor _getEstadoColor(int estadoId) {
    switch (estadoId) {
      case 1:
        return PdfColors.blue;
      case 2:
        return PdfColors.yellow;
      case 3:
        return PdfColors.orange;
      case 4:
        return PdfColors.green;
      case 5:
        return PdfColors.red;
      default:
        return PdfColors.black;
    }
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
}
