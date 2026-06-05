import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class QuizScreen extends StatefulWidget {
  final String temaId;
  final String temaNombre;
  final String subtemaId;
  final String subtemaNombre;
  final String subtemaDificultad; // Recibida del Lobby

  const QuizScreen({
    super.key, 
    required this.temaId, 
    required this.temaNombre, 
    required this.subtemaId, 
    required this.subtemaNombre,
    required this.subtemaDificultad,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _preguntaActual = 0;
  int _puntos = 0;
  Timer? _timer;
  int _secondsRemaining = 20;
  int _totalPreguntas = 0;

  // Configuración de iconos y colores estilo Kahoot
  final List<Color> _colores = [const Color(0xFFe21b3c), const Color(0xFF1368ce), const Color(0xFFd89e00), const Color(0xFF26890c)];
  final List<IconData> _iconos = [Icons.change_history, Icons.diamond, Icons.circle, Icons.square];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 20;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
            _verificarRespuesta(-1, -1); 
          }
        });
      }
    });
  }

  void _verificarRespuesta(int seleccionado, int correcta) {
    _timer?.cancel();
    
    if (seleccionado != -1 && seleccionado == correcta) {
      _puntos += 100;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Correcto! +100 puntos'), backgroundColor: Colors.green, duration: Duration(milliseconds: 600)),
      );
    } else {
      String msj = seleccionado == -1 ? '¡Tiempo agotado!' : 'Incorrecto';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msj), backgroundColor: Colors.red, duration: const Duration(milliseconds: 600)),
      );
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _preguntaActual++;
          if (_preguntaActual < _totalPreguntas) {
            _startTimer();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2), // Fondo gris claro de la imagen
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('preguntas')
            .where('subtemaId', isEqualTo: widget.subtemaId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var docs = snapshot.data!.docs;
          _totalPreguntas = docs.length;

          if (docs.isEmpty) return const Center(child: Text('Cargando preguntas...'));
          
          if (_preguntaActual >= _totalPreguntas) {
            return _pantallaFinal();
          }

          var datosPregunta = docs[_preguntaActual];
          List opciones = datosPregunta['opciones'];

          return SafeArea(
            child: Column(
              children: [
                // 1. HEADER AZUL INFORMATIVO
                Container(
                  color: const Color(0xFF1368ce),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pregunta ${_preguntaActual + 1}/$_totalPreguntas | Nivel: ${widget.subtemaDificultad} | Puntos: $_puntos',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // 2. TARJETA CENTRAL DE PREGUNTA
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, spreadRadius: 5)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            datosPregunta['texto'],
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // CRONÓMETRO CIRCULAR
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 90, height: 90,
                              child: CircularProgressIndicator(
                                value: _secondsRemaining / 20,
                                strokeWidth: 8,
                                color: _secondsRemaining > 5 ? const Color(0xFF1368ce) : Colors.red,
                                backgroundColor: Colors.grey[200],
                              ),
                            ),
                            Text('${_secondsRemaining}s', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. GRILLA DE RESPUESTAS (BOTONES DE COLORES)
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: opciones.length,
                      itemBuilder: (context, i) {
                        return _answerButton(
                          opciones[i], 
                          _colores[i], 
                          _iconos[i],
                          () => _verificarRespuesta(i, datosPregunta['index_correcta']),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _answerButton(String texto, Color color, IconData icono, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: Colors.white, size: 45),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                texto,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pantallaFinal() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
          const SizedBox(height: 20),
          const Text('¡Juego Terminado!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text('Puntuación final: $_puntos', style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1368ce), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            onPressed: () => Navigator.pop(context), 
            child: const Text('Volver al inicio', style: TextStyle(color: Colors.white, fontSize: 18))
          ),
        ],
      ),
    );
  }
}