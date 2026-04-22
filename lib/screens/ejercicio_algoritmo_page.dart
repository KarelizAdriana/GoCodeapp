import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EjercicioAlgoritmosPage extends StatefulWidget {
  final int orden;

  const EjercicioAlgoritmosPage({super.key, required this.orden});

  @override
  State<EjercicioAlgoritmosPage> createState() =>
      _EjercicioAlgoritmosPageState();
}

class _EjercicioAlgoritmosPageState extends State<EjercicioAlgoritmosPage> {
  Map<String, dynamic>? ejercicio;

  bool cargando = true;
  bool guardando = false;

  bool mostrandoTeoria = true;
  String? opcionSeleccionada;

  bool respondido = false;
  bool correcta = false;
  bool mostrarPremio = false;

  @override
  void initState() {
    super.initState();
    cargarEjercicio();
  }

  Future<void> cargarEjercicio() async {
    final query =
        await FirebaseFirestore.instance
            .collection('ejercicios')
            .where('temaId', isEqualTo: 'introduccion_algoritmos')
            .where('orden', isEqualTo: widget.orden)
            .where('activo', isEqualTo: true)
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      ejercicio = query.docs.first.data();
      ejercicio!['docId'] = query.docs.first.id;
    }

    if (mounted) {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> responder() async {
    if (ejercicio == null || opcionSeleccionada == null || guardando) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final esCorrecta = opcionSeleccionada == ejercicio!['respuestaCorrecta'];

    setState(() {
      guardando = true;
      respondido = true;
      correcta = esCorrecta;
    });

    final progresoRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('progreso')
        .doc('introduccion_algoritmos');

    await progresoRef.set({
      'teoriaVista': true,
      'ejerciciosIntentados': FieldValue.increment(1),
      'ejerciciosCorrectos':
          esCorrecta ? FieldValue.increment(1) : FieldValue.increment(0),
      'ultimoEjercicio':
          esCorrecta ? (widget.orden < 9 ? widget.orden + 1 : 9) : widget.orden,
      'completado': esCorrecta ? widget.orden == 9 : false,
    }, SetOptions(merge: true));

    await progresoRef.collection('ejercicios').doc(ejercicio!['docId']).set({
      'orden': widget.orden,
      'respondido': true,
      'correcto': esCorrecta,
    }, SetOptions(merge: true));

    if (esCorrecta) {
      final puntos = ejercicio!['puntos'] ?? 150;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'puntos': FieldValue.increment(puntos),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          mostrarPremio = true;
        });
      }
    }

    if (mounted) {
      setState(() {
        guardando = false;
      });
    }
  }

  void intentarDeNuevo() {
    setState(() {
      respondido = false;
      correcta = false;
      opcionSeleccionada = null;
    });
  }

  void continuarDespuesDePremio() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF050816),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF59DBD7)),
        ),
      );
    }

    if (ejercicio == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF050816),
        body: Center(
          child: Text(
            'No se encontró el ejercicio',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final opciones = List<String>.from(ejercicio!['opciones']);

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child:
                      mostrandoTeoria
                          ? _buildTeoria()
                          : _buildPregunta(opciones),
                ),

                if (mostrarPremio) _buildPremioOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeoria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(progressFactor: widget.orden / 9),
        const SizedBox(height: 24),
        Text(
          ejercicio!['teoriaTitulo'] ?? ejercicio!['pregunta'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          ejercicio!['teoriaTexto'] ?? 'Aquí irá la teoría de este ejercicio.',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        if ((ejercicio!['tip'] ?? '').toString().isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF111A31),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF24314E)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFFFFD45C)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ejercicio!['tip'],
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                mostrandoTeoria = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF59DBD7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: const Text(
              'SIGUIENTE',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPregunta(List<String> opciones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(progressFactor: widget.orden / 9),
        const SizedBox(height: 18),
        const Text(
          'EJERCICIO',
          style: TextStyle(
            color: Color(0xFF59DBD7),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          ejercicio!['pregunta'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 18),
        if ((ejercicio!['tip'] ?? '').toString().isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF111A31),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF24314E)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFFFFD45C)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ejercicio!['tip'],
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: opciones.length,
            itemBuilder: (context, index) {
              final opcion = opciones[index];
              final seleccionada = opcionSeleccionada == opcion;
              final esCorrecta = opcion == ejercicio!['respuestaCorrecta'];

              Color borde = const Color(0xFF24314E);
              Color fondo = const Color(0xFF111A31);
              IconData? icono;
              Color iconoColor = Colors.white;

              if (!respondido && seleccionada) {
                borde = const Color(0xFF59DBD7);
                fondo = const Color(0xFF16263A);
              }

              if (respondido) {
                if (seleccionada && !esCorrecta) {
                  borde = const Color(0xFFFF6A6A);
                  fondo = const Color(0xFF3A161A);
                  icono = Icons.close;
                  iconoColor = const Color(0xFFFF6A6A);
                } else if (esCorrecta) {
                  borde = const Color(0xFF67E2D7);
                  fondo = const Color(0xFF163331);
                  icono = Icons.check;
                  iconoColor = const Color(0xFF67E2D7);
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GestureDetector(
                  onTap:
                      respondido
                          ? null
                          : () {
                            setState(() {
                              opcionSeleccionada = opcion;
                            });
                          },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: fondo,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: borde, width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                icono != null
                                    ? iconoColor.withOpacity(0.15)
                                    : Colors.transparent,
                            border: Border.all(color: borde, width: 2),
                          ),
                          child:
                              icono != null
                                  ? Icon(icono, color: iconoColor, size: 18)
                                  : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            opcion,
                            style: TextStyle(
                              color:
                                  respondido && esCorrecta
                                      ? const Color(0xFF67E2D7)
                                      : respondido &&
                                          seleccionada &&
                                          !esCorrecta
                                      ? const Color(0xFFFF7B7B)
                                      : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (respondido && !correcta)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: intentarDeNuevo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9C9C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text(
                'INTENTAR DE NUEVO',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        if (!respondido)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: opcionSeleccionada == null ? null : responder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF59DBD7),
                disabledBackgroundColor: const Color(0xFF2B3952),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child:
                  guardando
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        'CONTINUAR',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader({required double progressFactor}) {
    return Row(
      children: [
        _circleButton(icon: Icons.close, onTap: () => Navigator.pop(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF1D2335),
              borderRadius: BorderRadius.circular(30),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressFactor,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF59DBD7),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF122332),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '+${ejercicio?['puntos'] ?? 150}',
            style: const TextStyle(
              color: Color(0xFF59DBD7),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremioOverlay() {
    final puntos = ejercicio?['puntos'] ?? 150;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.45),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 260,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF64E4E0), Color(0xFF7ED7B0)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x553CE4DF),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 62,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '+$puntos',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '¡Puntos Ganados!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: continuarDespuesDePremio,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF59DBD7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text(
                      'CONTINUAR',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
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
