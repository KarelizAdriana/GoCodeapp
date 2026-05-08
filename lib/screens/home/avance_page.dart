import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AvancePage extends StatelessWidget {
  const AvancePage({super.key});

  static const Color bgColor = Colors.white;
  static const Color mainText = Color(0xFF111827);
  static const Color softText = Color(0xFF6B7280);
  static const Color primary = Color(0xFF58CFC6);
  static const Color primaryDark = Color(0xFF1AAFA5);
  static const Color cardBorder = Color(0xFFE5E7EB);

  static const int totalAlgoritmos = 9;

  Future<Map<String, dynamic>> cargarAvance() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return {};

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final progresoDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('progreso')
            .doc('introduccion_algoritmos')
            .get();

    return {
      'usuario': userDoc.data() ?? {},
      'algoritmos': progresoDoc.data() ?? {},
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: cargarAvance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }

        final usuario = snapshot.data?['usuario'] ?? {};
        final algoritmos = snapshot.data?['algoritmos'] ?? {};

        final puntos = usuario['puntos'] ?? 0;
        final correctos = algoritmos['ejerciciosCorrectos'] ?? 0;
        final intentados = algoritmos['ejerciciosIntentados'] ?? 0;
        final ultimoEjercicio = algoritmos['ultimoEjercicio'] ?? 1;

        final progreso = (correctos / totalAlgoritmos).clamp(0.0, 1.0);
        final porcentaje = (progreso * 100).round();

        final disponibles =
            ultimoEjercicio > totalAlgoritmos
                ? totalAlgoritmos
                : ultimoEjercicio;

        return Container(
          color: bgColor,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: primary, size: 34),
                  SizedBox(width: 10),
                  Text(
                    'Mi Avance',
                    style: TextStyle(
                      color: mainText,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Revisa tu progreso en cada curso',
                style: TextStyle(color: softText, fontSize: 15),
              ),
              const SizedBox(height: 26),

              _cursoCard(
                assetPath: 'assets/images/logok.png',
                titulo: 'Introducción a Algoritmos',
                progreso: progreso,
                porcentaje: porcentaje,
                disponibles:
                    '$disponibles / $totalAlgoritmos lecciones disponibles',
                puntos: puntos,
                intentados: intentados,
                correctos: correctos,
                activo: true,
              ),

              const SizedBox(height: 16),

              _cursoBloqueado(
                assetPath: 'assets/images/python.png',
                titulo: 'Python',
              ),

              const SizedBox(height: 16),

              _cursoBloqueado(
                assetPath: 'assets/images/html.png',
                titulo: 'HTML',
              ),

              const SizedBox(height: 16),

              _cursoBloqueado(assetPath: null, titulo: 'SQL'),

              const SizedBox(height: 16),

              _cursoBloqueado(
                assetPath: 'assets/images/cplus.png',
                titulo: 'C++',
              ),

              const SizedBox(height: 16),

              _cursoBloqueado(
                assetPath: 'assets/images/java (2).png',
                titulo: 'Java',
              ),

              const SizedBox(height: 16),

              _cursoBloqueado(
                assetPath: 'assets/images/csharp.png',
                titulo: 'C#',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cursoCard({
    required String assetPath,
    required String titulo,
    required double progreso,
    required int porcentaje,
    required String disponibles,
    required int puntos,
    required int intentados,
    required int correctos,
    required bool activo,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFFFD),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Image.asset(assetPath, fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: mainText,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      disponibles,
                      style: const TextStyle(
                        color: softText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFFFD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$porcentaje%',
                  style: const TextStyle(
                    color: primaryDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const Text(
                'Progreso',
                style: TextStyle(color: softText, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '$correctos / $totalAlgoritmos',
                style: const TextStyle(
                  color: mainText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 9,
              backgroundColor: const Color(0xFFE5E7EB),
              color: primary,
            ),
          ),

          const SizedBox(height: 16),

          _datoInterno(
            icono: Icons.check_circle_outline,
            titulo: 'Ejercicios correctos',
            valor: '$correctos',
          ),

          const SizedBox(height: 10),

          _datoInterno(
            icono: Icons.edit_note_rounded,
            titulo: 'Intentos realizados',
            valor: '$intentados',
          ),

          const SizedBox(height: 10),

          _datoInterno(
            icono: Icons.star_rounded,
            titulo: 'Puntos acumulados',
            valor: '$puntos',
          ),
        ],
      ),
    );
  }

  Widget _datoInterno({
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Icon(icono, color: primaryDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: mainText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              color: primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cursoBloqueado({required String? assetPath, required String titulo}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(18),
            ),
            child:
                assetPath == null
                    ? const Icon(
                      Icons.storage_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 30,
                    )
                    : Image.asset(assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: mainText,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              '0%',
              style: TextStyle(color: softText, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
