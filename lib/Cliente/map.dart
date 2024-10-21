import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class Mapas2 extends StatefulWidget {
  const Mapas2({super.key});

  @override
  _Mapas2State createState() => _Mapas2State();
}

class _Mapas2State extends State<Mapas2> {
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
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
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
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text(
                  'Debes permitir los permisos de ubicacion, porfavor cierra y vuelve a abrir la aplicacion'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
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
    Navigator.pop(context,
        '${_currentPosition!.latitude},${_currentPosition!.longitude}');
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
