import 'package:flutter/material.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart'; // <-- Add this import
import 'package:dummy_bank/observer.dart';

class OTPVerificationPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final Function(String) onVerificationComplete;
  final Function() onResendCode;
  final Function() onCancel;

  const OTPVerificationPage({
    required this.onVerificationComplete,
    required this.onResendCode,
    required this.onCancel,
    this.verificationId = '',
    this.phoneNumber = '',
    Key? key,
  }) : super(key: key);

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final List<String> _otpDigits = List.filled(6, '');
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isError = false;
  int _resendCountdown = 30;
  bool _isLoading = false;
  int _currentFocusIndex = 0;
  List<bool> _showDigit = List.filled(6, false);

  void _startResendTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() => _resendCountdown--);
        _startResendTimer();
      }
    });
  }

  Future<void> _verifyOTP() async {
    final enteredOTP = _otpDigits.join();

    if (enteredOTP.length != 6) {
      setState(() => _isError = true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(Duration(milliseconds: 500));
      widget.onVerificationComplete(enteredOTP);
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
      _otpDigits.fillRange(0, 6, '');
      _currentFocusIndex = 0;
      _isError = false;
      _showDigit.fillRange(0, 6, false);
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  void _onNumberPressed(int number) {
    if (_currentFocusIndex < 6) {
      setState(() {
        _otpDigits[_currentFocusIndex] = number.toString();
        _showDigit[_currentFocusIndex] = true;

        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _showDigit[_currentFocusIndex] = false;
              if (_currentFocusIndex < 5) {
                _currentFocusIndex++;
                FocusScope.of(context).requestFocus(_focusNodes[_currentFocusIndex]);
              }
            });
          }
        });
      });
    }
  }

  void _onBackspacePressed() {
    if (_currentFocusIndex > 0 && _otpDigits[_currentFocusIndex].isEmpty) {
      setState(() => _currentFocusIndex--);
    }
    setState(() {
      _otpDigits[_currentFocusIndex] = '';
      _showDigit[_currentFocusIndex] = false;
    });
    FocusScope.of(context).requestFocus(_focusNodes[_currentFocusIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return RouteAwareWrapper(
      screenName: 'OTPVerificationPage',
      observer: routeObserver,
      child: GestureWrapper(
        screenName: 'OTPVerificationPage',
        child: Scaffold(
          appBar: AppBar(
            title: Text('OTP Verification', style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF3B5EDF),
            iconTheme: IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: widget.onCancel,
            ),
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
                      Icon(Icons.sms_outlined, size: 60, color: Theme.of(context).primaryColor),
                      SizedBox(height: 20),
                      Text(
                        'Verify Your Number',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        widget.phoneNumber.isNotEmpty
                            ? 'Enter the OTP sent to ${widget.phoneNumber}'
                            : 'Enter the 6-digit OTP sent to your mobile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
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
                                  _showDigit[index] || _otpDigits[index].isEmpty
                                      ? _otpDigits[index]
                                      : '*',
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
                            'Invalid OTP. Please try again',
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Didn\'t receive the code? '),
                          TextButton(
                            onPressed: _resendCountdown == 0 && !_isLoading
                                ? () {
                              setState(() => _resendCountdown = 30);
                              _startResendTimer();
                              widget.onResendCode();
                            }
                                : null,
                            child: Text(
                              _resendCountdown == 0
                                  ? 'Resend OTP'
                                  : 'Resend in $_resendCountdown seconds',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildNumericPad(),
            ],
          ),
        ),
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
