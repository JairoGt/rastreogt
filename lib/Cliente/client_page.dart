import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:rastreogt/Cliente/pInfo.dart';
import 'package:rastreogt/Cliente/seguimiento.dart';
import 'package:rastreogt/conf/export.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {

  String nombreUsuario = 'Mister';
  String nombreNegocio = 'Mi Negocio';
  String negoid = '';
  String nickname = '';
     List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
    late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;


    Future<void> _checkUserInfo() async {
    if (user != null) {
      final userEmail = user!.email ?? '';
      final docSnapshot = await firestore.collection('users').doc(userEmail).collection('userData').doc('pInfo').get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['estadoid'] == 0) {
          _showIncompleteInfoDialog();
        }
      }
    }
  }


   // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      debugPrint('Couldn\'t check connectivity status: $e');
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    setState(() {
      _connectionStatus = result;
    });
    // ignore: avoid_print
    if (_connectionStatus.contains(ConnectivityResult.none)) {
      showDialog(context: context,
      
       builder: 
        (BuildContext context) {
          return AlertDialog(
            title: const Text('Error de Conexión'),
            content: const Text('No hay conexión a internet. Por favor, verifica tu conexión e inténtalo de nuevo.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
       );
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Conexión establecida'),
        ),
      );
    }
   
  
    print('Connectivity changed: $_connectionStatus');
  }

  void _showIncompleteInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Acción requerida'),
          content: const Text('Por favor, completa tu información personal y agrega una ubicación.'),
          actions: [
            TextButton(
              onPressed: () {
               Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserInfoScreen(userEmail: user?.email,) ,
                    ),
                  );
              },
              child: Text('OK',style: 
              GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.inverseSurface,
              )
              ,),
            ),
          ],
        );
      },
    );
  }

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

