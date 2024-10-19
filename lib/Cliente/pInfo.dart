import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:rastreogt/Cliente/map.dart';

class UserInfoScreen extends StatefulWidget {
  final String? userEmail;

  const UserInfoScreen({super.key, required this.userEmail});

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();

  Map<String, Map<String, dynamic>> addresses = {
    'Casa': {'direccion': '', 'ubicacion': const GeoPoint(0, 0)},
    'Trabajo': {'direccion': '', 'ubicacion': const GeoPoint(0, 0)},
    'Otros': {'direccion': '', 'ubicacion': const GeoPoint(0, 0)},
  };

  String? selectedAddressType;

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
          _nameController.text = data['name'] ?? '';
          _telefonoController.text = (data['telefono'] ?? 0).toString();
          _direccionController.text = data['direccion'] ?? '';
          GeoPoint ubicacion = data['ubicacion'] ?? const GeoPoint(0, 0);
          _ubicacionController.text = _formatGeoPoint(ubicacion);
        });

        QuerySnapshot addressesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userEmail)
            .collection('userData')
            .doc('pInfo')
            .collection('misDirecciones')
            .get();

        setState(() {
          for (var doc in addressesSnapshot.docs) {
            String type = doc.id;
            Map<String, dynamic> addressData =
                doc.data() as Map<String, dynamic>;
            addresses[type] = {
              'direccion': addressData['direccion'] ?? '',
              'ubicacion':
                  addressData['ubicacion'] as GeoPoint? ?? const GeoPoint(0, 0),
            };
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la información $e')),
      );
    }
  }

  Future<void> _saveUserInfo() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userEmail)
            .collection('userData')
            .doc('pInfo')
            .update({
          'name': _nameController.text,
          'telefono': _telefonoController.text,
          'direccion': _direccionController.text,
          'ubicacion': _parseGeoPoint(_ubicacionController.text),
        });

        for (var entry in addresses.entries) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userEmail)
              .collection('userData')
              .doc('pInfo')
              .collection('misDirecciones')
              .doc(entry.key)
              .set(entry.value);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Información actualizada correctamente'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la información: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEditDialog(String addressType) {
    TextEditingController dialogDireccionController = TextEditingController(
        text: addresses[addressType]!['direccion'] as String);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('Editar $addressType'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dialogDireccionController,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await _selectLocation(addressType);
                    setState(
                        () {}); // Actualizar el diálogo para mostrar la nueva ubicación
                  },
                  child: const Text('Seleccionar Ubicación'),
                ),
                const SizedBox(height: 10),
                Text(
                    'Ubicación actual: ${_formatGeoPoint(addresses[addressType]!['ubicacion'] as GeoPoint)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    addresses[addressType]!['direccion'] =
                        dialogDireccionController.text;
                    if (selectedAddressType == addressType) {
                      _direccionController.text =
                          dialogDireccionController.text;
                      _updateUbicacionController(addressType);
                    }
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _selectLocation(String addressType) async {
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

      setState(() {
        addresses[addressType]!['ubicacion'] = GeoPoint(latitude, longitude);
        if (selectedAddressType == addressType) {
          _ubicacionController.text =
              _formatGeoPoint(GeoPoint(latitude, longitude));
        }
      });
    }
  }

  void _updateSelectedAddress(String? newValue) {
    setState(() {
      selectedAddressType = newValue;
      if (newValue != null) {
        _direccionController.text = addresses[newValue]!['direccion'] as String;
        _updateUbicacionController(newValue);
      }
    });
  }

  void _updateUbicacionController(String addressType) {
    GeoPoint geoPoint = addresses[addressType]!['ubicacion'] as GeoPoint;
    _ubicacionController.text = _formatGeoPoint(geoPoint);
  }

  String _formatGeoPoint(GeoPoint geoPoint) {
    return '${geoPoint.latitude.toStringAsFixed(6)}, ${geoPoint.longitude.toStringAsFixed(6)}';
  }

  GeoPoint _parseGeoPoint(String text) {
    List<String> parts = text.split(',');
    return GeoPoint(
      double.parse(parts[0].trim()),
      double.parse(parts[1].trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Información del Usuario'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
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
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                inputFormatters: [
                  FilteringTextInputFormatter
                      .digitsOnly, // Permite solo números
                  LengthLimitingTextInputFormatter(8),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un teléfono';
                  }
                  if (value.length != 8) {
                    return 'El número debe tener 8 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedAddressType,
                      decoration:
                          const InputDecoration(labelText: 'Tipo de Dirección'),
                      items: addresses.keys.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: _updateSelectedAddress,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: selectedAddressType != null
                        ? () => _showEditDialog(selectedAddressType!)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección'),
                enabled: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'No se puede quedar vacio, porfavor revise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _ubicacionController,
                decoration: const InputDecoration(labelText: 'Ubicación'),
                enabled: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor seleccione una ubicacion';
                  }
                  return null;
                },
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
