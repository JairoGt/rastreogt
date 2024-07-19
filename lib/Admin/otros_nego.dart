import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

class OtrosNegociosPage extends StatelessWidget {
  final String userEmail;
  final String nickname;
  final Function onNegocioChanged;

  const OtrosNegociosPage({super.key, 
    required this.userEmail,
    required this.nickname,
    required this.onNegocioChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Otros Negocios'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 114, 130, 255), Colors.white],
                begin: Alignment.centerLeft,
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
                .where('estadoid', isEqualTo: 1)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Error al cargar los negocios'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No se encontraron negocios'));
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
                              });

                          // Llama a la función para actualizar el negocio actual en la UI
                          onNegocioChanged(doc.id);
                          Navigator.pop(context);
                        } catch (e) {
                          print('Error al actualizar el negocio: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error al actualizar el negocio'),
                            ),
                          );
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