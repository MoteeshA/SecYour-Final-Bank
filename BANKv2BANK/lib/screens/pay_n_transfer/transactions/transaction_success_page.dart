import 'package:flutter/material.dart';

class TransactionSuccessPage extends StatelessWidget {
  final String accountNumber;
  final String amount;
  final String remarks;

  const TransactionSuccessPage({
    Key? key,
    required this.accountNumber,
    required this.amount,
    required this.remarks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentTime = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white54,
      body: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          margin: EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 72),
                SizedBox(height: 16),
                Text("Payment Successful",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Text("Your transaction completed successfully"),
                Divider(height: 32),
                _infoRow("Amount", "₹$amount"),
                _infoRow("To", "A/C: $accountNumber"),
                _infoRow("Remarks", remarks.isNotEmpty ? remarks : "-"),
                _infoRow("Date", "${currentTime.toLocal()}"),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text("Done",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}