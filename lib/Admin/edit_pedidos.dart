import 'package:rastreogt/conf/export.dart';

class EditPedidos extends StatefulWidget {
  const EditPedidos({super.key});

  @override
  _EditPedidosState createState() => _EditPedidosState();
}

class _EditPedidosState extends State<EditPedidos> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idPedidoController = TextEditingController();
  final List<TextEditingController> _productoControllers = [];
  final List<TextEditingController> _precioControllers = [];
  var _sumaTotal = 0.0;
  bool _isPedidoLoaded = false;
  final List<Map<String, String>> _productos = [];
void mostrarDialogo(BuildContext context, String titulo, String mensaje, bool esExitoso) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                esExitoso ? 'assets/lotties/correct.json' : 'assets/lotties/error.json',
                width: 100,
                height: 100,
                fit: BoxFit.fill,
              ),
              const SizedBox(height: 10),
              Text(mensaje),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }
  Future<void> _buscarPedido() async {
    if (!mounted) return;
    final idPedido = _idPedidoController.text.toUpperCase();
    if (idPedido.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor ingrese un ID de pedido')));
      return;
    }
 
    final pedidoDoc = await FirebaseFirestore.instance.collection('pedidos').doc(idPedido).get();
  if (!mounted) return;
    if (!pedidoDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido no encontrado')));
      return;
    } 
 final pedidoData = pedidoDoc.data() as Map<String, dynamic>;
  if (pedidoData['estadoid'] == 3) {
    mostrarDialogo(context, 'Error', 'El pedido ya está en camino', false);
    return;
  }

    final productos = await FirebaseFirestore.instance.collection('pedidos').doc(idPedido).collection('Productos').get();
    _productos.clear();
    _productoControllers.clear();
    _precioControllers.clear();

    for (var producto in productos.docs) {
      final data = producto.data();
      for (int i = 1; i <= 5; i++) {
        final nombreKey = 'producto$i';
        final precioKey = 'precio$i';
        if (data.containsKey(nombreKey) && data.containsKey(precioKey)) {
          final nombre = data[nombreKey]?.toString() ?? '';
          final precio = data[precioKey]?.toString() ?? '';
          if (nombre.isNotEmpty && precio.isNotEmpty) {
            _productos.add({'nombre': nombre, 'precio': precio});
            _productoControllers.add(TextEditingController(text: nombre));
            _precioControllers.add(TextEditingController(text: precio));
          }
        }
      }
    }

    _calcularTotal();

    setState(() {
      _isPedidoLoaded = true;
    });
  }

  void _calcularTotal() {
    var suma = 0.0;
    for (var controller in _precioControllers) {
      if (controller.text.isNotEmpty) {
        final precio = double.tryParse(controller.text) ?? 0.0;
        suma += precio;
      }
    }
    setState(() {
      _sumaTotal = suma;
    });
  }

  Widget _buildIdPedidoField() {
    return TextFormField(
      controller: _idPedidoController,
      decoration: const InputDecoration(
        labelText: 'ID Pedido',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildBuscarButton() {
    return ElevatedButton(
      onPressed: _buscarPedido,
      child: const Text('Buscar Pedido'),
    );
  }

  List<Widget> _buildProductoPrecioFields() {
    List<Widget> fields = [];
    for (int i = 0; i < _productoControllers.length; i++) {
      fields.add(Row(
        children: [
        Expanded(
              child: TextFormField(
                controller: _productoControllers[i],
                decoration: InputDecoration(
                  labelText: 'Producto ${i + 1}',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El producto no puede \nestar vacío';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 15),
            SizedBox(
              width: 90, // Ajusta el ancho según tus necesidades
              child: TextFormField(
                controller: _precioControllers[i],
                decoration: InputDecoration(
                  labelText: 'Precio ${i + 1}',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _calcularTotal(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El precio \nno puede \nestar vacío';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 15),
            IconButton(
              icon: const Icon(Icons.remove_circle),
              onPressed: () {
                setState(() {
                  _productoControllers.removeAt(i);
                  _precioControllers.removeAt(i);
                  _calcularTotal();
                });
              },
            ),
        ],
      ));
      fields.add(const SizedBox(height: 20));
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

  Widget _buildTotalField() {
    return Text(
      'Total: Q $_sumaTotal',
      style: GoogleFonts.asul(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildGuardarButton() {
  return ElevatedButton(
    onPressed: () async {
      if (_formKey.currentState!.validate()) {
        try {
          FirebaseFirestore firestore = FirebaseFirestore.instance;
          CollectionReference users = firestore.collection('pedidos');
          DocumentReference userDocument = users.doc(_idPedidoController.text.toUpperCase());
          CollectionReference userData = userDocument.collection('Productos');
          DocumentReference pInfoDocument = userData.doc(_idPedidoController.text.toUpperCase());

          // Inicializa el mapa para almacenar los datos del pedido
          Map<String, dynamic> pInfoData = {};

          // Agrega los productos y precios al mapa con claves dinámicas
          for (int i = 0; i < _productoControllers.length; i++) {
            pInfoData['producto${i + 1}'] = _productoControllers[i].text;
            pInfoData['precio${i + 1}'] = _precioControllers[i].text;
          }

          // Agrega la suma total y otros campos necesarios al mapa
          pInfoData['precioTotal'] = _sumaTotal;

          // Verifica si el documento existe
          DocumentSnapshot docSnapshot = await pInfoDocument.get();
          if (!docSnapshot.exists) {
            // Si el documento no existe, créalo
          
          
          } else {
            // Si el documento existe, actualízalo
          
            await pInfoDocument.set(pInfoData);
          }
          
          if(context.mounted){
            if(!mounted) return;
              showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
              Text('Datos modificados exitosamente',
              style: GoogleFonts.asul(
                fontSize: 20,
                fontWeight: FontWeight.bold,  
              ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
          }else{
            return;
          }
        if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos guardados exitosamente')));
        } catch (e) {
           ('Error al guardar los datos: $e');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar los datos: $e')));
        } 
      }
    },
    child: const Text('Guardar Cambios'),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Pedido'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildIdPedidoField(),
                const SizedBox(height: 20),
                _buildBuscarButton(),
                if (_isPedidoLoaded) ...[
                  const SizedBox(height: 20),
                  ..._buildProductoPrecioFields(),
                  const SizedBox(height: 20),
                ElevatedButton(
    onPressed: _agregarProducto,
    child: const Text('Agregar más'),
  ),
                  const SizedBox(height: 20),
                  _buildTotalField(),
                  const SizedBox(height: 20),
                  _buildGuardarButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}         