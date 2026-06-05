import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditQuestionsScreen extends StatelessWidget {
  final String subtemaId;
  const EditQuestionsScreen({super.key, required this.subtemaId});
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Preguntas')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('preguntas').where('subtemaId', isEqualTo: subtemaId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return ListTile(
                title: Text(doc['texto']),
                subtitle: Text("${doc['opciones'].length} opciones"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _dialogoEditarPregunta(context, doc)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => doc.reference.delete()),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _dialogoEditarPregunta(BuildContext context, DocumentSnapshot doc) {
  // 1. Cargamos los datos actuales en controladores
  final textoController = TextEditingController(text: doc['texto']);
  final opcionesControllers = List.generate(
    4, 
    (i) => TextEditingController(text: doc['opciones'][i].toString())
  );
  int correctIndex = doc['index_correcta'];

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder( // StatefulBuilder permite cambiar el dropdown dentro del diálogo
      builder: (context, setState) => AlertDialog(
        title: const Text('Editar Pregunta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textoController,
                decoration: const InputDecoration(labelText: 'Pregunta'),
              ),
              const SizedBox(height: 10),
              ...List.generate(4, (i) => TextField(
                controller: opcionesControllers[i],
                decoration: InputDecoration(labelText: 'Opción ${i + 1}'),
              )),
              const SizedBox(height: 10),
              const Text('Respuesta Correcta:'),
              DropdownButton<int>(
                value: correctIndex,
                isExpanded: true,
                onChanged: (val) => setState(() => correctIndex = val!),
                items: List.generate(4, (i) => DropdownMenuItem(
                  value: i, 
                  child: Text('Opción ${i + 1}')
                )),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancelar')
          ),
          ElevatedButton(
            onPressed: () async {
              // 2. Actualizamos en Firebase
              await doc.reference.update({
                'texto': textoController.text,
                'opciones': opcionesControllers.map((c) => c.text).toList(),
                'index_correcta': correctIndex,
              });
              if (context.mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pregunta actualizada'), backgroundColor: Colors.blue),
              );
            },
            child: const Text('Guardar Cambios'),
          ),
        ],
      ),
    ),
  );
}
}