import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'main_screen.dart';
import 'package:another_flushbar/flushbar.dart';
import '../services/storage_service.dart';
import "../layout/app_router.dart";
import '../routes/app_routes.dart';
import '../services/location_service.dart';

// ============================================================
// PALETTE — mirrors the CSS custom properties used in login.css
// ============================================================
class _Palette {
  static const greenDeep = Color(0xFF0F2E22);
  static const greenDeep2 = Color(0xFF163E2F);
  static const greenMid = Color(0xFF1E4D3B);
  static const greenFresh = Color(0xFF1F8F56);
  static const greenLight = Color(0xFF347056);
  static const mustard = Color(0xFFF2C14E);
  static const gold400 = Color(0xFFF5C863);
  static const slate = Color(0xFF5C6B60);
  static const slateLight = Color(0xFF8A968D);
  static const line = Color(0xFFE1E7E2);
  static const lineSoft = Color(0xFFEDF1EE);
  static const cream200 = Color(0xFFF6F1E1);
  static const green050 = Color(0xFFF0FAF3);
  static const danger = Color(0xFFC0392B);
  static const dangerBg = Color(0xFFFBEAE8);
  static const info = Color(0xFF3574CE);
  static const purple = Color(0xFF7A55CE);
}

class LoginPage extends StatefulWidget {
  final String? message;
  const LoginPage({super.key, this.message});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  // ================= ORIGINAL STATE / LOGIC (unchanged) =================
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    final String? savedEmail = prefs.getString('saved_email');
    final String? savedPassword = await _secureStorage.read(
      key: 'saved_password',
    );

    if (!mounted) return;

    setState(() {
      _emailController.text = savedEmail ?? '';
      _passwordController.text = savedPassword ?? '';
    });

