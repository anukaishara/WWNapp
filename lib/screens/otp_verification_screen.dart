import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'home_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email; // Email to which OTP is sent
  const OtpVerificationScreen({super.key, required this.email});

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  String? _generatedOtp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOtp(); // Send OTP after the screen is displayed
    });
  }

  // Generate a random 6-digit OTP
  String _generateOtp() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0'); // Ensures a 6-digit OTP
  }

  // Send OTP via Gmail SMTP
  Future<void> _sendEmail(String email, String otp) async {
    // Configure the Gmail SMTP server with your email and app password
    final smtpServer = gmail('worldwidenews018@gmail.com', 'dinlvjaqthpewsxi'); // Replace with your credentials

    // Compose the email
    final message = Message()
      ..from = Address('worldwidenews018@gmail.com', 'WWNapp') // Replace with your Gmail
      ..recipients.add(email) // Recipient's email
      ..subject = 'Your OTP Code' // Subject of the email
      ..text = 'Your OTP code is: $otp'; // Email body

    try {
      // Attempt to send the email
      await send(message, smtpServer);
      print("OTP email successfully sent to $email");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP sent to your email. Please check!")),
      );
    } catch (e) {
      print("Failed to send OTP email: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send OTP email. Please try again.")),
      );
    }
  }

  // Send OTP to the user's email
  void _sendOtp() {
    _generatedOtp = _generateOtp(); // Generate OTP
    _sendEmail(widget.email, _generatedOtp!); // Send OTP via email
  }

  // Validate the OTP entered by the user
  void _validateOtp() {
    if (_otpController.text.trim() == _generatedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Verified! Redirecting to Home Screen...")),
      );

      // Redirect to Home Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP! Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Top red header
          Container(
            height: MediaQuery.of(context).size.height / 2,
            color: const Color.fromARGB(255, 187, 51, 41),
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verify Your Account',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'An OTP has been sent to your email: ${widget.email}',
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Please enter the OTP below to continue.',
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Bottom white form
          Positioned(
            top: MediaQuery.of(context).size.height / 4,
            left: MediaQuery.of(context).size.width * 0.05,
            right: MediaQuery.of(context).size.width * 0.05,
            bottom: 0,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'OTP Code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 203, 55, 45),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _validateOtp,
                      child: const Text(
                        'Verify OTP',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _sendOtp,
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
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
