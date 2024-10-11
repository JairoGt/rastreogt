// Importamos las bibliotecas necesarias
// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison, iterable_contains_unrelated_type
import 'package:rastreogt/conf/export.dart';

String nickname = '';
final firebaseFirestore = FirebaseFirestore.instance.collection('pedidos');
final now = DateTime.now();
final pedidosRef = FirebaseFirestore.instance.collection('pedidos');
final motoristasRef = FirebaseFirestore.instance.collection('motos');
final User? user = FirebaseAuth.instance.currentUser;

class AsignarPedidos extends StatefulWidget {
  const AsignarPedidos({super.key});

  @override
  _AsignarPedidosState createState() => _AsignarPedidosState();
}

class _AsignarPedidosState extends State<AsignarPedidos> {
  List<DocumentSnapshot> pedidos = [];
  List<DocumentSnapshot> motoristas = [];
  late String _idPedido = '0';
  late String _idMotorista = '0';

  Future<void> obtenerNombreUsuario() async {
    DocumentSnapshot usuario = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.email)
        .get();
    setState(() {
      nickname = usuario['negoname'];
    });
    // Llamar a _fetchPedidos después de obtener el nickname
    _fetchPedidos();
    _fetchMotoristas();
  }

  Future<List<DocumentSnapshot>> _fetchPedidos() async {
    QuerySnapshot snapshot = await pedidosRef
        .where('estadoid', isEqualTo: 1)
        .where('negoname', isEqualTo: nickname)
        .get();
    return snapshot.docs;
  }

  Future<List<DocumentSnapshot>> _fetchMotoristas() async {
    QuerySnapshot snapshot = await motoristasRef
        .where("estadoid", isEqualTo: 1)
        .where("negoname", isEqualTo: nickname)
        .get();
    return snapshot.docs;
  }

  @override
  void initState() {
    super.initState();
    obtenerNombreUsuario();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        elevation: 0,
        title: Text(
          'Asignar pedidos',
          style: GoogleFonts.roboto(
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      body: Stack(children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: themeNotifier.currentTheme.brightness == Brightness.dark
                  ? [
                      const Color.fromARGB(255, 95, 107, 143),
                      const Color.fromARGB(255, 171, 170, 197)
                    ]
                  : [const Color.fromARGB(255, 114, 130, 255), Colors.white],
              begin: Alignment.centerLeft,
              end: Alignment.bottomCenter,
            ),
          ),
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
                    child: FutureBuilder<List<DocumentSnapshot>>(
                      future: _fetchPedidos(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return const Text('Error al cargar los pedidos');
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Text(
                            ' No se encontraron pedidos',
                            style: GoogleFonts.roboto(
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        } else {
                          pedidos = snapshot.data!;
                          return ListView.separated(
                            separatorBuilder:
                                (BuildContext context, int index) =>
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
                                        '  Error al cargar el precio total');
                                  } else if (!snapshot.hasData ||
                                      !snapshot.data!.exists) {
                                    return Text(
                                      '  No se encontraron datos correctos del pedido',
                                      style: GoogleFonts.roboto(
                                        textStyle: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  } else {
                                    final preciototal =
                                        snapshot.data!['precioTotal'];
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
                                      subtitle: RichText(
                                        text: TextSpan(
                                          text: 'Total: ',
                                          style: const TextStyle(
                                            // color: Colors.black,
                                            fontSize: 16,
                                          ),
                                          children: <TextSpan>[
                                            TextSpan(
                                              text:
                                                  'Q${preciototal.toString()}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  '  -  ${pedidos[index]['nickname']}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      value: _idPedido == pedidos[index].id,
                                      onChanged: (value) {
                                        _idPedido =
                                            value! ? pedidos[index].id : '';
                                        setState(() {});
                                      },
                                    );
                                  }
                                },
                              );
                            },
                          );
                        }
                      },
                    ),
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
                          child: FutureBuilder<List<DocumentSnapshot>>(
                            future: _fetchMotoristas(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return ListView.separated(
                                  separatorBuilder:
                                      (BuildContext context, int index) =>
                                          const Divider(),
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      // height: 50,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                      child: CheckboxListTile(
                                        title: Text(
                                          snapshot.data![index]['name'],
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                            snapshot.data![index]['email']),
                                        value: _idMotorista ==
                                            snapshot.data![index]['idmoto']
                                                .toString(),
                                        onChanged: (value) {
                                          // Actualiza el valor de _idMotorista
                                          _idMotorista = value!
                                              ? snapshot.data![index]['idmoto']
                                                  .toString()
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
      ]),
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
                SnackBar(
                  content: const Text('Alerta estas dejando un campo vacio'),
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
              return;
            } else {
              try {
                await pedidosRef.doc(_idPedido).update({
                  'idMotorista': _idMotorista,
                  'estadoid': 2,
                  'fechadespacho': Timestamp.fromDate(now),
                });

// Navegar a otra página

                Navigator.popAndPushNamed(context, '/admin');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Pedido asignado correctamente'),
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
              SnackBar(
                content:
                    const Text('Error al asignar el pedido, intente de nuevo'),
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
        },
        child: const Icon(Icons.assignment_sharp),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
