// Importamos las bibliotecas necesarias
// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison, iterable_contains_unrelated_type
import 'package:rastreogt/conf/export.dart';

String nickname = '';
// Inicializamos Cloud Firestore
final firebaseFirestore = FirebaseFirestore.instance.collection('pedidos');
final now = DateTime.now();
// Colección de pedidos
final pedidosRef = FirebaseFirestore.instance.collection('pedidos');

final motoristasRef = FirebaseFirestore.instance.collection('users');
final User? user = FirebaseAuth.instance.currentUser;
// Clase principal de la aplicación
class AsignarPedidos extends StatefulWidget {
  const AsignarPedidos({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AsignarPedidosState createState() => _AsignarPedidosState();
}

// Estado de la aplicación
class _AsignarPedidosState extends State<AsignarPedidos> {
  // Lista de pedidos
  List<DocumentSnapshot> pedidos = [];

  // Lista de motoristas
  List<DocumentSnapshot> motoristas = [];

  // ID del pedido seleccionado
  late String _idPedido = '0';

  // ID del motorista seleccionado
  late String _idMotorista = '0';
   Future<void> obtenerNombreUsuario() async {
    DocumentSnapshot usuario = await FirebaseFirestore.instance.collection('users').doc(user?.email).get();
    setState(() {
     // nombreUsuario = user?.displayName ?? usuario['nickname'];
      nickname = usuario['negoname'];
    });
  }
  final timestamp = Timestamp.fromDate(now);

  @override
  void initState() {
    super.initState();
    obtenerNombreUsuario(); 
    // Obtener pedidos
    pedidosRef.where('estadoid', isEqualTo: 1)
    .where('negoname', isEqualTo: nickname)
    .snapshots().listen((snapshot) {
      pedidos = snapshot.docs;

      if (mounted) {
        setState(() {});
      }
    });

    // Obtener motoristas
    motoristasRef.snapshots().listen((snapshot) {
      motoristas = snapshot.docs;

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
     final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title:  Text('Asignar pedidos',style: 
        GoogleFonts.roboto(
          textStyle: const TextStyle(
            //color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        )
        ,),
      ),
      body: Stack(
        children: [
          Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themeNotifier.currentTheme.brightness == Brightness.dark
                ? [const Color.fromARGB(255, 95, 107, 143), const Color.fromARGB(255, 171, 170, 197)]
                      :
                  [const Color.fromARGB(255, 114, 130, 255), Colors.white],
                  begin: Alignment.centerLeft,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Lottie.asset(
                      'assets/lotties/estelas.json', 
                      fit: BoxFit.cover,
                      animate: true,
                      repeat: false
                      ),
         SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'SELECCIONA UN PEDIDO',
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 300,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    borderOnForeground: true,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    child: ListView.separated(
                        separatorBuilder: (BuildContext context, int index) =>
                            const Divider(),
                        physics: const ClampingScrollPhysics(),
                        itemCount: pedidos.length,
                        itemBuilder: (context, index) {
                          return FutureBuilder<DocumentSnapshot>(
                            future: pedidosRef
                                .doc(pedidos[index].id)
                                .collection('Productos')
                                .doc(pedidos[index].id)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return const Text(
                                    'Error al cargar el precio total');
                              } else if (!snapshot.hasData ||
                                  !snapshot.data!.exists) {
                                return const Text(
                                    'No se encontraron datos correcto del pedido');
                              } else {
                                final preciototal = snapshot.data!['precioTotal'];
                                return CheckboxListTile(
                                  title: Text(
                                    pedidos[index]['idpedidos'] +
                                        ' \n Entrega en: ' +
                                        pedidos[index]['direccion'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(preciototal.toString()),
                                  value: _idPedido == pedidos[index].id,
                                  onChanged: (value) {
                                    _idPedido = value! ? pedidos[index].id : '';
                                    setState(() {});
                                  },
                                );
                              }
                            },
                          );
                        }),
                  ),
                ),
              ),
        
              const Text(
                'SELECCIONA AL MOTORISTA ',
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
              ),
              // Lista de motoristas
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 300,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          borderOnForeground: true,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(12)),
                          ),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: motoristasRef
                                .where('role', isEqualTo: 'moto')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return ListView.separated(
                                  separatorBuilder:
                                      (BuildContext context, int index) =>
                                          const Divider(),
                                  itemCount: snapshot.data!.docs.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      // height: 50,
                                      color:
                                          Theme.of(context).colorScheme.inversePrimary,
                                      child: CheckboxListTile(
                                        title: Text(
                                          snapshot.data!.docs[index]['name'],
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                            snapshot.data!.docs[index]['idmoto']),
                                        value: _idMotorista ==
                                            snapshot.data!.docs[index]['email'],
                                        onChanged: (value) {
                                          // Actualiza el valor de _idMotorista
                                          _idMotorista = value!
                                              ? snapshot.data!.docs[index]
                                                  ['email']
                                              : '';
                                          // Actualiza el widget
                                          if (mounted) {
                                            setState(() {});
                                          }
                                        },
                                      ),
                                    );
                                  },
                                  physics: const ClampingScrollPhysics(),
                                  shrinkWrap: true,
                                  primary: false,
                                );
                              } else {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
     ] ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Container(height: 50.0),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.green // Si el tema es oscuro, usa texto blanco
            : Colors.blueAccent,
        onPressed: () async {
          //print(_idPedido);

          try {
// Mostrar un mensaje de error
            if (_idPedido == '0' || _idMotorista == '0') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('No se ha seleccionado ningún Motorista o Pedido'),
                ),
              );
              return;
            } else {
              try {
                await pedidosRef.doc(_idPedido).update({
                  'idMotorista': _idMotorista,
                  'estadoid': 2,
                  'fechadespacho': Timestamp.fromDate(now),
                });

// Navegar a otra página

                Navigator.popAndPushNamed(context, '/listaPedidos');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
// ignore: prefer_interpolation_to_compose_strings
                    content: Text('Pedido Asignado'),
                  ),
                );
              } catch (e) {
                // Mostrar un mensaje de error
                ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
// ignore: prefer_interpolation_to_compose_strings
                    content: Text('Alerta estas dejando un campo vacio  $e'),
                  ),
                );
                Navigator.popAndPushNamed(context, '/asignacion');
              }
            }
          } on FirebaseException {
            Navigator.popAndPushNamed(context, '/asignacion');

// Mostrar un mensaje de error
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Error no has seleccionado el Pedido o al motorista asegurate de seleccionar a los 2 '),
              ),
            );
          }
        },
        child: const Icon(Icons.assignment_sharp),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
