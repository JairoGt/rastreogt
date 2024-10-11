// ignore_for_file: file_names, unused_element, non_constant_identifier_names
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:rastreogt/conf/export.dart';

// Pantalla para crear un pedido.
class CrearPedidoScreen extends StatefulWidget {
  const CrearPedidoScreen({super.key});

  @override
  State<CrearPedidoScreen> createState() => _CrearPedidoScreenState();
}

// Define la hora y fecha actual.
final now = DateTime.now();

class _CrearPedidoScreenState extends State<CrearPedidoScreen>
    with SingleTickerProviderStateMixin {
  // Define los controladores de texto para los campos de texto.
  final _nombresController = TextEditingController();
  final _precioTotalController = TextEditingController();
  final _direccionController = TextEditingController();
  final _nicknameController = TextEditingController();
  final List<TextEditingController> _productoControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _precioControllers = [
    TextEditingController()
  ];
  // Define las variables para validar el usuario y calcular la suma total.
  bool _isUserValidated = false;
  double _sumaTotal = 0.0;
  User? user = FirebaseAuth.instance.currentUser;

  GeoPoint _ubicacionNegocio = const GeoPoint(0, 0);
  // Obtener la hora y fecha del teléfono.
  // Convertir la hora y fecha a un objeto de tipo Timestamp.
  final timestamp = Timestamp.fromDate(now);

  // Declarar un controlador de animación
  late AnimationController _animationController;

  // Declara una clave global para el formulario
  final _formKey = GlobalKey<FormState>();

  bool _isButtonEnabled = false;
  String contenido = '';
  String negoid = '';
  String direccion = '';
  String emailuser = '';
  GeoPoint ubicacion = const GeoPoint(0, 0);
  String token = '';

  // Inicializa el estado del widget y llama a la función mostrarContenido y mostrarNegoid.
  @override
  void initState() {
    super.initState();
    mostrarContenido();
    mostrarNegoid();
    // Inicializa el controlador de animación
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animationController.forward();
  }

//Extraer el contenido del negocio para el pedido
// Funcion Future para obtener el contenido del negocio
  Future<void> mostrarContenido() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference collectionRef = firestore.collection('users');
    final DocumentReference documentRef = collectionRef.doc('${user!.email}');
    final DocumentSnapshot doc = await documentRef.get();

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user?.email);
    final idBussiness = doc['idBussiness'];
    try {
      // Obtener la ubicación del negocio
      final negocioDoc =
          await userDoc.collection('negocios').doc(idBussiness).get();

      setState(() {
        contenido = doc['negoname'];
        _ubicacionNegocio = negocioDoc['ubicacionnego'];
      });
    } catch (e) {
      // Manejar el caso en que el documento no exista
      AlertDialog(
        title: const Text('Error'),
        content: Text('Error al obtener el contenido del negocio: $e'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cerrar'),
          ),
        ],
      );
    }
  }

  //Extraer la dirección y ubicación del cliente
  Future<void> dataNickname(String nickname) async {
    final String? email = await getEmailFromNickname(nickname);
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference collectionRef = firestore.collection('users');
    // Extraer el email desde el documento en la colección 'users'
    final DocumentReference userDocRef = collectionRef.doc(email);
    final DocumentSnapshot userDoc = await userDocRef.get();
    final DocumentReference documentRef =
        collectionRef.doc(email).collection('userData').doc('pInfo');
    final DocumentSnapshot doc = await documentRef.get();
    // se extrae tokenid para notificaciones del cliente
    final DocumentReference tokenclient = collectionRef.doc(email);
    final DocumentSnapshot doc2 = await tokenclient.get();
    try {
      if (doc.exists) {
        setState(() {
          direccion = doc['direccion'];
          ubicacion = doc['ubicacion'];
          emailuser = userDoc['email'];
          token = doc2['token'];
        });
      } else {
        // Manejar el caso en que el documento no exista
        setState(() {
          direccion = 'No disponible';
          // ubicacion = 'No disponible';
        });
      }
    } catch (e) {
      AlertDialog(
        title: const Text('Error'),
        content: Text('Error al obtener la dirección del cliente: $e'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cerrar'),
          ),
        ],
      );
    }
  }

  //Extraer el negocio id de la base de datos para el pedido
  Future<void> mostrarNegoid() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference collectionRef = firestore.collection('users');
    final DocumentReference documentRef = collectionRef.doc('${user!.email}');
    final DocumentSnapshot doc = await documentRef.get();
    setState(() {
      negoid = doc['nego'];
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Pedido'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Muestra el saludo y el nombre del usuario.
                //Llamamos todas las funciones que necesitamos para el pedido
                _buildNicknameField(),
                const SizedBox(height: 20.0),
                _buildValidarButton(),
                const SizedBox(height: 20),
                if (_isUserValidated) ...[
                  _buildDireccionField(),
                  const SizedBox(height: 20),
                  ..._buildProductoPrecioFields(),
                  const SizedBox(height: 20),
                  _buildAgregarProductoButton(),
                  const SizedBox(height: 20),
                  _buildSumaTotalField(),
                  const SizedBox(height: 20),
                  _buildCrearPedidoButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

// Define el campo de texto para el nickname del usuario.
  Widget _buildNicknameField() {
    return TextFormField(
      controller: _nicknameController,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        labelText: 'Nickname del usuario',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, ingrese el nickname del usuario';
        }
        return null;
      },
    );
  }

// Define el botón para validar el usuario.
  Widget _buildValidarButton() {
    return ElevatedButton(
      onPressed: () {
        dataNickname(_nicknameController.text);
        _validarUsuario(_nicknameController.text);
        //  ('ubi '+ubicacion);
      },
      child: const Text('Validar'),
    );
  }

// Define el campo de texto para la dirección de entrega.
  Widget _buildDireccionField() {
    return TextFormField(
      enabled: false,
      controller: direccion == ''
          ? _direccionController
          : TextEditingController(text: direccion),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        labelText: 'Dirección de entrega',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, ingrese la dirección de entrega';
        }
        return null;
      },
      onChanged: (value) {
        _isButtonEnabled = _formKey.currentState!.validate();
      },
    );
  }

