import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'ejercicio_algoritmo_page.dart';

class IntroAlgoritmosPathPage extends StatefulWidget {
  const IntroAlgoritmosPathPage({super.key});

  @override
  State<IntroAlgoritmosPathPage> createState() =>
      _IntroAlgoritmosPathPageState();
}

class _IntroAlgoritmosPathPageState extends State<IntroAlgoritmosPathPage> {
  int ultimoEjercicio = 1;
  Set<int> ejerciciosCompletados = {};

  @override
  void initState() {
    super.initState();
    cargarProgreso();
  }

  Future<void> cargarProgreso() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final progresoDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('progreso')
            .doc('introduccion_algoritmos')
            .get();

    if (progresoDoc.exists) {
      final data = progresoDoc.data()!;
      ultimoEjercicio = data['ultimoEjercicio'] ?? 1;
    }

    final ejerciciosSnap =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('progreso')
            .doc('introduccion_algoritmos')
            .collection('ejercicios')
            .get();

    ejerciciosCompletados =
        ejerciciosSnap.docs
            .where((d) => (d.data()['correcto'] ?? false) == true)
            .map((d) => d.data()['orden'] as int)
            .toSet();

    if (mounted) setState(() {});
  }

  void abrirEjercicio(int orden) async {
    if (orden > ultimoEjercicio) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EjercicioAlgoritmosPage(orden: orden)),
    );

    cargarProgreso();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                  children: [
                    Row(
                      children: [
                        _topButton(
                          icon: Icons.close,
                          text: 'Volver',
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Introducción a algoritmos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Completa los 9 ejercicios para avanzar',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    const SizedBox(height: 24),

                    ...List.generate(9, (index) {
                      final orden = index + 1;
                      final completado = ejerciciosCompletados.contains(orden);
                      final desbloqueado = orden <= ultimoEjercicio;

                      final dx = (index % 2 == 0) ? 40.0 : -40.0;

                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 26),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap:
                                    desbloqueado
                                        ? () => abrirEjercicio(orden)
                                        : null,
                                child: Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        desbloqueado
                                            ? const Color(0xFF58D9D7)
                                            : const Color(0xFF2E3448),
                                    boxShadow:
                                        desbloqueado
                                            ? const [
                                              BoxShadow(
                                                color: Color(0x5538E0DC),
                                                blurRadius: 16,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                            : [],
                                  ),
                                  child: Icon(
                                    completado
                                        ? Icons.check_rounded
                                        : desbloqueado
                                        ? Icons.play_arrow_rounded
                                        : Icons.lock,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ejercicio $orden',
                                style: TextStyle(
                                  color:
                                      desbloqueado
                                          ? Colors.white
                                          : Colors.white38,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (orden == ultimoEjercicio)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Text(
                                    'EMPEZAR',
                                    style: TextStyle(
                                      color: Color(0xFF51CFCB),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2135),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A3654)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
