import 'dart:async';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:rastreogt/conf/export.dart';

class AdminPagejr extends StatefulWidget {
  const AdminPagejr({super.key});

  @override
  _AdminPageStatejr createState() => _AdminPageStatejr();
}

class _AdminPageStatejr extends State<AdminPagejr>
    with SingleTickerProviderStateMixin {
  String nombreUsuario = 'Mister';
  String nombreNegocio = 'Mi Negocio';
  String negoid = '';
  String nickname = '';
  String emailOff = '';
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
    DocumentSnapshot usuario = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.email)
        .get();

    setState(() {
      String nombreCompleto = user?.displayName ?? usuario['name'];
      List<String> nombres = nombreCompleto.split(' ');
      nombreUsuario =
          nombres.length >= 3 ? '${nombres[0]} ${nombres[2]}' : nombreCompleto;
      nickname = usuario['nickname'];
    });
  }

  Future<void> obtenerNego() async {
    DocumentSnapshot usuario = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.email)
        .get();
    setState(() {
      nombreNegocio = usuario['nego'];
    });
  }

  Future<void> obtenerNegoid() async {
    DocumentSnapshot usuario = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.email ?? nombreUsuario)
        .get();
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

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.currentTheme.brightness == Brightness.dark;

    return Scaffold(
      drawer: const ModernDrawer(),
      body: Builder(
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        const Color.fromARGB(
                            255, 1, 47, 87), // Color más oscuro de la paleta
                        const Color.fromARGB(
                            255, 0, 90, 122), // Segundo color de la paleta
                        const Color(
                            0xFF012442), // Color más oscuro de la paleta
                      ]
                    : [
                        const Color(0xFFDDE8F0), // Color más claro de la paleta
                        const Color(0xFF97CBDC), // Tercer color de la paleta
                      ],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isDarkMode),
                  Expanded(
                    child: _buildModernGrid(isDarkMode),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  EvaIcons.menu2Outline,
                  color: isDarkMode ? Colors.white : const Color(0xFF004581),
                  size: 28,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              Text(
                obtenerSaludo(),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF004581),
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(
                  user?.photoURL ?? 'https://via.placeholder.com/150',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              nombreUsuario,
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: isDarkMode ? Colors.white70 : const Color(0xFF018ABD),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF018ABD).withOpacity(0.2)
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  EvaIcons.briefcaseOutline,
                  color: isDarkMode ? Colors.white70 : const Color(0xFF004581),
                ),
                const SizedBox(width: 12),
                Text(
                  nombreNegocio,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : const Color(0xFF004581),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernGridItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xFF018ABD).withOpacity(0.2)
              : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF004581).withOpacity(0.5)
                    : const Color(0xFF97CBDC).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: isDarkMode ? Colors.white : const Color(0xFF004581),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : const Color(0xFF004581),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernGrid(bool isDarkMode) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': EvaIcons.shoppingBagOutline,
        'title': 'Crear Pedido',
        'route': '/crearPedido'
      },
      {
        'icon': EvaIcons.editOutline,
        'title': 'Editar Pedido',
        'route': '/pedidoscola'
      },
      {
        'icon': EvaIcons.fileTextOutline,
        'title': 'Bitacora de Envios',
        'route': '/listapedidos'
      },
      {
        'icon': EvaIcons.folderAddOutline,
        'title': 'Otros Negocios',
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        return _buildModernGridItem(
          icon: menuItems[index]['icon'],
          title: menuItems[index]['title'],
          onTap: () {
            if (menuItems[index]['title'] == 'Otros Negocios') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtrosNegociosPage(
                    userEmail: user?.email ?? nombreUsuario,
                    nickname: nickname,
                    onNegocioChanged: _updateNegocio,
                    negoname: negoid,
                  ),
                ),
              );
            } else {
              Navigator.pushNamed(context, menuItems[index]['route']);
            }
          },
          isDarkMode: isDarkMode,
        );
      },
    );
  }
}
  // @override
  // Widget build(BuildContext context) {
  //   final themeNotifier = Provider.of<ThemeNotifier>(context);

  //   return PopScope(
  //     canPop: false,
  //     child: Scaffold(
  //       drawer: const ModernDrawer(),
  //       extendBodyBehindAppBar: true,
  //       appBar: AppBar(
  //         elevation: 0,
  //         backgroundColor: Colors.transparent,
  //         leading: Builder(
  //           builder: (context) => IconButton(
  //             icon: Icon(Icons.menu,
  //                 color:
  //                     themeNotifier.currentTheme.brightness == Brightness.dark
  //                         ? Colors.white
  //                         : Colors.black),
  //             onPressed: () => Scaffold.of(context).openDrawer(),
  //           ),
  //         ),
  //         actions: [
  //           Padding(
  //             padding: const EdgeInsets.only(right: 16.0),
  //             child: CircleAvatar(
  //               backgroundImage: NetworkImage(
  //                   user?.photoURL ?? 'https://via.placeholder.com/150'),
  //             ),
  //           ),
  //         ],
  //       ),
  //       body: Stack(
  //         children: [
  //           Container(
  //             decoration: BoxDecoration(
  //               gradient: LinearGradient(
  //                 colors:
  //                     themeNotifier.currentTheme.brightness == Brightness.dark
  //                         ? [
  //                             const Color(0xFF2C3E50), // Azul oscuro profundo
  //                             const Color.fromARGB(
  //                                 255, 32, 60, 87), // Azul grisáceo
  //                           ]
  //                         : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
  //                 begin: Alignment.topLeft,
  //                 end: Alignment.bottomRight,
  //               ),
  //             ),
  //           ),
  //           SafeArea(
  //             child: Column(
  //               children: [
  //                 const SizedBox(height: 20),
  //                 _buildHeader(),
  //                 const SizedBox(height: 30),
  //                 Expanded(
  //                   child: _buildGridView(),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