// Define el botón para agregar más productos.
  Widget _buildAgregarProductoButton() {
    return ElevatedButton(
      onPressed: _agregarProducto,
      child: const Text('Agregar más'),
    );
  }

// Define el campo de texto para la suma total del pedido.
  Widget _buildSumaTotalField() {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        labelText: 'Suma total',
      ),
      controller: TextEditingController(text: _sumaTotal.toStringAsFixed(2)),
    );
  }

// Define el botón para crear el pedido y llama a la función _crearPedido.
  Widget _buildCrearPedidoButton() {
    return ElevatedButton(
      onPressed: _isButtonEnabled ? _crearPedido : null,
      child: const Text('Crear pedido'),
    );
  }

// Define los campos de texto para los productos y precios.
  List<Widget> _buildProductoPrecioFields() {
    List<Widget> fields = [];
    for (int i = 0; i < _productoControllers.length; i++) {
      fields.add(
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _productoControllers[i],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      labelText: 'Nombre del producto ${i + 1}',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingrese el nombre del producto';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 88,
                  child: TextFormField(
                    controller: _precioControllers[i],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      labelText: 'Precio ${i + 1}',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingrese el precio del producto';
                      }
                      final precio = double.tryParse(value);
                      if (precio == null || precio <= 0) {
                        return 'Por favor, ingrese un número positivo';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _calcularSumaTotal();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }
    return fields;
  }

// Define la función para agregar más productos.
  void _agregarProducto() {
    if (_productoControllers.length < 6) {
      setState(() {
        _productoControllers.add(TextEditingController());
        _precioControllers.add(TextEditingController());
      });
    }
  }

// Define la función para calcular la suma total del pedido.
  void _calcularSumaTotal() {
    double suma = 0.0;
    for (var controller in _precioControllers) {
      final precio = double.tryParse(controller.text);
      if (precio != null) {
        suma += precio;
      }
    }
    setState(() {
      _sumaTotal = suma;
      _isButtonEnabled = _formKey.currentState!.validate();
    });
  }

// Define la función para obtener el email a partir del nickname.
  Future<String?> getEmailFromNickname(String nickname) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final QuerySnapshot querySnapshot = await firestore
        .collection('users')
        .where('nickname', isEqualTo: nickname)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first['email'];
    } else {
      return null;
    }
  }

