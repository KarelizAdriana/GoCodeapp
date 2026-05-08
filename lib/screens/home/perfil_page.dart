import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/welcome_page.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  static const Color bgColor = Colors.white;
  static const Color mainText = Color(0xFF111827);
  static const Color softText = Color(0xFF6B7280);
  static const Color primary = Color(0xFF58CFC6);
  static const Color primaryDark = Color(0xFF1AAFA5);
  static const Color cardBorder = Color(0xFFE5E7EB);

  final TextEditingController nombreController = TextEditingController();

  bool cargando = true;
  bool guardando = false;
  bool editando = false;

  String nombre = 'GoCode User';
  String correo = '';
  String puntos = '0';
  String? fotoUrl;

  @override
  void initState() {
    super.initState();
    cargarUsuario();
  }

  Future<void> cargarUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final data = doc.data();

    nombre = data?['nombre'] ?? user.displayName ?? 'GoCode User';
    correo = data?['correo'] ?? user.email ?? 'Sin correo';
    puntos = data?['puntos']?.toString() ?? '0';
    fotoUrl = data?['fotoPerfil'] ?? user.photoURL;

    nombreController.text = nombre;

    if (mounted) {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> guardarNombre() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nuevoNombre = nombreController.text.trim();

    if (nuevoNombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'nombre': nuevoNombre,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await user.updateDisplayName(nuevoNombre);

    setState(() {
      nombre = nuevoNombre;
      guardando = false;
      editando = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nombre actualizado')));
  }

  Future<void> cambiarFotoPerfil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();

    final imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 800,
    );

    if (imagen == null) return;

    setState(() {
      guardando = true;
    });

    try {
      final Uint8List bytes = await imagen.readAsBytes();

      final ref = FirebaseStorage.instance
          .ref()
          .child('usuarios')
          .child(user.uid)
          .child('foto_perfil.jpg');

      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fotoPerfil': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.updatePhotoURL(url);

      setState(() {
        fotoUrl = url;
        guardando = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto actualizada')));
    } catch (e) {
      setState(() {
        guardando = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir foto: $e')));
    }
  }

  Future<void> cerrarSesion() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
              children: [
                const Text(
                  'Mi Perfil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mainText,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 26),

                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEFFFFD),
                          border: Border.all(color: primary, width: 3),
                        ),
                        child: ClipOval(
                          child:
                              fotoUrl == null || fotoUrl!.isEmpty
                                  ? const Icon(
                                    Icons.person_outline,
                                    color: primaryDark,
                                    size: 70,
                                  )
                                  : Image.network(
                                    fotoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => const Icon(
                                          Icons.person_outline,
                                          color: primaryDark,
                                          size: 70,
                                        ),
                                  ),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 4,
                        child: GestureDetector(
                          onTap: guardando ? null : cambiarFotoPerfil,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: mainText,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  correo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: softText, fontSize: 14),
                ),

                const SizedBox(height: 24),

                Container(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nombre',
                        style: TextStyle(
                          color: softText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: cardBorder),
                        ),
                        child:
                            editando
                                ? TextField(
                                  controller: nombreController,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: const TextStyle(
                                    color: mainText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  onSubmitted: (_) async {
                                    await guardarNombre();
                                  },
                                  onEditingComplete: () async {
                                    await guardarNombre();
                                  },
                                )
                                : Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        nombre,
                                        style: const TextStyle(
                                          color: mainText,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          editando = true;
                                        });
                                      },
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        color: primary,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                _datoPerfil(
                  icono: Icons.star_rounded,
                  titulo: 'Puntos acumulados',
                  valor: puntos,
                ),

                const SizedBox(height: 12),

                _datoPerfil(
                  icono: Icons.email_outlined,
                  titulo: 'Correo',
                  valor: correo,
                ),

                const SizedBox(height: 24),

                OutlinedButton.icon(
                  onPressed: cerrarSesion,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
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

  Widget _datoPerfil({
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFFFFD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icono, color: primaryDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: softText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  valor,
                  style: const TextStyle(
                    color: mainText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
