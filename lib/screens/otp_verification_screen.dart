import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'first_login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String? _generatedOtp;
  String _enteredOtp = '';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOtp();
    });
  }

  String _generateOtp() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  Future<void> _sendEmail(String email, String otp) async {
    setState(() => _isSending = true);
    final smtpServer = gmail('worldwidenews018@gmail.com', 'dinlvjaqthpewsxi');
    final message = Message()
      ..from = const Address('worldwidenews018@gmail.com', 'WWNapp')
      ..recipients.add(email)
      ..subject = 'Your OTP Code'
      ..text = 'Your OTP code is: $otp';

    try {
      await send(message, smtpServer);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "OTP sent to your email. Please check your inbox and spam/junk folder if you don't see it.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Failed to send OTP email. Please try again.")),
      );
    }
    setState(() => _isSending = false);
  }

  void _sendOtp() {
    _generatedOtp = _generateOtp();
    _sendEmail(widget.email, _generatedOtp!);
  }

  void _validateOtp() {
    if (_enteredOtp == _generatedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Verified!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FirstLoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP! Please try again.")),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 187, 51, 41),
      body: SafeArea(
        child: Column(
          children: [
            // Red header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: 40, left: 24, right: 24, bottom: 32),
              color: const Color.fromARGB(255, 187, 51, 41),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verify Your Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'An OTP has been sent to your email:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.email,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Please enter the OTP below to continue.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // White OTP form, centered in remaining space
            Expanded(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32), bottom: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OtpTextField(
                        numberOfFields: 6,
                        borderColor: const Color.fromARGB(255, 187, 51, 41),
                        focusedBorderColor:
                            const Color.fromARGB(255, 187, 51, 41),
                        showFieldAsBox: true,
                        fieldWidth: 44,
                        borderRadius: BorderRadius.circular(8),
                        cursorColor: const Color.fromARGB(255, 187, 51, 41),
                        textStyle: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        onSubmit: (otp) => setState(() => _enteredOtp = otp),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 203, 55, 45),
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: _isSending ? null : _validateOtp,
                          child: _isSending
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  'Verify OTP',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _isSending ? null : _sendOtp,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: Color.fromARGB(255, 187, 51, 41),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
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
      ),
    );
  }
}
