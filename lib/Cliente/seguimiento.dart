import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:rastreogt/Home/timeline.dart';
import 'package:rastreogt/providers/themeNoti.dart';

class ProcessTimelinePage extends StatefulWidget {
  final String idPedidos;
  ProcessTimelinePage({required this.idPedidos});
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
        title: Text(
          'Process Timeline',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _searchAndUpdateTimeline,
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
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Enter ID',
                    labelStyle: GoogleFonts.poppins(),
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
              const SizedBox(
                  height:
                      10), // Adds space between the search field and timeline
              TimelineWidget(
                processes: _processes,
                processIndex: _processIndex,
              ),
              const SizedBox(
                  height:
                      20), // Adds space between the timeline and order details
              if (_orderDetails != null) ...[
                Container(
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    //color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 5.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                  ),
                  child:Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Detalles del Pedido',
        style: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 10.0),
      Text(
        'ID: ${_orderDetails!['idpedidos']}',
        style: GoogleFonts.roboto(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
      const SizedBox(height: 10.0),
      Text(
        'Estado: ${_getEstadoDescripcion(_orderDetails!['estadoid'])}',
        style: GoogleFonts.roboto(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
      const SizedBox(height: 10.0),
      Text(
        'Negocio: ${_orderDetails!['nego']}',
        style: GoogleFonts.roboto(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          //color: Colors.white70,
        ),
      ),
      Text(
        'Fecha: ${_orderDetails!['fechaCreacion'] != null ? DateFormat('dd/MM/yyyy').format((_orderDetails!['fechaCreacion'] as Timestamp).toDate()) : 'Fecha no disponible'}',
        style: GoogleFonts.roboto(
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
            // Navegar al mapa
            Navigator.pushNamed(context, '/map');
          },
          child: const Text('Ir a mapa'),
        ),
        
      ),
      ElevatedButton(
                  onPressed: () async {
                    print(_controller.text);
                    if (_controller.text.isNotEmpty) {
                     

                   
                      FirebaseFirestore.instance
                          .collection('pedidos')
                          .doc(_trackingNumber)
                          .update({
                        'idcliente': '${user!.email}',
                      });
                      // Registra el pedido para recibir notificaciones
                      await FirebaseMessaging.instance
                          .subscribeToTopic('pedido_$_trackingNumber');
                    print('Subscribed to pedido_$_trackingNumber');
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Activado'),
                            // ignore: prefer_const_constructors
                            content:
                                Text('Te has suscrito a las notificaciones'),
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
                            // ignore: prefer_const_constructors
                            content: Text(
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
              ],
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _processIndex = ((_processIndex + 1) % _processes.length).toInt();
          });
        },
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(FontAwesomeIcons.arrowRight),
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