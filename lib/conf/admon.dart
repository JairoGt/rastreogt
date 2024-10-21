import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rastreogt/Admin/drawer.dart';

class BusinessConfirmationScreen extends StatefulWidget {
  const BusinessConfirmationScreen({super.key});

  @override
  _BusinessConfirmationScreenState createState() =>
      _BusinessConfirmationScreenState();
}

class _BusinessConfirmationScreenState
    extends State<BusinessConfirmationScreen> {
  String? selectedUser;
  List<String> usersWithPendingBusinesses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsersWithPendingBusinesses();
  }

  Future<void> _loadUsersWithPendingBusinesses() async {
    setState(() {
      isLoading = true;
    });

    try {
      final QuerySnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      List<String> newUsersList = [];

      for (var userDoc in userSnapshot.docs) {
        final pendingBusinesses = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('negocios')
            .where('estadoid', isEqualTo: 0)
            .get();

        if (pendingBusinesses.docs.isNotEmpty) {
          newUsersList.add(userDoc.id);
        }
      }

      setState(() {
        usersWithPendingBusinesses = newUsersList;
        if (!usersWithPendingBusinesses.contains(selectedUser)) {
          selectedUser = null;
        }
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener usuarios > $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        drawer: const ModernDrawer(),
        appBar: AppBar(
          title: const Text('Confirmar Negocios'),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                        'Usuarios con negocios pendientes: ${usersWithPendingBusinesses.length}'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedUser,
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar usuario',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: usersWithPendingBusinesses.map((String email) {
                        return DropdownMenuItem<String>(
                          value: email,
                          child: Text(email, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedUser = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: selectedUser == null
                          ? const Center(
                              child: Text(
                                  'Seleccione un usuario para ver sus negocios'))
                          : StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(selectedUser)
                                  .collection('negocios')
                                  .where('estadoid', isEqualTo: 0)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                }
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return const Center(
                                      child: Text(
                                          'No hay negocios pendientes de confirmación para este usuario.'));
                                }
                                return ListView.builder(
                                  itemCount: snapshot.data!.docs.length,
                                  itemBuilder: (context, index) {
                                    var business = snapshot.data!.docs[index];
                                    return Card(
                                      child: ListTile(
                                        title: Text(business['negoname'] ??
                                            'Negocio sin nombre'),
                                        subtitle: Text(
                                            'ID: ${business.id}, Estado: ${business['estadoid']}'),
                                        trailing: ElevatedButton(
                                          child: const Text('Confirmar'),
                                          onPressed: () => _confirmBusiness(
                                              context,
                                              selectedUser!,
                                              business.id),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _confirmBusiness(
      BuildContext context, String userEmail, String businessId) async {
    try {
      await confirmBusiness(userEmail, businessId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Negocio confirmado exitosamente')),
      );
      await _loadUsersWithPendingBusinesses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al confirmar el negocio: $e')),
      );
    }
  }

  Future<void> confirmBusiness(String userEmail, String businessId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.runTransaction((transaction) async {
      DocumentReference businessRef = firestore
          .collection('users')
          .doc(userEmail)
          .collection('negocios')
          .doc(businessId);
      DocumentReference userRef = firestore.collection('users').doc(userEmail);

      DocumentSnapshot businessSnapshot = await transaction.get(businessRef);

      if (!businessSnapshot.exists) {
        throw Exception('El negocio no existe');
      }

      Map<String, dynamic> businessData =
          businessSnapshot.data() as Map<String, dynamic>;

      if (businessData['estadoid'] != 0) {
        throw Exception(
            'El negocio ya ha sido confirmado o está en un estado inválido');
      }

      transaction.update(businessRef, {'estadoid': 1});
      transaction.update(userRef, {
        'role': 'admin',
        'nego': businessData['nego'],
        'idBussiness': businessId,
        'negoname': businessData['negoname'] ?? '',
      });
    });
  }
}
