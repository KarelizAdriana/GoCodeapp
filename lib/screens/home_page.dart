import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'intro_algoritmos_path_page.dart';
import 'welcome_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _CourseNode {
  const _CourseNode({
    required this.name,
    required this.assetPath,
    required this.fallbackIcon,
    required this.color,
  });

  final String name;
  final String? assetPath;
  final IconData fallbackIcon;
  final Color color;
}

class _HomePageState extends State<HomePage> {
  int currentTab = 0;

  static const Color bgColor = Colors.white;
  static const Color mainText = Color(0xFF111111);
  static const Color softText = Color(0xFF6B7280);
  static const Color navyDark = Color(0xFF0E1A2B);

  final List<_CourseNode> courses = const [
    _CourseNode(
      name: 'Introducción a algoritmos',
      assetPath: null,
      fallbackIcon: Icons.account_tree_rounded,
      color: Color(0xFF4B73B5),
    ),
    _CourseNode(
      name: 'Python',
      assetPath: 'assets/images/python.png',
      fallbackIcon: Icons.code,
      color: Color.fromARGB(255, 109, 221, 109),
    ),
    _CourseNode(
      name: 'HTML',
      assetPath: 'assets/images/html.png',
      fallbackIcon: Icons.language,
      color: Color.fromARGB(255, 255, 103, 33),
    ),

    _CourseNode(
      name: 'SQL',
      assetPath: null,
      fallbackIcon: Icons.storage_rounded,
      color: Color.fromARGB(255, 255, 224, 85),
    ),
    _CourseNode(
      name: 'C++',
      assetPath: 'assets/images/cplus.png',
      fallbackIcon: Icons.settings,
      color: Color.fromARGB(255, 126, 71, 177),
    ),
    _CourseNode(
      name: 'Java',
      assetPath: 'assets/images/java (2).png',
      fallbackIcon: Icons.coffee,
      color: Color.fromARGB(255, 116, 55, 37),
    ),
    _CourseNode(
      name: 'C#',
      assetPath: 'assets/images/csharp.png',
      fallbackIcon: Icons.tag,
      color: Color.fromARGB(255, 72, 121, 201),
    ),
  ];

