import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rastreogt/firebase_options.dart';
import 'package:rastreogt/conf/export.dart';
import 'Admin/create_pedidos.dart';
import 'Admin/reasignar_moto.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// function to listen to background changes
Future _firebaseBackgroundMessage(RemoteMessage message) async {
  if (message.notification != null) {}
}

// to handle notification on foreground on web platform
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

//@pragma('vm:entry-point')
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "lib/.env");

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    print("Firebase initialized successfully in main");

    await PushNotifications.localNotiInit();

    // Configuración de Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Configuración de Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessage);
    await _setupForegroundMessaging();
    await _setupInitialMessage();

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
    print("Error initializing Firebase: $e");
    // Considera mostrar un diálogo de error al usuario aquí
  }
}

Future<void> _setupForegroundMessaging() async {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _handleForegroundMessage(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleMessageOpenedApp(message);
  });
}

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
    // Considera lanzar una excepción aquí si quieres que el error se propague
  }
}

Future<void> _setupInitialMessage() async {
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    _handleInitialMessage(initialMessage);
  }
}

void _handleForegroundMessage(RemoteMessage message) {
  String payloadData = jsonEncode(message.data);
  if (message.notification != null) {
    if (kIsWeb) {
      showNotification(
          title: message.notification!.title!,
          body: message.notification!.body!);
    } else {
      PushNotifications.showSimpleNotification(
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

void _handleMessageOpenedApp(RemoteMessage message) {
  if (message.notification != null) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamed("/message", arguments: message);
    } else {
      debugPrint('El navigatorKey no está listo todavía.');
    }
  }
}

void _handleInitialMessage(RemoteMessage message) {
  Future.delayed(const Duration(seconds: 1), () {
    navigatorKey.currentState!.pushNamed("/message", arguments: message);
  });
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  // ... resto de tu código onStart
}

List<Map<String, dynamic>> _pendingNotifications = [];

Future<void> processPendingNotifications(String userEmail) async {
  for (var notification in _pendingNotifications) {
    await _saveNotificationToFirestore(userEmail, notification);
  }
  _pendingNotifications.clear();
  debugPrint('Notificaciones pendientes procesadas');
}

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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) =>
          Builder(builder: (BuildContext context) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'RastreoGT',
          theme: themeNotifier.currentTheme,
          routes: {
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
