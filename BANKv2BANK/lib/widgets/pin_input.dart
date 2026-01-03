import 'package:flutter/material.dart';

class PinInput extends StatelessWidget {
  final int pinLength;
  final String enteredPin;

  const PinInput({
    Key? key,
    required this.enteredPin,
    this.pinLength = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pinLength, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8),
          padding: EdgeInsets.all(12),
          width: 40,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              index < enteredPin.length ? '●' : '',
              style: TextStyle(fontSize: 24),
            ),
          ),
        );
      }),
    );
  }
}
