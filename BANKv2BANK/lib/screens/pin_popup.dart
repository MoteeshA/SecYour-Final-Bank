import 'package:flutter/material.dart';

class PinPopup extends StatefulWidget {
  final void Function(String) onComplete;

  const PinPopup({
    required this.onComplete,
    Key? key,
  }) : super(key: key);

  @override
  _PinPopupState createState() => _PinPopupState();
}

class _PinPopupState extends State<PinPopup> {
  static const int pinLength = 5;
  static const String correctPin = '12345';

  final List<String> _otpDigits = List.filled(pinLength, '');
  final List<FocusNode> _focusNodes = List.generate(pinLength, (index) => FocusNode());
  bool _isError = false;
  bool _isLoading = false;
  int _currentFocusIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    final enteredPIN = _otpDigits.join();

    if (enteredPIN.length != pinLength || enteredPIN != correctPin) {
      setState(() => _isError = true);
      _clearOTPFields();
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(Duration(milliseconds: 500));
      widget.onComplete(enteredPIN);
    } catch (e) {
      setState(() {
        _isError = true;
        _isLoading = false;
      });
      _clearOTPFields();
    }
  }

  void _clearOTPFields() {
    setState(() {
      _otpDigits.fillRange(0, pinLength, '');
      _currentFocusIndex = 0;
      // Keep error flag as is
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  void _onNumberPressed(int number) {
    if (_currentFocusIndex < pinLength) {
      setState(() {
        _otpDigits[_currentFocusIndex] = number.toString();
        if (_currentFocusIndex < pinLength - 1) {
          _currentFocusIndex++;
          FocusScope.of(context).requestFocus(_focusNodes[_currentFocusIndex]);
        }
      });
    }
  }

  void _onBackspacePressed() {
    if (_currentFocusIndex > 0 && _otpDigits[_currentFocusIndex].isEmpty) {
      setState(() => _currentFocusIndex--);
    }
    setState(() {
      _otpDigits[_currentFocusIndex] = '';
    });
    FocusScope.of(context).requestFocus(_focusNodes[_currentFocusIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PIN verification', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF3B5EDF),
        iconTheme: IconThemeData(color: Colors.white),
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 20),
                  Icon(Icons.password_outlined, size: 60, color: Theme.of(context).primaryColor),
                  SizedBox(height: 20),
                  Text(
                    'Verify Your PIN',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Enter your 5-digit PIN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(pinLength, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() => _currentFocusIndex = index);
                          FocusScope.of(context).requestFocus(_focusNodes[index]);
                        },
                        child: Container(
                          width: 45,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 2,
                                color: _currentFocusIndex == index
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _otpDigits[index].isNotEmpty ? '*' : '',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_isError)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Incorrect PIN. Please try again.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : Text('VERIFY', style: TextStyle(fontSize: 16)),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildNumericPad(),
        ],
      ),
    );
  }

  Widget _buildNumericPad() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(width: 80, height: 60), // Empty space
              _buildKeypadButton('0'),
              _buildKeypadButton('⌫', isBackspace: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String text, {bool isBackspace = false}) {
    return SizedBox(
      width: 80,
      height: 60,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: () {
            if (isBackspace) {
              _onBackspacePressed();
            } else {
              _onNumberPressed(int.parse(text));
            }
          },
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isBackspace ? Colors.red : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
