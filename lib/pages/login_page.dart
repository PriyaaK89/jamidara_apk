import 'package:flutter/material.dart';
import '../services/api_service.dart';
import "../routes/app_routes.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'main_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

void _login() async {
  if (_formKey.currentState!.validate()) {
    print('Form validated. Attempting login with:');
    print('Email: ${_emailController.text.trim()}');
    print('Password: ${_passwordController.text.trim()}');

    try {
      final response = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      print('Login API Response: $response');

      // Check token instead of success
if (response['token'] != null) {
   ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Login Successful')),
  );

  final token = response['token'];
  final employeeId = response['user']['id'];

  //  SAVE SESSION
final service = FlutterBackgroundService();
if (await service.isRunning()) {
  service.invoke("stopService");
}

//  CLEAR old session completely
final prefs = await SharedPreferences.getInstance();
await prefs.clear();

//  SAVE new session
await prefs.setString('token', token);
await prefs.setInt('employee_id', employeeId);

if (response['token'] != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Login Successful')),
  );

  final token = response['token'];
  final employeeId = response['user']['id'];

  final service = FlutterBackgroundService();
  if (await service.isRunning()) {
    service.invoke("stopService");
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await prefs.setString('token', token);
  await prefs.setInt('employee_id', employeeId);

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => MainScreen(
        employeeId: employeeId,
        token: token,
      ),
    ),
  );
}
}
else {
        print('Login failed, response: $response');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Login failed')),
        );
      }
    } catch (e, stackTrace) {
      print('Login error: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  } else {
    print('Form validation failed');
  }
}

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1E4D3B),
            Color(0xFF2F614D),
            Color(0xFF3F7A61),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [

                // ===== LOGO =====
                Image.asset(
                  'assets/images/jsc_logo.png',
                  height: 90,
                ),

                const SizedBox(height: 40),

                // ===== LOGIN CARD =====
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
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

                        // ===== EMAIL FIELD =====
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 18),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(15),
                              borderSide: BorderSide.none,
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

                        // ===== PASSWORD FIELD =====
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 18),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(15),
                              borderSide: BorderSide.none,
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

                        // ===== LOGIN BUTTON =====
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF1E4D3B),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
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

                const SizedBox(height: 25),

                const Text(
                  "Let’s grow together 🌱",
                  style: TextStyle(
                    color: Colors.white70,
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
}