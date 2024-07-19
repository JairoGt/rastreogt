import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class RolePage extends StatefulWidget {
  const RolePage({super.key});

  @override
  _RolePageState createState() => _RolePageState();
}

class _RolePageState extends State<RolePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<DocumentSnapshot> _usersList = [];
  List<DocumentSnapshot> _filteredUsersList = [];
  User? user = FirebaseAuth.instance.currentUser;
  String _currentUserNegoname = ''; // Tu propio negoname

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getCurrentUserNegoname();
    _getUsers1();
  }

  Future<void> _getCurrentUserNegoname() async {
    DocumentSnapshot currentUserSnapshot = await _firestore.collection('users').doc(user!.email).get();
    _currentUserNegoname = currentUserSnapshot['negoname'];
    print('Negoname: $_currentUserNegoname');
  }

  void _getUsers1() async {
    setState(() {});

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset('assets/lotties/search.json'),
                const SizedBox(height: 20),
                Text(
                  'Cargando...',
                  style: GoogleFonts.aBeeZee(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    QuerySnapshot usersSnapshot = await _firestore.collection('users')
        .where('email', isNotEqualTo: user!.email)
        .where('negoname', isEqualTo: _currentUserNegoname)
        .get();
    _usersList = usersSnapshot.docs;
    _filterUsers();

    await Future.delayed(const Duration(seconds: 2));
    Navigator.of(context).pop();
    setState(() {});
  }

  void _getUsers() async {
    setState(() {});

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset('assets/lotties/search.json'),
                const SizedBox(height: 20),
                Text(
                  'Cargando...',
                  style: GoogleFonts.aBeeZee(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    await Future.delayed(const Duration(seconds: 2));

    QuerySnapshot usersSnapshot = await _firestore.collection('users')
        .where('nickname', isEqualTo: _searchController.text)
        .get();
    _usersList = usersSnapshot.docs;
    _filterUsers();

    await Future.delayed(const Duration(seconds: 2));

    setState(() {});

    Navigator.of(context).pop();
  }

  void _filterUsers() {
    String searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isEmpty) {
      _filteredUsersList = _usersList;
    } else {
      _filteredUsersList = _usersList.where((user) {
        String nickname = user['nickname'].toLowerCase();
        String role = user['role'].toLowerCase();
        return nickname.contains(searchQuery) && role == 'client';
      }).toList();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _updateRole(String email, String role) async {
    DocumentReference userDocument = _firestore.collection('users').doc(email);
    Map<String, dynamic> data = {
      'role': role,
      'estadoid': 0,
      'negoname': _currentUserNegoname,
    };
    if (role == 'moto') {
      String id = _getRandomId(3);
      data['idmoto'] = id;
    }
    await userDocument.update(data);
    _getUsers1();
  }

  String _getRandomId(int length) {
    var random = Random();
    var digits = List.generate(length, (_) => random.nextInt(10));
    return digits.join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambio de Roles'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _getUsers(),
              decoration: InputDecoration(
                labelText: 'Buscar por nickname',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: const Icon(Icons.search),
                
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredUsersList.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot user = _filteredUsersList[index];
                  return Card(
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(user['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Role: ${user['role']}'),
                          Text('Nickname: ${user['nickname']}'),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                          const PopupMenuItem(
                            value: 'client',
                            child: Text('Cliente'),
                          ),
                          const PopupMenuItem(
                            value: 'moto',
                            child: Text('Moto'),
                          ),
                        ],
                        onSelected: (role) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('¿Desea realizar el cambio? a $role'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _updateRole(user['email'], role);
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Aceptar'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getUsers,
        backgroundColor: Colors.teal,
        child:  const Icon(Icons.search),
      ),
    );
  }
}