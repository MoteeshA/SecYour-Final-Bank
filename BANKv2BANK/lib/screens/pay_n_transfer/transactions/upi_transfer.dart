import 'package:flutter/material.dart';
import 'transaction_success_page.dart';
import 'package:dummy_bank/screens/pin_popup.dart';

import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart';

import 'package:dummy_bank/observer.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:easy_localization/easy_localization.dart';

class UpiTransferPage extends StatefulWidget {
  @override
  _UpiTransferPageState createState() => _UpiTransferPageState();
}

class _UpiTransferPageState extends State<UpiTransferPage> {
  final _formKey = GlobalKey<FormState>();
  String upiId = '';
  String amount = '';
  String remarks = '';

  // 🔊 Text-to-Speech instance
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.55);
  }

  /// Speak localized Odia/English message
  Future<void> _speakTransferMessage() async {
    try {
      await _flutterTts.stop();

      // Get app language
      final locale = context.locale;

      String lang;
      if (locale.languageCode == 'or' || locale.languageCode == 'od') {
        lang = 'or-IN'; // Odia
      } else {
        lang = 'en-IN'; // English
      }

      await _flutterTts.setLanguage(lang);

      // 🔁 Localized message from JSON
      final text = 'within_bank_tts_message'.tr(
        namedArgs: {'amount': amount},
      );

      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("TTS error: $e");
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  void _showPinPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PinPopup(
        onComplete: (enteredPin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionSuccessPage(
                accountNumber: upiId,
                amount: amount,
                remarks: remarks,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitTransfer() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // 🔊 Speak localized TTS message
      await _speakTransferMessage();

      // Confirmation popup
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Confirm UPI Transfer"),
          content: Text(
            "Recipient: Nikhil\n"
                "UPI ID: $upiId\n"
                "Amount: ₹$amount\n\n"
                "Are you sure you want to proceed?",
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showPinPopup();
              },
              child: Text("Confirm"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RouteAwareWrapper(
      screenName: 'UpiTransferPage',
      observer: routeObserver,
      child: GestureWrapper(
        screenName: 'UpiTransferPage',
        child: Scaffold(
          appBar: AppBar(
            title: Text("UPI Transfer", style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF3B5EDF),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildField(
                    label: "Recipient UPI ID",
                    hint: "e.g. name@bank",
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => upiId = val!,
                  ),
                  _buildField(
                    label: "Amount (₹)",
                    hint: "Enter amount",
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      final n = num.tryParse(val);
                      return (n == null || n <= 0)
                          ? 'Enter a valid amount'
                          : null;
                    },
                    onSaved: (val) => amount = val!,
                  ),
                  _buildField(
                    label: "Remarks",
                    hint: "Purpose (optional)",
                    keyboardType: TextInputType.text,
                    validator: null,
                    onSaved: (val) => remarks = val ?? '',
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitTransfer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3B5EDF),
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child: Text(
                      "Proceed to Transfer",
                      style: TextStyle(color: Colors.white, fontSize: 17),
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

  Widget _buildField({
    required String label,
    required String hint,
    required TextInputType keyboardType,
    required FormFieldValidator<String>? validator,
    required FormFieldSetter<String> onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        keyboardType: keyboardType,
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }
}
