import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MotoristaMapScreen extends StatefulWidget {
  final LatLng ubicacionCliente;
  final LatLng ubicacionNegocio;
  final LatLng ubicacionM;

  const MotoristaMapScreen({
    super.key,
    required this.ubicacionCliente,
    required this.ubicacionNegocio,
    required this.ubicacionM,
  });

  @override
  _MotoristaMapScreenState createState() => _MotoristaMapScreenState();
}

class _MotoristaMapScreenState extends State<MotoristaMapScreen> {
  LatLng? _ubicacionActual;
  List<LatLng> _polylineCoordinates = [];
  final String _googleApiKey =
      'AIzaSyDkAtZ521Ge8ZFU5UPaH5Y_IkjUd-yG2CY'; // Asegúrate de reemplazar esto con tu clave de API

  @override
  void initState() {
    super.initState();
    _ubicacionActual =
        widget.ubicacionM; // Inicializar con la ubicación del negocio
    _obtenerUbicacionActual();
  }

  void _obtenerUbicacionActual() async {
    var locationData = await Geolocator.getCurrentPosition();
    setState(() {
      _ubicacionActual = LatLng(locationData.latitude, locationData.longitude);
      _obtenerRuta();
    });
  }

  Future<void> _obtenerRuta() async {
    if (_ubicacionActual == null) return;

    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_ubicacionActual!.latitude},${_ubicacionActual!.longitude}&destination=${widget.ubicacionCliente.latitude},${widget.ubicacionCliente.longitude}&key=$_googleApiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final List<LatLng> polylineCoordinates = [];
      final steps = data['routes'][0]['legs'][0]['steps'];

      for (var step in steps) {
        final startLocation = step['start_location'];
        final endLocation = step['end_location'];
        polylineCoordinates
            .add(LatLng(startLocation['lat'], startLocation['lng']));
        polylineCoordinates.add(LatLng(endLocation['lat'], endLocation['lng']));
      }

      setState(() {
        _polylineCoordinates = polylineCoordinates;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta del Motorista'),
      ),
      body: _ubicacionActual == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _ubicacionActual!,
                zoom: 14.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('motorista'),
                  position: _ubicacionActual!,
                  infoWindow:
                      const InfoWindow(title: 'Ubicación Actual del Motorista'),
                ),
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
              },
              polylines: {
                Polyline(
                  polylineId: const PolylineId('ruta'),
                  points: _polylineCoordinates,
                  color: Colors.blue,
                  width: 5,
                ),
              },
              onMapCreated: (controller) {
              },
            ),
    );
  }
}
