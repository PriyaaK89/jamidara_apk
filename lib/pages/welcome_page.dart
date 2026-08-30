import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  // ================= ANIMATION CONTROLLERS =================
  late final AnimationController _entranceController;
  late final AnimationController _glowController;
  late final AnimationController _pulseController;
  late final AnimationController _particleController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _growthSlide;
  late final Animation<double> _growthFade;

  bool _isRequestingPermissions = false;

  // ===== Seed -> Plant growth stages (cycles on a timer) =====
  static const List<String> _growthStages = ['🌰', '🌱', '🌿', '🪴'];
  int _growthIndex = 0;
  Timer? _growthTimer;

  // ===== Wandering background particles =====
  final List<_Particle> _particles = const [
    _Particle(baseX: 0.12, baseY: 0.18, radius: 5, ampX: 22, ampY: 16, freqX: 1, freqY: 2, phase: 0.0, isGold: false),
    _Particle(baseX: 0.85, baseY: 0.14, radius: 7, ampX: 18, ampY: 24, freqX: 2, freqY: 1, phase: 1.1, isGold: true),
    _Particle(baseX: 0.25, baseY: 0.42, radius: 4, ampX: 26, ampY: 20, freqX: 1, freqY: 1, phase: 2.4, isGold: false),
    _Particle(baseX: 0.78, baseY: 0.55, radius: 6, ampX: 20, ampY: 18, freqX: 2, freqY: 3, phase: 0.6, isGold: false),
    _Particle(baseX: 0.55, baseY: 0.28, radius: 3.5, ampX: 16, ampY: 22, freqX: 3, freqY: 2, phase: 3.2, isGold: true),
    _Particle(baseX: 0.15, baseY: 0.72, radius: 6, ampX: 24, ampY: 14, freqX: 1, freqY: 2, phase: 4.0, isGold: false),
    _Particle(baseX: 0.9, baseY: 0.78, radius: 5, ampX: 18, ampY: 20, freqX: 2, freqY: 1, phase: 1.8, isGold: false),
    _Particle(baseX: 0.45, baseY: 0.85, radius: 4.5, ampX: 20, ampY: 16, freqX: 1, freqY: 3, phase: 2.9, isGold: true),
  ];

  @override
  void initState() {
    super.initState();

    // Overall entrance choreography
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _taglineFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _growthFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
    );
    _growthSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _buttonFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();

    // Ambient glow drifting behind the logo
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // Gentle pulse on the "Get Started" button so the page feels alive
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Slow, seamless loop driving the wandering particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    // Cycle the seed -> sprout -> leaf -> plant stages
    _growthTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted) return;
      setState(() {
        _growthIndex = (_growthIndex + 1) % _growthStages.length;
      });
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _growthTimer?.cancel();
    super.dispose();
  }

  // ================= PERMISSION FUNCTION =================
  Future<bool> _requestPermissions(BuildContext context) async {
    bool allGranted = true;

    Map<Permission, String> permissions = {
      Permission.camera: 'Camera',
      Permission.phone: 'Phone',
      Permission.notification: 'Notification',
      Permission.contacts: 'Contacts',
    };

    // Battery optimization
    if (!await Permission.ignoreBatteryOptimizations.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }

    for (var entry in permissions.entries) {
      PermissionStatus status = await entry.key.status;

      if (!status.isGranted) {
        status = await entry.key.request();
      }

      if (!status.isGranted) {
        allGranted = false;

        if (status.isPermanentlyDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${entry.value} permission is permanently denied. Please enable it from settings.',
              ),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: openAppSettings,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${entry.value} permission is required')),
          );
        }
      }
    }

    // Check GPS service first
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable GPS to continue")),
      );
      await Geolocator.openLocationSettings();
      return false;
    }

    // Request foreground location first
    PermissionStatus locationWhenInUse =
        await Permission.locationWhenInUse.status;
    if (!locationWhenInUse.isGranted) {
      locationWhenInUse = await Permission.locationWhenInUse.request();
    }

    if (!locationWhenInUse.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission is required")),
      );
      return false;
    }

    // Then request background location
    PermissionStatus locationAlways = await Permission.locationAlways.status;
    if (!locationAlways.isGranted) {
      locationAlways = await Permission.locationAlways.request();
    }

    if (!locationAlways.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please allow background location ('Allow all the time') in app settings",
          ),
          action: SnackBarAction(
            label: "Settings",
            onPressed: openAppSettings,
          ),
        ),
      );
      return false;
    }

    return allGranted;
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ===== BACKGROUND GRADIENT (slightly richer, still green) =====
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2E22),
                  Color(0xFF163E2F),
                  Color(0xFF1E4D3B),
                  Color(0xFF347056),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ===== ANIMATED SOFT CIRCLE GLOW (top-left) =====
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final offset = _glowController.value * 20;
              return Positioned(
                top: -100 + offset,
                left: -50 - offset,
                child: child!,
              );
            },
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // ===== SECOND SOFT GLOW (bottom-right) for depth, warm gold tint =====
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final offset = (1 - _glowController.value) * 25;
              return Positioned(
                bottom: -120 + offset,
                right: -60 - offset,
                child: child!,
              );
            },
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF2C14E).withOpacity(0.05),
              ),
            ),
          ),

          // ===== FAINT DECORATIVE RING for subtle texture =====
          Positioned(
            top: 60,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.06),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // ===== WANDERING PARTICLES =====
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ParticlePainter(
                      particles: _particles,
                      t: _particleController.value,
                      canvasSize: size,
                    ),
                  );
                },
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ===== LOGO with fade/scale-in + breathing glow =====
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final glowStrength =
                                0.15 + (_pulseController.value * 0.1);
                            return Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(glowStrength),
                                    Colors.white.withOpacity(0.02),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: child,
                            );
                          },
                          child: Image.asset(
                            'assets/images/jsc_logo.png',
                            height: 120,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // ===== TAGLINE with slide + fade-in =====
                    SlideTransition(
                      position: _taglineSlide,
                      child: FadeTransition(
                        opacity: _taglineFade,
                        child: const Text(
                          "Empowering Agriculture with Innovation",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ===== SEED -> PLANT GROWTH BADGE =====
                    SlideTransition(
                      position: _growthSlide,
                      child: FadeTransition(
                        opacity: _growthFade,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 450),
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  _growthStages[_growthIndex],
                                  key: ValueKey<int>(_growthIndex),
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Growing with every season",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 38),

                    // ===== PREMIUM BUTTON with slide-in + gentle pulse =====
                    SlideTransition(
                      position: _buttonSlide,
                      child: FadeTransition(
                        opacity: _buttonFade,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final scale =
                                1.0 + (_pulseController.value * 0.015);
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isRequestingPermissions
                                  ? null
                                  : () async {
                                      setState(() {
                                        _isRequestingPermissions = true;
                                      });

                                      bool granted =
                                          await _requestPermissions(context);

                                      if (!mounted) return;

                                      setState(() {
                                        _isRequestingPermissions = false;
                                      });

                                      if (granted) {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const LoginPage()),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                disabledBackgroundColor:
                                    Colors.white.withOpacity(0.7),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                elevation: 10,
                                shadowColor: Colors.black45,
                              ),
                              child: _isRequestingPermissions
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Color(0xFF1E4D3B),
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      "Get Started",
                                      style: TextStyle(
                                        color: Color(0xFF1E4D3B),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ===== FOOTER TEXT with fade + slide-in =====
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textFade,
                        child: const Text(
                          "Let’s grow together 🌱",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= PARTICLE DATA + PAINTER =================
// Small wandering "ball" particles drifting in gentle loops behind the
// content. freqX/freqY are kept as whole numbers so the sine motion
// completes full cycles and loops seamlessly with the controller.
class _Particle {
  final double baseX; // fraction of screen width, 0..1
  final double baseY; // fraction of screen height, 0..1
  final double radius;
  final double ampX; // horizontal wander distance in px
  final double ampY; // vertical wander distance in px
  final double freqX;
  final double freqY;
  final double phase;
  final bool isGold;

  const _Particle({
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.ampX,
    required this.ampY,
    required this.freqX,
    required this.freqY,
    required this.phase,
    required this.isGold,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0..1 looping value
  final Size canvasSize;

  _ParticlePainter({
    required this.particles,
    required this.t,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dx = math.sin((t * 2 * math.pi * p.freqX) + p.phase) * p.ampX;
      final dy = math.cos((t * 2 * math.pi * p.freqY) + p.phase) * p.ampY;

      final center = Offset(
        (p.baseX * canvasSize.width) + dx,
        (p.baseY * canvasSize.height) + dy,
      );

      final color = p.isGold
          ? const Color(0xFFF2C14E).withOpacity(0.35)
          : Colors.white.withOpacity(0.28);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawCircle(center, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.t != t;
  }
}