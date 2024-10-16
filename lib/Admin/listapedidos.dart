import 'package:rastreogt/conf/export.dart';
import 'edit_pedidos.dart';

class ListaPedidos extends StatefulWidget {
  const ListaPedidos({super.key});

  @override
  _ListaPedidosState createState() => _ListaPedidosState();
}

class _ListaPedidosState extends State<ListaPedidos> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? negocio;

  Map<int, String> estadoDescriptions = {
    1: 'Creado',
    2: 'Despachado',
    3: 'Entregado',
    4: 'En Proceso',
    5: 'Cancelado',
  };

  Future<void> _obtenerNegoname() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.email).get();
      if (userDoc.exists) {
        setState(() {
          negocio = userDoc.get('negoname');
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _obtenerNegoname();
  }

  Future<void> _cancelarPedido(String idPedido) async {
    TextEditingController observacionesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancelar Pedido',
              style: GoogleFonts.asul(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¿Estás seguro de que quieres cancelar este pedido?',
                  style: GoogleFonts.asul()),
              const SizedBox(height: 20),
              TextField(
                controller: observacionesController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar', style: GoogleFonts.asul()),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Confirmar', style: GoogleFonts.asul()),
              onPressed: () async {
                await _firestore.collection('pedidos').doc(idPedido).update({
                  'estadoid': 5,
                  'observaciones': observacionesController.text,
                });
                Navigator.of(context).pop();
                setState(() {}); // Refresh the list
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.currentTheme.brightness == Brightness.dark;
    final Color primaryColor = isDarkMode
        ? const Color.fromARGB(255, 1, 47, 87)
        : const Color(0xFFDDE8F0);
    final Color secondaryColor = isDarkMode
        ? const Color.fromARGB(255, 0, 90, 122)
        : const Color(0xFF97CBDC);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor.withOpacity(0.9),
        centerTitle: true,
        leading: IconButton(
          color: isDarkMode ? Colors.white : Colors.black,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Lista de Pedidos',
            style: GoogleFonts.asul(
              color: isDarkMode ? Colors.white : Colors.black,
            )),
      ),
      body: Stack(children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('pedidos')
              .where('estadoid', isLessThan: 3)
              .where('negoname', isEqualTo: negocio)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final pedidos = snapshot.data!.docs;

            return ListView.builder(
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                final pedido = pedidos[index].data() as Map<String, dynamic>;
                final idPedido = pedidos[index].id;
                final estadoId = pedido['estadoid'] as int;
                final estadoDescripcion =
                    estadoDescriptions[estadoId] ?? 'Desconocido';
                final direccion =
                    pedido['direccion'] as String? ?? 'No especificada';

                return Card(
                  elevation: 4,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text('Pedido: $idPedido',
                        style: GoogleFonts.asul(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estado: $estadoDescripcion',
                            style: GoogleFonts.asul()),
                        Text('Dirección: $direccion',
                            style: GoogleFonts.asul()),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditPedidos(idPedido: idPedido),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: () => _cancelarPedido(idPedido),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ]),
    );
  }
}
