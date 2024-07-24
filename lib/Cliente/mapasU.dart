import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatelessWidget {
  final LatLng ubicacionCliente;
  final LatLng ubicacionNegocio;

  const MapScreen({Key? key, required this.ubicacionCliente, required this.ubicacionNegocio}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ubicaciones'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: ubicacionCliente,
          zoom: 14.0,
        ),
        markers: {
          Marker(
            markerId: MarkerId('cliente'),
            position: ubicacionCliente,
            infoWindow: InfoWindow(title: 'Ubicación del Cliente'),
          ),
          Marker(
            markerId: MarkerId('negocio'),
            position: ubicacionNegocio,
            infoWindow: InfoWindow(title: 'Ubicación del Negocio'),
          ),
        },
      ),
    );
  }
}