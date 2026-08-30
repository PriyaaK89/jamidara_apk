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

class LoginPage extends StatefulWidget {
  final String? message;
  const LoginPage({super.key, this.message});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // ===== Purely visual: entrance + ambient glow (same feel as WelcomePage) =====
  late final AnimationController _entranceController;
  late final AnimationController _glowController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _cardFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();

    // Slow ambient glow drift behind the logo — same idea as WelcomePage,
    // kept subtle so it doesn't distract from the form.
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ===== BACKGROUND GRADIENT — same palette as WelcomePage =====
          Container(
            width: double.infinity,
            height: double.infinity,
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

          // ===== SOFT DRIFTING GLOW (top-left) =====
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final offset = _glowController.value * 18;
              return Positioned(
                top: -100 + offset,
                left: -50 - offset,
                child: child!,
              );
            },
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // ===== SOFT DRIFTING GLOW (bottom-right, warm gold tint) =====
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final offset = (1 - _glowController.value) * 20;
              return Positioned(
                bottom: -110 + offset,
                right: -60 - offset,
                child: child!,
              );
            },
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF2C14E).withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    // ===== LOGO — fade/scale-in + gentle breathing glow =====
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            final glowStrength =
                                0.12 + (_glowController.value * 0.08);
                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(glowStrength),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                              child: child,
                            );
                          },
                          child: Image.asset(
                            'assets/images/jsc_logo.png',
                            height: 90,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),

                    // ===== LOGIN CARD — fade + slide-in =====
                    FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const Text(
                                  "Welcome Back",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E4D3B),
                                  ),
                                ),
                                const SizedBox(height: 25),

                                // EMAIL FIELD
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  cursorColor: const Color(0xFF1E4D3B),
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    prefixIcon: const Icon(
                                      Icons.email,
                                      color: Color(0xFF2F614D),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3F7A61),
                                        width: 1.5,
                                      ),
                                    ),
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

                                const SizedBox(height: 20),

                                // PASSWORD FIELD
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  cursorColor: const Color(0xFF1E4D3B),
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock,
                                      color: Color(0xFF2F614D),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3F7A61),
                                        width: 1.5,
                                      ),
                                    ),
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

                                const SizedBox(height: 30),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E4D3B),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 6,
                                      shadowColor: const Color(0xFF3F7A61)
                                          .withOpacity(0.5),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      "Let’s grow together 🌱",
                      style: TextStyle(color: Colors.white70),
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