    debugPrint('Saved email: $savedEmail');
    debugPrint('Saved password loaded: ${savedPassword != null}');
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }
    bool locationOk = await LocationService.checkLocation(context);
    if (!locationOk) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      debugPrint('Login API Response: $response');

      if (!mounted) return;

      if (response['token'] != null) {
        final token = response['token'];
        final employeeId = response['user']['id'];

        final prefs = await SharedPreferences.getInstance();

        // login session save
        await prefs.setString('token', token);
        await prefs.setInt('employee_id', employeeId);
        await prefs.reload();
        print("LOGIN SAVED → ID: $employeeId, TOKEN: $token");
        // last entered credentials save
        await prefs.setString('saved_email', _emailController.text.trim());
        await _secureStorage.write(
          key: 'saved_password',
          value: _passwordController.text.trim(),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.appRouter,
          (route) => false,
          arguments: {"employeeId": employeeId, "token": token},
        );
        await StorageService.saveUser(token, employeeId);

        await StorageService.saveFullUser(
          token,
          employeeId,
          response['user'],
        );
        await Flushbar(
          message: "Login Successful",
          duration: const Duration(seconds: 1),
          flushbarPosition: FlushbarPosition.BOTTOM,
          backgroundColor: const Color.fromARGB(255, 63, 145, 66),
          margin: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(8),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        ).show(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Login failed')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Login error: $e');
      debugPrint('Stack trace: $stackTrace');
      Flushbar(
        message: "Something went wrong",
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.BOTTOM,
        backgroundColor: Colors.red,
      ).show(context);
      if (!mounted) return;

      Flushbar(
        message: "Error: $e",
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        backgroundColor: Colors.red,
      ).show(context);
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // Decorative-only toast, mirrors showToastLogin() in login.js.
  // Does not touch auth logic — purely a design-parity affordance.
  void _showInfoToast(String message) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: _Palette.greenDeep2,
      margin: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(8),
      icon: const Icon(Icons.info_outline, color: Colors.white),
    ).show(context);
  }

  // ================= ANIMATION CONTROLLERS (design only) =================

  // Card entrance (fade + slide) — mirrors the "sheetUp" cubic-bezier curve
  // from the CSS (700ms, 150ms delay).
  late final AnimationController _entranceController;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _brandFade;

  // Ambient background glow drift (6s reverse loop).
  late final AnimationController _glowController;

  // Ken Burns slow zoom/pan on the backdrop image (22s alternate loop).
  late final AnimationController _kenBurnsController;

  // Three independently-timed floating leaf particles on the backdrop
  // (9s / 11s / 7.5s) — mirrors .leaf1/.leaf2/.leaf3 in login.css.
  late final AnimationController _leaf1Controller;
  late final AnimationController _leaf2Controller;
  late final AnimationController _leaf3Controller;

  // Button shimmer sweep (3.2s loop).
  late final AnimationController _shimmerController;

  // Logo badge pulse (3.2s loop) — mirrors badgePulse in login.css.
  late final AnimationController _badgeController;

  // Splash / intro sequence (~3.8s total, then removed).
  late final AnimationController _splashController;
  late final AnimationController _ring1Controller;
  late final AnimationController _ring2Controller;
  late final AnimationController _ring3Controller;
  // Glow pulse behind the splash logo — mirrors .splash-glow (glowPulse,
  // 2.4s loop, starts ~1s into the splash).
  late final AnimationController _splashGlowController;
  bool _showSplash = true;

  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _brandFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _kenBurnsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat(reverse: true);

    _leaf1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
    _leaf2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    );
    _leaf3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7500),
    )..repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _leaf2Controller.repeat(reverse: true);
    });

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    // ---- Splash sequence ----
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );
    _ring1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _ring2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _ring3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _ring1Controller.repeat();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _ring2Controller.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) _ring3Controller.repeat();
    });

    _splashGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _showSplash) {
        _splashGlowController.repeat(reverse: true);
      }
    });

    _splashController.forward().whenComplete(() {
      if (mounted) {
        setState(() => _showSplash = false);
        _splashGlowController.stop();
        _entranceController.forward();
      }
    });

    _loadSavedCredentials();
    if (widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Flushbar(
          message: widget.message!,
          duration: const Duration(seconds: 2),
          flushbarPosition: FlushbarPosition.TOP,
          backgroundColor: Colors.green,
          margin: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(8),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        ).show(context);
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    _glowController.dispose();
    _kenBurnsController.dispose();
    _leaf1Controller.dispose();
    _leaf2Controller.dispose();
    _leaf3Controller.dispose();
    _shimmerController.dispose();
    _badgeController.dispose();
    _splashController.dispose();
    _ring1Controller.dispose();
    _ring2Controller.dispose();
    _ring3Controller.dispose();
    _splashGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 40, 24, 28),
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _brandFade,
                      child: _buildTopBrand(),
                    ),
                    const SizedBox(height: 22),
                    FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: _buildLoginSheet(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showSplash) _buildSplash(),
        ],
      ),
    );
  }

  // ============================================================
  // BACKDROP — bg image (Ken Burns) + dark overlay + jaali dots + leaves
  // ============================================================
  Widget _buildBackdrop() {
    return Positioned.fill(
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _kenBurnsController,
            builder: (context, child) {
              final t = _kenBurnsController.value; // 0 -> 1
              final scale = 1.0 + (0.12 * t);
              final dx = -1.5 * t; // percent-ish drift
              final dy = -2.0 * t;
              return Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: Image.asset(
              'assets/images/login_bg.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _Palette.greenDeep,
                      _Palette.greenDeep2,
                      _Palette.greenMid,
                      _Palette.greenLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          // overlay gradient (matches the two stacked CSS gradients)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _Palette.greenDeep.withOpacity(0.55),
                  _Palette.greenDeep.withOpacity(0.35),
                  const Color(0xFF05160E).withOpacity(0.55),
                  const Color(0xFF04100A).withOpacity(0.93),
                ],
                stops: const [0.0, 0.30, 0.62, 1.0],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _Palette.greenDeep2.withOpacity(0.35),
                  _Palette.mustard.withOpacity(0.10),
                ],
              ),
            ),
          ),
          // jaali dot pattern
          Opacity(
            opacity: 0.10,
            child: CustomPaint(
              painter: _JaaliPainter(),
              child: const SizedBox.expand(),
            ),
          ),
          // floating leaf particles
          _floatingLeaf(
            controller: _leaf1Controller,
            top: 0.14,
            left: 0.08,
            size: 22,
            color: _Palette.mustard,
          ),
          _floatingLeaf(
            controller: _leaf2Controller,
            top: 0.22,
            right: 0.10,
            size: 16,
            color: _Palette.greenFresh,
            reverse: true,
          ),
          _floatingLeaf(
            controller: _leaf3Controller,
            top: 0.09,
            left: 0.55,
            size: 14,
            color: _Palette.mustard,
          ),
        ],
      ),
    );
  }

  Widget _floatingLeaf({
    required AnimationController controller,
    double? top,
    double? left,
    double? right,
    required double size,
    required Color color,
    bool reverse = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final v = controller.value;
            final wave = math.sin(v * math.pi); // 0 -> 1 -> 0
            final dy = 16 * wave * (reverse ? -1 : 1);
            final rot = (12 * wave) * (math.pi / 180);
            return Positioned(
              top: top != null ? top * constraints.maxHeight + dy : null,
              left: left != null ? left * constraints.maxWidth : null,
              right: right != null ? right * constraints.maxWidth : null,
              child: Opacity(
                opacity: 0.55,
                child: Transform.rotate(angle: rot, child: child),
              ),
            );
          },
          child: _leafIcon(size: size, color: color),
        );
      },
    );
  }

  // ============================================================
  // TOP BRAND — logo badge, brand name/sub, CRM title, tagline
  // ============================================================
  Widget _buildTopBrand() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _badgeController,
          builder: (context, child) {
            final v = _badgeController.value;
            final blur = 26.0 + (4.0 * v);
            final spread = 3.0 + (4.0 * v);
            final ringOpacity = 0.55 - (0.27 * v);
            return Container(
              width: 94,
              height: 94,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: blur,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: _Palette.mustard.withOpacity(ringOpacity),
                    blurRadius: 0,
                    spreadRadius: spread,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Image.asset(
            'assets/images/jamidara_logo_transparent.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.eco,
              color: _Palette.greenMid,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'JAMIDARA SEEDS CORPORATION',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Sowing Trust. Growing Together.',
          style: TextStyle(
            color: Color(0xFFEAF4EC),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            children: [
              TextSpan(text: 'Jamidara '),
              TextSpan(
                text: 'CRM',
                style: TextStyle(color: _Palette.mustard),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Sales', style: TextStyle(color: Color(0xFFEAF4EC), fontSize: 12.5, fontWeight: FontWeight.w600)),
            _TagDot(),
            Text('Field', style: TextStyle(color: Color(0xFFEAF4EC), fontSize: 12.5, fontWeight: FontWeight.w600)),
            _TagDot(),
            Text('Performance', style: TextStyle(color: Color(0xFFEAF4EC), fontSize: 12.5, fontWeight: FontWeight.w600)),
            _TagDot(),
            Text('Growth', style: TextStyle(color: Color(0xFFEAF4EC), fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // LOGIN SHEET — white rounded card with the original form logic
  // ============================================================
  Widget _buildLoginSheet() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 50,
            offset: const Offset(0, -20),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _Palette.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Text(
              'Welcome Back 👋',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF173726),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your field activity, sales, attendance and performance from one place.',
              style: TextStyle(
                fontSize: 12.5,
                color: _Palette.slate,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            _LabeledField(
              label: 'Email',
              icon: Icons.person_outline,
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                cursorColor: _Palette.greenMid,
                autocorrect: false,
                style: const TextStyle(fontSize: 14.5, color: Color(0xFF1C2A22)),
                decoration: const InputDecoration(
                  hintText: 'Email',
                  border: InputBorder.none,
                  isDense: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),

            _LabeledField(
              label: 'Password',
              icon: Icons.lock_outline,
              trailing: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: _Palette.slateLight,
                  size: 19,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              child: TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                cursorColor: _Palette.greenMid,
                style: const TextStyle(fontSize: 14.5, color: Color(0xFF1C2A22)),
                decoration: const InputDecoration(
                  hintText: 'Password',
                  border: InputBorder.none,
                  isDense: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Row(
                    children: [
                      Container(
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: _rememberMe
                              ? const LinearGradient(colors: [
                                  _Palette.greenFresh,
                                  _Palette.greenDeep2,
                                ])
                              : null,
                          border: _rememberMe
                              ? null
                              : Border.all(color: _Palette.line, width: 1.6),
                        ),
                        child: _rememberMe
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Remember Me',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF3B463D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showInfoToast(
                    'Contact your administrator to reset your password.',
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _Palette.greenDeep2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildLoginButton(),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: Divider(color: _Palette.line)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'OR CONTINUE WITH',
                    style: TextStyle(
                      fontSize: 11,
                      color: _Palette.slateLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: _Palette.line)),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _AltButton(
                    icon: Icons.smartphone,
                    label: 'Login with OTP',
                    iconColor: _Palette.info,
                    onTap: () => _showInfoToast('OTP login coming soon'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AltButton(
                    icon: Icons.fingerprint,
                    label: 'Biometric',
                    iconColor: _Palette.purple,
                    onTap: () => _showInfoToast('Biometric login coming soon'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Center(
              child: Text.rich(
                TextSpan(
                  text: 'Need help? ',
                  style: TextStyle(fontSize: 12, color: _Palette.slate),
                  children: [
                    TextSpan(
                      text: 'Contact Admin',
                      style: TextStyle(
                        color: _Palette.greenDeep2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _isLoading ? null : _login,
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_Palette.greenDeep, _Palette.greenFresh],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x590E2F21),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                // shimmer sweep
                if (!_isLoading)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final w = constraints.maxWidth;
                              final x = -w * 0.6 +
                                  (_shimmerController.value * w * 1.8);
                              return Stack(
                                children: [
                                  Positioned(
                                    left: x,
                                    top: 0,
                                    bottom: 0,
                                    width: w * 0.4,
                                    child: Transform(
                                      transform: Matrix4.skewX(-0.35),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0),
                                              Colors.white.withOpacity(0.35),
                                              Colors.white.withOpacity(0),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.login, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: Colors.white,
                                ),
                              ),
                            ],
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

  // ============================================================
  // SPLASH / INTRO — logo pop + glow, rings, leaves, title, loader bar
  // ============================================================
  Widget _buildSplash() {
    return AnimatedBuilder(
      animation: _splashController,
      builder: (context, child) {
        final t = _splashController.value; // 0 -> 1 over 3800ms
        final exitT = ((t - (3200 / 3800)) / (600 / 3800)).clamp(0.0, 1.0);
        return Opacity(
          opacity: 1 - exitT,
          child: IgnorePointer(
            ignoring: exitT > 0,
            child: child,
          ),
        );
      },
      child: Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.4, -0.6),
              radius: 1.2,
              colors: [Color(0x5957C782), Colors.transparent],
              stops: [0.0, 0.55],
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A2A1B),
                  Color(0xFF0E3A24),
                  Color(0xFF123F28),
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // pulsing rings — 110px -> 340px, mirrors ringPulse
                _ringPulse(_ring1Controller, _Palette.greenFresh),
                _ringPulse(_ring2Controller, _Palette.mustard),
                _ringPulse(_ring3Controller, _Palette.greenFresh),

                // three drifting leaf particles — mirrors .splash-leaf
                // (leaf-a / leaf-b / leaf-c) fading + settling into place
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedBuilder(
                      animation: _splashController,
                      builder: (context, child) {
                        final ms = _splashController.value * 3800;
                        return Stack(
                          children: [
                            _splashLeaf(
                              constraints: constraints,
                              ms: ms,
                              delayMs: 300,
                              top: 0.20,
                              left: 0.16,
                              size: 26,
                              color: const Color(0xFF8EDDAE),
                              fromOffset: const Offset(-30, 10),
                              fromRotationDeg: -30,
                              toRotationDeg: 8,
                              finalOpacity: 0.55,
                            ),
                            _splashLeaf(
                              constraints: constraints,
                              ms: ms,
                              delayMs: 600,
                              top: 0.24,
                              right: 0.14,
                              size: 18,
                              color: _Palette.mustard,
                              fromOffset: const Offset(30, -10),
                              fromRotationDeg: 30,
                              toRotationDeg: -10,
                              finalOpacity: 0.55,
                            ),
                            _splashLeaf(
                              constraints: constraints,
                              ms: ms,
                              delayMs: 900,
                              bottom: 0.24,
                              left: 0.22,
                              size: 16,
                              color: const Color(0xFF8EDDAE),
                              fromOffset: const Offset(-20, 20),
                              fromRotationDeg: 20,
                              toRotationDeg: -6,
                              finalOpacity: 0.50,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: Listenable.merge(
                        [_splashController, _splashGlowController],
                      ),
                      builder: (context, child) {
                        final logoT =
                            ((_splashController.value * 3800 - 150) / 1000)
                                .clamp(0.0, 1.0);
                        final scale = Curves.easeOutBack.transform(logoT) *
                                0.6 +
                            0.4;
                        // glow pulse behind the logo, mirrors .splash-glow
                        final glowMs = _splashController.value * 3800;
                        final glowActive = glowMs >= 1000;
                        final gv = _splashGlowController.value;
                        final glowOpacity = glowActive ? 0.2 + (0.3 * gv) : 0.0;
                        final glowScale = 0.9 + (0.18 * gv);
                        return Opacity(
                          opacity: logoT.clamp(0.0, 1.0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (glowActive)
                                Transform.scale(
                                  scale: glowScale,
                                  child: Container(
                                    width: 210,
                                    height: 210,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.white.withOpacity(glowOpacity),
                                          Colors.white.withOpacity(0.0),
                                        ],
                                        stops: const [0.0, 0.65],
                                      ),
                                    ),
                                  ),
                                ),
                              Transform.scale(
                                scale: scale.clamp(0.0, 1.15),
                                child: child,
                              ),
                            ],
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 150,
                        child: Image.asset(
                          'assets/images/jamidara_logo_transparent.png',
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.eco,
                                  color: Colors.white, size: 60),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    AnimatedBuilder(
                      animation: _splashController,
                      builder: (context, child) {
                        final titleT =
                            ((_splashController.value * 3800 - 1100) / 800)
                                .clamp(0.0, 1.0);
                        return Opacity(
                          opacity: titleT,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - titleT)),
                            child: child,
                          ),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(text: 'Jamidara'),
                            TextSpan(
                              text: 'CRM',
                              style: TextStyle(color: _Palette.mustard),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedBuilder(
                      animation: _splashController,
                      builder: (context, child) {
                        final tagT =
                            ((_splashController.value * 3800 - 1350) / 800)
                                .clamp(0.0, 1.0);
                        return Opacity(
                          opacity: tagT,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - tagT)),
                            child: child,
                          ),
                        );
                      },
                      child: const Text(
                        'Sowing Trust. Growing Together.',
                        style: TextStyle(
                          color: Color(0xFFCFEBD7),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    AnimatedBuilder(
                      animation: _splashController,
                      builder: (context, child) {
                        final loaderT =
                            ((_splashController.value * 3800 - 1600) / 200)
                                .clamp(0.0, 1.0);
                        return Opacity(opacity: loaderT, child: child);
                      },
                      child: SizedBox(
                        width: 120,
                        height: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            color: Colors.white.withOpacity(0.15),
                            child: AnimatedBuilder(
                              animation: _shimmerController,
                              builder: (context, child) {
                                final x =
                                    -0.3 + (_shimmerController.value * 1.3);
                                return Align(
                                  alignment: Alignment(x * 2, 0),
                                  child: FractionallySizedBox(
                                    widthFactor: 0.3,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _Palette.mustard,
                                            _Palette.greenFresh,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One splash-intro leaf: fades in, drifts from [fromOffset] to (0,0) and
  /// rotates from [fromRotationDeg] to [toRotationDeg], settling at
  /// [finalOpacity] — mirrors the leafDrift1/2/3 keyframes in login.css.
  Widget _splashLeaf({
    required BoxConstraints constraints,
    required double ms,
    required double delayMs,
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
    required Offset fromOffset,
    required double fromRotationDeg,
    required double toRotationDeg,
    required double finalOpacity,
  }) {
    final progress = ((ms - delayMs) / 800).clamp(0.0, 1.0);
    final eased = Curves.easeOut.transform(progress);
    final opacity = progress <= 0
        ? 0.0
        : (progress < 0.3
            ? (progress / 0.3) * 0.85
            : 0.85 - ((progress - 0.3) / 0.7) * (0.85 - finalOpacity));
    final dx = fromOffset.dx * (1 - eased);
    final dy = fromOffset.dy * (1 - eased);
    final rotDeg = fromRotationDeg + (toRotationDeg - fromRotationDeg) * eased;
    final scale = 0.6 + (0.4 * eased);

    double? topPx = top != null ? top * constraints.maxHeight : null;
    double? bottomPx = bottom != null ? bottom * constraints.maxHeight : null;
    double? leftPx = left != null ? left * constraints.maxWidth : null;
    double? rightPx = right != null ? right * constraints.maxWidth : null;

    return Positioned(
      top: topPx,
      bottom: bottomPx,
      left: leftPx,
      right: rightPx,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: rotDeg * math.pi / 180,
            child: Transform.scale(
              scale: scale,
              child: _leafIcon(size: size, color: color),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ringPulse(AnimationController controller, Color color) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final v = controller.value;
        final size = 110 + (230 * v);
        final opacity = (0.9 * (1 - v)).clamp(0.0, 0.9);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(opacity * 0.9),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }

  /// Leaf glyph matching the outline path used by the SVG leaf icons in
  /// login.js/login.css (a rounded leaf silhouette rather than Material's
  /// generic eco icon), rendered with CustomPaint so the shape matches.
  Widget _leafIcon({required double size, required Color color}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LeafPainter(color: color),
    );
  }
}

// ============================================================
// SMALL SUPPORTING WIDGETS
// ============================================================

class _TagDot extends StatelessWidget {
  const _TagDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: _Palette.mustard,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _LabeledField extends StatefulWidget {
  final String label;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _LabeledField({
    required this.label,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  State<_LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<_LabeledField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: _focused ? _Palette.greenFresh : _Palette.line,
              width: _focused ? 1.5 : 1.5,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: _Palette.greenFresh.withOpacity(0.12),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: _Palette.greenLight),
              const SizedBox(width: 9),
              Expanded(
                child: Focus(
                  focusNode: _focusNode,
                  child: widget.child,
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
        Positioned(
          top: -8,
          left: 12,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _Palette.slate,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AltButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _AltButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _Palette.line, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2B3B32),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tiled dot pattern matching the CSS `.jaali` background.
class _JaaliPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.9);
    const spacing = 26.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Leaf silhouette matching the SVG path used across login.html:
// "M12 22c-5-2-7-5-7-9V5l7-3 7 3v8c0 4-2 7-7 9z" (drawn on a 24x24 grid,
// scaled to fit the requested size).
class _LeafPainter extends CustomPainter {
  final Color color;
  const _LeafPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 24;
    final scaleY = size.height / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(12 * scaleX, 22 * scaleY)
      ..cubicTo(
        7 * scaleX, 20 * scaleY,
        5 * scaleX, 17 * scaleY,
        5 * scaleX, 13 * scaleY,
      )
      ..lineTo(5 * scaleX, 5 * scaleY)
      ..lineTo(12 * scaleX, 2 * scaleY)
      ..lineTo(19 * scaleX, 5 * scaleY)
      ..lineTo(19 * scaleX, 13 * scaleY)
      ..cubicTo(
        19 * scaleX, 17 * scaleY,
        17 * scaleX, 20 * scaleY,
        12 * scaleX, 22 * scaleY,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LeafPainter oldDelegate) =>
      oldDelegate.color != color;
}