import 'package:flutter/material.dart';
import 'dart:math';

class RandomVerificationPage extends StatefulWidget {
  final VoidCallback onVerified;

  const RandomVerificationPage({required this.onVerified});

  @override
  _RandomVerificationPageState createState() => _RandomVerificationPageState();
}

class _RandomVerificationPageState extends State<RandomVerificationPage> {
  final Color primaryBlue = const Color(0xFF3B5EDF);
  final Color lightBg = const Color(0xFFF5F7FA);
  final Random _random = Random();
  late List<Map<String, dynamic>> _selectedQuestions;
  final Map<String, String> _answers = {};

  @override
  void initState() {
    super.initState();
    _generateRandomQuestions();
  }

  void _generateRandomQuestions() {
    final allQuestions = [
      {
        'key': 'mpin',
        'label': 'Enter 4-digit MPIN',
        'hint': 'e.g., 1234',
        'obscure': true,
        'validator': (value) => value?.length == 4 ? null : 'Must be 4 digits',
      },
      {
        'key': 'aadhaar',
        'label': 'Last 4 digits of Aadhaar',
        'hint': 'e.g., 5678',
        'obscure': false,
        'validator': (value) => value?.length == 4 ? null : 'Must be 4 digits',
      },
      {
        'key': 'mobile',
        'label': 'Last 5 digits of registered mobile',
        'hint': 'e.g., 98765',
        'obscure': false,
        'validator': (value) => value?.length == 5 ? null : 'Must be 5 digits',
      },
      {
        'key': 'dob',
        'label': 'Date of Birth (DD/MM/YYYY)',
        'hint': 'e.g., 01/01/1990',
        'obscure': false,
        'validator': (value) => value?.length == 10 ? null : 'Invalid format',
      },
    ];

    // Randomly select 1-2 questions
    allQuestions.shuffle();
    _selectedQuestions = allQuestions.sublist(0, _random.nextInt(2) + 1); // 1 or 2 items
  }

  void _submit() {
    // Mock validation (replace with actual checks)
    bool isValid = true;
    for (var q in _selectedQuestions) {
      if (_answers[q['key']]?.isEmpty ?? true) {
        isValid = false;
        break;
      }
    }

    if (isValid) {
      widget.onVerified(); // Proceed if answers are "valid"
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields correctly.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildQuestionInput(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['label'],
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          obscureText: question['obscure'],
          decoration: InputDecoration(
            hintText: question['hint'],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: question['validator'],
          onChanged: (value) => _answers[question['key']] = value,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text("Security Check"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                // Header
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security,
                    size: 40,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Verify It’s You",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Answer ${_selectedQuestions.length} security question(s):",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                // Dynamic Questions
                ..._selectedQuestions.map(_buildQuestionInput).toList(),
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 16,
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
    );
  }
}