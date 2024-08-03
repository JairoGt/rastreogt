import 'package:google_fonts/google_fonts.dart';
import 'package:rastreogt/conf/export.dart';

class OtrosNegociosPage extends StatelessWidget {
  final String userEmail;
  final String nickname;
  final String negoname;
  final Function onNegocioChanged;

  const OtrosNegociosPage({super.key, 
    required this.userEmail,
    required this.nickname,
    required this.onNegocioChanged, required this.negoname,
  });

  @override
  Widget build(BuildContext context) {
       final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Otros Negocios'),
      ),
      body: Stack(
        children: [
          Container(
            decoration:  BoxDecoration(
              gradient: LinearGradient(
                colors: themeNotifier.currentTheme.brightness == Brightness.dark
              ? [const Color.fromARGB(255, 23, 41, 72), Colors.blueGrey]
                      :
                  [const Color.fromARGB(255, 114, 130, 255), Colors.white],
                begin: Alignment.center,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Lottie.asset(
            'assets/lotties/estelas.json', // Asegúrate de que el archivo Lottie esté en la carpeta assets
            fit: BoxFit.cover,
            animate: true,
            repeat: false,
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
      .collection('users')
      .doc(userEmail)
      .collection('negocios')
      .where('nickname', isEqualTo: nickname)
      .where('negoname', isNotEqualTo: negoname)
      .where('estadoid', isEqualTo: 1)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return  Center(child: Text('Error al cargar los negocios',
        style: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: themeNotifier.currentTheme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
      ),
      ));
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
      return  Center(child: Text('No se encontraron negocios',
      style: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: themeNotifier.currentTheme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
      ),
      ));
    }

              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      title: Text(
                        doc['negoname'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        doc['nego'],
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () async {
                        try {
                          // Actualiza el negocio actual en Firebase
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userEmail)
                              .update({'negoname': doc['negoname']
                              ,
                            'nego':doc['nego'],
                            'idBussiness':doc['idBussiness'],
                              });

                          // Llama a la función para actualizar el negocio actual en la UI
                        
                          onNegocioChanged(doc.id);
                        if(context.mounted){
                          Navigator.pop(context);
                        }
                          
                        } catch (e) {

                          if(context.mounted){
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al actualizar el negocio $e'),
                            ),
                          );
                          }else{
                            return;
                          }
                        
                        }
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}