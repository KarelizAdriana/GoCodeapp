import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/google_auth_service.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool cargandoGoogle = false;

  Future<void> iniciarConGoogle() async {
    if (cargandoGoogle) return;

    setState(() {
      cargandoGoogle = true;
    });

    try {
      final credencialUsuario = await GoogleAuthService.signInWithGoogle();

      if (credencialUsuario == null) {
        return;
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      var mensaje = 'No se pudo iniciar sesión con Google';

      if (e.code == 'account-exists-with-different-credential') {
        mensaje =
            'Ese correo ya estuvo registrado con otro método de inicio de sesión';
      } else if (e.code == 'network-request-failed') {
        mensaje = 'No hay conexicción a internet';
      } else if (e.code == 'invalid-credential') {
        mensaje = 'La credencial de Google no es válida';
      }

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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 410),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    '¡Hola, Futuro Programador!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 10),
                  const Text(
                    'Aprende programación explorando el universo del código',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF475467),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginPage(),
                                      ),
                                    );
                                  },
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
                              ),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    Navigator.push(
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
                        const Icon(
                          Icons.rocket_launch_rounded,
                          color: Color(0xFF0E2A52),
                          size: 46,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Comienza tu aventura en GoCode',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF101828),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Inicia sesión o crea tu cuenta para explorar el universo del código.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF475467),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 22),
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
                          icono: Icons.g_mobiledata,
                          texto: 'Continuar con Google',
                          onTap: iniciarConGoogle,
                          cargando: cargandoGoogle,
                        ),
                        const SizedBox(height: 12),
                        _botonSocial(
                          icono: Icons.code,
                          texto: 'Continuar con GitHub',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Términos    Privacidad',
                    style: TextStyle(color: Color(0xFF667085), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _botonSocial({
    required IconData icono,
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
                : Icon(icono, color: const Color(0xFF0E2A52), size: 22),
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
}
