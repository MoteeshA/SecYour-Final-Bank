import 'dart:convert'; // 👈 for base64Encode

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart'; // 🌍 Localization
import 'training.dart';

// ⚠️ In production, move these to backend / env variables
const String _twilioAccountSid = 'REMOVED_TWILIO_SID';
const String _twilioAuthToken = '5634e36661315510658327b090905cc4';
const String _twilioVerifyServiceSid = 'VAfeb60a838a103b8411b75e90a4fddf05';

// 👇 Hardcoded test OTP
const String _testOtp = '123456';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _securityAnswerController =
  TextEditingController();
  final TextEditingController _mpinController = TextEditingController();
  final TextEditingController _confirmMpinController = TextEditingController();

  String? _selectedQuestion;

  bool otpSent = false;
  bool otpVerified = false;
  bool askDetails = false;
  bool setMpin = false;
  bool _obscureMpin = true;
  bool _obscureConfirmMpin = true;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page == 0 && otpSent) {
        setState(() => otpSent = true);
      } else if (page == 1 && otpVerified) {
        setState(() => otpVerified = true);
      } else if (page == 2 && askDetails) {
        setState(() => askDetails = true);
      } else if (page == 3 && setMpin) {
        setState(() => setMpin = true);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _securityAnswerController.dispose();
    _mpinController.dispose();
    _confirmMpinController.dispose();
    super.dispose();
  }

  // ---------------------- TWILIO INTEGRATION ----------------------

  String _buildBasicAuthHeader() {
    final creds = '$_twilioAccountSid:$_twilioAuthToken';
    final encoded = base64Encode(utf8.encode(creds));
    return 'Basic $encoded';
  }

  /// Send OTP using Twilio Verify (with fallback to test OTP 123456)
  Future<void> sendOtp(String phone) async {
    if (phone.isEmpty || phone.length != 10) {
      _showSnack('error_phone_invalid'.tr());
      return;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      _showSnack('error_phone_digits_only'.tr());
      return;
    }

    final String toNumber = '+91$phone';
    final uri = Uri.https(
      'verify.twilio.com',
      '/v2/Services/$_twilioVerifyServiceSid/Verifications',
    );

    try {
      _showSnack('otp_sending'.tr());

      final response = await http.post(
        uri,
        headers: {
          'Authorization': _buildBasicAuthHeader(),
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': toNumber,
          'Channel': 'sms',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // ✅ Normal Twilio flow
        setState(() {
          otpSent = true;
        });

        await _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );

        _showSnack('otp_sent'.tr());
      } else {
        // ❌ Twilio failed – still allow test OTP
        setState(() {
          otpSent = true;
        });

        await _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );

        _showSnack(
          'Failed to send OTP (${response.statusCode}). ${'otp_test_hint'.tr()}',
        );
      }
    } catch (e) {
      // ❌ Network / config error – still allow test OTP
      setState(() {
        otpSent = true;
      });

      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      _showSnack(
        'Error sending OTP: $e\n${'otp_test_hint'.tr()}',
      );
    }
  }

  /// Verify OTP using Twilio Verify (with hardcoded test OTP 123456 fallback)
  Future<void> verifyOtp(String phone, String otp) async {
    if (otp.isEmpty || otp.length != 6) {
      _showSnack('error_otp_invalid'.tr());
      return;
    }
    if (phone.isEmpty || phone.length != 10) {
      _showSnack('error_phone_missing'.tr());
      return;
    }

    final String toNumber = '+91$phone';

    // 🔐 TEST BYPASS: If user enters 123456, skip Twilio and approve directly
    if (otp == _testOtp) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("phone", toNumber);

      setState(() {
        otpVerified = true;
        askDetails = true;
      });

      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      _showSnack('${'otp_verified'.tr()} (${_testOtp})');
      return;
    }

    // 👉 Otherwise, do normal Twilio verification
    final uri = Uri.https(
      'verify.twilio.com',
      '/v2/Services/$_twilioVerifyServiceSid/VerificationCheck',
    );

    try {
      _showSnack('otp_verifying'.tr());

      final response = await http.post(
        uri,
        headers: {
          'Authorization': _buildBasicAuthHeader(),
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': toNumber,
          'Code': otp,
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status == 'approved') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("phone", toNumber);

          setState(() {
            otpVerified = true;
            askDetails = true;
          });

          await _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );

          _showSnack('otp_verified'.tr());
        } else {
          _showSnack("❌ Incorrect OTP. Status: $status");
        }
      } else {
        _showSnack(
          "Failed to verify OTP (${response.statusCode}). ${'otp_test_hint'.tr()}",
        );
      }
    } catch (e) {
      _showSnack(
        "Error verifying OTP: $e\n${'otp_test_hint'.tr()}",
      );
    }
  }

  // ---------------------- DETAILS & MPIN ----------------------

  Future<void> saveUserDetails() async {
    if (_nameController.text.isEmpty) {
      _showSnack('error_name_required'.tr());
      return;
    }

    if (_selectedQuestion == null) {
      _showSnack('error_security_question_required'.tr());
      return;
    }

    if (_securityAnswerController.text.isEmpty) {
      _showSnack('error_security_answer_required'.tr());
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("name", _nameController.text.trim());
    await prefs.setString("security_question", _selectedQuestion!);
    await prefs.setString(
      "security_answer",
      _securityAnswerController.text.trim().toLowerCase(),
    );

    setState(() {
      askDetails = false;
      setMpin = true;
    });

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> saveMpin() async {
    if (_mpinController.text.length != 6) {
      _showSnack('error_mpin_length'.tr());
      return;
    }

    if (_mpinController.text != _confirmMpinController.text) {
      _showSnack('error_mpin_mismatch'.tr());
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("mpin", _mpinController.text);
    await prefs.setBool("registered", true);

    _showSnack('registration_complete'.tr());

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TrainingPage()),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildIndicator(int currentPage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentPage == index
                ? Colors.blue.shade700
                : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = otpSent
        ? (otpVerified
        ? (askDetails
        ? 2
        : (setMpin
        ? 3
        : 2))
        : 1)
        : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
          const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          onPressed: () {
            if (currentPage > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );

              if (currentPage == 1) {
                setState(() => otpSent = false);
              } else if (currentPage == 2) {
                setState(() => otpVerified = false);
              } else if (currentPage == 3) {
                setState(() {
                  askDetails = true;
                  setMpin = false;
                });
              }
            } else {
              Navigator.maybePop(context); // back to language screen
            }
          },
        ),
        title: Text(
          'registration_title'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildIndicator(currentPage),
            const SizedBox(height: 20),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPhonePage(),
                  _buildOtpPage(),
                  _buildDetailsPage(),
                  _buildMpinPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- PAGES ----------------------

  Widget _buildPhonePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.phone_iphone,
            size: 64,
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'phone_verification_title'.tr(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'phone_verification_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: _inputDecoration(
              'phone_number_label'.tr(),
              Icons.phone,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => sendOtp(_phoneController.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'send_otp'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOtpPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.sms,
            size: 64,
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'otp_title'.tr(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'otp_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: _inputDecoration("OTP Code", Icons.lock_outline),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'resend_otp_question'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              TextButton(
                onPressed: () => sendOtp(_phoneController.text.trim()),
                child: Text(
                  'resend_otp'.tr(),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => verifyOtp(
                _phoneController.text.trim(),
                _otpController.text.trim(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'verify_otp'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.security, size: 64, color: Colors.blue.shade700),
          const SizedBox(height: 16),
          Text(
            'security_details_title'.tr(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'security_details_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration(
              'full_name_label'.tr(),
              Icons.person_outline,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedQuestion,
            items: [
              // These can also be localized if you want
              "What is your favourite color?",
              "What is your pet's name?",
              "What city were you born in?",
              "What is your mother's maiden name?"
            ]
                .map(
                  (q) => DropdownMenuItem(
                value: q,
                child: Text(
                  q,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
                .toList(),
            onChanged: (val) => setState(() => _selectedQuestion = val),
            decoration: _inputDecoration(
              'security_question_label'.tr(),
              Icons.question_answer,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _securityAnswerController,
            decoration: _inputDecoration(
              'security_answer_label'.tr(),
              Icons.edit,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saveUserDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'continue_button'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMpinPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'set_mpin_title'.tr(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'set_mpin_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _mpinController,
            obscureText: _obscureMpin,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: _inputDecoration(
              'enter_mpin_label'.tr(),
              Icons.lock_outline,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureMpin ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: () =>
                    setState(() => _obscureMpin = !_obscureMpin),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmMpinController,
            obscureText: _obscureConfirmMpin,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: _inputDecoration(
              'confirm_mpin_label'.tr(),
              Icons.lock_outline,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmMpin
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: () => setState(
                        () => _obscureConfirmMpin = !_obscureConfirmMpin),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saveMpin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'complete_registration_button'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.grey),
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding:
      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}