// Define la función para validar el usuario.
  void _validarUsuario(String nickname) async {
    final String? email = await getEmailFromNickname(nickname);

    if (email != null) {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final DocumentReference documentRef =
          firestore.collection('users').doc(email);
      final DocumentSnapshot doc = await documentRef.get();

      if (doc.exists) {
        setState(() {
          _isUserValidated = true;
        });
      } else {
        setState(() {
          _isUserValidated = false;
        });
        ('El usuario con el email $email no existe');
      }
    } else {
      setState(() {
        _isUserValidated = false;
      });
      ('El nickname $nickname no existe');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El nickname  $nickname no existe'),
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

// Define la función para actualizar el listado de nombres.
  void _actualizarListadoNombres() {
    final nombres = _nombresController.text.split(',');
    setState(() {
      _listadoNombres = nombres;
    });
  }

// Define la función para mostrar un mensaje emergente con el número de pedido generado.
  void _mostrarMensajePedidoCreado(String idPedido) {
    final dialog = AlertDialog(
      title: const Text("Exito"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/lotties/correct.json',
            width: 200,
            height: 200,
            animate: true,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 10),
          Text(
            'Pedido creado exitosamente',
            style: GoogleFonts.asul(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ID del pedido: $idPedido',
            style: GoogleFonts.asul(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: idPedido));
              _navegarAPedidosCreados();
            },
            child: Text('Copiar ID',
                style: GoogleFonts.asul(
                  color: Theme.of(context).colorScheme.inverseSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ))),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
    showDialog(context: context, builder: (context) => dialog);
  }

// Define la función para crear el pedido.
  void _crearPedido() async {
    // Obtener los datos del pedido del usuario.
    List<String> nombres =
        _productoControllers.map((controller) => controller.text).toList();
    List<double> precios = _precioControllers
        .map((controller) => double.tryParse(controller.text) ?? 0.0)
        .toList();

    final random = Random();
    final idPedido =
        random.nextInt(3000) + 1; // Genera un número entre 1 y 3000
    final idPedidoFormateado =
        idPedido.toString().padLeft(3, '0'); // Asegura que tenga 3 dígitos
    final idPedidoSJP = '$contenido$idPedidoFormateado';

    // Crear el pedido .
    FirebaseFirestore.instance.collection('pedidos').doc(idPedidoSJP).set({});
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference users = firestore.collection('pedidos');
    DocumentReference userDocument = users.doc(idPedidoSJP);
    Map<String, dynamic> data = {
      'direccion': direccion,
      'estadoid': 1,
      'idMotorista': '0',
      'idcliente': emailuser,
      'idpedidos': idPedidoSJP,
      'fechaCreacion': Timestamp.fromDate(now),
      'fechaEntrega': Timestamp.fromDate(now),
      'ubicacionCliente': ubicacion,
      'ubicacionNegocio': _ubicacionNegocio,
      'negoname': contenido,
      'observaciones': '',
      'nickname': _nicknameController.text,
      'nego': negoid,
    };

    await userDocument.set(data);

    CollectionReference userData = userDocument.collection('Productos');
    DocumentReference prod = userData.doc(idPedidoSJP);

    // Inicializa el mapa para almacenar los datos del pedido
    Map<String, dynamic> pInfoData = {};

    // Agrega los productos y precios al mapa con claves dinámicas
    for (int i = 0; i < nombres.length; i++) {
      pInfoData['producto${i + 1}'] = nombres[i];
      pInfoData['precio${i + 1}'] = precios[i];
    }

    // Agrega la suma total y otros campos necesarios al mapa
    pInfoData['precioTotal'] = _sumaTotal;
    pInfoData['telefono'] = 0;
    pInfoData['ubicacion'] = ubicacion;
    pInfoData['token'] = token;

    // Guarda el mapa en Firestore
    await prod.set(pInfoData);

    // Mostrar el mensaje emergente con el número de pedido generado.
    _mostrarMensajePedidoCreado(idPedidoSJP);

    // Mostrar un mensaje de confirmación.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pedido creado con éxito'),
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

  // Navegar a la pantalla de pedidos creados.(Asignar motorista)
  void _navegarAPedidosCreados() {
    // Limpiar los campos de generar pedido.
    _nombresController.clear();
    _precioTotalController.clear();
    _direccionController.clear();
    Navigator.pop(context); // Cierra el drawer
    Navigator.pushNamed(context, '/asignacion');
  }

// Define la función para mostrar un diálogo con los campos para agregar productos.
  void _mostrarDialogoAgregarProductos() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            List<TextEditingController> productoControllers = [
              TextEditingController()
            ];
            List<TextEditingController> precioControllers = [
              TextEditingController()
            ];
            double sumaTotal = 0.0;

            void agregarCampoProducto() {
              if (productoControllers.length < 6) {
                setState(() {
                  productoControllers.add(TextEditingController());
                  precioControllers.add(TextEditingController());
                });
              }
            }

            void actualizarSumaTotal() {
              double suma = 0.0;
              for (var controller in precioControllers) {
                double? precio = double.tryParse(controller.text);
                if (precio != null) {
                  suma += precio;
                }
              }
              setState(() {
                sumaTotal = suma;
              });
            }

            return AlertDialog(
              title: const Text('Agregar Productos'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < productoControllers.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: productoControllers[i],
                                decoration: InputDecoration(
                                  labelText: 'Producto ${i + 1}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: precioControllers[i],
                                decoration: InputDecoration(
                                  labelText: 'Precio ${i + 1}',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) => actualizarSumaTotal(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: agregarCampoProducto,
                      child: const Text('+'),
                    ),
                    const SizedBox(height: 20),
                    Text('Suma Total: \$$sumaTotal'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Listado de nombres de productos.
List<String> _listadoNombres = [];
