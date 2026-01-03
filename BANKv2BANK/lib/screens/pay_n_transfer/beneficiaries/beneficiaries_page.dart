import 'package:flutter/material.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart'; // <-- Add this import
import 'package:dummy_bank/observer.dart';

class BeneficiariesPage extends StatefulWidget {
  @override
  _BeneficiariesPageState createState() => _BeneficiariesPageState();
}

class _BeneficiariesPageState extends State<BeneficiariesPage> {
  final List<Map<String, dynamic>> _beneficiaries = [
    {
      'id': '1',
      'name': 'Harsh Kumar',
      'accountNumber': '1234567890',
      'bank': 'ABC Bank',
      'ifsc': 'ABCD0123456',
      'type': 'Within Bank',
    },
    {
      'id': '2',
      'name': 'Divya Singh',
      'accountNumber': '9876543210',
      'bank': 'XYZ Bank',
      'ifsc': 'XYZ0987654',
      'type': 'Other Bank',
    },
  ];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  String _selectedType = 'Within Bank';


  void _addBeneficiary() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _beneficiaries.add({
          'id': DateTime.now().toString(),
          'name': _nameController.text,
          'accountNumber': _accountController.text,
          'bank': _bankController.text,
          'ifsc': _ifscController.text,
          'type': _selectedType,
        });

        // Clear form
        _nameController.clear();
        _accountController.clear();
        _bankController.clear();
        _ifscController.clear();

        // Close the add dialog
        Navigator.of(context).pop();
      });
    }
  }

  void _deleteBeneficiary(String id) {
    setState(() {
      _beneficiaries.removeWhere((beneficiary) => beneficiary['id'] == id);
    });
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Beneficiary"),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: "Beneficiary Name"),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _accountController,
                    decoration: InputDecoration(labelText: "Account Number"),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _bankController,
                    decoration: InputDecoration(labelText: "Bank Name"),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _ifscController,
                    decoration: InputDecoration(labelText: "IFSC Code"),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    items: ['Within Bank', 'Other Bank']
                        .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                    decoration: InputDecoration(labelText: "Transfer Type"),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: _addBeneficiary,
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RouteAwareWrapper(
      screenName: 'BeneficiariesPage',
      observer: routeObserver,
      child: GestureWrapper(
        screenName: 'BeneficiariesPage',
        child: Scaffold(
          appBar: AppBar(
            title: Text("Manage Beneficiaries",
              style: TextStyle(color: Colors.white),),
            backgroundColor: Color(0xFF3B5EDF),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: _beneficiaries.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No Beneficiaries Added",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  "Tap the + button to add beneficiaries",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _beneficiaries.length,
            itemBuilder: (context, index) {
              final beneficiary = _beneficiaries[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: beneficiary['type'] == 'Within Bank'
                        ? Colors.blue[100]
                        : Colors.green[100],
                    child: Icon(
                      beneficiary['type'] == 'Within Bank'
                          ? Icons.account_balance
                          : Icons.account_balance_wallet,
                      color: beneficiary['type'] == 'Within Bank'
                          ? Colors.blue
                          : Colors.green,
                    ),
                  ),
                  title: Text(
                    beneficiary['name'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text("A/C: ${beneficiary['accountNumber']}"),
                      Text("Bank: ${beneficiary['bank']}"),
                      Text("IFSC: ${beneficiary['ifsc']}"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteBeneficiary(beneficiary['id']),
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddDialog,
            child: Icon(Icons.add, color: Colors.white),
            backgroundColor: Color(0xFF3B5EDF),
            elevation: 4,
          ),
        ),
      ),
    );
  }
}
