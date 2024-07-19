import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rastreogt/Admin/asignar_moto.dart';
import 'package:rastreogt/Admin/bitacora_pedidos.dart';
import 'package:rastreogt/Admin/create_pedidos.dart';
import 'package:rastreogt/Admin/edit_pedidos.dart';
import 'package:rastreogt/Admin/reasignar_moto.dart';
import 'package:rastreogt/Admin/rol_buscar.dart';
import 'package:rastreogt/auth/login/login.dart';
import 'package:rastreogt/firebase_options.dart';
import 'package:rastreogt/providers/pedidosProvider.dart';
import 'package:rastreogt/providers/themeNoti.dart';
import 'package:rastreogt/providers/themeNoti.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(
     MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PedidosProvider()),
        ChangeNotifierProvider(create: (_) => UsuariosProvider()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context,themeNotifier,child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'RastreoGT',
        theme: themeNotifier.currentTheme,
        routes: {
    '/asignacion': (context) => const AsignarPedidos(),
          //'/admin' :(context) => const AdminScreen(),
          //'/login' :(context) => const Login(),
          //'/motoasignado' :(context) => const MotoPage(),
          //'/cliente' :(context) => const ClientScreen(),
          //'/tracking':(context) => const ClienteTrack(),
         // '/otrosnegocios':(context) => OtrosNegociosPage(),
          '/rolbuscar':(context) => const RolePage(),
          '/editPedido': (context) =>  const EditPedidos(),
          '/listapedidos':(context) => const PedidosPage(),
          '/reasignar':(context) => const ReasignarPedidos(),
         '/crearPedido':(context) => const CrearPedidoScreen(),
        },
        home:  Login(),
      ),
  
    );
  }
}
