import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:rastreogt/Cliente/notipage.dart';
import 'package:rastreogt/Cliente/pinfo.dart';
import 'package:rastreogt/Cliente/seguimiento.dart';
import 'package:rastreogt/conf/export.dart';

// Modelo de Notificación
class Notification {
  final String id;
  final String message;
  final String title;
  final DateTime timestamp;

  Notification(this.title,
      {required this.id, required this.message, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp,
    };
  }

  static Notification fromMap(Map<String, dynamic> map) {
    return Notification(
      map['title'] ??
          'Sin título', // Proporciona un valor por defecto si es nulo
      id: map['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      message: map['message'] ?? 'Sin mensaje',
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
    );
  }
}

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
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<void> _checkUserInfo() async {
    if (user != null) {
      final userEmail = user!.email ?? '';
      final docSnapshot = await firestore
          .collection('users')
          .doc(userEmail)
          .collection('userData')
          .doc('pInfo')
          .get();
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
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error de Conexión'),
            content: const Text(
                'No hay conexión a internet. Por favor, verifica tu conexión e inténtalo de nuevo.'),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Conexión establecida'),
        ),
      );
    }
  }

  void _showIncompleteInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Acción requerida'),
          content: const Text(
              'Por favor, completa tu información personal y agrega una ubicación.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserInfoScreen(
                      userEmail: user?.email,
                    ),
                  ),
                );
              },
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inverseSurface,
                ),
              ),
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

  // En la clase _ClientPageState, agrega estas funciones:

  List<Notification> _notifications = [];

  Future<void> _loadNotifications() async {
    final userEmail = user?.email ?? '';
    final notificationsSnapshot = await firestore
        .collection('users')
        .doc(userEmail)
        .collection('notificaciones')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      _notifications = notificationsSnapshot.docs
          .map((doc) => Notification.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> _deleteNotification(String notificationId) async {
    final userEmail = user?.email ?? '';
    await firestore
        .collection('users')
        .doc(userEmail)
        .collection('notificaciones')
        .doc(notificationId)
        .delete();

    setState(() {
      _notifications
          .removeWhere((notification) => notification.id == notificationId);
    });
  }

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
        nombreUsuario =
            nombreCompleto; // En caso de que no haya suficientes partes, usa el nombre completo
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

  void _showNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsPage(
          fetchNotifications: () async {
            await _loadNotifications();
            return _notifications;
          },
          onDelete: (String id) async {
            await _deleteNotification(id);
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    obtenerNombreUsuario();
    obtenerNego();
    initConnectivity();
    obtenerNegoid();
    _loadNotifications();
    _startAutoScroll();
    _checkUserInfo();
    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      setState(() {
        _connectionStatus = result;
      });
    });
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
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () => _showNotifications(),
            ),
          ],
        ),
        drawer: const ModernDrawer(),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: themeNotifier.currentTheme.brightness == Brightness.dark
                  ? [const Color.fromARGB(255, 23, 41, 72), Colors.blueGrey]
                  : [const Color.fromARGB(255, 114, 130, 255), Colors.white],
              begin: Alignment.center,
              end: Alignment.bottomLeft,
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeCard(context),
                        const SizedBox(height: 20),
                        _buildClientIdCard(context),
                        const SizedBox(height: 20),
                        _buildSearchBar(context),
                        const SizedBox(height: 20),
                        Expanded(child: _buildActiveOrdersSection(context)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color.fromARGB(87, 57, 73, 113).withOpacity(0.4)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido',
              style: GoogleFonts.poppins(fontSize: 23),
            ),
            const SizedBox(height: 5),
            Text(
              nombreUsuario,
              style: GoogleFonts.poppins(
                  fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              obtenerSaludo(),
              style: GoogleFonts.poppins(
                  fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientIdCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Tu ID de cliente es: $nickname',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white),
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: nickname)).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ID de cliente copiado al portapapeles'),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: const Icon(Icons.search, color: Colors.white),
        title: Text(
          'ID PEDIDO',
          style: GoogleFonts.zillaSlab(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProcessTimelinePage(idPedidos: ''),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveOrdersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis Pedidos en curso',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pedidos')
                .where('nickname', isEqualTo: nickname)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              var data = snapshot.data;
              if (data == null) {
                return const Center(child: Text('No hay datos disponibles'));
              }

              var pedidosFiltrados = data.docs.where((pedido) {
                var pedidoData = pedido.data() as Map<String, dynamic>;
                return pedidoData['nickname'] == nickname &&
                    pedidoData['estadoid'] < 4;
              }).toList();

              if (pedidosFiltrados.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        "assets/lotties/stopM.json",
                        animate: true,
                        repeat: false,
                        height: 250,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No tienes pedidos asignados',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: pedidosFiltrados.length,
                itemBuilder: (context, index) {
                  var pedido =
                      pedidosFiltrados[index].data() as Map<String, dynamic>;
                  return _buildOrderCard(context, pedido);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> pedido) {
    var idPedido = pedido['idpedidos'];
    var fecha = (pedido['fechaCreacion'] as Timestamp).toDate();
    var tiempoTranscurrido = _calcularTiempoTranscurrido(fecha);

    return GestureDetector(
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
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pedido #$idPedido',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fecha: ${fecha.day}/${fecha.month}/${fecha.year}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Creado hace:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              Text(
                tiempoTranscurrido,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calcularTiempoTranscurrido(DateTime fecha) {
    var ahora = DateTime.now();
    var diferencia = ahora.difference(fecha);
    var minutosTranscurridos = diferencia.inMinutes;

    if (minutosTranscurridos < 60) {
      return '$minutosTranscurridos minutos';
    } else if (minutosTranscurridos < 1440) {
      var horasTranscurridas = diferencia.inHours;
      return '$horasTranscurridas horas';
    } else {
      var diasTranscurridos = diferencia.inDays;
      return '$diasTranscurridos días';
    }
  }
}
