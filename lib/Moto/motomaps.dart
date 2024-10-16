import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class MotoristaMapScreen extends StatefulWidget {
  final LatLng ubicacionCliente;
  final LatLng ubicacionNegocio;
  // final LatLng ubicacionM;

  const MotoristaMapScreen({
    super.key,
    required this.ubicacionCliente,
    required this.ubicacionNegocio,

    // required this.ubicacionM,
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
    // _ubicacionActual =
    //     widget.ubicacionM; // Inicializar con la ubicación del negocio
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

  void _abrirNavegacion() async {
    if (_ubicacionActual == null) return;

    // Mostrar el diálogo para elegir entre Google Maps y Waze
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar aplicación de navegación'),
          content:
              const Text('¿Qué aplicación deseas usar para la navegación?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _abrirGoogleMaps();
              },
              child: const Text('Google Maps'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _abrirWaze();
              },
              child: const Text('Waze'),
            ),
          ],
        );
      },
    );
  }

  void _abrirGoogleMaps() async {
    if (_ubicacionActual == null) return;

    // Intenta con Google Maps primero
    final String googleMapsUrl =
        'google.navigation:q=${widget.ubicacionCliente.latitude},${widget.ubicacionCliente.longitude}&mode=d';

    final Uri googleUri = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(googleUri)) {
      await launchUrl(googleUri);
    }
  }

  void _abrirWaze() async {
    if (_ubicacionActual == null) return;
    final String wazeUrl =
        'waze://?ll=${widget.ubicacionCliente.latitude},${widget.ubicacionCliente.longitude}&navigate=yes';

    final Uri wazeUri = Uri.parse(wazeUrl);

    if (await canLaunchUrl(wazeUri)) {
      await launchUrl(wazeUri);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text(
                'No se pudo abrir Waze. ¿Tienes la aplicación instalada?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta del Motorista'),
        actions: [
          IconButton(
            icon: const Icon(Icons.navigation),
            onPressed: _abrirNavegacion,
          ),
        ],
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
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen),
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
              onMapCreated: (controller) {},
            ),
    );
  }
}
