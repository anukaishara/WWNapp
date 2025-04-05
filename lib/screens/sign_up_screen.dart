import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'otp_verification_screen.dart';
import '../services/google_auth_service.dart';
import '../services/facebook_auth_service.dart';
import 'first_login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  // Keys for SharedPreferences
  static const String _rememberedEmailKey = 'remembered_email';
  static const String _rememberedPasswordKey = 'remembered_password';
  static const String _isRememberedKey = 'is_remembered';

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_rememberedEmailKey, _emailController.text.trim());
      await prefs.setString(_rememberedPasswordKey, _passwordController.text.trim());
      await prefs.setBool(_isRememberedKey, true);
    }
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email address")),
      );
      return;
    }

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      await _saveCredentials();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OtpVerificationScreen(email: email)),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Sign up failed")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An unexpected error occurred")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);
      final user = await GoogleAuthService().signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FirstLoginScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In Failed: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    try {
      setState(() => _isLoading = true);
      final user = await FacebookAuthService().signInWithFacebook();
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FirstLoginScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Facebook Sign-In Failed: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height / 2,
              color: const Color.fromARGB(255, 187, 51, 41),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 50),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'New to Here?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'By signing up, you agree to our',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'privacy policy and Terms of Service.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 4,
            left: MediaQuery.of(context).size.width * 0.05,
            right: MediaQuery.of(context).size.width * 0.05,
            bottom: 0,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _signUp(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (bool? value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                        const Text(
                          'Remember Me',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 203, 55, 45),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _isLoading ? null : _signUp,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'SIGN UP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 30),
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: Image.asset('assets/google_icon.png', height: 24),
                          label: const Text(
                            'Sign up with Google',
                            style: TextStyle(color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 216, 215, 215),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _signInWithFacebook,
                          icon: Image.asset('assets/facebook_icon.png', height: 24),
                          label: const Text('Sign up with Facebook', 
                              style: TextStyle(color: Colors.black)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 216, 215, 215),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text(
                        'Already Have an Account?',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}