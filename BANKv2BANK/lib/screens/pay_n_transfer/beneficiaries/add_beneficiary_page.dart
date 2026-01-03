import 'package:flutter/material.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart'; // <-- Add this import
import 'package:dummy_bank/observer.dart';

class AddBeneficiaryPage extends StatefulWidget {
  @override
  _AddBeneficiaryPageState createState() => _AddBeneficiaryPageState();
}

class _AddBeneficiaryPageState extends State<AddBeneficiaryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  String? _selectedBank;

  // Sample bank list
  final List<String> banks = [
    'Canara Bank',
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return RouteAwareWrapper(
      screenName: 'AddBeneficiaryPage',
      observer: routeObserver,
      child: GestureWrapper(
        screenName: 'AddBeneficiaryPage',
        child: Scaffold(
          appBar: AppBar(
            title: Text('Add Beneficiary',
              style: TextStyle(color: Colors.white),),
            iconTheme: IconThemeData(color: Colors.white),
            backgroundColor: Color(0xFF3B5EDF),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildTextField(
                    label: 'Beneficiary Name',
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter name';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    label: 'Account Number',
                    controller: _accountController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter account number';
                      }
                      if (value.length < 8) {
                        return 'Account number too short';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedBank,
                    decoration: InputDecoration(
                      labelText: 'Bank',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: banks.map((String bank) {
                      return DropdownMenuItem<String>(
                        value: bank,
                        child: Text(bank),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedBank = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a bank';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    label: 'IFSC Code',
                    controller: _ifscController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter IFSC code';
                      }
                      if (value.length != 11) {
                        return 'IFSC must be 11 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context, {
                          'name': _nameController.text,
                          'account': _accountController.text,
                          'bank': _selectedBank!,
                          'ifsc': _ifscController.text,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3B5EDF),
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child: Text(
                      'Add Beneficiary',
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required FormFieldValidator<String>? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
}
