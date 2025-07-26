import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:finalapp/screens/signup_screen.dart';
import 'package:finalapp/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              // Logo
              _buildLogo(),
              const SizedBox(height: 40),
              // Login Text
              const Text(
                'Log In',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              // Email/Username Field
              _buildTextField(
                controller: _emailController,
                hintText: 'Enter email or username',
                obscureText: false,
              ),
              const SizedBox(height: 15),
              // Password Field
              _buildTextField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 15),
              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }
                    
                    setState(() {
                      _isLoading = true;
                    });
                    
                    try {
                      if (kDebugMode) debugPrint('Attempting login with email: ${_emailController.text.trim()}');
                      
                      final credential = await FirebaseService.signInWithEmailAndPasswordAndInit(
                        _emailController.text.trim(),
                        _passwordController.text,
                      );
                      
                      if (kDebugMode) debugPrint('Login successful for user: ${credential.user?.uid}');
                    } on FirebaseAuthException catch (e) {
                      if (kDebugMode) debugPrint('Firebase auth error: ${e.code} - ${e.message}');
                      String message = 'Login failed';
                      switch (e.code) {
                        case 'user-not-found':
                          message = 'No user found with this email';
                          break;
                        case 'wrong-password':
                          message = 'Wrong password';
                          break;
                        case 'invalid-email':
                          message = 'Invalid email address';
                          break;
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      }
                    } catch (e) {
                      if (kDebugMode) debugPrint('General login error: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Login failed. Please try again.')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Log In'),
                ),
              ),
              const SizedBox(height: 20),
              // OR divider
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('OR'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              // Social Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(
                    onPressed: () {},
                    icon: 'G',
                    color: Colors.white,
                  ),
                  const SizedBox(width: 20),
                  _buildSocialButton(
                    onPressed: () {},
                    icon: 'f',
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't you have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    child: const Text('Sign up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Icon(
          Icons.layers,
          size: 60,
          color: Colors.indigo[900],
        ),
        const SizedBox(height: 10),
        Text(
          'CareSync',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.indigo[900],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required String icon,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            icon,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: icon == 'G' ? Colors.red : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
