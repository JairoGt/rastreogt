import 'package:rastreogt/Cliente/detalle_pedido.dart';
import 'package:rastreogt/conf/export.dart';
import 'package:intl/intl.dart';
import 'package:rastreogt/conf/timeline.dart';

class ProcessTimelinePage extends StatefulWidget {
  final String idPedidos;
  const ProcessTimelinePage({super.key, required this.idPedidos});
  @override
  _ProcessTimelinePageState createState() => _ProcessTimelinePageState();
}

class _ProcessTimelinePageState extends State<ProcessTimelinePage> {
  int _processIndex = 0;
  String _trackingNumber = '';
  User? user = FirebaseAuth.instance.currentUser;
  TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? _orderDetails;
 

  final List<String> _processes = [
    'Creado',
    'Preparando',
    'En Camino',
    'Entregado'
  ]; // Define the processes list

  void _searchAndUpdateTimeline() async {
    String id = _controller.text;
    if (id.isEmpty) return;

    DocumentSnapshot docSnapshot =
        await FirebaseFirestore.instance.collection('pedidos').doc(id).get();

    if (docSnapshot.exists) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
      setState(() {
        _processIndex = data['estadoid'] - 1;
        _orderDetails = data; // Update order details
      });
    } else {
      setState(() {
        _processIndex = 0; // O algún estado por defecto
        _orderDetails = null;
      });
    }
  }

    void _onTrackingNumberChanged() {
    setState(() {
      _trackingNumber = _controller.text
          .toUpperCase()
          .trim()
          .replaceAll(' ', '');
    });
  }
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.idPedidos);
   _controller.addListener(_onTrackingNumberChanged);
    _searchAndUpdateTimeline();
    // Aquí puedes agregar la lógica para buscar el pedido usando el idPedido
    _trackingNumber = widget.idPedidos;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
@override
Widget build(BuildContext context) {
  final themeNotifier = Provider.of<ThemeNotifier>(context);
  return Scaffold(
    appBar: AppBar(
      centerTitle: true,
      title: Text(
        'Seguimiento de Pedido',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: (){
            
          },
        ),
      ],
    ),
    body: Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: themeNotifier.currentTheme.brightness == Brightness.dark
                  ? [const Color.fromARGB(255, 23, 41, 72), Colors.blueGrey]
                  : [const Color.fromARGB(255, 114, 130, 255), Colors.white],
              begin: Alignment.center,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
        SizedBox.expand(
          child: Lottie.asset(
            'assets/lotties/estelas.json',
            fit: BoxFit.cover,
            animate: true,
            repeat: false,
          ),
        ),
        SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  textInputAction: TextInputAction.search,
                  onFieldSubmitted: (value) {
                    _searchAndUpdateTimeline();
                  },
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Enter ID',
                   // labelStyle: GoogleFonts.poppins(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchAndUpdateTimeline,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_orderDetails != null) ...[
                TimelineWidget(
                  processes: _processes,
                  processIndex: _processIndex,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                     showDialog(
    context: context,
    builder: (BuildContext context) {
      return DetalleDialog(orderId: _orderDetails!['idpedidos']);
    },
  );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                        color:  Theme.of(context).brightness == Brightness.dark
                  ? const Color.fromARGB(155, 0, 0, 0).withOpacity(0.5)
                  : Colors.deepPurple.withOpacity(0.5),
                          blurRadius: 5.0,
                          spreadRadius: 2.0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ver detalles del Pedido',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          color: Colors.white70
                          ),
                        ),
                        const SizedBox(height: 10.0),
                       
                        const SizedBox(height: 10.0),
                        Text(
                          'Negocio que envia: \n${_orderDetails!['nego']}',
                          style: GoogleFonts.roboto(
                            fontSize: 18.0,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10.0),
                        Text(
                          'Fecha de envio: \n${_orderDetails!['fechaCreacion'] != null ? DateFormat('dd/MM/yyyy').format((_orderDetails!['fechaCreacion'] as Timestamp).toDate()) : 'Fecha no disponible'}',
                          style: GoogleFonts.roboto(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                         SizedBox(height: 10.0),
                        Text(
                            'Motorista Asignado: \n${_orderDetails!['motoname'] != null ? _orderDetails!['motoname'] : 'Ocurrio un Error al cargar el nombre'}',                          style: GoogleFonts.roboto(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/map');
                            },
                            child: const Text('Ir a mapa'),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (_controller.text.isNotEmpty) {
                              FirebaseFirestore.instance
                                  .collection('pedidos')
                                  .doc(_trackingNumber)
                                  .update({
                                'idcliente': '${user!.email}',
                              });
                              await FirebaseMessaging.instance
                                  .subscribeToTopic('pedido_$_trackingNumber');
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Activado'),
                                    content: const Text('Te has suscrito a las notificaciones'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('OK'),
                                      )
                                    ],
                                  );
                                },
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Error'),
                                    content: Text('El número de seguimiento no puede estar vacío'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('OK'),
                                      )
                                    ],
                                  );
                                },
                              );
                            }
                          },
                          child: const Text('Activar Notificaciones'),
                        ),
                      ],
                    ),
                  ),
                ),
                
              ],
            ],
          ),
        ),
      ],
    ),
   
  );
}
}
String _getEstadoDescripcion(int estadoid) {
  switch (estadoid) {
    case 1:
      return 'Creado';
    case 2:
      return 'Preparando';
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