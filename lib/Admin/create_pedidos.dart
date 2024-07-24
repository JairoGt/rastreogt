// ignore_for_file: file_names, unused_element, non_constant_identifier_names

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:rastreogt/conf/export.dart';

String getGreeting() {
  final currentTime = DateTime.now();
  final hour = currentTime.hour;

  if (hour >= 5 && hour < 12) {
    return 'Buen día';
  } else if (hour >= 12 && hour < 18) {
    return 'Buena tarde';
  } else {
    return 'Buena noche';
  }
}

class CrearPedidoScreen extends StatefulWidget {
  const CrearPedidoScreen({super.key});

  @override
  State<CrearPedidoScreen> createState() => _CrearPedidoScreenState();
}

final now = DateTime.now();

class _CrearPedidoScreenState extends State<CrearPedidoScreen>
    with SingleTickerProviderStateMixin {
  final _nombresController = TextEditingController();
  final _precioTotalController = TextEditingController();
  final _direccionController = TextEditingController();
  final _nicknameController = TextEditingController();
   final List<TextEditingController> _productoControllers = [TextEditingController()];
  final List<TextEditingController> _precioControllers = [TextEditingController()];
  bool _isUserValidated = false;
  double _sumaTotal = 0.0;
  User? user = FirebaseAuth.instance.currentUser;
 
 GeoPoint _ubicacionNegocio = const GeoPoint(0, 0);
  // Obtener la hora y fecha del teléfono.
  // Convertir la hora y fecha a un objeto de tipo Timestamp.
  final timestamp = Timestamp.fromDate(now);

  // Declare an animation controller for the text field transitions
  late AnimationController _animationController;

  // Declare an animation for the text field opacity

  final _formKey = GlobalKey<FormState>();

  bool _isButtonEnabled = false;
  String contenido = '';
  String negoid = '';
  String direccion = '';
GeoPoint ubicacion = const GeoPoint(0, 0);
String token = '';
  @override
  void initState() {
    super.initState();
    mostrarContenido();
    mostrarNegoid();
   
    
    // Initialize the animation controller with a duration of one second
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Initialize the text field opacity animation with a curve and a range

    // Start the animation when the screen is loaded
    _animationController.forward();
  }

  Future<void> mostrarContenido() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference collectionRef = firestore.collection('users');
    final DocumentReference documentRef = collectionRef.doc('${user!.email}');
    final DocumentSnapshot doc = await documentRef.get();
    //Extraer las ubicaciones de la base de datos
     // Obtener la ubicación del cliente
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user?.email);
    final idBussiness = doc['idBussiness'];

    // Obtener la ubicación del negocio
    final negocioDoc = await userDoc.collection('negocios').doc(idBussiness).get();
    
    setState(() {
      contenido = doc['negoname'];
     
      
      _ubicacionNegocio = negocioDoc['ubicacionnego'];
     
      print('Ubicación del negocio: ${_ubicacionNegocio.latitude}, ${_ubicacionNegocio.longitude}');
    });
  }

  Future<void> dataNickname(String nickname) async {
    final String? email = await getEmailFromNickname(nickname);
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CollectionReference collectionRef = firestore.collection('users');
  final DocumentReference documentRef = collectionRef.doc(email).collection('userData').doc('pInfo');
  final DocumentSnapshot doc = await documentRef.get();
  // extraemos el tokenid para notificaciones del cliente
    final DocumentReference tokenclient = collectionRef.doc(email);
  final DocumentSnapshot doc2 = await tokenclient.get();
  
  if (doc.exists) {
    setState(() {
      direccion = doc['direccion'];
   ubicacion = doc['ubicacion'];
    token = doc2['token'];

    });
  } else {
    // Manejar el caso en que el documento no exista
    setState(() {
      direccion = 'No disponible';
     // ubicacion = 'No disponible';
    });
  }
}
   
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
// Dispose the animation controller when the screen is disposed
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

Widget _buildValidarButton() {
  return ElevatedButton(
    onPressed: (){
      dataNickname(_nicknameController.text);
      _validarUsuario(_nicknameController.text);
     //  ('ubi '+ubicacion);
     
    },
    child: const Text('Validar'),
  );
}

