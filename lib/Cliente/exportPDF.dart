import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:rastreogt/Cliente/historicopedidos.dart';

class PdfExporter {
  static Future<void> exportarPedidosAPdf(List<Pedido> pedidos) async {
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
            _buildHeader(themeColor, accentColor, image),
            pw.SizedBox(height: 20),
            pw.Paragraph(
                text: 'Resumen de pedidos realizados',
                style:
                    const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
            pw.SizedBox(height: 20),
            _buildPedidosTable(pedidosConfirmados, 'Pedidos Confirmados'),
            pw.SizedBox(height: 20),
            _buildPedidosTable(pedidosCancelados, 'Pedidos Cancelados'),
            pw.SizedBox(height: 20),
            _buildResumenFinanciero(pedidosConfirmados, pedidosCancelados),
          ];
        },
        footer: _buildFooter,
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildHeader(
      PdfColor themeColor, PdfColor accentColor, pw.MemoryImage image) {
    return pw.Header(
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
            decoration:
                pw.BoxDecoration(shape: pw.BoxShape.circle, color: accentColor),
            child: pw.Center(child: pw.Image(image)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPedidosTable(List<Pedido> pedidos, String title) {
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

  static pw.Widget _buildResumenFinanciero(
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

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey),
          ),
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.Text(
              'El camino hacia el éxito y el camino hacia el fracaso son exactamente el mismo camino.',
              style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                  fontWeight: pw.FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  static String getEstadoDescripcion(int? estado) {
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
}
