import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rastreogt/firebase_options.dart';
import 'package:rastreogt/conf/export.dart';
import 'Admin/create_pedidos.dart';
import 'Admin/reasignar_moto.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Clave global para el navegador, permite acceder al contexto de navegación desde cualquier parte de la app
final navigatorKey = GlobalKey<NavigatorState>();

// Función para manejar mensajes de Firebase en segundo plano
Future _firebaseBackgroundMessage(RemoteMessage message) async {
  if (message.notification != null) {
    await PushNotifications.showHighPriorityNotification(
      title: message.notification!.title ?? 'Nueva notificación',
      body: message.notification!.body ?? '',
      payload: jsonEncode(message.data),
    );
  }
}

// Función para mostrar notificaciones en primer plano en la plataforma web
void showNotification({required String title, required String body}) {
  showDialog(
    context: navigatorKey.currentContext!,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Ok"))
      ],
    ),
  );
}

// Punto de entrada principal de la aplicación
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carga las variables de entorno
  await dotenv.load(fileName: "lib/.env");

  try {
    // Inicializa Firebase
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Inicializa las notificaciones locales y configura el canal de notificaciones
    await PushNotifications.localNotiInit();
    await PushNotifications.setupNotificationChannel();

    // Configura Crashlytics para capturar errores
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Configura Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessage);
    await _setupForegroundMessaging();
    await _setupInitialMessage();

    // Ejecuta la aplicación con los proveedores necesarios
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider(create: (_) => PedidosProvider()),
          ChangeNotifierProvider(create: (_) => UsuariosProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    debugPrint("Error al inicializar Firebase: $e");
  }
}

// Configura el manejo de mensajes en primer plano
Future<void> _setupForegroundMessaging() async {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _handleForegroundMessage(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleMessageOpenedApp(message);
  });
}

// Inicializa Firebase de manera separada (útil para servicios en segundo plano)
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint("Error initializing Firebase: $e");
  }
}

// Configura el manejo del mensaje inicial (cuando la app se abre desde una notificación)
Future<void> _setupInitialMessage() async {
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    _handleInitialMessage(initialMessage);
  }
}

// Maneja los mensajes recibidos cuando la app está en primer plano
void _handleForegroundMessage(RemoteMessage message) {
  String payloadData = jsonEncode(message.data);
  if (message.notification != null) {
    if (kIsWeb) {
      showNotification(
          title: message.notification!.title!,
          body: message.notification!.body!);
    } else {
      PushNotifications.showHighPriorityNotification(
          title: message.notification!.title!,
          body: message.notification!.body!,
          payload: payloadData);
    }
    _addNotification(
      message.notification!.title ?? 'Nueva notificación',
      message.notification!.body ?? '',
    );
  }
}

// Maneja la acción de abrir la app desde una notificación cuando está en segundo plano
void _handleMessageOpenedApp(RemoteMessage message) {
  if (message.notification != null) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamed("/message", arguments: message);
    } else {
      debugPrint('El navigatorKey no está listo todavía.');
    }
  }
}

// Maneja el mensaje inicial cuando la app se abre desde una notificación
void _handleInitialMessage(RemoteMessage message) {
  Future.delayed(const Duration(seconds: 1), () {
    navigatorKey.currentState!.pushNamed("/message", arguments: message);
  });
}

// Punto de entrada para el servicio en segundo plano
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
}

// Lista para almacenar notificaciones pendientes
List<Map<String, dynamic>> _pendingNotifications = [];

// Procesa las notificaciones pendientes cuando el usuario se autentica
Future<void> processPendingNotifications(String userEmail) async {
  for (var notification in _pendingNotifications) {
    await _saveNotificationToFirestore(userEmail, notification);
  }
  _pendingNotifications.clear();
  debugPrint('Notificaciones pendientes procesadas');
}

// Añade una nueva notificación
Future<void> _addNotification(String message, String title) async {
  final newNotification = {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    'title': title,
    'message': message,
    'timestamp': DateTime.now(),
  };

  final user = FirebaseAuth.instance.currentUser;
  if (user != null && user.email != null) {
    // Usuario autenticado, guarda la notificación directamente
    await _saveNotificationToFirestore(user.email!, newNotification);
  } else {
    // Usuario no autenticado, agrega a la cola pendiente
    _pendingNotifications.add(newNotification);
    debugPrint(
        'Notificación añadida a la cola pendiente: ${newNotification['id']}');
  }
}

// Guarda una notificación en Firestore
Future<void> _saveNotificationToFirestore(
    String userEmail, Map<String, dynamic> notification) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .collection('notificaciones')
        .doc(notification['id'])
        .set(notification);
    debugPrint('Notificación guardada en Firestore: ${notification['id']}');
  } catch (e) {
    debugPrint('Error al guardar notificación en Firestore: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) =>
          Builder(builder: (BuildContext context) {
        return MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', ''), // Español
          ],
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'RastreoGT',
          theme: themeNotifier.currentTheme,
          routes: {
            // Definición de rutas de la aplicación
            '/asignacion': (context) => const AsignarPedidos(),
            '/home': (context) => const Login(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/splash': (context) => const SplashScreen(),
            '/admin': (context) => const AdminPage(),
            '/moto': (context) => const MotoristaScreen(),
            '/rolbuscar': (context) => const RolePage(),
            '/editPedido': (context) => const EditPedidos(),
            '/listapedidos': (context) => const PedidosPage(),
            '/reasignar': (context) => const ReasignarPedidos(),
            '/crearPedido': (context) => const CrearPedidoScreen(),
            '/pedidoscola': (context) => const ListaPedidos(),
            '/adminjr': (context) => const AdminPagejr(),
            '/adminfull': (context) => const BusinessConfirmationScreen()
          },
          initialRoute: '/splash',
        );
      }),
    );
  }
}
