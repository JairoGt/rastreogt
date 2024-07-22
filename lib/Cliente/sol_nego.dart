import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';
import 'package:rastreogt/conf/export.dart';

/// Tus credenciales de autenticación de Google
///
/// Cómo obtener credenciales - https://medium.com/@a.marenkov/how-to-get-credentials-for-google-sheets-456b7e88c430
const _credentials = r'''
{
  "type": "service_account",
  "project_id": "apprastreogt",
  "private_key_id": "7215d1829f2189de2698ae2a3813d9f6f496bd8c",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDHFh6b24lhLYPY\n55f4rjuGgWpCLJBuQrKFZxjzxdYyS58XwZjTJbXxBejIlSbzo8rhGYMiJhwYHvrC\nGG+Ff8rrzX5WakpgSoRhxvXIJ/gH7NbiMSv1+Cu4TYscwOq3kEplmffo0gk4x/pt\nanPdCYNle16JnMA+jzTcpxrXYKcHc6pJEV9AnBgInOL0Ey3pYghalaivjLIMEKmK\nlOAWhSR3ptwfX9C0Duz7520V8NCIjKjG/K2bk70K1CXnNRNy5P9FliLFTJtBl6mC\ndtIxjFv+IuQDviBPsZp97utsrSKSkmcSiBIO0i7etmD6BdoR6Ag3yBfnmLrf/oSZ\nQTeoJ6EnAgMBAAECggEATXe8el5PU0qQMu9PUduOWxTxoYVQwC7g44sOCRFy+0g0\nxFw3WPYkGYD4p1Bug0C5eaThQ4D7zqEDZ1J11sc20VG5duvOPDDS2W8/hV6UI5VT\nully5zfl30YBOzOQQdR6NpXWgzhzkS4zsq7JHfoNMIh0bWza250C71dw2N0JsZpu\neKOkdfxoI+B3irHfI0lytI1VaAY4aJO61y5MWCMZbcRY2u1bvjVGz6ThUYSViCLH\n7epnAuW8fDAn1pVhKGl1eqn1H8zkijo06NZr0iL+nxwRjfY4Kc6qW4PMb+jb6KxW\nWNrJsP7y5KCS0bTXJTTs2n99tIVTbRvDoeWoBjzYXQKBgQD3iEgxNnmmYtRzxfZ9\nc/8sLhfA/GkB1cDjFgidA0wR0GobCWNuAJP3BwhjCqFcTC99FztZBChbVBurZHuK\n9h1qRzHqtsf+jreeN65XDvSawggWdzXCWIGPgOAXOHtp/vspd2m8s1AGzutoN+Tw\nMH6fn4BCzW72TwG682k3ukCzJQKBgQDN5ZTP9hlJlepzdHf44W+hF2pTPW4j9aQz\nbOmBamTXMiJNHe8wJVpveEjzvpDpECfdadU1KFRdQytrqT7rQSi3gqLNSIaqprX9\nrea0qTAAxzpkkJDCEgru+VJt9BCD2nS7kEultrunYXzOdniK0HNmw3ks3WEEFNZ+\nMN2jH483WwKBgAvQfWGb8AJ5BRrhf/pM5wj8yjVz1q83vJUaIB8eYSsYf3f64rwF\nWwqXU1cm0rzNBhc6XKLLCAIT6Z4slZj0VkMUUtWZE8KanTj3/2I4XIRmbmxkFDTK\ndKScyhVRpNJSUTqRcIKJLHCmv6WhxVORfPmxazXFCF7JNpPtuj/mq9/hAoGAG7gX\nw7OXDfAP40E/0ZLQC3jyiIhRpqewVngIK7MeJlaKhaVNCUdOGImyEJaMPcQ+CbHw\n0To/uVqMou7jGJrqF2KP9mEYOCs/fwqFb7cDTmeD9fv8cRQqwqdwMHtWKdokMwgn\nFwU12D/opIcQjWeo0aHpU1/uarU/dzeu7wIVrtcCgYEAyjm4sEET2bZuEujBilEi\nJURE2Cvphl5nH/ZoK9/4KpbbvgICGm8a7xCS0DAjI5ilrLdsjcPhA+eLm4UgBwpg\ntodRqhMVIjWR8LZUUddvoZZbTBCzUQfXPNfDB0GsZ1eEXemgmcrBpgv+L9YfTH79\n35kOjIC1OgcDiXRJrkdPF6w=\n-----END PRIVATE KEY-----\n",
  "client_email": "apprastreogt@appspot.gserviceaccount.com",
  "client_id": "106104842321893788745",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/apprastreogt%40appspot.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''';

/// Tu ID de hoja de cálculo
///
/// Se puede encontrar en el enlace a tu hoja de cálculo -
/// el enlace se ve así https://docs.google.com/spreadsheets/d/YOUR_SPREADSHEET_ID/edit#gid=0
const _spreadsheetId = '1JKDGcrfI9BGsFMraGEwI3CGFh9msBcur500Jp9OKpHo';


class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _emailController = TextEditingController();
  final _nombreNegocioController = TextEditingController();
  final _estadoController = TextEditingController();
  final _direccionController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;



Future<void> _enviarDatos() async {
  try {
    print('Iniciando envío de datos...');
    final gsheets = GSheets(_credentials);
    print('Credenciales cargadas correctamente.');
    final ss = await gsheets.spreadsheet(_spreadsheetId);
    print('Hoja de cálculo cargada correctamente.');
    var sheet = ss.worksheetByTitle('rastreogt');
    if (sheet == null) {
      print('Hoja de trabajo "rastreogt" no encontrada, creando una nueva.');
      sheet = await ss.addWorksheet('rastreogt');
    } else {
      print('Hoja de trabajo "rastreogt" encontrada.');
    }

    final data = [
      user?.email,
      _nombreNegocioController.text,
      'Solicitud Creada',
      _direccionController.text,
      DateTime.now().toIso8601String(),
    ];

    print('Datos a enviar: $data');
    final result = await sheet.values.appendRow(data);
    if (result) {
      print('Datos enviados correctamente a Google Sheets.');
      
      // Insertar datos en Firestore
      final firestore = FirebaseFirestore.instance;
      final userEmail = user?.email ?? '';
      final negocioIdBase = userEmail.split('@')[0];
      String negocioId = negocioIdBase;
      int counter = 1;

      // Verificar si el documento ya existe y ajustar el ID
      while ((await firestore.collection('users').doc(userEmail).collection('negocios').doc(negocioId).get()).exists) {
        negocioId = '$negocioIdBase$counter';
        counter++;
      }

      await firestore.collection('users').doc(userEmail).collection('negocios').doc(negocioId).set({
        'email': user?.email,
        'nego': _nombreNegocioController.text,
        'negoname':'DF',
        'estadoid': 0,
        'direccion': _direccionController.text,
        'fechaSolicitud': DateTime.now().toIso8601String(),
      });

      print('Datos enviados correctamente a Firestore.');
    } else {
      print('Error al enviar datos a Google Sheets.');
    }
    final lastRow = await sheet.values.lastRow();
    print('Última fila en la hoja de trabajo: $lastRow');
  } catch (e) {
    print('Error al enviar datos: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Google Sheets'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _nombreNegocioController,
              decoration: InputDecoration(labelText: 'Nombre del Negocio'),
            ),
       
            TextField(
              controller: _direccionController,
              decoration: InputDecoration(labelText: 'Dirección'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _enviarDatos,
              child: Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}