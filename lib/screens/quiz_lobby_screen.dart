import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz_screen.dart';
import 'edit_questions_screen.dart'; // Crearemos esta ahora

class QuizLobbyScreen extends StatelessWidget {
  final String subtemaId;
  final String subtemaNombre;
  final String subtemaDificultad;
  final String temaId;
  final String temaNombre;

  const QuizLobbyScreen({
    super.key,
    required this.subtemaId,
    required this.subtemaNombre,
    required this.subtemaDificultad,
    required this.temaId,
    required this.temaNombre, 
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      backgroundColor: Colors.indigo[900], // Fondo oscuro tipo Kahoot
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz, size: 100, color: Colors.amber),
            const SizedBox(height: 20),
            Text(subtemaNombre, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(temaNombre, style: TextStyle(fontSize: 18, color: Colors.indigo[100])),
            const SizedBox(height: 40),
            
            // Botón Jugar (Para todos)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(
                temaId: temaId, temaNombre: temaNombre, subtemaId: subtemaId, subtemaNombre: subtemaNombre,subtemaDificultad: subtemaDificultad,
              ))),
              child: const Text('EMPEZAR JUEGO'),
            ),

            if (isAdmin) ...[
              const SizedBox(height: 20),
              // Botón Editar (Solo Admin)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditQuestionsScreen(subtemaId: subtemaId))),
                icon: const Icon(Icons.edit),
                label: const Text('GESTIONAR PREGUNTAS'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}