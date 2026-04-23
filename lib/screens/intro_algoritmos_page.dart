import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'ejercicio_algoritmo_page.dart';

class IntroAlgoritmosPage extends StatelessWidget {
  const IntroAlgoritmosPage({super.key});

  Future<void> marcarTeoriaVista() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final progresoRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('progreso')
        .doc('introduccion_algoritmos');

    final doc = await progresoRef.get();
    final data = doc.data();

    await progresoRef.set({
      'teoriaVista': true,
      'completado': data?['completado'] ?? false,
      'ejerciciosCorrectos': data?['ejerciciosCorrectos'] ?? 0,
      'ejerciciosIntentados': data?['ejerciciosIntentados'] ?? 0,
      'ultimoEjercicio':
          (data?['ultimoEjercicio'] ?? 1) < 1
              ? 1
              : (data?['ultimoEjercicio'] ?? 1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _circleButton(
                        icon: Icons.close,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF172238),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 110,
                              decoration: BoxDecoration(
                                color: const Color(0xFF60E4E8),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x663DE4E8),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    '¿Qué es un\nalgoritmo?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Un algoritmo es un conjunto de pasos ordenados y finitos que se siguen para resolver un problema o realizar una tarea.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    width: 250,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1530),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFF1A3F7A)),
                    ),
                    child: const Text(
                      'Ejemplo sencillo\n\n'
                      '1. Encender la computadora\n'
                      '2. Abrir el programa\n'
                      '3. Escribir el código\n'
                      '4. Ejecutarlo\n\n'
                      'Ese orden de pasos es un algoritmo.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await marcarTeoriaVista();

                        if (!context.mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => const EjercicioAlgoritmosPage(orden: 1),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5AD7D7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        'CONTINUAR',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF202437),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
