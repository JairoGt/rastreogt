import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapasC extends StatefulWidget {
  const MapasC({super.key});

  @override
  _MapasCState createState() => _MapasCState();
}

class _MapasCState extends State<MapasC> {
  GoogleMapController? mapController;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

Future<void> _getCurrentLocation() async {
  var status = await Permission.location.status;
  if (status.isGranted) {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  } else if (status.isDenied) {
    // Solicita el permiso si es denegado
    var newStatus = await Permission.location.request();
    if (newStatus.isGranted) {
      // Intenta obtener la ubicación nuevamente si el permiso es concedido
      _getCurrentLocation();
    } else {
      // Maneja el caso donde el usuario niega el permiso
      print("Permiso de ubicación denegado");
    }
  } else if (status.isPermanentlyDenied) {
    // Abre la configuración del app para que el usuario pueda conceder el permiso manualmente
    openAppSettings();
  }
}
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_currentPosition != null) {
      _moveCameraToPosition();
    }
  }

  void _moveCameraToPosition() {
    mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _currentPosition!, zoom: 15.0),
    ));
  }

  void _onTap(LatLng position) {
    setState(() {
      _currentPosition = position;
      _moveCameraToPosition();
    });
  }

  void _confirmLocation() {
    Navigator.pop(context, '${_currentPosition!.latitude},${_currentPosition!.longitude}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmLocation,
          ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 15.0,
              ),
              onTap: _onTap,
              markers: {
                Marker(
                  markerId: const MarkerId('selected-location'),
                  position: _currentPosition!,
                ),
              },
            ),
    );
  }
}