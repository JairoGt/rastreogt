import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:rastreogt/Admin/asignar_moto.dart';
import 'package:rastreogt/Admin/bitacora_pedidos.dart';
import 'package:rastreogt/Admin/create_pedidos.dart';
import 'package:rastreogt/Admin/edit_pedidos.dart';
import 'package:rastreogt/Admin/reasignar_moto.dart';
import 'package:rastreogt/Admin/rol_buscar.dart';
import 'package:rastreogt/Home/onboarding.dart';
import 'package:rastreogt/Home/splash.dart';
import 'package:rastreogt/conf/noti_api.dart';
import 'package:rastreogt/auth/login/login.dart';
import 'package:rastreogt/firebase_options.dart';
import 'package:rastreogt/conf/export.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PushNotifications.localNotiInit();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Listen to background notifications
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessage);

  // on background notification tapped
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.notification != null) {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamed("/message", arguments: message);
      } else {
        debugPrint('El navigatorKey no está listo todavía.');
      }
    }
  });

// to handle foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
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
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      _addNotification(
        message.notification!.title ?? 'Nueva notificación',
        message.notification!.body ?? '',
      );
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
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
    }
  });

// Actualiza también _firebaseBackgroundMessage y el manejo de getInitialMessage de manera similar

  // for handling in terminated state
  final RemoteMessage? message =
      await FirebaseMessaging.instance.getInitialMessage();

  if (message != null) {
    Future.delayed(const Duration(seconds: 1), () {
      navigatorKey.currentState!.pushNamed("/message", arguments: message);
    });
  }

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

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
}

List<Map<String, dynamic>> _pendingNotifications = [];

Future<void> processPendingNotifications(String userEmail) async {
  for (var notification in _pendingNotifications) {
    await _saveNotificationToFirestore(userEmail, notification);
  }
  _pendingNotifications.clear();
  print('Notificaciones pendientes procesadas');
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
    print('Notificación añadida a la cola pendiente: ${newNotification['id']}');
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
    print('Notificación guardada en Firestore: ${notification['id']}');
  } catch (e) {
    print('Error al guardar notificación en Firestore: $e');
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
          },
          initialRoute: '/splash',
        );
      }),
    );
  }
}
