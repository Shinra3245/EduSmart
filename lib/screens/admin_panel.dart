import 'package:app_kahoot/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  // --- CONTROLADORES ---
  final _temaController = TextEditingController();
  final _subtemaController = TextEditingController();
  final _preguntaController = TextEditingController();
  final _emojiBusquedaController = TextEditingController(); // Nuevo: Para buscar iconos
  final _opcionesControllers = List.generate(4, (_) => TextEditingController());

  // --- VARIABLES DE ESTADO ---
  String? _selectedTemaIdParaSubtema;
  String? _temaIdFiltroParaPregunta;
  String? _subtemaIdSeleccionado;
  String _dificultadSubtema = 'Fácil';
  int _correctIndex = 0;

  // --- VARIABLES DE EMOJI API ---
  String _emojiSeleccionado = "❓"; 
  List<dynamic> _listaEmojis = []; 
  bool _cargandoEmojis = false;
  final String _apiKey = "e0a8469bd071e40261029dd1bc8a43d4a64cf3ab";

  @override
  void initState() {
    super.initState();
    _cargarEmojis(); // Carga inicial (populares)
  }

  // --- FUNCIÓN PARA LLAMAR A LA API (CON BÚSQUEDA) ---
  Future<void> _cargarEmojis({String query = ""}) async {
    setState(() => _cargandoEmojis = true);
    try {
      // Si hay búsqueda usamos el endpoint 'emojis?search=', si no, el general
      String url = query.isEmpty 
          ? "https://emoji-api.com/emojis?access_key=$_apiKey"
          : "https://emoji-api.com/emojis?search=$query&access_key=$_apiKey";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200 && response.body != "null") {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _listaEmojis = data.take(50).toList(); // Limitamos a 50 para fluidez
          _cargandoEmojis = false;
        });
      } else {
        setState(() => _cargandoEmojis = false);
      }
    } catch (e) {
      setState(() {
        _listaEmojis = ["🚀", "🧪", "🌎", "🧬", "📚", "🎨", "⚽"]; // Respaldo
        _cargandoEmojis = false;
      });
    }
  }

  final List<Color> _coloresKahoot = [const Color(0xFFe21b3c), const Color(0xFF1368ce), const Color(0xFFd89e00), const Color(0xFF26890c)];
  final List<IconData> _iconosKahoot = [Icons.change_history, Icons.diamond, Icons.circle, Icons.square];

  // --- MÉTODOS DE APOYO VISUAL ---
  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        children: [Padding(padding: const EdgeInsets.all(20), child: child)],
      ),
    );
  }

  Widget _buildOptionInput({required int index, required TextEditingController controller, required IconData icon, required Color color}) {
    String letter = String.fromCharCode(65 + index);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Container(
            width: 55, height: 55,
            decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15))),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(hintText: "Opción $letter", border: InputBorder.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- LÓGICA DE FIREBASE ---
  Future<void> _crearTema() async {
    if (_temaController.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('temas').add({
      'nombre': _temaController.text.trim(),
      'icono': _emojiSeleccionado,
    });
    _temaController.clear();
    _mostrarAviso('Tema Creado con éxito', Colors.green);
  }

  Future<void> _crearSubtema() async {
    if (_selectedTemaIdParaSubtema == null || _subtemaController.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('subtemas').add({
      'nombre': _subtemaController.text,
      'temaId': _selectedTemaIdParaSubtema,
      'dificultad': _dificultadSubtema,
    });
    _subtemaController.clear();
    _mostrarAviso('Subtema Creado', Colors.green);
  }

  Future<void> _guardarPregunta() async {
    if (_subtemaIdSeleccionado == null || _preguntaController.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('preguntas').add({
      'subtemaId': _subtemaIdSeleccionado,
      'texto': _preguntaController.text,
      'opciones': _opcionesControllers.map((c) => c.text).toList(),
      'index_correcta': _correctIndex,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _preguntaController.clear();
    for (var c in _opcionesControllers) { c.clear(); }
    _mostrarAviso('Pregunta guardada', Colors.green);
  }

  void _mostrarAviso(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }

  // (Aquí puedes pegar tus funciones CRUD _editarNombre, _borrarTemaSeguro, etc.)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9),
      body: Column(
        children: [
          // HEADER AZUL
          Container(
            padding: const EdgeInsets.only(top: 50, left: 10, right: 10, bottom: 20),
            color: const Color(0xFF1368ce),
            child: Row(
              children: [
                // --- NUEVO BOTÓN DE REGRESO ---
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  tooltip: 'Regresar al Inicio',
                  onPressed: () => Navigator.pop(context), // Cierra el panel y vuelve al Home
                ),
                const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 10),
                const Expanded( // Usamos Expanded para evitar que el texto se corte en pantallas pequeñas
                  child: Text(
                    'Panel de Administración', 
                    style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.power_settings_new, color: Colors.white),
                  tooltip: 'Cerrar Sesión',
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // --- SECCIÓN 1: TEMAS CON BUSCADOR DE ICONOS ---
                  _buildSectionCard(
                    title: 'TEMAS',
                    icon: Icons.book,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _temaController, 
                          decoration: const InputDecoration(labelText: 'Nombre del Tema', border: OutlineInputBorder())
                        ),
                        const SizedBox(height: 15),
                        const Text("Selecciona o Busca un Icono:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        
                        // Buscador de Emojis
                        TextField(
                          controller: _emojiBusquedaController,
                          decoration: InputDecoration(
                            hintText: "Escribe en inglés: 'space', 'science', 'history'...",
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () => _cargarEmojis(query: _emojiBusquedaController.text),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (val) => _cargarEmojis(query: val),
                        ),
                        const SizedBox(height: 10),

                        _cargandoEmojis 
                          ? const Center(child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator()))
                          : SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _listaEmojis.length,
                                itemBuilder: (context, i) {
                                  String emoji = _listaEmojis[i] is String ? _listaEmojis[i] : _listaEmojis[i]['character'];
                                  return GestureDetector(
                                    onTap: () => setState(() => _emojiSeleccionado = emoji),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      width: 50,
                                      decoration: BoxDecoration(
                                        color: _emojiSeleccionado == emoji ? Colors.blue[100] : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: _emojiSeleccionado == emoji ? Colors.blue : Colors.transparent, width: 2),
                                      ),
                                      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 25))),
                                    ),
                                  );
                                },
                              ),
                            ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity, 
                          child: ElevatedButton(
                            onPressed: _crearTema, 
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), 
                            child: const Text('Registrar Tema')
                          )
                        ),
                      ],
                    ),
                  ),

                  // --- SECCIÓN 2: SUBTEMAS ---
                  _buildSectionCard(
                    title: 'SUBTEMAS',
                    icon: Icons.file_copy,
                    child: Column(
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('temas').snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const LinearProgressIndicator();
                            return DropdownButtonFormField<String>(
                              value: _selectedTemaIdParaSubtema,
                              decoration: const InputDecoration(labelText: 'Tema Padre', border: OutlineInputBorder()),
                              items: snapshot.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['nombre']))).toList(),
                              onChanged: (val) => setState(() => _selectedTemaIdParaSubtema = val),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(controller: _subtemaController, decoration: const InputDecoration(labelText: 'Nombre del Subtema', border: OutlineInputBorder())),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _dificultadSubtema,
                          decoration: const InputDecoration(labelText: 'Dificultad', border: OutlineInputBorder()),
                          items: ['Fácil', 'Medio', 'Difícil'].map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                          onChanged: (val) => setState(() => _dificultadSubtema = val!),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _crearSubtema, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('Registrar Subtema'))),
                      ],
                    ),
                  ),

                  // --- SECCIÓN 3: PREGUNTAS ---
                  _buildSectionCard(
                    title: 'PREGUNTAS',
                    icon: Icons.list_alt,
                    child: Column(
                      children: [
                        // Filtro de Tema y Subtema
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('temas').snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox();
                            return DropdownButtonFormField<String>(
                              value: _temaIdFiltroParaPregunta,
                              decoration: const InputDecoration(labelText: 'Filtrar Tema', border: OutlineInputBorder()),
                              items: snapshot.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['nombre']))).toList(),
                              onChanged: (v) => setState(() { _temaIdFiltroParaPregunta = v; _subtemaIdSeleccionado = null; }),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        if (_temaIdFiltroParaPregunta != null)
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('subtemas').where('temaId', isEqualTo: _temaIdFiltroParaPregunta).snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const LinearProgressIndicator();
                              return DropdownButtonFormField<String>(
                                value: _subtemaIdSeleccionado,
                                decoration: const InputDecoration(labelText: 'Subtema Destino', border: OutlineInputBorder()),
                                items: snapshot.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['nombre']))).toList(),
                                onChanged: (v) => setState(() => _subtemaIdSeleccionado = v),
                              );
                            },
                          ),
                        const SizedBox(height: 15),
                        TextField(controller: _preguntaController, maxLines: 2, decoration: const InputDecoration(hintText: 'Texto de la Pregunta', border: OutlineInputBorder())),
                        const SizedBox(height: 15),
                        // Grid de Opciones Estilizadas
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.3, crossAxisSpacing: 10),
                          itemCount: 4,
                          itemBuilder: (context, i) => _buildOptionInput(index: i, controller: _opcionesControllers[i], icon: _iconosKahoot[i], color: _coloresKahoot[i]),
                        ),
                        const SizedBox(height: 15),
                        const Text('Respuesta Correcta:'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(4, (i) => ChoiceChip(
                            label: Text(String.fromCharCode(65+i)),
                            selected: _correctIndex == i,
                            onSelected: (s) => setState(() => _correctIndex = i),
                          )),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _subtemaIdSeleccionado == null ? null : _guardarPregunta, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1368ce), foregroundColor: Colors.white), child: const Text('Guardar Pregunta'))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}