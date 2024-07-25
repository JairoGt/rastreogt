import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:rastreogt/conf/export.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  String nombreUsuario = 'Mister';
  String nombreNegocio = 'Mi Negocio';
  String negoid = '';
  String nickname = '';
   String currentNegocioId = '';
   int _repeatCount = 0;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
   late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    obtenerNombreUsuario();
    obtenerNego();
    obtenerNegoid();
      _controller = AnimationController(vsync: this);
     _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _repeatCount++;
        if (_repeatCount < 3) {
          _controller.forward(from: 0.0);
        } else {
          _controller.stop();
        }
      }
    });
  }
 @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _updateNegocio(String newNegocioId) {
    setState(() {
      currentNegocioId = newNegocioId;
    });
    obtenerNombreUsuario();
    obtenerNego();
    obtenerNegoid();
  }
  Future<void> obtenerNombreUsuario() async {
    DocumentSnapshot usuario = await FirebaseFirestore.instance.collection('users').doc(user?.email).get();
    setState(() {
      nombreUsuario = user?.displayName ?? usuario['nickname'];
      nickname = usuario['nickname'];
    });
  }

  Future<void> obtenerNego() async {
    DocumentSnapshot usuario = await FirebaseFirestore.instance.collection('users').doc(user?.email).get();
    setState(() {
      nombreNegocio = usuario['nego'];
    });
  }

  Future<void> obtenerNegoid() async {
    DocumentSnapshot usuario = await FirebaseFirestore.instance.collection('users').doc(user?.email).get();
    setState(() {
      negoid = usuario['negoname'];
    });
  }

  String obtenerSaludo() {
    final horaActual = DateTime.now().hour;
    if (horaActual < 12) {
      return 'Buenos días';
    } else if (horaActual < 18) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }

  Future<List<Map<String, dynamic>>> obtenerUltimosPedidos(String negocio) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('pedidos')
        .where('negoname', isEqualTo: negocio)
        .orderBy('fechaCreacion', descending: true)
        .limit(5)
        .get();

    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  @override
  Widget build(BuildContext context) {
        final themeNotifier = Provider.of<ThemeNotifier>(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
       drawer: const ModernDrawer(),
        //backgroundColor: const Color.fromARGB(62, 0, 0, 0),
        extendBodyBehindAppBar: true,
        appBar:AppBar(
        
          //backgroundColor: const Color.fromARGB(79, 0, 0, 0),
          elevation: 1,
          centerTitle: true,
          automaticallyImplyLeading: false,
          bottom: PreferredSize(preferredSize: 
          const Size.fromHeight(20.0),
          
                    child: Center(
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Builder(
                                builder: (context) {
                                  return IconButton(
                                    icon: const Icon(Icons.menu),
                                    onPressed: () {
                                      Scaffold.of(context).openDrawer();
                                    },
                                  );
                                }
                              ),
                              const SizedBox(width: 50),
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance.collection('users').doc(user?.email).snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  }
                                  if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  }
                                  if (!snapshot.hasData || !snapshot.data!.exists) {
                                    return const Text('Usuario no encontrado');
                                  }
                      
                                  var usuarioData = snapshot.data!.data() as Map<String, dynamic>;
                                  nombreUsuario = user?.displayName ?? usuarioData['nickname'];
                                  nombreNegocio = usuarioData['nego'];
                                  negoid = usuarioData['negoname'];
                      
                                  return Center(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(width: 50,),
                                        Center(
                                          child: Text(
                                            obtenerSaludo(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          nombreUsuario,
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const Spacer(),
                              CircleAvatar(
                                backgroundImage: NetworkImage(user?.photoURL ?? 'https://via.placeholder.com/150'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
        ),
       ), body: Stack(
          children: [
            
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themeNotifier.currentTheme.brightness == Brightness.dark
              ? [const Color.fromARGB(255, 23, 41, 72), Colors.blueGrey]
                      :
                  [const Color.fromARGB(255, 114, 130, 255), Colors.white],
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Lottie.asset(
          'assets/lotties/estelas.json',
          controller: _controller,
          fit: BoxFit.cover,
          animate: true,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward();
          },
        ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                 Center(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user?.email).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text('Usuario no encontrado');
            }

            var usuarioData = snapshot.data!.data() as Map<String, dynamic>;
            nombreNegocio = usuarioData['nego'];

            return Text(
              nombreNegocio,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                //color: Color.fromARGB(255, 105, 89, 160),
              ),
            );
          },
        ),
      ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(16.0),
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      children: [
                        _buildGridItem(
                          icon: EvaIcons.shoppingBagOutline,
                          title: 'Crear Pedido',
                          onTap: () {
                            Navigator.pushNamed(context, '/crearPedido');
                          },
                        ),
                        _buildGridItem(
                          icon: EvaIcons.editOutline,
                          title: 'Editar Pedido',
                          onTap: () {
                          Navigator.pushNamed(context, '/editPedido');
                          },
                        ),
                        _buildGridItem(
                          icon: EvaIcons.personOutline,
                          title: 'Buscar y Cambiar Roles',
                          onTap: () {
                            Navigator.pushNamed(context, '/rolbuscar');
                          },
                        ),
                      
                        _buildGridItem(
                          icon: EvaIcons.fileTextOutline,
                          title: 'Bitacora de Envios',
                          onTap: () {
                            Navigator.pushNamed(context, '/listapedidos');
                          },
                        ),
                          _buildGridItem(
                          icon: EvaIcons.folderAddOutline,
                          title: 'Otros Negocios',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OtrosNegociosPage(userEmail: 
                                user?.email ?? '', nickname: nickname, onNegocioChanged: _updateNegocio,),
                                
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
     ) ;
  }

  Widget _buildGridItem({required IconData icon, required String title, required VoidCallback onTap}) {
      final themeNotifier = Provider.of<ThemeNotifier>(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: themeNotifier.currentTheme.brightness == Brightness.dark
                      ? Colors.grey[900]!.withOpacity(0.5)
                      :
           const Color.fromARGB(157, 255, 255, 255),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
             color: themeNotifier.currentTheme.brightness == Brightness.dark
                      ? Colors.grey[900]!.withOpacity(0.5)
                      :
             const Color.fromARGB(255, 105, 89, 160).withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                
              ),
            ),
          ],
        ),
      ),
    );
  }
}