import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:rastreogt/conf/export.dart';

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
  GeoPoint ubicacionM = const GeoPoint(0, 0);
  String nick1 = '';
  String nego = '';
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
    try {
      // Obtener el documento del usuario actual
      DocumentSnapshot currentUserSnapshot =
          await _firestore.collection('users').doc(user!.email).get();

      // Obtener el idBusiness del documento del usuario
      String idBusiness = currentUserSnapshot['idBussiness'];

      // Acceder al documento en la subcolección 'negocios' usando idBusiness
      final DocumentReference documentRef = _firestore
          .collection('users')
          .doc(user!.email)
          .collection('negocios')
          .doc(idBusiness);

      // Obtener el documento de la subcolección
      final DocumentSnapshot doc = await documentRef.get();

      // Extraer la información de 'ubicacion'
      ubicacionM = doc['ubicacionnego'];
      _currentUserNegoname = doc['negoname'];
      nego = doc['nego'];
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('tuvimos un error $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

    try {
      QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('email', isNotEqualTo: user!.email)
          .where('negoname', isEqualTo: _currentUserNegoname)
          .get();
      _usersList = usersSnapshot.docs;
      _filterUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar los usuarios: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    if (!mounted) return;
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

    try {
      await Future.delayed(const Duration(seconds: 2));
      QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('nickname', isEqualTo: _searchController.text)
          // .where('negoname', isEqualTo: _currentUserNegoname)
          .get();

      _usersList = usersSnapshot.docs;
      _filterUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar los usuarios: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() {});
    }
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
    if (_filteredUsersList.isEmpty) {
      // Asegúrate de que el diálogo de carga se cierre antes de mostrar el diálogo de "No se encontraron usuarios"

      Future.delayed(Duration.zero, () {
        _showNoUsersFoundDialog();
      });
    }
  }

  void _showNoUsersFoundDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No se encontraron usuarios'),
          content: const Text(
              'Estas dejando vacio el campo de busqueda o el usuario ya es moto o admin o no existe'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  void _updateRole(String email, String role) async {
    try {
      // Obtener el documento del usuario
      DocumentReference userDocument =
          _firestore.collection('users').doc(email);
      DocumentSnapshot userSnapshot = await userDocument.get();

      // Verificar si el documento existe y obtener el nickname
      String nick1 = '';
      if (userSnapshot.exists) {
        final data = userSnapshot.data() as Map<String, dynamic>?;
        if (data != null) {
          nick1 = data['nickname'] ?? '';
        }
      }

      // Preparar los datos para actualizar el rol del usuario
      Map<String, dynamic> data = {
        'role': role,
        'estadoid': 0,
      };

      if (role == 'moto') {
        // Obtener el documento de la moto
        DocumentReference motoDocument =
            _firestore.collection('motos').doc(email);
        DocumentSnapshot motoSnapshot = await motoDocument.get();

        String? id;
        if (motoSnapshot.exists) {
          final motoData = motoSnapshot.data() as Map<String, dynamic>?;
          if (motoData != null) {
            id = motoData['idmoto'];
          }
        }

        if (id == null || id.isEmpty) {
          id = _getRandomId(3);
          data['idmoto'] = id;
        }

        // Crear una colección 'motos' y un documento 'moto' dentro de ella
        Map<String, dynamic> motoData = {
          'idmoto': id,
          'estadoid':
              1, // Estado de la moto (0 = baja, 1 = Disponible, 2 = En ruta, etc.)
          'negoname': _currentUserNegoname,
          'name': nick1,
          'email': email,
          'telefono': 0,
          'ubicacionM': ubicacionM,
        };

        await motoDocument.set(motoData);
      }

      if (role == 'client') {
        // Crear una colección 'motos' y un documento 'moto' dentro de ella
        CollectionReference motos = _firestore.collection('motos');
        DocumentReference motoDocument = motos.doc(email);

        Map<String, dynamic> motoData = {
          'estadoid':
              3, // Estado de la moto (0 = inactivo, 1 = Disponible, 2 = En ruta, 3 = baja, etc.)
        };

        await motoDocument.update(motoData);
        CollectionReference users = _firestore.collection('users');
        DocumentReference userDocument = users.doc(email);
        Map<String, dynamic> userData = {
          'role': role,
          'estadoid': 0,
          'negoname': 'df',
          'nego': 'df',
        };
        await userDocument.update(userData);
      }

      if (role == 'admin') {
        CollectionReference users = _firestore.collection('users');
        DocumentReference userDocument = users.doc(email);
        Map<String, dynamic> userData = {
          'role': role,
          'estadoid': 0,
          'negoname': _currentUserNegoname,
          'nego': nego,
        };
        await userDocument.update(userData);
      }

      await userDocument.update(data);
      _getUsers1();
    } catch (error) {
      // Manejo de errores
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el rol del usuario: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                              title: Text(
                                  '¿Desea enviar solicitud de cambio? a $role'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    'Cancelar',
                                    style: GoogleFonts.aBeeZee(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inverseSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _updateRole(user['email'], role);
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    'Aceptar',
                                    style: GoogleFonts.aBeeZee(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inverseSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
        child: const Icon(Icons.search),
      ),
    );
  }
}
