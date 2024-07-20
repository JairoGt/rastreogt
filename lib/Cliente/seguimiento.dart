import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rastreogt/Home/timeline.dart';
import 'package:rastreogt/providers/themeNoti.dart';
import 'package:timelines/timelines.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

const kTileHeight = 30.0;
const completeColor = Color(0xff0a0a0a); // Negro
const inProgressColor = Color(0xff00ff00); // Verde brillante
const todoColor = Color(0xffd1d2d7); // Gris claro

class ProcessTimelinePage extends StatefulWidget {
  @override
  _ProcessTimelinePageState createState() => _ProcessTimelinePageState();
}

class _ProcessTimelinePageState extends State<ProcessTimelinePage> {
  int _processIndex = 0;
  final TextEditingController _idController = TextEditingController();
  Map<String, dynamic>? _orderDetails;
  List<String> _processes = ['Process 1', 'Process 2', 'Process 3', 'Process 4']; // Define the processes list

  void _searchAndUpdateTimeline() async {
    String id = _idController.text;
    if (id.isEmpty) return;

    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance.collection('pedidos').doc(id).get();

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

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Process Timeline')),
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
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: 'Enter ID',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchAndUpdateTimeline,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10), // Adds space between the search field and timeline
              ProcessTimeline(processIndex: _processIndex),
              SizedBox(height: 20), // Adds space between the timeline and order details
              if (_orderDetails != null) ...[
                Container(
                  padding: EdgeInsets.all(16.0),
                  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 5.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalles del Pedido',
                        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10.0),
                      Text('ID: ${_orderDetails!['id']}'),
                      Text('Estado: ${_orderDetails!['estado']}'),
                      Text('Cliente: ${_orderDetails!['cliente']}'),
                      Text('Fecha: ${_orderDetails!['fecha']}'),
                      SizedBox(height: 20.0),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            // Navegar al mapa
                            Navigator.pushNamed(context, '/map');
                          },
                          child: Text('Ir a mapa'),
                        ),
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
        backgroundColor: inProgressColor,
        child: const Icon(FontAwesomeIcons.chevronRight),
      ),
    );
  }
}
