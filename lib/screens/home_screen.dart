import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'admin_panel.dart';
import 'quiz_lobby_screen.dart';
import 'dart:async'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- VARIABLES DE ESTADO ---
  String? _subtemaSeleccionadoId;
  String? _subtemaSeleccionadoNombre;
  String? _subtemaDificultad; // <-- AQUÍ ESTÁ DECLARADA
  String? _temaNombre;
  String? _temaId;

  // --- VARIABLES ADMINISTRATIVAS ---
  bool _isAdmin = false; 
  late StreamSubscription<User?> _authSubscription; 

  // Mapa de colores institucional
  Color _getThemeColor(String nombre) {
    String n = nombre.toLowerCase();
    if (n.contains('matem')) return const Color(0xFF1368ce); 
    if (n.contains('historia')) return const Color(0xFFd89e00); 
    if (n.contains('ciencias')) return const Color(0xFF26890c); 
    return const Color(0xFF46178f); 
  }

  @override
  void initState() {
    super.initState();
    _isAdmin = FirebaseAuth.instance.currentUser != null;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) setState(() => _isAdmin = user != null);
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel(); 
    super.dispose();
  }

  // --- FUNCIONES ADMINISTRATIVAS ---
  void _showEditDialog(DocumentSnapshot doc, String collection) {
    String nameField = 'nombre'; 
    TextEditingController editController = TextEditingController(text: doc[nameField]);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Editar $collection"),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(hintText: "Nombre de $collection"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            TextButton(
              onPressed: () async {
                final newName = editController.text.trim();
                if (newName.isNotEmpty) {
                  await FirebaseFirestore.instance.collection(collection).doc(doc.id).update({nameField: newName});
                  Navigator.pop(context);
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteThemeCascadingConfirm(DocumentSnapshot themeDoc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Eliminar Tema"),
          content: Text("¿Seguro que quieres eliminar el tema '${themeDoc['nombre'].toUpperCase()}' y todos sus subtemas y preguntas vinculados? Esta acción es irreversible."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                _deleteThemeCascading(themeDoc); 
                Navigator.pop(context); 
              },
              child: const Text("Eliminar Todo"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteThemeCascading(DocumentSnapshot themeDoc) async {
    var subDocs = await FirebaseFirestore.instance.collection('subtemas').where('temaId', isEqualTo: themeDoc.id).get();
    for (var subDoc in subDocs.docs) {
      var qDocs = await FirebaseFirestore.instance.collection('preguntas').where('subtemaId', isEqualTo: subDoc.id).get();
      for (var qDoc in qDocs.docs) { await qDoc.reference.delete(); }
      await subDoc.reference.delete();
    }
    await themeDoc.reference.delete();
  }

  void _showDeleteSubthemeConfirm(DocumentSnapshot subDoc, String temaNombre) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Eliminar Subtema"),
          content: Text("¿Seguro que quieres eliminar el subtema '${subDoc['nombre']}' del tema '$temaNombre' y sus preguntas vinculadas?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                var qDocs = await FirebaseFirestore.instance.collection('preguntas').where('subtemaId', isEqualTo: subDoc.id).get();
                for (var qDoc in qDocs.docs) { await qDoc.reference.delete(); }
                await subDoc.reference.delete();
                Navigator.pop(context);
              },
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1368ce), 
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Seleccionar Tema', 
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                    onPressed: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPanel()));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                      }
                    },
                  ),
                ],
              ),
            ),

            // --- CUERPO PRINCIPAL ---
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F2F2), 
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('temas').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var temaDoc = snapshot.data!.docs[index];
                        var temaData = temaDoc.data() as Map<String, dynamic>;
                        
                        String icono = temaData.containsKey('icono') ? temaData['icono'] : "📁";
                        Color colorTema = _getThemeColor(temaData['nombre']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: colorTema,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: ExpansionTile(
                            shape: const Border(),
                            iconColor: Colors.white,
                            collapsedIconColor: Colors.white,
                            leading: Text(icono, style: const TextStyle(fontSize: 24)),
                            title: Row(
                              children: [
                                Text(
                                  temaData['nombre'].toUpperCase(), 
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                                ),
                                if (_isAdmin) ...[ 
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditDialog(temaDoc, 'temas'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _showDeleteThemeCascadingConfirm(temaDoc),
                                  ),
                                ]
                              ],
                            ),
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))
                                ),
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('subtemas')
                                      .where('temaId', isEqualTo: temaDoc.id)
                                      .snapshots(),
                                  builder: (context, subSnapshot) {
                                    if (!subSnapshot.hasData) return const LinearProgressIndicator();
                                    
                                    return Column(
                                      children: subSnapshot.data!.docs.map((subDoc) {
                                        var subData = subDoc.data() as Map<String, dynamic>;
                                        String dificultad = subData.containsKey('dificultad') ? subData['dificultad'] : 'Fácil';

                                        return RadioListTile<String>(
                                          activeColor: colorTema,
                                          title: Row(
                                            children: [
                                              Text(
                                                "${subData['nombre']} - $dificultad", 
                                                style: const TextStyle(fontWeight: FontWeight.w500)
                                              ),
                                              if (_isAdmin) ...[ 
                                                const Spacer(),
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                                  onPressed: () => _showEditDialog(subDoc, 'subtemas'),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () => _showDeleteSubthemeConfirm(subDoc, temaData['nombre']),
                                                ),
                                              ]
                                            ],
                                          ),
                                          value: subDoc.id,
                                          groupValue: _subtemaSeleccionadoId,
                                          onChanged: (val) {
                                            setState(() {
                                              _subtemaSeleccionadoId = val;
                                              _subtemaSeleccionadoNombre = subData['nombre'];
                                              _subtemaDificultad = dificultad; // <-- AQUÍ SE EXTRAE Y GUARDA
                                              _temaId = temaDoc.id;
                                              _temaNombre = temaData['nombre'];
                                            });
                                          },
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // --- ÁREA INFERIOR: BOTÓN INICIAR ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26890c), 
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))
                  ),
                  onPressed: _subtemaSeleccionadoId == null ? null : () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => QuizLobbyScreen(
                      subtemaId: _subtemaSeleccionadoId!,
                      subtemaNombre: _subtemaSeleccionadoNombre!,
                      subtemaDificultad: _subtemaDificultad!, // <-- SE MANDA AL LOBBY SIN ERROR
                      temaId: _temaId!,
                      temaNombre: _temaNombre!,
                    )));
                  },
                  child: const Text(
                    'Iniciar Quiz', 
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}