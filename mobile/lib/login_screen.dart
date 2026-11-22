import 'package:flutter/material.dart';
import 'api_service.dart';
import 'forgot_password_screen.dart';

const Color authTeal = Color(0xFF0F766E);
const Color authDark = Color(0xFF073D3B);
const Color authBackground = Color(0xFFF8FBFC);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final result = await ApiService.login(
        email: emailController.text.trim().toLowerCase(),
        password: passwordController.text,
      );

      if (!mounted) return;

      final data = result['data'];
      final statusCode = result['statusCode'];

      if (statusCode == 200 &&
          data is Map &&
          data['token'] != null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
              (route) => false,
          arguments: {
            'token': data['token'].toString(),
            'user': data['user'] is Map
                ? Map<String, dynamic>.from(data['user'])
                : <String, dynamic>{},
          },
        );
      } else {
        showMessage(
          data is Map
              ? data['message']?.toString() ??
              'Login failed. Please try again.'
              : 'Login response did not contain an authentication token.',
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage('Unable to connect to server: $e');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 750;

            return Row(
              children: [
                if (wide)
                  const Expanded(
                    child: AuthBrandPanel(isRegister: false),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints:
                        const BoxConstraints(maxWidth: 430),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!wide) ...[
                              const Center(
                                child: AuthLogo(),
                              ),
                              const SizedBox(height: 30),
                            ],
                            const Text(
                              'WELCOME BACK',
                              style: TextStyle(
                                color: authTeal,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Sign in to your account',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263238),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enter your details to continue your wellness journey.',
                              style: TextStyle(
                                color: Color(0xFF718078),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE8EEEE),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.04,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const AuthFieldLabel(
                                      'Email address',
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: emailController,
                                      keyboardType:
                                      TextInputType.emailAddress,
                                      decoration: authInputDecoration(
                                        'you@example.com',
                                        Icons.email_outlined,
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter your email.';
                                        }
                                        if (!RegExp(
                                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                        ).hasMatch(value.trim())) {
                                          return 'Enter a valid email address.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 22),
                                    const AuthFieldLabel('Password'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: passwordController,
                                      obscureText: obscurePassword,
                                      decoration: authInputDecoration(
                                        'Enter your password',
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
                                      validator: (value) {
                                        if (value == null ||
                                            value.isEmpty) {
                                          return 'Please enter your password.';
                                        }
                                        return null;
                                      },
                                    ),

                                    // FORGOT PASSWORD LINK
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                              const ForgotPasswordScreen(),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: authTeal,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 28),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed:
                                        loading ? null : login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: authTeal,
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
                                          'Sign in',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                            FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            Center(
                              child: Column(
                                children: [
                                  const Text(
                                    'NEW TO HEALTHMATE?',
                                    style: TextStyle(
                                      color: Color(0xFF718078),
                                      fontSize: 11,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Create an account',
                                      style: TextStyle(
                                        color: authTeal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'Your wellness journey starts here.',
                                    style: TextStyle(
                                      color: Color(0xFF718078),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// --------------------------------------------------
// REGISTRATION SCREEN
// --------------------------------------------------

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final targetWeightController = TextEditingController();

  String gender = 'Male';
  String goal = 'lose';

  bool loading = false;
  bool obscurePassword = true;
  bool registered = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    targetWeightController.dispose();
    super.dispose();
  }

  String? requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? numberValidator(
      String? value, {
        double? min,
        double? max,
        String field = 'Value',
      }) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required.';
    }

    final number = double.tryParse(value);

    if (number == null) return 'Enter a valid number.';
    if (min != null && number < min) {
      return '$field must be at least $min.';
    }
    if (max != null && number > max) {
      return '$field must not exceed $max.';
    }

    return null;
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final result = await ApiService.register(
        name: nameController.text.trim(),
        email: emailController.text.trim().toLowerCase(),
        password: passwordController.text,
        age: int.parse(ageController.text),
        gender: gender,
        height: double.parse(heightController.text),
        weight: double.parse(weightController.text),
        targetWeight: double.parse(targetWeightController.text),
        goal: goal,
      );

      if (!mounted) return;

      if (result['statusCode'] == 200 ||
          result['statusCode'] == 201) {
        setState(() => registered = true);
        showMessage(
          result['data']?['message']?.toString() ??
              'Account created successfully! Please login.',
        );
      } else {
        showMessage(
          result['data']?['message']?.toString() ??
              'Registration failed. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage('Unable to connect to server: $e');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authBackground,
      appBar: AppBar(
        backgroundColor: authBackground,
        surfaceTintColor: authBackground,
        title: const Text('Create account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: AuthLogo()),
                  const SizedBox(height: 25),
                  const Text(
                    'GET STARTED',
                    style: TextStyle(
                      color: authTeal,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your account',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Build healthier habits with your personal wellness companion.',
                    style: TextStyle(
                      color: Color(0xFF718078),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (registered)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: authTeal,
                            size: 55,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Account created successfully!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please login using your registered email and password.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: authTeal,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Login to HealthMate'),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE8EEEE),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AuthSectionTitle(
                              'Personal Information',
                            ),
                            const SizedBox(height: 16),
                            const AuthFieldLabel('Full Name'),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: nameController,
                              decoration: authInputDecoration(
                                'Enter your full name',
                                Icons.person_outline,
                              ),
                              validator: requiredText,
                            ),
                            const SizedBox(height: 17),
                            const AuthFieldLabel('Email Address'),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: authInputDecoration(
                                'you@example.com',
                                Icons.email_outlined,
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Email is required.';
                                }
                                if (!RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(value.trim())) {
                                  return 'Enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 17),
                            const AuthFieldLabel('Password'),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              decoration: authInputDecoration(
                                'Minimum 6 characters',
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required.';
                                }
                                if (value.length < 6) {
                                  return 'Password must contain at least 6 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 25),
                            const AuthSectionTitle(
                              'Health Profile',
                            ),
                            const SizedBox(height: 16),
                            const AuthFieldLabel('Age'),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: ageController,
                              keyboardType: TextInputType.number,
                              decoration: authInputDecoration(
                                'Enter your age',
                                Icons.calendar_today_outlined,
                              ),
                              validator: (v) => numberValidator(
                                v,
                                min: 13,
                                max: 120,
                                field: 'Age',
                              ),
                            ),
                            const SizedBox(height: 17),
                            const AuthFieldLabel('Gender'),
                            const SizedBox(height: 7),
                            DropdownButtonFormField<String>(
                              initialValue: gender,
                              decoration: authInputDecoration(
                                'Select gender',
                                Icons.person_outline,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Male',
                                  child: Text('Male'),
                                ),
                                DropdownMenuItem(
                                  value: 'Female',
                                  child: Text('Female'),
                                ),
                                DropdownMenuItem(
                                  value: 'Other',
                                  child: Text('Other'),
                                ),
                                DropdownMenuItem(
                                  value: 'Prefer not to say',
                                  child: Text('Prefer not to say'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => gender = value);
                                }
                              },
                            ),
                            const SizedBox(height: 17),
                            const AuthFieldLabel('Height (cm)'),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: heightController,
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: authInputDecoration(
                                'Enter height in cm',
                                Icons.height,
                              ),
                              validator: (v) => numberValidator(
                                v,
                                min: 50,
                                max: 250,
                                field: 'Height',
                              ),
                            ),
                            const SizedBox(height: 17),
                            const AuthFieldLabel(
                              'Current Weight (kg)',
                            ),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: weightController,
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: authInputDecoration(
                                'Enter current weight',
                                Icons.monitor_weight_outlined,
                              ),
                              validator: (v) => numberValidator(
                                v,
                                min: 1,
                                max: 500,
                                field: 'Current weight',
                              ),
                            ),
                            const SizedBox(height: 17),
                            const AuthFieldLabel(
                              'Target Weight (kg)',
                            ),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: targetWeightController,
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: authInputDecoration(
                                'Enter target weight',
                                Icons.flag_outlined,
                              ),
                              validator: (v) => numberValidator(
                                v,
                                min: 1,
                                max: 500,
                                field: 'Target weight',
                              ),
                            ),
                            const SizedBox(height: 17),
                            const AuthFieldLabel('Fitness Goal'),
                            const SizedBox(height: 7),
                            DropdownButtonFormField<String>(
                              initialValue: goal,
                              decoration: authInputDecoration(
                                'Select your goal',
                                Icons.track_changes,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'lose',
                                  child: Text('Lose Weight'),
                                ),
                                DropdownMenuItem(
                                  value: 'gain',
                                  child: Text('Gain Weight'),
                                ),
                                DropdownMenuItem(
                                  value: 'maintain',
                                  child: Text('Maintain Weight'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => goal = value);
                                }
                              },
                            ),
                            const SizedBox(height: 26),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed:
                                loading ? null : register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: authTeal,
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
                                  'Create Account',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  if (!registered)
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: Color(0xFF718078),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Login to HealthMate',
                              style: TextStyle(
                                color: authTeal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'Your health information is associated with your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF718078),
                        fontSize: 11,
                      ),
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

// --------------------------------------------------
// REUSABLE AUTHENTICATION WIDGETS
// --------------------------------------------------

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: authTeal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'H',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'HealthMate',
          style: TextStyle(
            fontSize: 23,
            color: authDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class AuthBrandPanel extends StatelessWidget {
  final bool isRegister;

  const AuthBrandPanel({
    super.key,
    required this.isRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(45),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF073D3B),
            Color(0xFF0F766E),
            Color(0xFF115E59),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AuthLogo(),
          const SizedBox(height: 65),
          Text(
            isRegister
                ? 'YOUR PERSONAL WELLNESS COMPANION'
                : 'YOUR HEALTH. YOUR JOURNEY.',
            style: const TextStyle(
              color: Color(0xFF99F6E4),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isRegister
                ? 'Build healthier habits. Live better.'
                : 'A healthier life starts with you.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isRegister
                ? 'Track your daily activities, understand your progress and build a healthier lifestyle with HealthMate.'
                : 'Track your daily habits, understand your wellness patterns, and take small steps towards a healthier lifestyle.',
            style: const TextStyle(
              color: Color(0xFFD0F2ED),
              height: 1.7,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 35),
          _highlight('Track your wellness'),
          _highlight('Understand your progress'),
          _highlight('Build healthier habits'),
          const SizedBox(height: 55),
          Text(
            isRegister
                ? 'Your health journey starts here.'
                : 'Healthcare & Wellness Companion',
            style: const TextStyle(
              color: Color(0xFFCCFBF1),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlight(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 17),
    child: Row(
      children: [
        const Icon(
          Icons.check_circle,
          color: Color(0xFF99F6E4),
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ],
    ),
  );
}

class AuthFieldLabel extends StatelessWidget {
  final String text;

  const AuthFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF263238),
      ),
    );
  }
}

class AuthSectionTitle extends StatelessWidget {
  final String text;

  const AuthSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: authDark,
      ),
    );
  }
}

InputDecoration authInputDecoration(
    String hint,
    IconData icon,
    ) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(
      icon,
      color: const Color(0xFF718078),
      size: 20,
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
        color: authTeal,
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: Colors.red,
      ),
    ),
  );
}