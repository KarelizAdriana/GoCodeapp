import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'welcome_page.dart';

class RegisterPasswordPage extends StatefulWidget {
  final String nombre;
  final String apellido;
  final String correo;

  const RegisterPasswordPage({
    super.key,
    required this.nombre,
    required this.apellido,
    required this.correo,
  });

  @override
  State<RegisterPasswordPage> createState() => _RegisterPasswordPageState();
}

class _RegisterPasswordPageState extends State<RegisterPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final passwordController = TextEditingController();
  final confirmarPasswordController = TextEditingController();

  bool ocultarPassword = true;
  bool ocultarConfirmPassword = true;
  bool cargando = false;

  @override
  void dispose() {
    passwordController.dispose();
    confirmarPasswordController.dispose();
    super.dispose();
  }

  String? validarPassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Escribe tu contraseña';
    }

    if (password.length < 6) {
      return 'Tu contraseña debe tener al menos 6 caracteres';
    }

    return null;
  }

  String? validarConfirmarPassword(String? value) {
    final confirmar = value ?? '';

    if (confirmar.isEmpty) {
      return 'Confirma tu contraseña';
    }

    if (confirmar != passwordController.text) {
      return 'La contraseña y la confirmación deben ser iguales';
    }

    return null;
  }

  Future<void> crearCuenta() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe tu contraseña y confírmala correctamente'),
        ),
      );
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: widget.correo.toLowerCase(),
            password: passwordController.text.trim(),
          );

      final user = credencial.user;

      if (user == null) {
        throw Exception('No se pudo crear la cuenta');
      }

      final nombreCompleto = '${widget.nombre} ${widget.apellido}'.trim();

      await user.updateDisplayName(nombreCompleto);
      await user.sendEmailVerification();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'nombre': widget.nombre,
        'apellido': widget.apellido,
        'nombreCompleto': nombreCompleto,
        'correo': widget.correo.toLowerCase(),
        'nivelActual': 1,
        'puntos': 0,
        'activo': true,
        'correoVerificado': false,
        'creadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cuenta creada. Revisa tu correo ${widget.correo.toLowerCase()} para verificarlo',
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomePage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Ocurrió un error al crear la cuenta';

      if (e.code == 'email-already-in-use') {
        mensaje = 'Ese correo ya está registrado';
      } else if (e.code == 'invalid-email') {
        mensaje = 'Ese correo no es válido';
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña es muy débil';
      } else if (e.code == 'network-request-failed') {
        mensaje = 'No hay conexión a internet';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error inesperado. Inténtalo otra vez')),
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Configura tu contraseña'),
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: const Color(0xFF101828),
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Crea tu contraseña',
                    style: TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Escribe tu contraseña y luego confírmala igual en ambos campos',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF475467)),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: passwordController,
                    obscureText: ocultarPassword,
                    style: const TextStyle(color: Color(0xFF101828)),
                    decoration: _inputDecoration(
                      'Escribe tu contraseña',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            ocultarPassword = !ocultarPassword;
                          });
                        },
                        icon: Icon(
                          ocultarPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF667085),
                        ),
                      ),
                    ),
                    validator: validarPassword,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: confirmarPasswordController,
                    obscureText: ocultarConfirmPassword,
                    style: const TextStyle(color: Color(0xFF101828)),
                    decoration: _inputDecoration(
                      'Confirma tu contraseña',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            ocultarConfirmPassword = !ocultarConfirmPassword;
                          });
                        },
                        icon: Icon(
                          ocultarConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF667085),
                        ),
                      ),
                    ),
                    validator: validarConfirmarPassword,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: cargando ? null : crearCuenta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E2A52),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child:
                          cargando
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Crear cuenta',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Volver al paso anterior',
                      style: TextStyle(color: Color(0xFF667085)),
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

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF98A2B3)),
      filled: true,
      fillColor: const Color(0xFFFFFFFF),
      suffixIcon: suffixIcon,
      errorStyle: const TextStyle(color: Colors.redAccent),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD7DFEE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0E2A52), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
