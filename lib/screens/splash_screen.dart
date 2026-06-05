import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Animaciones para la esfera
  late Animation<double> _sphereDrop1; 
  late Animation<double> _sphereBounceUp; 
  late Animation<double> _sphereDrop2; 
  late Animation<double> _sphereScale; 
  late Animation<double> _sphereFadeOut; 

  // Animaciones para el Logo y Texto
  late Animation<double> _logoScale;
  late Animation<double> _contentFadeIn;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 3000),
    );

    // --- COREOGRAFÍA DE LA ESFERA ---
    
    // 1. Primera caída 
    _sphereDrop1 = Tween<double>(begin: -2.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.25, curve: Curves.easeInQuad)),
    );

    // 2. Rebote hacia arriba 
    _sphereBounceUp = Tween<double>(begin: 0.0, end: -0.8).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.25, 0.45, curve: Curves.easeOutQuad)),
    );

    // 3. Segunda caída 
    _sphereDrop2 = Tween<double>(begin: -0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.45, 0.60, curve: Curves.easeInQuad)),
    );

    // 4. EXPANSIÓN MASIVA (Onda de choque) 
    _sphereScale = Tween<double>(begin: 1.0, end: 40.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.60, 0.90, curve: Curves.easeOutCubic)),
    );

    // 5. Desaparición de la esfera 
    _sphereFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.65, 0.90, curve: Curves.easeOut)),
    );

    // --- COREOGRAFÍA DEL LOGO Y TEXTO ---

    // 6. El logo crece 
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.60, 0.85, curve: Curves.elasticOut)),
    );

    // 7. Fade In general 
    _contentFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.60, 0.80, curve: Curves.easeIn)),
    );

    // 8. El texto se desliza hacia arriba
    _textSlide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.65, 0.90, curve: Curves.easeOutCubic)),
    );

    _controller.forward();

    // Temporizador
    Timer(const Duration(milliseconds: 4000), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = const Offset(0.0, 1.0);
            var end = Offset.zero;
            var curve = Curves.easeInOutQuart;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getSpherePosition() {
    if (_controller.value <= 0.25) return _sphereDrop1.value;
    if (_controller.value <= 0.45) return _sphereBounceUp.value;
    if (_controller.value <= 0.60) return _sphereDrop2.value;
    return 0.0; 
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          // --- CAMBIO: Fondo Negro Puro ---
          backgroundColor: Colors.black, 
          body: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. LA ESFERA 
                FractionalTranslation(
                  translation: Offset(0, _getSpherePosition()),
                  child: Transform.scale(
                    scale: _sphereScale.value, 
                    child: Opacity(
                      opacity: _sphereFadeOut.value,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          // --- CAMBIO: Degradado Morado-Rosa ---
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF8A2BE2), // Morado
                              Color(0xFFFF69B4), // Rosa
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                             BoxShadow(
                               // Sombra a juego con el rosa
                               color: const Color(0xFFFF69B4).withOpacity(0.6), 
                               blurRadius: 20,
                               spreadRadius: 2,
                             )
                          ]
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. EL LOGO Y EL TEXTO 
                Opacity(
                  opacity: _contentFadeIn.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // LOGO ANIMADO
                      ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(35),
                            image: const DecorationImage(
                              image: AssetImage('assets/logo.png'), 
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // TEXTO ANIMADO
                      SlideTransition(
                        position: _textSlide,
                        child: const Text(
                          'EduSmart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}