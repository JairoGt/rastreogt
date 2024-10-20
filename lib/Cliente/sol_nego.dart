import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:gsheets/gsheets.dart';
import 'package:rastreogt/Cliente/mapacentral.dart';
import 'package:rastreogt/conf/export.dart';

String _credentials = dotenv.env['GOOGLE_CREDENTIALS']!;

String _spreadsheetId = dotenv.env['GOOGLE_SHEET_ID']!;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _nombreNegocioController = TextEditingController();
  final _direccionController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _codigoGeneradoController =
      TextEditingController();
  final TextEditingController _codigoManualController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  String nick = '';
  String? _originalCoordinates;
  bool _codigoManual = false;

  Future<void> _fetchUserInfo() async {
    try {
      DocumentSnapshot userInfo = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.email)
          .collection('userData')
          .doc('pInfo')
          .get();

      if (userInfo.exists) {
        Map<String, dynamic> data = userInfo.data() as Map<String, dynamic>;
        setState(() {
          nick = data['nickname'] ??
              'Sin apodo'; // Proveer valor por defecto si es null
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la información $e')),
      );
      debugPrint("$e");
    }
  }

  @override
  void initState() {
    super.initState();
    _nombreNegocioController.addListener(_actualizarCodigo);
    _actualizarCodigo(); // Inicializar el código
    _fetchUserInfo();
  }

  void _limpiarCampos() {
    setState(() {
      _nombreNegocioController.clear();
      _direccionController.clear();
      _ubicacionController.clear();
      _codigoGeneradoController.clear();
      _codigoManualController.clear();
      _codigoManual = false;
      _originalCoordinates = null;
    });
  }

  void _actualizarCodigo() {
    if (_codigoManual == true) {
      setState(() {
        _codigoGeneradoController.text = _generarCodigo();
      });
    } else {
      setState(() {
        _codigoGeneradoController.text = _generarCodigo();
      });
    }
  }

  String _generarCodigo() {
    String email = user?.email ?? '';
    String nombreNegocio = _nombreNegocioController.text;

    if (email.isEmpty || nombreNegocio.isEmpty) {
      return '';
    }

    String primeraLetraEmail = email[0].toUpperCase();
    List<String> palabrasNegocio =
        nombreNegocio.split(' ').where((p) => p.isNotEmpty).toList();
    String primeraLetraNombre =
        palabrasNegocio.isNotEmpty ? palabrasNegocio[0][0].toUpperCase() : '';
    String segundaLetraNombre =
        palabrasNegocio.length > 1 ? palabrasNegocio[1][0].toUpperCase() : '';

    return '$primeraLetraEmail$primeraLetraNombre$segundaLetraNombre';
  }

  Future<void> _enviarDatos() async {
    if (_credentials != null) {
      try {
        // Reemplaza \" con "
        String unescapedCredentials = _credentials.replaceAll(r'\"', '"');

        // Decodifica el JSON sin escapar
        var credentialsJson = jsonDecode(unescapedCredentials);
        print("Credenciales decodificadas: $credentialsJson");
      } catch (e) {
        print("Error al decodificar las credenciales: $e");
      }
    } else {
      print("No se encontró GOOGLE_CREDENTIALS en el archivo .env");
    }

    print("Spreadsheet ID: $_spreadsheetId");
    try {
      final gsheets = GSheets(_credentials);
      final ss = await gsheets.spreadsheet(_spreadsheetId);
      var sheet = ss.worksheetByTitle('rastreogt');
      sheet ??= await ss.addWorksheet('rastreogt');

      String codigo =
          _codigoManual ? _codigoGeneradoController.text : _generarCodigo();

      // Verificar si el código ya existe en Google Sheets
      final existingCodes = await sheet.values.column(6);
      if (existingCodes.contains(codigo) && !_codigoManual) {
        setState(() {
          _codigoManual = true;
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Código Duplicado'),
              content: const Text(
                  'El código generado ya existe, por favor, ingresa uno manualmente.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }
      final data = [
        user!.email?.toUpperCase(),
        _nombreNegocioController.text,
        'Solicitud Creada',
        _direccionController.text,
        DateTime.now().toIso8601String(),
        codigo,
      ];

      final result = await sheet.values.appendRow(data);
      if (result) {
        // Guardar en Firebase
        final firestore = FirebaseFirestore.instance;
        final userEmail = user?.email ?? '';
        final negocioIdBase = userEmail.split('@')[0];
        String negocioId = negocioIdBase;
        int counter = 1;

        while ((await firestore
                .collection('users')
                .doc(userEmail)
                .collection('negocios')
                .doc(negocioId)
                .get())
            .exists) {
          negocioId = '$negocioIdBase$counter';
          counter++;
        }

        Map<String, dynamic> firestoreData = {
          'email': user?.email,
          'nego': _nombreNegocioController.text,
          'negoname': codigo,
          'estadoid': 0,
          'direccion': _direccionController.text,
          'idBussiness': negocioId,
          'fechaSolicitud': DateTime.now().toIso8601String(),
        };

        // Agregar coordenadas si están disponibles
        if (_originalCoordinates != null && _originalCoordinates!.isNotEmpty) {
          final coordinates = _originalCoordinates!.split(',');
          if (coordinates.length == 2) {
            try {
              final latitude = double.parse(coordinates[0]);
              final longitude = double.parse(coordinates[1]);
              firestoreData['ubicacionnego'] = GeoPoint(latitude, longitude);
            } catch (e) {
              debugPrint('Error al parsear las coordenadas: $e');
            }
          }
        }

        try {
          await firestore
              .collection('users')
              .doc(userEmail)
              .collection('negocios')
              .doc(negocioId)
              .set(firestoreData);

          debugPrint('Datos enviados a Firebase correctamente');
          debugPrint('Dirección guardada: ${firestoreData['direccion']}');
          debugPrint('Ubicación guardada: ${firestoreData['ubicacionnego']}');
        } catch (e) {
          debugPrint('Error al enviar datos a Firebase: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al enviar datos a Firebase: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Solicitud Creada'),
              content: const Text('Tu solicitud ha sido creada correctamente.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        if (_originalCoordinates == null || _originalCoordinates!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Advertencia: No se seleccionó una ubicación'),
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
    } catch (e) {
      debugPrint('Error general al enviar los datos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar los datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    _limpiarCampos();
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapasC(),
      ),
    );

    if (result != null) {
      final coordinates = result.split(',');
      final latitude = double.parse(coordinates[0]);
      final longitude = double.parse(coordinates[1]);

      try {
        _originalCoordinates = result;

        List<Placemark> placemarks =
            await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
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
        setState(() {
          _ubicacionController.text = 'Error al obtener la dirección';
        });
      }
    }
  }

  @override
  void dispose() {
    _nombreNegocioController.dispose();
    _direccionController.dispose();
    _ubicacionController.dispose();
    _codigoGeneradoController.dispose();
    _codigoManualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitud de Negocio'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: TextEditingController(text: user?.email),
                  decoration: const InputDecoration(labelText: 'Email'),
                  readOnly: true,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nombreNegocioController,
                  decoration:
                      const InputDecoration(labelText: 'Nombre del Negocio'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'No puede estar vacío';
                    } else if (!RegExp(
                            r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ]+([ ]*[a-zA-ZáéíóúÁÉÍÓÚñÑ]+)*$')
                        .hasMatch(value)) {
                      return 'El nombre debe comenzar y terminar con letras, y solo puede \ncontener letras, espacios y acentos';
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
                      return 'No Puede estar vacío';
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
                TextFormField(
                  controller: _codigoGeneradoController,
                  decoration:
                      const InputDecoration(labelText: 'Código Generado'),
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El código no puede estar vacío';
                    } else if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
                      return 'El código solo puede contener letras, no se permite espacios';
                    } else if (value.length > 3) {
                      return 'El código no puede tener más de 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (_codigoManual)
                  TextFormField(
                    controller: _codigoGeneradoController,
                    decoration:
                        const InputDecoration(labelText: 'Código Manual'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El código no puede estar vacío';
                      } else if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
                        return 'El código solo puede contener letras';
                      } else if (value.length > 3) {
                        return 'El código no puede tener más de 3 caracteres';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Si el formulario es válido, muestra un snackbar o realiza alguna acción

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Enviando datos...'),
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
                      await _enviarDatos();
                    } else {
                      // Si el formulario no es válido, actualiza el estado para mostrar los errores
                      setState(() {});
                    }
                  },
                  child: const Text('Enviar'),
                ),
                const SizedBox(height: 80),
                ElevatedButton(
                  onPressed: _mostrarEstadoNegocio,
                  child: const Text('Ver mis solicitudes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarEstadoNegocio() async {
    try {
      // Reemplaza \" con "
      String unescapedCredentials = _credentials.replaceAll(r'\"', '"');

      // Decodifica el JSON sin escapar
      var credentialsJson = jsonDecode(unescapedCredentials);
      final gsheets = GSheets(credentialsJson); // Define _credentials
      final ss = await gsheets.spreadsheet(_spreadsheetId);
      var sheet = ss.worksheetByTitle('rastreogt');

      if (sheet == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo encontrar la hoja de cálculo'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Leer las columnas de la hoja (correo electrónico en la primera, nombre del negocio en la segunda, estado en la tercera)
      final correos = await sheet.values
          .column(1); // Suponiendo que los correos están en la columna 1
      final nombresNegocios = await sheet.values.column(2);
      final estadosNegocios = await sheet.values.column(3);

      if (correos.isEmpty ||
          nombresNegocios.isEmpty ||
          estadosNegocios.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay datos en la hoja'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Obtener el correo del usuario (puedes reemplazar esto por la manera en que obtienes el correo del usuario logueado)
      final correoUsuario = user!.email!
          .toUpperCase(); // Cambia esto por tu correo electrónico actual

      // Filtrar solo los negocios asociados al correo electrónico del usuario
      List<String> negociosFiltrados = [];
      List<String> estadosFiltrados = [];

      for (int i = 0; i < correos.length; i++) {
        if (correos[i] == correoUsuario) {
          negociosFiltrados.add(nombresNegocios[i]);
          estadosFiltrados.add(estadosNegocios[i]);
        }
      }

      if (negociosFiltrados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontraron negocios asociados a tu correo'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Mostrar el nombre del negocio y el estado en un AlertDialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Estado de mis solicitudes'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < negociosFiltrados.length; i++)
                  ListTile(
                    title: Text(negociosFiltrados[i]),
                    subtitle: Text('Estado: ${estadosFiltrados[i]}'),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cerrar',
                  style: GoogleFonts.podkova(
                      textStyle:
                          const TextStyle(color: Colors.blue, fontSize: 20)),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('$e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener los datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
