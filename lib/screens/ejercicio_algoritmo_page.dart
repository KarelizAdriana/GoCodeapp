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
  String? ejercicioId;

  bool cargando = true;
  bool guardando = false;

  bool mostrandoTeoria = true;
  String? opcionSeleccionada;

  bool respondido = false;
  bool correcta = false;
  bool mostrarPremio = false;

  static const int totalEjercicios = 9;

  static const Color bgColor = Colors.white;
  static const Color mainText = Color(0xFF111111);
  static const Color softText = Color(0xFF6B7280);
  static const Color primary = Color(0xFF58CFC6);
  static const Color primaryDark = Color(0xFF1AAFA5);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color disabledColor = Color(0xFFD1D5DB);
  static const Color correctColor = Color(0xFF10B981);
  static const Color wrongColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    cargarEjercicio();
  }

  Future<void> cargarEjercicio() async {
    try {
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
        ejercicioId = query.docs.first.id;
      }
    } catch (e) {
      debugPrint('Error al cargar ejercicio: $e');
    }

    if (mounted) {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> responder() async {
    if (ejercicio == null ||
        ejercicioId == null ||
        opcionSeleccionada == null ||
        guardando) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final respuestaCorrecta = ejercicio!['respuestaCorrecta'] as String;
    final esCorrecta = opcionSeleccionada == respuestaCorrecta;
    final puntos = ejercicio!['puntos'] ?? 0;

    setState(() {
      guardando = true;
      respondido = true;
      correcta = esCorrecta;
    });

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final progresoRef = userRef
        .collection('progreso')
        .doc('introduccion_algoritmos');

    final ejercicioProgresoRef = progresoRef
        .collection('ejercicios')
        .doc(ejercicioId);

    final ejercicioProgresoDoc = await ejercicioProgresoRef.get();

    final yaRespondidoCorrecto =
        ejercicioProgresoDoc.exists &&
        (ejercicioProgresoDoc.data()?['correcto'] ?? false) == true;

    if (esCorrecta) {
      final siguienteEjercicio =
          widget.orden < totalEjercicios ? widget.orden + 1 : totalEjercicios;

      await progresoRef.set({
        'teoriaVista': true,
        'ejerciciosIntentados': FieldValue.increment(1),
        'ejerciciosCorrectos':
            yaRespondidoCorrecto
                ? FieldValue.increment(0)
                : FieldValue.increment(1),
        'ultimoEjercicio': siguienteEjercicio,
        'completado': widget.orden == totalEjercicios,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ✅ CORRECCIÓN: no sobrescribir puntos si ya era correcto
      if (!yaRespondidoCorrecto) {
        await ejercicioProgresoRef.set({
          'orden': widget.orden,
          'respondido': true,
          'correcto': true,
          'puntosGanados': puntos,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await userRef.set({
          'puntos': FieldValue.increment(puntos),
        }, SetOptions(merge: true));
      } else {
        await ejercicioProgresoRef.set({
          'orden': widget.orden,
          'respondido': true,
          'correcto': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (mounted) {
        setState(() {
          mostrarPremio = true;
        });
      }
    } else {
      await progresoRef.set({
        'teoriaVista': true,
        'ejerciciosIntentados': FieldValue.increment(1),
        'ultimoEjercicio': widget.orden,
        'completado': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await ejercicioProgresoRef.set({
        'orden': widget.orden,
        'respondido': true,
        'correcto': false,
        'puntosGanados': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    if (ejercicio == null) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text(
            'No se encontró el ejercicio',
            style: TextStyle(color: mainText),
          ),
        ),
      );
    }

    final opciones = List<String>.from(ejercicio!['opciones']);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
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
        _buildHeader(progressFactor: widget.orden / totalEjercicios),
        const SizedBox(height: 30),
        Text(
          ejercicio!['teoriaTitulo'] ?? ejercicio!['pregunta'],
          style: const TextStyle(
            color: mainText,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardBorder),
          ),
          child: Text(
            ejercicio!['teoriaTexto'] ?? 'Aquí irá la teoría del ejercicio.',
            style: const TextStyle(
              color: mainText,
              fontSize: 17,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Spacer(),
        _mainButton(
          text: 'CONTINUAR',
          enabled: true,
          onPressed: () {
            setState(() {
              mostrandoTeoria = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPregunta(List<String> opciones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(progressFactor: widget.orden / totalEjercicios),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFFFFD),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary),
          ),
          child: const Text(
            'EJERCICIO',
            style: TextStyle(
              color: primaryDark,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          ejercicio!['pregunta'],
          style: const TextStyle(
            color: mainText,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 16),
        if ((ejercicio!['tip'] ?? '').toString().isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFFF59E0B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ejercicio!['tip'],
                    style: const TextStyle(
                      color: mainText,
                      fontSize: 15,
                      height: 1.3,
                    ),
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
              final letra = String.fromCharCode(65 + index);
              final seleccionada = opcionSeleccionada == opcion;
              final esCorrecta = opcion == ejercicio!['respuestaCorrecta'];

              Color fondo = Colors.white;
              Color borde = cardBorder;
              Color letraFondo = const Color(0xFFF3F4F6);
              Color letraColor = softText;
              Color textoColor = mainText;
              IconData? icono;

              if (!respondido && seleccionada) {
                fondo = const Color(0xFFEFFFFD);
                borde = primary;
                letraFondo = primary;
                letraColor = Colors.white;
              }

              if (respondido) {
                if (esCorrecta) {
                  fondo = const Color(0xFFECFDF5);
                  borde = correctColor;
                  letraFondo = correctColor;
                  letraColor = Colors.white;
                  textoColor = correctColor;
                  icono = Icons.check_rounded;
                }

                if (seleccionada && !esCorrecta) {
                  fondo = const Color(0xFFFEF2F2);
                  borde = wrongColor;
                  letraFondo = wrongColor;
                  letraColor = Colors.white;
                  textoColor = wrongColor;
                  icono = Icons.close_rounded;
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
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: fondo,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: borde, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: letraFondo,
                          ),
                          child: Center(
                            child:
                                icono == null
                                    ? Text(
                                      letra,
                                      style: TextStyle(
                                        color: letraColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    )
                                    : Icon(
                                      icono,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            opcion,
                            style: TextStyle(
                              color: textoColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
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
          _mainButton(
            text: 'INTENTAR DE NUEVO',
            enabled: true,
            backgroundColor: wrongColor,
            onPressed: intentarDeNuevo,
          ),
        if (!respondido)
          _mainButton(
            text: guardando ? '' : 'COMPLETAR',
            enabled: opcionSeleccionada != null && !guardando,
            onPressed: responder,
            loading: guardando,
          ),
      ],
    );
  }

  Widget _buildHeader({required double progressFactor}) {
    final puntos = ejercicio?['puntos'] ?? 0;

    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF3F4F6),
            ),
            child: const Icon(Icons.close_rounded, color: mainText, size: 26),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 13,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(30),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressFactor,
              child: Container(
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFEFFFFD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary),
          ),
          child: Text(
            '+$puntos',
            style: const TextStyle(
              color: primaryDark,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _mainButton({
    required String text,
    required bool enabled,
    required VoidCallback onPressed,
    Color backgroundColor = primary,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: disabledColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child:
            loading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
      ),
    );
  }

  Widget _buildPremioOverlay() {
    final puntos = ejercicio?['puntos'] ?? 0;

    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.white, size: 76),
                  const SizedBox(height: 12),
                  Text(
                    '+$puntos',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '¡Puntos ganados!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 26),
                  _mainButton(
                    text:
                        widget.orden == totalEjercicios
                            ? 'FINALIZAR'
                            : 'CONTINUAR',
                    enabled: true,
                    backgroundColor: Colors.white,
                    onPressed: continuarDespuesDePremio,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
