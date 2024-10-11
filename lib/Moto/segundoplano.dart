import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart'; // Importa firebase_core
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      iOS: DarwinInitializationSettings(),
      android: AndroidInitializationSettings('ic_bg_service_small'),
    ),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Servicio de localización',
      initialNotificationContent: 'Servicio de localización activado',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Asegúrate de inicializar Firebase en iOS
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  Timer.periodic(const Duration(seconds: 30), (timer) async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    await updateMotoristaLocation(position, auth, db);
  });
}

Future<void> updateMotoristaLocation(
    Position position, FirebaseAuth auth, FirebaseFirestore db) async {
  try {
    User? user = auth.currentUser;
    if (user == null) {
      return;
    }

    String userEmail = user.email!;
    DocumentSnapshot motoristaDoc =
        await db.collection('motos').doc(userEmail).get();

    if (!motoristaDoc.exists) {
      return;
    }

    int estadoid = motoristaDoc['estadoid'];
    if (estadoid == 1) {
      stopBackgroundService();
      debugPrint('Servicio detenido');
      return;
    }

    double latitude = position.latitude;
    double longitude = position.longitude;

    await db.collection('motos').doc(userEmail).update({
      'ubicacionM': GeoPoint(latitude, longitude),
    });
  } catch (e) {
    // Handle the error
    debugPrint('Error al actualizar la ubicación: $e');
  }
}

void stopBackgroundService() {
  FlutterBackgroundService().invoke("stopService");
}