Future<void> obtenerNombreUsuario() async {
  DocumentSnapshot usuario = await FirebaseFirestore.instance
      .collection('users')
      .doc(user?.email)
      .get();
  
  setState(() {
    String nombreCompleto = user?.displayName ?? usuario['name'];
    List<String> nombres = nombreCompleto.split(' ');

    // Asegúrate de que hay al menos tres partes en el nombre
    if (nombres.length >= 3) {
      nombreUsuario = '${nombres[0]} ${nombres[2]}';
    } else {
      nombreUsuario = nombreCompleto; // En caso de que no haya suficientes partes, usa el nombre completo
    }

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
        .doc(user?.email)
        .get();
    setState(() {
      negoid = usuario['negoname'];
    });
  }

  String obtenerSaludo() {
    final horaActual = DateTime.now().hour;
    if (horaActual < 12) {
      return 'Buen día';
    } else if (horaActual < 18) {
      return 'Buena tarde';
    } else {
      return 'Buena noche';
    }
  }


  @override
  void initState() {
    super.initState();
    obtenerNombreUsuario();
    obtenerNego();
    initConnectivity();
    obtenerNegoid();
    _startAutoScroll();
    _checkUserInfo();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_scrollController.hasClients) {
        final maxScrollExtent = _scrollController.position.maxScrollExtent;
        final currentScrollPosition = _scrollController.position.pixels;
        final newScrollPosition = currentScrollPosition + 200;

        if (newScrollPosition >= maxScrollExtent) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.animateTo(
            newScrollPosition,
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

@override
Widget build(BuildContext context) {
  final themeNotifier = Provider.of<ThemeNotifier>(context);
  return PopScope(
    canPop: false,
    child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color.fromARGB(0, 206, 202, 202),
          statusBarIconBrightness: Brightness.light,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Stack(children: [
                Builder(builder: (context) {
                  return IconButton(
                    alignment: Alignment.bottomRight,
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  );
                }),
              ]),
            ],
          ),
        ),
      ),
      drawer: const ModernDrawer(),
      body: Stack(children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: themeNotifier.currentTheme.brightness == Brightness.dark
                  ? [const Color.fromARGB(255, 23, 41, 72), Colors.blueGrey]
                  : [const Color.fromARGB(255, 114, 130, 255), Colors.white],
              begin: Alignment.center,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
        SizedBox.expand(
          child: Lottie.asset(
            'assets/lotties/estelas.json',
            fit: BoxFit.cover,
            animate: true,
            repeat: false,
          ),
        ),
   Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const SizedBox(height: 30),
    Padding(
      padding: const EdgeInsets.only(top: 100, left: 30),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(
  color: Theme.of(context).brightness == Brightness.dark
      ? Color.fromARGB(87, 57, 73, 113).withOpacity(0.4) // Color para modo oscuro
      : Colors.white.withOpacity(0.5), // Color para modo claro
  borderRadius: BorderRadius.circular(10), // Bordes redondeados
),
        padding: const EdgeInsets.all(10), // Padding interno del contenedor
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido',
              style: GoogleFonts.poppins(
                fontSize: 23,
               
              ),
            ),
            const SizedBox(height: 5),
            Text(
              nombreUsuario,
              style: GoogleFonts.poppins(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                
              ),
            ),
            const SizedBox(height: 5),
            Text(
              obtenerSaludo(),
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
    Padding(
      padding: const EdgeInsets.only(top: 50, left: 50),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Tu ID de cliente es: $nickname',
          style: GoogleFonts.poppins(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
    ),

    Column(
      children: [
            SizedBox(height: 300,),
     Padding(
        padding: const EdgeInsets.all(18.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color.fromARGB(155, 0, 0, 0).withOpacity(0.5)
                    : Colors.deepPurple.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProcessTimelinePage(
                        idPedidos: '',
                      ),
                    ),
                  );
                },
                child: Text(
                  'ID PEDIDO',
                  style: GoogleFonts.zillaSlab(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    
    const SizedBox(height: 20),
    Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color.fromARGB(155, 0, 0, 0).withOpacity(0.5)
              : Color.fromARGB(255, 165, 131, 224).withOpacity(0.5),
          child: InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: nickname));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Código de cliente copiado al portapapeles'),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Toca aqui para copiar tu ID de cliente',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    const SizedBox(height: 30),
    Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: Text(
          'Mis Pedidos en curso',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
    StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pedidos')
          .where('nickname', isEqualTo: nickname)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        var data = snapshot.data;
        if (data == null) {
          return const Center(
            child: Text('No hay datos disponibles'),
          );
        }

        var pedidos = data.docs;
        var pedidosFiltrados = pedidos.where((pedido) {
          var pedidoData = pedido.data() as Map<String, dynamic>;
          return pedidoData['nickname'] == nickname &&
              pedidoData['estadoid'] < 4;
        }).toList();

        if (pedidosFiltrados.isEmpty) {
          return const Center(
            child: Text('No hay pedidos para este usuario'),
          );
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: pedidosFiltrados.length,
            itemBuilder: (context, index) {
              var pedido = pedidosFiltrados[index].data() as Map<String, dynamic>;
              var idPedido = pedido['idpedidos'];
              var fecha = (pedido['fechaCreacion'] as Timestamp).toDate();

              var ahora = DateTime.now();
              var diferencia = ahora.difference(fecha);
              var minutosTranscurridos = diferencia.inMinutes;

              String tiempoTranscurrido;
              if (minutosTranscurridos < 60) {
                tiempoTranscurrido = '$minutosTranscurridos minutos';
              } else if (minutosTranscurridos < 1440) {
                var horasTranscurridas = diferencia.inHours;
                tiempoTranscurrido = '$horasTranscurridas horas';
              } else {
                var diasTranscurridos = diferencia.inDays;
                tiempoTranscurrido = '$diasTranscurridos días';
              }

              return Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProcessTimelinePage(idPedidos: idPedido),
                      ),
                    );
                  },
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color.fromARGB(155, 0, 0, 0)
                              : Colors.deepPurple.withOpacity(0.5),
                          blurRadius: 10.0,
                          spreadRadius: 2.0,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Pedido #$idPedido',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Fecha: ${fecha.day}/${fecha.month}/${fecha.year}',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Creado hace:',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 1, left: 8),
                          child: Text(
                            tiempoTranscurrido,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    )
  ],
)
      ]),
    ),
  );
}
}
