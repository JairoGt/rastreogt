import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class MapScreen extends StatefulWidget {
  final LatLng ubicacionCliente;
  final LatLng ubicacionNegocio;
  final LatLng ubicacionM;
  final String idMotorista;
  final String emailM;
  const MapScreen({
    super.key,
    required this.ubicacionCliente,
    required this.ubicacionNegocio,
    required this.ubicacionM,
    required this.idMotorista,
    required this.emailM,
  });

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _ubicacionMotorista;
  BitmapDescriptor? _motoristaIcon;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _iniciarActualizacionPeriodica();
  }

  Future<void> _loadCustomMarker() async {
    final byteData = await rootBundle.load('assets/images/motorista_icon.png');
    final bytes = byteData.buffer.asUint8List();

    // Redimensionar la imagen
    final resizedBytes = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 138,  // Ancho deseado
      minHeight: 138, // Altura deseada
      quality: 100,
    );

    _motoristaIcon = BitmapDescriptor.fromBytes(resizedBytes);
    setState(() {});
  }

  void _iniciarActualizacionPeriodica() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _actualizarUbicacionMotorista();
    });
  }

  Future<void> _actualizarUbicacionMotorista() async {
    String emailM = widget.emailM;
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('motos')
        .doc(emailM)
        .get();

    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      if (data != null) {
        if (mounted) {
          setState(() {
            _ubicacionMotorista = LatLng(data['ubicacionM'].latitude, data['ubicacionM'].longitude);
          });
          _moverCamara(_ubicacionMotorista!);
        }
      }
    }
  }

  void _moverCamara(LatLng nuevaUbicacion) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(nuevaUbicacion),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicaciones'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.ubicacionNegocio,
          zoom: 14.0,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('cliente'),
            position: widget.ubicacionCliente,
            infoWindow: const InfoWindow(title: 'Ubicación del Cliente'),
          ),
          Marker(
            markerId: const MarkerId('negocio'),
            position: widget.ubicacionNegocio,
            infoWindow: const InfoWindow(title: 'Ubicación del Negocio'),
          ),
          if (_ubicacionMotorista != null)
            Marker(
              markerId: const MarkerId('motorista'),
              position: _ubicacionMotorista!,
              icon: _motoristaIcon ?? BitmapDescriptor.defaultMarker,
              infoWindow: const InfoWindow(title: 'Ubicación del Motorista'),
            ),
        },
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
    );
  }
}