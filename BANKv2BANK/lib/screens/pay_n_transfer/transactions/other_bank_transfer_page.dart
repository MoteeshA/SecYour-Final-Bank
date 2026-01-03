import 'package:flutter/material.dart';
import 'transaction_success_page.dart';
import 'package:dummy_bank/screens/pin_popup.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart';
import 'package:dummy_bank/observer.dart';
import 'package:flutter_tts/flutter_tts.dart';

class OtherBankTransferPage extends StatefulWidget {
  @override
  _OtherBankTransferPageState createState() => _OtherBankTransferPageState();
}

class _OtherBankTransferPageState extends State<OtherBankTransferPage> {
  final _formKey = GlobalKey<FormState>();
  String accountNumber = '';
  String confirmAccountNumber = '';
  String ifscCode = '';
  String beneficiaryName = '';
  String amount = '';
  String remarks = '';
  String pin = '';

  // 🔊 Text-to-Speech instance
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.55); // slower, clear
  }

  Future<void> _speak(String text) async {
    try {
      await _flutterTts.stop();
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
                accountNumber: accountNumber,
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

      if (accountNumber != confirmAccountNumber) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account numbers don't match")),
        );
        return;
      }

      // 🎤 Voice confirmation text
      final speakText =
          "You are about to transfer rupees $amount to $beneficiaryName "
          "with account number $accountNumber in other bank. "
          "If this is correct, press Confirm to proceed to transfer.";

      // 1️⃣ Speak aloud
      await _speak(speakText);

      // 2️⃣ Show confirmation dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Confirm Other Bank Transfer"),
          content: Text(
            "Beneficiary: $beneficiaryName\n"
                "Account Number: $accountNumber\n"
                "IFSC: $ifscCode\n"
                "Amount: ₹$amount\n\n"
                "Are you sure you want to proceed?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel"),
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
      screenName: 'OtherBankTransferPage',
      observer: routeObserver,
      child: GestureWrapper(
        screenName: 'OtherBankTransferPage',
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              "Transfer to Other Bank",
              style: TextStyle(color: Colors.white),
            ),
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
                    label: "Beneficiary Account Number",
                    hint: "Enter account number",
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => accountNumber = val!,
                  ),
                  _buildField(
                    label: "Confirm Account Number",
                    hint: "Re-enter account number",
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => confirmAccountNumber = val!,
                  ),
                  _buildField(
                    label: "IFSC Code",
                    hint: "Enter 11-digit IFSC",
                    keyboardType: TextInputType.text,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (val.length != 11) return 'Invalid IFSC';
                      return null;
                    },
                    onSaved: (val) => ifscCode = val!,
                  ),
                  _buildField(
                    label: "Beneficiary Name",
                    hint: "Account holder name",
                    keyboardType: TextInputType.name,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => beneficiaryName = val!,
                  ),
                  _buildField(
                    label: "Amount (₹)",
                    hint: "Enter amount",
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => amount = val!,
                  ),
                  // (Optional) You can add remarks field like others:
                  // _buildField(
                  //   label: "Remarks",
                  //   hint: "Purpose (optional)",
                  //   keyboardType: TextInputType.text,
                  //   validator: null,
                  //   onSaved: (val) => remarks = val ?? '',
                  // ),
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
