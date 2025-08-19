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
      // After user signs up and you have their email, you can set preferences if needed.
      // await UserDataService.setPreferences(email, preferences); // Removed undefined 'preferences'
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
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F0), // Subtle white-reddish background[4]
      body: Stack(
        children: [
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: screenHeight * 0.34,
              color: const Color.fromARGB(255, 187, 51, 41),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_add, color: Colors.red[700], size: 40),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'New to Here?',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'By signing up, you agree to our',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'privacy policy and Terms of Service.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Card Form
          Positioned(
            top: screenHeight * 0.22,
            left: MediaQuery.of(context).size.width * 0.05,
            right: MediaQuery.of(context).size.width * 0.05,
            bottom: 0,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // Email
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email, color: Colors.red),
                        filled: true,
                        fillColor: const Color(0xFFFFF0F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock, color: Colors.red),
                        filled: true,
                        fillColor: const Color(0xFFFFF0F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.red,
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
                    const SizedBox(height: 12),
                    // Confirm Password
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.red),
                        filled: true,
                        fillColor: const Color(0xFFFFF0F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.red,
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
                          activeColor: Colors.red,
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
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isLoading ? null : _signUp,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'SIGN UP',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Divider(thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "or sign up with",
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Expanded(child: Divider(thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: Image.asset('assets/google_icon.png', height: 24),
                      label: const Text(
                        'Sign up with Google',
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F5F5),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithFacebook,
                      icon: Image.asset('assets/facebook_icon.png', height: 24),
                      label: const Text('Sign up with Facebook',
                          style: TextStyle(color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F5F5),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 18),
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
            Container(
              color: Colors.black.withOpacity(0.05),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
