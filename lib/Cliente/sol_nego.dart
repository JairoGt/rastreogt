import 'package:geocoding/geocoding.dart';
import 'package:gsheets/gsheets.dart';
import 'package:rastreogt/Cliente/map.dart';
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
/// Se puede encontrar en el enlace a tu hoja de cálculo -
/// el enlace se ve así https://docs.google.com/spreadsheets/d/YOUR_SPREADSHEET_ID/edit#gid=0
const _spreadsheetId = '1JKDGcrfI9BGsFMraGEwI3CGFh9msBcur500Jp9OKpHo';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _emailController = TextEditingController();
  final _nombreNegocioController = TextEditingController();
  final _direccionController = TextEditingController();
   final TextEditingController _ubicacionController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;


String? _originalCoordinates;
Future<void> _enviarDatos() async {
  try {
    final gsheets = GSheets(_credentials);
    final ss = await gsheets.spreadsheet(_spreadsheetId);
    var sheet = ss.worksheetByTitle('rastreogt');
    if (sheet == null) {
      sheet = await ss.addWorksheet('rastreogt');
    } else {
    }

    final data = [
     user!.email?.toUpperCase(),
      _nombreNegocioController.text,
      'Solicitud Creada',
      _direccionController.text,
      DateTime.now().toIso8601String(),
    ];

    final result = await sheet.values.appendRow(data);
    if (result) {
      showDialog(context: context,
       builder: (BuildContext context) {
         return AlertDialog(
           title: const Text('Solicitud Creada'),
           content: const Text('Tu solicitud ha sido creada correctamente.'),
           actions: [
             TextButton(
               onPressed: () {
                 Navigator.of(context).pop();
               },
               child: const Text('OK'),
             ),
           ],
         );
       },
       
       );
      
       if (_originalCoordinates != null) {
      final coordinates = _originalCoordinates!.split(',');
      final latitude = double.parse(coordinates[0]);
      final longitude = double.parse(coordinates[1]);
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
        'idBussiness': negocioId,
        'ubicacionnego': GeoPoint(latitude, longitude),
        'fechaSolicitud': DateTime.now().toIso8601String(),
      });
  
       }else{
           ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una ubicación')),
      );
       }
    
    } else {
      
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al enviar los datos: $e'),
        backgroundColor: Colors.red,
      ),
    );  
  }
}



Future<void> _selectLocation() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => LocationPickerScreen(),
    ),
  );

  if (result != null) {
    final coordinates = result.split(',');
    final latitude = double.parse(coordinates[0]);
    final longitude = double.parse(coordinates[1]);

    try {
      // Guardar las coordenadas originales
      _originalCoordinates = result;

      // Obtener la dirección a partir de las coordenadas
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Manejar valores nulos y proporcionar valores predeterminados
        String street = place.street ?? 'Calle desconocida';
        String locality = place.locality ?? 'Localidad desconocida';

        String formattedAddress = "$street, $locality";

        setState(() {
          _ubicacionController.text = formattedAddress;
        });
      } else {
        setState(() {
          _ubicacionController.text = 'Dirección no encontrada';
        });
      }
    } catch (e) {
      // Manejar cualquier excepción que ocurra durante la geocodificación inversa
      setState(() {
        _ubicacionController.text = 'Error al obtener la dirección';
      });
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Google Sheets'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: user!.email == null ? _emailController : TextEditingController(text: user!.email),
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreNegocioController,
              decoration: const InputDecoration(labelText: 'Nombre del Negocio'),
            ),
         const SizedBox(height: 20),
            TextField(
              controller: _direccionController,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
              const SizedBox(height: 20),
           TextFormField(
                controller: _ubicacionController,
                decoration: const InputDecoration(labelText: 'Ubicación'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona una ubicación';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectLocation,
                child: const Text('Seleccionar Ubicación'),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _enviarDatos,
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
  
}