Widget _buildDireccionField() {

  return TextFormField(
    enabled: false,
    controller: direccion == '' ? _direccionController : TextEditingController(text: direccion),
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

Widget _buildAgregarProductoButton() {
  return ElevatedButton(
    onPressed: _agregarProducto,
    child: const Text('Agregar más'),
  );
}

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

Widget _buildCrearPedidoButton() {
  return ElevatedButton(
    onPressed: _isButtonEnabled ? _crearPedido : null,
    child: const Text('Crear pedido'),
  );
}

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

void _agregarProducto() {
  if (_productoControllers.length < 6) {
    setState(() {
      _productoControllers.add(TextEditingController());
      _precioControllers.add(TextEditingController());
    });
  }
}

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

Future<String?> getEmailFromNickname(String nickname) async {

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final QuerySnapshot querySnapshot = await firestore.collection('users')
      .where('nickname', isEqualTo: nickname)
      .limit(1)
      .get();
  
  if (querySnapshot.docs.isNotEmpty) {
    return querySnapshot.docs.first['email'];
  } else {
    return null;
  }
}

void _validarUsuario(String nickname) async {
  final String? email = await getEmailFromNickname(nickname);
  
  if (email != null) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference documentRef = firestore.collection('users').doc(email);
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
  }
}

void _actualizarListadoNombres() {
  final nombres = _nombresController.text.split(',');
  setState(() {
    _listadoNombres = nombres;
  });
}

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
              Text('Pedido creado exitosamente',
              style: GoogleFonts.asul(
                fontSize: 20,
                fontWeight: FontWeight.bold,  
              ),
              ),
              const SizedBox(height: 10),
              Text('ID del pedido: $idPedido',style: 
              GoogleFonts.asul(
                fontSize: 20,
                fontWeight: FontWeight.bold,  
              )
              ,),
            ],
          ),
          actions: [
            
            TextButton(onPressed: (){
              Clipboard.setData(ClipboardData(text: idPedido));
            // Limpiar los campos de generar pedido.
    _nombresController.clear();
    _precioTotalController.clear();
    _direccionController.clear();
    Navigator.pop(context);
    // Navegar a la pantalla de pedidos creados.
    Navigator.popAndPushNamed(context, '/asignacion');
            }, child: Text('Copiar ID'
            , style: GoogleFonts.asul(
                fontSize: 20,
                fontWeight: FontWeight.bold,  
              )
            )),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
  showDialog(context: context, builder: (context) => dialog);
}


void _crearPedido() async {
  // Obtener los datos del pedido del usuario.
  List<String> nombres = _productoControllers.map((controller) => controller.text).toList();
  List<double> precios = _precioControllers.map((controller) => double.tryParse(controller.text) ?? 0.0).toList();

  final random = Random();
  final idPedido = random.nextInt(3000) + 1; // Genera un número entre 1 y 3000
  final idPedidoFormateado = idPedido.toString().padLeft(3, '0'); // Asegura que tenga 3 dígitos
  final idPedidoSJP = '$contenido$idPedidoFormateado';

  // Crear el pedido en Cloud Firestore.
  FirebaseFirestore.instance.collection('pedidos').doc(idPedidoSJP).set({});
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference users = firestore.collection('pedidos');
  DocumentReference userDocument = users.doc(idPedidoSJP);
  Map<String, dynamic> data = {
    'direccion': direccion,
    'estadoid': 1,
    'idMotorista': '0',
    'idcliente': '0',
    'idpedidos': idPedidoSJP,
    'fechaCreacion': Timestamp.fromDate(now),
    'fechaEntrega': Timestamp.fromDate(now),
    'ubicacionCliente': ubicacion,
    'ubicacionNegocio': _ubicacionNegocio,
    'negoname': contenido,
    'nickname': _nicknameController.text,
    'nego': negoid,
  };

  await userDocument.set(data);

  CollectionReference userData = userDocument.collection('Productos');

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
  await userData.add(pInfoData);

  // Mostrar el mensaje emergente con el número de pedido generado.
  _mostrarMensajePedidoCreado(idPedidoSJP);

  // Mostrar un mensaje de confirmación.
  if (mounted){
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Pedido creado correctamente'),
    ),
  );
  }
}
  void _navegarAPedidosCreados() {
    // Limpiar los campos de generar pedido.
    _nombresController.clear();
    _precioTotalController.clear();
    _direccionController.clear();
    Navigator.pop(context);
    // Navegar a la pantalla de pedidos creados.
    Navigator.popAndPushNamed(context, '/asignacion');
  }
  // Mostrar un mensaje de confirmación.


void _mostrarDialogoAgregarProductos() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          List<TextEditingController> productoControllers = [TextEditingController()];
          List<TextEditingController> precioControllers = [TextEditingController()];
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
