import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/google_auth_service.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'register_password_page.dart';
import 'welcome_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final correoController = TextEditingController();

  bool cargandoGoogle = false;

  @override
  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    correoController.dispose();
    super.dispose();
  }

  String? validarNombre(String? value) {
    final nombre = value?.trim() ?? '';

    if (nombre.isEmpty) {
      return 'Escribe tu nombre';
    }

    if (nombre.length < 2) {
      return 'Tu nombre es demasiado corto';
    }

    if (!RegExp(r"^[a-zA-ZÁÉÍÓÚáéíóúÑñ ]+$").hasMatch(nombre)) {
      return 'Tu nombre solo puede tener letras';
    }

    return null;
  }

  String? validarApellido(String? value) {
    final apellido = value?.trim() ?? '';

    if (apellido.isEmpty) {
      return 'Escribe tu apellido';
    }

    if (apellido.length < 2) {
      return 'Tu apellido es demasiado corto';
    }

    if (!RegExp(r"^[a-zA-ZÁÉÍÓÚáéíóúÑñ ]+$").hasMatch(apellido)) {
      return 'Tu apellido solo puede tener letras';
    }

    return null;
  }

  String? validarCorreo(String? value) {
    final correo = value?.trim() ?? '';

    if (correo.isEmpty) {
      return 'Escribe tu correo';
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(correo)) {
      return 'Pon un correo válido, por ejemplo: nombre@correo.com';
    }

    return null;
  }

  Future<void> continuarRegistro() async {
    FocusScope.of(context).unfocus();

    final formularioValido = _formKey.currentState!.validate();

    if (!formularioValido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa bien tus datos antes de continuar'),
        ),
      );
      return;
    }

    final email = correoController.text.trim().toLowerCase();

    try {
      final consulta =
          await FirebaseFirestore.instance
              .collection('users')
              .where('correo', isEqualTo: email)
              .limit(1)
              .get();

      if (!mounted) return;

      if (consulta.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ese correo ya está registrado')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => RegisterPasswordPage(
                nombre: nombreController.text.trim(),
                apellido: apellidoController.text.trim(),
                correo: email, //
              ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al verificar el correo')),
      );
    }
  }

  Future<void> iniciarConGoogle() async {
    if (cargandoGoogle) return;

    FocusScope.of(context).unfocus();

    setState(() {
      cargandoGoogle = true;
    });

    try {
      final credencialUsuario = await GoogleAuthService.signInWithGoogle();

      if (credencialUsuario == null || !mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String mensaje = 'No se pudo iniciar sesión con Google';

      if (e.code == 'account-exists-with-different-credential') {
        mensaje =
            'Ese correo ya está registrado con otro método de inicio de sesión';
      } else if (e.code == 'network-request-failed') {
        mensaje = 'No hay conexión a internet';
      } else if (e.code == 'invalid-credential') {
        mensaje = 'La credencial de Google no es válida';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al iniciar sesión con Google'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          cargandoGoogle = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logok.png', //ruta de imagen
                        width: 180,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aprende programación explorando el universo del código',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF475467), fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD7DFEE)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFD),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFD7DFEE)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginPage(),
                                      ),
                                    );
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: Text(
                                        'Iniciar Sesión',
                                        style: TextStyle(
                                          color: Color(0xFF475467),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0E2A52),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Registrarse',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _tituloCampo(
                                icon: Icons.person_outline,
                                texto: 'Nombre',
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: nombreController,
                                style: const TextStyle(
                                  color: Color(0xFF101828),
                                ),
                                decoration: _inputDecoration('Tu nombre'),
                                validator: validarNombre,
                              ),
                              const SizedBox(height: 16),
                              _tituloCampo(
                                icon: Icons.person_outline,
                                texto: 'Apellido',
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: apellidoController,
                                style: const TextStyle(
                                  color: Color(0xFF101828),
                                ),
                                decoration: _inputDecoration('Tu apellido'),
                                validator: validarApellido,
                              ),
                              const SizedBox(height: 16),
                              _tituloCampo(
                                icon: Icons.mail_outline,
                                texto: 'Correo electrónico',
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: correoController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  color: Color(0xFF101828),
                                ),
                                decoration: _inputDecoration('tu@email.com'),
                                validator: validarCorreo,
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: continuarRegistro,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0E2A52),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'CONTINUAR',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: const [
                            Expanded(child: Divider(color: Color(0xFFD7DFEE))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'o continúa con',
                                style: TextStyle(
                                  color: Color(0xFF667085),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Color(0xFFD7DFEE))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _botonSocial(
                          icon: Icons.g_mobiledata,
                          texto: 'Google',
                          onTap: iniciarConGoogle,
                          cargando: cargandoGoogle,
                        ),
                        const SizedBox(height: 12),
                        _botonSocial(
                          icon: Icons.code,
                          texto: 'GitHub',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const WelcomePage()),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Volver al inicio',
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

  Widget _tituloCampo({required IconData icon, required String texto}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0E2A52), size: 18),
        const SizedBox(width: 8),
        Text(
          texto,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _botonSocial({
    required IconData icon,
    required String texto,
    required VoidCallback onTap,
    bool cargando = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: cargando ? null : onTap,
        icon:
            cargando
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0E2A52),
                  ),
                )
                : Icon(icon, color: const Color(0xFF0E2A52), size: 20),
        label: Text(
          cargando ? 'Conectando...' : texto,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD7DFEE)),
          backgroundColor: const Color(0xFFFFFFFF),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
      fillColor: const Color(0xFFF8FAFD),
      suffixIcon: suffixIcon,
      errorStyle: const TextStyle(color: Colors.redAccent),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD7DFEE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0E2A52), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }
}
