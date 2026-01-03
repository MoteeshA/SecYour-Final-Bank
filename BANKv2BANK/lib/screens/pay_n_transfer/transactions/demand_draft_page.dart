import 'package:flutter/material.dart';
import 'transaction_success_page.dart';
import 'package:dummy_bank/screens/pin_popup.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart'; // <-- Add this import
import 'package:dummy_bank/observer.dart';

class DemandDraftPage extends StatefulWidget {
  @override
  _DemandDraftPageState createState() => _DemandDraftPageState();
}

class _DemandDraftPageState extends State<DemandDraftPage> {
  final _formKey = GlobalKey<FormState>();
  String payeeName = '';
  String payableAt = '';
  String amount = '';
  String remarks = '';

  void _submitDDRequest() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PinPopup(
          onComplete: (enteredPin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionSuccessPage(
                  accountNumber: 'Demand Draft',
                  amount: amount,
                  remarks: remarks,
                ),
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RouteAwareWrapper(
      screenName: 'DemandDraftPage',
      observer: routeObserver,
      child: GestureWrapper(
        screenName: 'DemandDraftPage',
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              "Request Demand Draft",
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
                    label: "Payee Name",
                    hint: "Enter payee's full name",
                    keyboardType: TextInputType.name,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                    onSaved: (val) => payeeName = val!,
                  ),
                  _buildField(
                    label: "Payable At (Location)",
                    hint: "Enter city or branch",
                    keyboardType: TextInputType.text,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                    onSaved: (val) => payableAt = val!,
                  ),
                  _buildField(
                    label: "Amount (₹)",
                    hint: "Enter amount",
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      final n = num.tryParse(val);
                      if (n == null || n <= 0) return 'Enter a valid amount';
                      return null;
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
                    onPressed: _submitDDRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3B5EDF),
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child: Text(
                      "Proceed to Request DD",
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