  Future<Map<String, dynamic>?> obtenerDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    return doc.data();
  }

  void abrirCurso(_CourseNode course) {
    if (course.name == 'Introducción a algoritmos') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const IntroAlgoritmosPathPage()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: navyDark,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Curso seleccionado: ${course.name}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      color: bgColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(
              backgroundColor: bgColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleSpacing: 0,
              title: const Text(
                'GoCode',
                style: TextStyle(
                  color: Color.fromARGB(255, 28, 243, 207),
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  letterSpacing: -0.4,
                ),
              ),
              leading: Builder(
                builder:
                    (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: _topIcon(Icons.menu),
                    ),
              ),
              actions: [
                Builder(
                  builder:
                      (context) => IconButton(
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                        icon: _topIcon(Icons.person_outline),
                      ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            drawer: Drawer(
              backgroundColor: bgColor,
              child: SafeArea(
                child: Column(
                  children: [
                    const DrawerHeader(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            color: Color.fromARGB(255, 10, 255, 235),
                            size: 36,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Menú',
                            style: TextStyle(
                              color: mainText,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Opciones de la app',
                            style: TextStyle(color: softText, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.trending_up, color: navyDark),
                      title: const Text(
                        'Avance de la app',
                        style: TextStyle(color: mainText),
                      ),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: navyDark),
                      title: const Text(
                        'Cerrar sesión',
                        style: TextStyle(color: mainText),
                      ),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();

                        if (!context.mounted) return;

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WelcomePage(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            endDrawer: Drawer(
              backgroundColor: bgColor,
              child: SafeArea(
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: obtenerDatosUsuario(),
                  builder: (context, snapshot) {
                    final data = snapshot.data;

                    final nombre =
                        data?['nombre'] ?? user?.displayName ?? 'Sin nombre';
                    final correo =
                        data?['correo'] ?? user?.email ?? 'Sin correo';
                    final puntos = data?['puntos']?.toString() ?? '0';
                    final nivel = data?['nivelActual']?.toString() ?? '1';

                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Color.fromARGB(255, 10, 255, 235),
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _datoPerfil('Nombre', nombre),
                        _datoPerfil('Correo', correo),
                        _datoPerfil('Nivel actual', nivel),
                        _datoPerfil('Puntos', puntos),
                      ],
                    );
                  },
                ),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _emptyHeroCard(),
                    const SizedBox(height: 20),
                    _courseGrid(),
                    const SizedBox(height: 20),
                    _infoCard(
                      title: 'Tu progreso',
                      subtitle: 'Sigue aprendiendo y avanza paso a paso.',
                      trailing: OutlinedButton(
                        onPressed: () {},
                        style: _outlineButtonStyle(),
                        child: const Text('Ver avance'),
                      ),
                      leading: SizedBox(
                        width: 52,
                        height: 52,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const SizedBox(
                              width: 52,
                              height: 52,
                              child: CircularProgressIndicator(
                                value: 0.2,
                                strokeWidth: 4,
                                backgroundColor: Color(0xFFE5E7EB),
                                color: navyDark,
                              ),
                            ),
                            const Text(
                              '20%',
                              style: TextStyle(
                                color: mainText,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoCard(
                      title: 'Racha',
                      subtitle: '2 días seguidos. Mantén tu ritmo.',
                      leading: _smallBoxIcon(
                        Icons.local_fire_department_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoCard(
                      title: 'Desafío diario',
                      subtitle: 'Completa una lección y gana experiencia.',
                      leading: _smallBoxIcon(Icons.smart_toy_outlined),
                      trailing: OutlinedButton(
                        onPressed: () {},
                        style: _outlineButtonStyle(),
                        child: const Text('Comenzar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Container(
              margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: BottomNavigationBar(
                currentIndex: currentTab,
                onTap: (value) => setState(() => currentTab = value),
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Color.fromARGB(255, 135, 255, 245),
                unselectedItemColor: softText,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                type: BottomNavigationBarType.fixed,

                showSelectedLabels: false,
                showUnselectedLabels: false,

                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: ' ',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.trending_up_outlined),
                    activeIcon: Icon(Icons.trending_up),
                    label: ' ',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: ' ',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topIcon(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: navyDark, size: 26),
    );
  }

  Widget _emptyHeroCard() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
    );
  }

  Widget _courseGrid() {
    return GridView.builder(
      itemCount: courses.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.80,
      ),
      itemBuilder: (context, index) {
        final course = courses[index];
        return _CourseCard(course: course, onTap: () => abrirCurso(course));
      },
    );
  }

  Widget _smallBoxIcon(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: navyDark, size: 22),
    );
  }

  Widget _infoCard({
    required String title,
    required String subtitle,
    required Widget leading,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),

        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: mainText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: softText,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing],
        ],
      ),
    );
  }

  ButtonStyle _outlineButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: navyDark,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    );
  }

  Widget _datoPerfil(String titulo, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: mainText,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(valor, style: const TextStyle(color: softText, fontSize: 14)),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTap});

  final _CourseNode course;
  final VoidCallback onTap;

  static const Color navyDark = Color(0xFF0E1A2B);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: course.color,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: course.color.withOpacity(0.9),
              width: 1.6,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(51, 255, 255, 255),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Center(
                  child:
                      course.assetPath != null
                          ? Image.asset(
                            course.assetPath!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                            errorBuilder:
                                (_, __, ___) => Icon(
                                  course.fallbackIcon,
                                  color: navyDark,
                                  size: 40,
                                ),
                          )
                          : Icon(
                            course.fallbackIcon,
                            color: navyDark,
                            size: 30,
                          ),
                ),

                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    course.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      letterSpacing: -0.2,
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
}
