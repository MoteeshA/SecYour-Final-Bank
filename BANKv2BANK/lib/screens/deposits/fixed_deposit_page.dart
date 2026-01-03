import 'package:flutter/material.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart'; // <-- Make sure this is imported
import 'package:dummy_bank/observer.dart';

class FixedDepositPage extends StatefulWidget {
  @override
  _FixedDepositPageState createState() => _FixedDepositPageState();
}

class _FixedDepositPageState extends State<FixedDepositPage> {
  final Color primaryBlue = Color(0xFF3B5EDF);

  @override
  Widget build(BuildContext context) {
    return RouteAwareWrapper(
      screenName: 'FixedDepositPage',
      observer: routeObserver,
      child: GestureWrapper(
        screenName: 'FixedDepositPage',
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              "Fixed Deposits",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF3B5EDF),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current FDs Section
                _buildSectionHeader("Your Fixed Deposits"),
                _buildFDItem(
                  "FD-456789",
                  "₹1,50,000",
                  "6.75%",
                  "15 May 2025",
                  Icons.account_balance,
                ),
                _buildFDItem(
                  "FD-987654",
                  "₹2,00,000",
                  "7.25%",
                  "22 Dec 2024",
                  Icons.savings,
                ),
                SizedBox(height: 24),

                // New FD Card
                _buildNewFDCard(),

                SizedBox(height: 24),

                // FD Rates Table
                _buildSectionHeader("Current Interest Rates"),
                _buildRateTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFDItem(String id, String amount, String rate, String maturity, IconData icon) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryBlue, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    id,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Amount: $amount • $rate",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Matures on",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  maturity,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewFDCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B5EDF), Color(0xFF4C84EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                "Create New FD",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            "Get higher returns with interest rates up to 7.5%",
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              "Start Now",
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text("Tenure", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Text("General",
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text("Senior",
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          // Table Rows
          _buildRateRow("7-14 Days", "4.50%", "5.00%"),
          _buildRateRow("15-29 Days", "5.00%", "5.50%"),
          _buildRateRow("30-45 Days", "5.50%", "6.00%"),
          _buildRateRow("46-90 Days", "6.00%", "6.50%"),
          _buildRateRow("91-180 Days", "6.50%", "7.00%"),
          _buildRateRow("181-364 Days", "7.00%", "7.50%"),
          _buildRateRow("1 Year", "7.25%", "7.75%", isLast: true),
        ],
      ),
    );
  }

  Widget _buildRateRow(String tenure, String general, String senior, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(tenure, style: TextStyle(color: Colors.grey.shade800)),
            ),
            Expanded(
              child: Text(general,
                  style: TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ),
            Expanded(
              child: Text(senior,
                  style: TextStyle(fontWeight: FontWeight.w600, color: primaryBlue),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
