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
  bool cargando = true;
  bool teoriaVista = false;

  static const int totalEjercicios = 9;

  static const Color _bgColor = Color(0xFFF8F8F8);
  static const Color _cardColor = Color(0xFF58CFC6);

  static const Color _nodeTop = Color(0xFF68D8D0);
  static const Color _nodeBottom = Color(0xFF2ABFB5);

  // Más oscuro para bloqueados
  static const Color _lockedNodeTop = Color(0xFFE5E7EB);
  static const Color _lockedNodeBottom = Color(0xFFD1D5DB);
  static const Color _lockedIconColor = Color(0xFF9CA3AF);

  static const Color _ringColor = Color(0xFFFFC914);
  static const Color _shadowColor = Color.fromARGB(40, 0, 0, 0);
  static const Color _pathColor = Color(0xFF5CCFC6);
  static const Color _textDark = Color(0xFF2B3040);
  static const Color _bubbleBorder = Color(0xFFE1E4EA);

  final List<IconData> nodeIcons = const [
    Icons.star_rounded,
    Icons.menu_book_rounded,
    Icons.fitness_center_rounded,
    Icons.inventory_2_outlined,
    Icons.menu_book_rounded,
    Icons.emoji_events_outlined,
    Icons.fast_forward_rounded,
    Icons.extension_rounded,
    Icons.flag_rounded,
  ];

  final List<Offset> nodePositions = const [
    Offset(70, 0),
    Offset(245, 150),
    Offset(110, 310),
    Offset(255, 470),
    Offset(120, 640),
    Offset(245, 800),
    Offset(100, 970),
    Offset(250, 1130),
    Offset(120, 1290),
  ];

  @override
  void initState() {
    super.initState();
    cargarProgreso();
  }

  Future<void> cargarProgreso() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
      return;
    }

    try {
      final progresoRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progreso')
          .doc('introduccion_algoritmos');

      final progresoDoc = await progresoRef.get();

      if (progresoDoc.exists) {
        final data = progresoDoc.data()!;
        ultimoEjercicio = (data['ultimoEjercicio'] ?? 1) as int;
        teoriaVista = (data['teoriaVista'] ?? false) as bool;
      } else {
        await progresoRef.set({
          'teoriaVista': false,
          'completado': false,
          'ejerciciosCorrectos': 0,
          'ejerciciosIntentados': 0,
          'ultimoEjercicio': 1,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        ultimoEjercicio = 1;
        teoriaVista = false;
      }

      if (ultimoEjercicio < 1) ultimoEjercicio = 1;
      if (ultimoEjercicio > totalEjercicios) ultimoEjercicio = totalEjercicios;

      ejerciciosCompletados = {};
      for (int i = 1; i < ultimoEjercicio; i++) {
        ejerciciosCompletados.add(i);
      }
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<void> abrirEjercicio(int orden) async {
    if (orden > ultimoEjercicio) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EjercicioAlgoritmosPage(orden: orden)),
    );

    await cargarProgreso();
  }

  int get nodoActivo {
    if (ultimoEjercicio < 1) return 1;

    if (ultimoEjercicio > totalEjercicios) {
      return totalEjercicios;
    }

    return ultimoEjercicio;
  }

  bool get mostrarEmpezar {
    return !teoriaVista && ultimoEjercicio == 1;
  }

  @override
  Widget build(BuildContext context) {
    const double mapHeight = 1460;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child:
            cargando
                ? const Center(child: CircularProgressIndicator())
                : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
                      children: [
                        Row(
                          children: [
                            _topButton(
                              icon: Icons.close_rounded,
                              text: 'Volver',
                              onTap: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildUnitCard(),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: mapHeight,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _PathPainter(
                                    positions: nodePositions,
                                    pathColor: _pathColor,
                                  ),
                                ),
                              ),

                              if (mostrarEmpezar)
                                Positioned(
                                  left: nodePositions[0].dx + 6,
                                  top: nodePositions[0].dy - 92,
                                  child: _buildStartBubble(),
                                ),

                              Positioned(
                                left: nodePositions[0].dx + 108,
                                top: nodePositions[0].dy + 8,
                                child: Image.asset(
                                  'assets/images/astro1.png',
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.contain,
                                ),
                              ),

                              Positioned(
                                left: 18,
                                top: nodePositions[3].dy + 78,
                                child: Image.asset(
                                  'assets/images/astro2.png',
                                  width: 98,
                                  height: 98,
                                  fit: BoxFit.contain,
                                ),
                              ),

                              ...List.generate(nodePositions.length, (index) {
                                final orden = index + 1;
                                final desbloqueado = orden <= ultimoEjercicio;
                                final completado = ejerciciosCompletados
                                    .contains(orden);
                                final activo = orden == nodoActivo;
                                final isFirst = orden == 1;

                                return Positioned(
                                  left: nodePositions[index].dx,
                                  top: nodePositions[index].dy,
                                  child: GestureDetector(
                                    onTap:
                                        desbloqueado
                                            ? () => abrirEjercicio(orden)
                                            : null,
                                    child:
                                        isFirst
                                            ? _buildStartNode(
                                              completado: completado,
                                              activo: activo,
                                              bloqueado: !desbloqueado,
                                            )
                                            : _buildLessonNode(
                                              icon:
                                                  completado
                                                      ? Icons.check_rounded
                                                      : nodeIcons[index %
                                                          nodeIcons.length],
                                              completado: completado,
                                              activo: activo,
                                              bloqueado: !desbloqueado,
                                            ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildUnitCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: _shadowColor, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unidad 1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Fundamentos del pensamiento algorítmico',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Color.fromARGB(150, 255, 255, 255),
                width: 1.3,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.format_list_bulleted_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'GUÍA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartBubble() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _bubbleBorder, width: 2),
            boxShadow: const [
              BoxShadow(
                color: _shadowColor,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: const Text(
            'EMPEZAR',
            style: TextStyle(
              color: _cardColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
        ),
        CustomPaint(size: const Size(24, 14), painter: _BubbleTailPainter()),
      ],
    );
  }

  Widget _buildStartNode({
    required bool completado,
    required bool activo,
    required bool bloqueado,
  }) {
    final Color innerColor = bloqueado ? _lockedNodeTop : _cardColor;
    final Color iconColor = bloqueado ? _lockedIconColor : Colors.white;

    if (activo) {
      return Container(
        width: 118,
        height: 118,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _ringColor,
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: innerColor,
            ),
            child: Icon(
              completado ? Icons.check_rounded : Icons.star_rounded,
              color: iconColor,
              size: 46,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bloqueado ? _lockedNodeBottom : _nodeBottom,
        boxShadow: const [
          BoxShadow(color: _shadowColor, blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Center(
        child: Container(
          width: 94,
          height: 94,
          decoration: BoxDecoration(shape: BoxShape.circle, color: innerColor),
          child: Icon(
            completado ? Icons.check_rounded : Icons.star_rounded,
            color: iconColor,
            size: 46,
          ),
        ),
      ),
    );
  }

  Widget _buildLessonNode({
    required IconData icon,
    required bool completado,
    required bool activo,
    required bool bloqueado,
  }) {
    final Color topColor = bloqueado ? _lockedNodeTop : _nodeTop;
    final Color bottomColor = bloqueado ? _lockedNodeBottom : _nodeBottom;
    final Color iconColor = bloqueado ? _lockedIconColor : Colors.white;

    if (activo) {
      return Container(
        width: 102,
        height: 102,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _ringColor,
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bloqueado ? _lockedNodeTop : _cardColor,
            ),
            child: Icon(
              completado ? Icons.check_rounded : icon,
              color: bloqueado ? _lockedIconColor : Colors.white,
              size: 34,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 74,
              decoration: BoxDecoration(
                color: bottomColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: _shadowColor,
                    blurRadius: 8,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 74,
              decoration: BoxDecoration(
                color: topColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                completado ? Icons.check_rounded : icon,
                color: iconColor,
                size: 34,
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _textDark, size: 26),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..color = Colors.white;
    final borderPaint =
        Paint()
          ..color = const Color(0xFFE1E4EA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final path = Path();
    path.moveTo(size.width / 2 - 10, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width / 2 + 10, 0);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PathPainter extends CustomPainter {
  final List<Offset> positions;
  final Color pathColor;

  const _PathPainter({required this.positions, required this.pathColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.length < 2) return;

    final paint =
        Paint()
          ..color = pathColor
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    for (int i = 0; i < positions.length - 1; i++) {
      final start = Offset(positions[i].dx + 46, positions[i].dy + 60);
      final end = Offset(positions[i + 1].dx + 46, positions[i + 1].dy + 8);

      final midY = (start.dy + end.dy) / 2;
      final control1 = Offset(start.dx, midY);
      final control2 = Offset(end.dx, midY);

      final path =
          Path()
            ..moveTo(start.dx, start.dy)
            ..cubicTo(
              control1.dx,
              control1.dy,
              control2.dx,
              control2.dy,
              end.dx,
              end.dy,
            );

      _drawDashedPath(canvas, path, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 14.0;
    const dashSpace = 10.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        final extract = metric.extractPath(
          distance,
          nextDistance.clamp(0, metric.length),
        );
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.pathColor != pathColor;
  }
}
