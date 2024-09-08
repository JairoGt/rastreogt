import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rastreogt/Cliente/detalle_pedido.dart';
import 'package:rastreogt/Cliente/mapascliente.dart';
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
  Map<String, dynamic>? _motoristaDetails;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> _processes = [
    'Creado',
    'En Proceso',
    'En Camino',
    'Entregado',
  ]; // Define the processes list

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.idPedidos);
    _controller.addListener(_onTrackingNumberChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
    _searchAndUpdateTimeline();
  });
    _trackingNumber = widget.idPedidos;
    _obtenerDetallesPedido();
  }

void _searchAndUpdateTimeline() async {
  String id = _controller.text;


  if (_formKey.currentState != null && _formKey.currentState!.validate()) {
    try {
      // Realiza la búsqueda y actualiza la línea de tiempo
      DocumentSnapshot docSnapshot =
          await FirebaseFirestore.instance.collection('pedidos').doc(id).get();

      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _processIndex = data['estadoid'] - 1;
          _orderDetails = data; // Update order details
        });

        // Obtener el idMotorista del pedido y llamar a _obtenerDetallesMotorista
        var idMotorista = _orderDetails!['idMotorista'];
        _obtenerDetallesMotorista(idMotorista);
      } else {
        setState(() {
          _processIndex = 0; // O algún estado por defecto
          _orderDetails = null;
          _motoristaDetails = null; // Limpiar los detalles del motorista si no se encuentra el pedido
          _controller.clear();
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Error', style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                )),
                content: const Text('Pedido no encontrado'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK', style: 
                      GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.inverseSurface,
                        fontWeight: FontWeight.bold,
                      )
                    ),
                  )
                ],
              );
            },
          );
        });
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error', style: GoogleFonts.poppins(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            )),
            content: Text('Ocurrió un error al buscar el pedido: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK', style: 
                  GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.inverseSurface,
                    fontWeight: FontWeight.bold,
                  )
                ),
              )
            ],
          );
        },
      );
    }
  } else {
    // Manejar el caso en que la validación falle
  }
}

  void _obtenerDetallesPedido() async {
    String? idPedido = widget.idPedidos;

    // Verificar si idPedido es nulo o vacío
    if (idPedido.isEmpty) {
      idPedido = _controller.text;
    }

    // Verificar nuevamente si idPedido es nulo o vacío después de intentar con _controller.text
    if (idPedido.isEmpty) {
      return;
    }

    // Intentar obtener los detalles del pedido con el idPedido válido
    var pedidoSnapshot = await FirebaseFirestore.instance.collection('pedidos').doc(idPedido).get();

    // Verificar si el pedido existe
    if (pedidoSnapshot.exists) {
      setState(() {
        _orderDetails = pedidoSnapshot.data();
      });
      // Obtener el idMotorista del pedido
      var idMotorista = _orderDetails!['idMotorista'];
      _obtenerDetallesMotorista(idMotorista);
    } else {
      // Si no se encuentra el pedido, imprimir un mensaje de error
    }
  }

  void _obtenerDetallesMotorista(String idMotorista) async {
    // Obtener los detalles del motorista buscando por el campo idMotorista
    var querySnapshot = await FirebaseFirestore.instance
        .collection('motos')
        .where('idmoto', isEqualTo: idMotorista)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        // Suponiendo que solo hay un documento que coincide con el idMotorista
        _motoristaDetails = querySnapshot.docs.first.data();
      });
    } else {
      setState(() {
        _motoristaDetails = null; // Limpiar los detalles del motorista si no se encuentra
      });
    }
  }

  void _onTrackingNumberChanged() {
    setState(() {
      _trackingNumber =
          _controller.text.toUpperCase().trim().replaceAll(' ', '');
    });
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
    resizeToAvoidBottomInset: false, // Evita que el contenido se mueva
    appBar: AppBar(
      title: const Text('Seguimiento de Pedido'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            setState(() {
              
            });
          },
        ),
      ],
    ),
    body: SafeArea(
      child: Stack(
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
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            textInputAction: TextInputAction.search,
                            onFieldSubmitted: (value) {
                              _searchAndUpdateTimeline();
                            },
                            controller: _controller,
                            decoration: InputDecoration(
                              labelStyle: GoogleFonts.poppins(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              filled: true,
                              fillColor: const Color.fromARGB(94, 255, 255, 255).withOpacity(0.2),
                              labelText: 'Enter ID',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: _searchAndUpdateTimeline,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, ingrese un número de seguimiento';
                              }
                              return null;
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                              TextInputFormatter.withFunction((oldValue, newValue) {
                                return newValue.copyWith(text: newValue.text.toUpperCase());
                              }),
                            ],
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
                                    return DetalleDialog(
                                        orderId: _orderDetails!['idpedidos']);
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).brightness == Brightness.dark
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
                                          color: Colors.white70),
                                    ),
                                    const SizedBox(height: 10.0),
                                    Text(
                                      'Negocio que envia: \n${_orderDetails!['nego']}',
                                      style: GoogleFonts.roboto(
                                        fontSize: 18.0,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10.0),
                                    Text(
                                      'Fecha de envio: \n${_orderDetails!['fechaCreacion'] != null ? DateFormat('dd/MM/yyyy').format((_orderDetails!['fechaCreacion'] as Timestamp).toDate()) : 'Fecha no disponible'}',
                                      style: GoogleFonts.roboto(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 10.0),
                                    Text(
                                      'Motorista Asignado: \n${_motoristaDetails?['name'] ?? 'Parece que no hay motorista asignado'}',
                                      style: GoogleFonts.roboto(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 20.0),
                                    Center(
                                      child: _orderDetails!['estadoid'] == 3
                                          ? ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20.0),
                                                ),
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => MapScreen(
                                                      emailM: _motoristaDetails?['email'],
                                                      idMotorista: _orderDetails!['idMotorista'],
                                                      ubicacionCliente: LatLng(
                                                          _orderDetails!['ubicacionCliente'].latitude,
                                                          _orderDetails!['ubicacionCliente'].longitude),
                                                      ubicacionNegocio: LatLng(
                                                          _orderDetails!['ubicacionNegocio'].latitude,
                                                          _orderDetails!['ubicacionNegocio'].longitude),
                                                      ubicacionM: LatLng(
                                                          _motoristaDetails?['latitude'] ?? 0.0,
                                                          _motoristaDetails?['longitude'] ?? 0.0),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text('Ir a mapa'),
                                            )
                                          : Container(), // Un widget vacío cuando estadoId es 4
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
                                              .subscribeToTopic(
                                                  'pedido_$_trackingNumber');
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text('Activado'),
                                                content: const Text(
                                                    'Te has suscrito a las notificaciones'),
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
                                                content: const Text(
                                                    'El número de seguimiento no puede estar vacío'),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}