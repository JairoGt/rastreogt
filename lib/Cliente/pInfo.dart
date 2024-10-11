import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rastreogt/Cliente/map.dart';

class UserInfoScreen extends StatefulWidget {
  final String? userEmail;

  const UserInfoScreen({super.key, required this.userEmail});

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      DocumentSnapshot userInfo = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userEmail)
          .collection('userData')
          .doc('pInfo')
          .get();

      if (userInfo.exists) {
        Map<String, dynamic> data = userInfo.data() as Map<String, dynamic>;
        setState(() {
          _emailController.text = widget.userEmail!;
          _direccionController.text = data['direccion'] ?? '';
          _nameController.text = data['name'] ?? '';
          _telefonoController.text = (data['telefono'] ?? 0).toString();
          _emailController.text = widget.userEmail!;
        });

        // Lee las coordenadas de Firestore
        GeoPoint geoPoint = (data['ubicacion']) ?? const GeoPoint(0, 0);
        double latitude = geoPoint.latitude;
        double longitude = geoPoint.longitude;

        // Utiliza el paquete geocoding para convertir las coordenadas en una dirección

        List<Placemark> placemarks =
            await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks.first;
          setState(() {
            _ubicacionController.text =
                '${placemark.street}, ${placemark.locality}, ${placemark.country}';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la información $e')),
      );
    }
  }

  String? _originalCoordinates;

  Future<void> _saveUserInfo() async {
    if (_formKey.currentState!.validate()) {
      if (_originalCoordinates != null) {
        final coordinates = _originalCoordinates!.split(',');
        final latitude = double.parse(coordinates[0]);
        final longitude = double.parse(coordinates[1]);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userEmail)
            .collection('userData')
            .doc('pInfo')
            .update({
          'direccion': _direccionController.text,
          'estadoid': 1,
          'name': _nameController.text,
          'telefono': _telefonoController.text,
          'ubicacion': GeoPoint(latitude, longitude),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Información actualizada correctamente'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      } else {
        // Manejar el caso en que no se hayan seleccionado coordenadas
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Por favor, selecciona una ubicación'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Mapas2(),
      ),
    );

    if (result != null) {
      final coordinates = result.split(',');
      final latitude = double.parse(coordinates[0]);
      final longitude = double.parse(coordinates[1]);

      try {
        // Guardar las coordenadas originales
        _originalCoordinates = result;

        // Obtener la dirección a partir de las coordenadas
        List<Placemark> placemarks =
            await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];

          // Manejar valores nulos y proporcionar valores predeterminados
          String street = place.street ?? 'Calle desconocida';
          String locality = place.locality ?? 'Localidad desconocida';

          String formattedAddress = "$street, $locality";

          setState(() {
            _ubicacionController.text = formattedAddress;
          });
        } else {
          setState(() {
            _ubicacionController.text = 'Dirección no encontrada';
          });
        }
      } catch (e) {
        // Manejar cualquier excepción que ocurra durante la geocodificación inversa
        setState(() {
          _ubicacionController.text = 'Error al obtener la dirección';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Información del Usuario'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 50),
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: false,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una dirección';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un teléfono';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                enabled: false,
                controller: _ubicacionController,
                decoration: const InputDecoration(labelText: 'Ubicación'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona una ubicación';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectLocation,
                child: const Text('Seleccionar Ubicación'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveUserInfo,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
