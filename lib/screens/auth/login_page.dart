import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/google_auth_service.dart';
import '../home/home_page.dart';
import 'register_page.dart';
import 'welcome_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final correoController = TextEditingController();
  final passwordController = TextEditingController();

  bool ocultarPassword = true;
  bool cargando = false;
  bool cargandoGoogle = false;

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String? validarCorreo(String? value) {
    final correo = value?.trim().toLowerCase() ?? '';

    if (correo.isEmpty) {
      return 'Escribe tu correo';
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(correo)) {
      return 'Pon un correo válido, por ejemplo: nombre@correo.com';
    }

    return null;
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

  Future<void> iniciarSesion() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa bien tu correo y tu contraseña'),
        ),
      );
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final credencial = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correoController.text.trim().toLowerCase(),
        password: passwordController.text.trim(),
      );

      final user = credencial.user;

      await user?.reload();
      final userActualizado = FirebaseAuth.instance.currentUser;

      if (userActualizado == null) {
        throw Exception('No se pudo obtener el usuario');
      }

      if (!userActualizado.emailVerified) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primero debes verificar tu correo antes de entrar'),
          ),
        );
        return;
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Ocurrió un error. Inténtalo otra vez.';

      if (e.code == 'invalid-email') {
        mensaje = 'Ese correo no se ve válido';
      } else if (e.code == 'user-not-found') {
        mensaje = 'No encontramos una cuenta con ese correo';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        mensaje = 'Correo o contraseña incorrectos';
      } else if (e.code == 'user-disabled') {
        mensaje = 'Esta cuenta fue desactivada';
      } else if (e.code == 'network-request-failed') {
        mensaje = 'No hay conexión a internet';
      } else if (e.code == 'too-many-requests') {
        mensaje = 'Demasiados intentos. Espera un momento';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrióun error inesperado')),
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
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

  Future<void> mostrarVentanaRecuperarPassword() async {
    final email = correoController.text.trim().toLowerCase();

    FocusScope.of(context).unfocus();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero escribe tu correo')),
      );
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Escribe un correo válido')));
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        final messenger = ScaffoldMessenger.of(context);

        bool cargandoEnvio = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> enviarEnlace() async {
              if (cargandoEnvio) return;

              setDialogState(() {
                cargandoEnvio = true;
              });

              try {
                final consulta =
                    await FirebaseFirestore.instance
                        .collection('users')
                        .where('correo', isEqualTo: email)
                        .limit(1)
                        .get();

                if (!mounted) return;

                if (consulta.docs.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('No encontramos una cuenta con ese correo'),
                    ),
                  );
                  return;
                }

                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: email,
                );

                if (!mounted) return;

                navigator.pop();

                await showDialog(
                  context: this.context,
                  builder: (successContext) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text(
                        'Enlace enviado',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF101828),
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Te enviamos un enlace para restablecer tu contraseña a:',
                            style: TextStyle(
                              color: Color(0xFF475467),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFD),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFD7DFEE),
                              ),
                            ),
                            child: Text(
                              email,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF101828),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Revisa tu bandeja de entrada y también spam o promociones.',
                            style: TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(successContext);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0E2A52),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'ENTENDIDO',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              } on FirebaseAuthException catch (e) {
                String mensaje =
                    'No se pudo enviar el enlace. Inténtalo otra vez.';

                if (e.code == 'invalid-email') {
                  mensaje = 'Ese correo no es válido';
                } else if (e.code == 'network-request-failed') {
                  mensaje = 'No hay conexión a internet';
                } else if (e.code == 'too-many-requests') {
                  mensaje = 'Demasiados intentos. Espera un momento';
                }

                if (!mounted) return;

                messenger.showSnackBar(SnackBar(content: Text(mensaje)));
              } catch (_) {
                if (!mounted) return;

                messenger.showSnackBar(
                  const SnackBar(content: Text('Ocurrió un error inesperado')),
                );
              } finally {
                if (mounted) {
                  setDialogState(() {
                    cargandoEnvio = false;
                  });
                }
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 390),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFD7DFEE)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Te enviaremos un enlace de recuperación al correo que escribiste en el inicio de sesión.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF475467)),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD7DFEE)),
                      ),
                      child: Text(
                        email,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF101828),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Asegúrate de que el correo esté bien escrito antes de continuar.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                cargandoEnvio
                                    ? null
                                    : () {
                                      navigator.pop();
                                    },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD7DFEE)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Color(0xFF0E2A52),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: cargandoEnvio ? null : enviarEnlace,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0E2A52),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child:
                                cargandoEnvio
                                    ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text(
                                      'ENVIAR',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
                                      'Iniciar Sesión',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterPage(),
                                      ),
                                    );
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: Text(
                                        'Registrarse',
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
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
                              const SizedBox(height: 16),
                              _tituloCampo(
                                icon: Icons.lock_outline,
                                texto: 'Contraseña',
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: passwordController,
                                obscureText: ocultarPassword,
                                style: const TextStyle(
                                  color: Color(0xFF101828),
                                ),
                                decoration: _inputDecoration(
                                  '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        ocultarPassword = !ocultarPassword;
                                      });
                                    },
                                    icon: Icon(
                                      ocultarPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF667085),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                validator: validarPassword,
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: mostrarVentanaRecuperarPassword,
                                  child: const Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(
                                      color: Color(0xFF0E2A52),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: cargando ? null : iniciarSesion,
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
                                  child:
                                      cargando
                                          ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Text(
                                            'INICIAR SESIÓN',
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
                                'o contin\u00faa con',
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
