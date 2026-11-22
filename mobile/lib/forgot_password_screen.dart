
import 'package:flutter/material.dart';
import 'api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool loading = false;
  bool otpSent = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  String? demoOtp;

  static const Color teal = Color(0xFF0F766E);
  static const Color dark = Color(0xFF073D3B);

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> requestOtp() async {
    final email = emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      showMessage('Please enter your email address');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(email)) {
      showMessage('Please enter a valid email address');
      return;
    }

    setState(() => loading = true);

    try {
      final result = await ApiService.forgotPassword(
        email: email,
      );

      if (!mounted) return;

      final data = result['data'];

      if (result['statusCode'] == 200 && data is Map) {
        setState(() {
          otpSent = true;
          demoOtp = data['demoOtp']?.toString();
        });

        showMessage('Demo OTP generated successfully');
      } else {
        showMessage(
          data is Map
              ? data['message']?.toString() ??
              'Unable to generate OTP'
              : 'Unable to generate OTP',
        );
      }
    } catch (error) {
      showMessage('Unable to connect to server: $error');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> resetPassword() async {
    final otp = otpController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmController.text;

    if (otp.length != 6) {
      showMessage('Please enter the six-digit OTP');
      return;
    }

    if (password.length < 6) {
      showMessage(
        'Password must contain at least 6 characters',
      );
      return;
    }

    if (password != confirmPassword) {
      showMessage('Passwords do not match');
      return;
    }

    setState(() => loading = true);

    try {
      final result = await ApiService.resetPassword(
        email: emailController.text.trim().toLowerCase(),
        otp: otp,
        newPassword: password,
      );

      if (!mounted) return;

      final data = result['data'];

      if (result['statusCode'] == 200) {
        showMessage(
          'Password reset successfully. Please login.',
        );

        await Future.delayed(
          const Duration(milliseconds: 500),
        );

        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        showMessage(
          data is Map
              ? data['message']?.toString() ??
              'Password reset failed'
              : 'Password reset failed',
        );
      }
    } catch (error) {
      showMessage('Unable to connect to server: $error');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  InputDecoration fieldDecoration(
      String hint,
      IconData icon,
      ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF718078),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFDCE6E5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFDCE6E5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: teal,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFC),
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: const Color(0xFFF8FBFC),
        foregroundColor: dark,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_reset,
                    color: teal,
                    size: 75,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Reset your password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Enter your registered email address '
                        'to generate a password reset OTP.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF718078),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Email Address',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !otpSent,
                    decoration: fieldDecoration(
                      'you@example.com',
                      Icons.email_outlined,
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (!otpSent)
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                        loading ? null : requestOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child:
                          CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Generate Demo OTP',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                  if (otpSent) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F5F2),
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFB7E4DC),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: teal,
                            size: 35,
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'EXHIBITION DEMO OTP',
                            style: TextStyle(
                              color: dark,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),

                          const SizedBox(height: 10),

                          SelectableText(
                            demoOtp ?? '',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 7,
                              color: teal,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'This OTP is valid for 10 minutes.',
                            style: TextStyle(
                              color: Color(0xFF718078),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Enter OTP',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: fieldDecoration(
                        'Six-digit OTP',
                        Icons.password,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'New Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: fieldDecoration(
                        'Enter new password',
                        Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword =
                              !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Confirm New Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: confirmController,
                      obscureText: obscureConfirmPassword,
                      decoration: fieldDecoration(
                        'Re-enter new password',
                        Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword =
                              !obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                        loading ? null : resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: loading
                          ? null
                          : () {
                        setState(() {
                          otpSent = false;
                          demoOtp = null;
                          otpController.clear();
                          passwordController.clear();
                          confirmController.clear();
                        });
                      },
                      child: const Text(
                        'Use another email',
                        style: TextStyle(color: teal),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
