import 'package:flutter/material.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart';
import 'package:dummy_bank/observer.dart';

class CardsPage extends StatefulWidget {
  @override
  _CardsPageState createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  final List<Map<String, dynamic>> _cards = [
    {
      'id': '1',
      'cardNumber': '•••• •••• •••• 4567',
      'fullNumber': '5123 4567 8912 4567',
      'cvv': '•••',
      'fullCvv': '123',
      'expiry': '12/25',
      'name': 'Harsh Kumar',
      'limit': '₹50,000',
      'isVisible': false,
    },
    {
      'id': '2',
      'cardNumber': '•••• •••• •••• 7890',
      'fullNumber': '4123 4567 9012 7890',
      'cvv': '•••',
      'fullCvv': '456',
      'expiry': '09/24',
      'name': 'Harsh Kumar',
      'limit': '₹75,000',
      'isVisible': false,
    },
  ];

  void _toggleCardVisibility(int index) {
    setState(() {
      _cards[index]['isVisible'] = !_cards[index]['isVisible'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return RouteAwareWrapper(
      screenName: 'CardsPage',
      observer: routeObserver,
      child: GestureWrapper(
        screenName: 'CardsPage',
        child: Scaffold(
          appBar: AppBar(
            title: Text("My Cards", style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF3B5EDF),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: ListView(
            padding: EdgeInsets.all(16),
            children: [
              ..._cards.map((card) => Column(
                children: [
                  // Card Display
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0A2342), Color(0xFF119DA4), Color(0xFF0C7489)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                card['isVisible']
                                    ? card['fullNumber']
                                    : card['cardNumber'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  card['isVisible']
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white,
                                ),
                                onPressed: () => _toggleCardVisibility(
                                    _cards.indexOf(card)),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Card Holder",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    card['name'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Expires",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    card['expiry'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "CVV",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    card['isVisible']
                                        ? card['fullCvv']
                                        : card['cvv'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Limit: ${card['limit']}",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Card Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCardAction(Icons.lock, "Manage PIN", () {
                        // Handle manage PIN
                      }),
                      _buildCardAction(Icons.block, "Block Card", () {
                        // Handle block card
                      }),
                      _buildCardAction(Icons.receipt, "Statements", () {
                        // Handle statements
                      }),
                      _buildCardAction(Icons.money, "Set Limit", () {
                        // Handle set limit
                      }),
                    ],
                  ),
                  SizedBox(height: 24),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardAction(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Color(0xFF3B5EDF)),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
