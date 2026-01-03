import 'package:flutter/material.dart';
// import 'transaction_success_page.dart'; // ⬅️ No longer needed
import 'package:dummy_bank/screens/pin_popup.dart';

import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:dummy_bank/observer.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart';

class WithinBankTransferPage extends StatefulWidget {
  const WithinBankTransferPage({Key? key}) : super(key: key);

  @override
  State<WithinBankTransferPage> createState() => _WithinBankTransferPageState();
}

class _WithinBankTransferPageState extends State<WithinBankTransferPage> {
  final _formKey = GlobalKey<FormState>();
  String accountNumber = '';
  String amount = '';
  String remarks = '';

  // 🔊 Text-to-Speech instance
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    // Mark transaction start as user enters the page
    PhishSafeTrackerManager().markTransactionStart();
  }

  /// Set TTS language based on current app locale (English / Odia)
  Future<void> _configureTtsLanguage() async {
    final locale = context.locale;
    String langCode;

    if (locale.languageCode == 'or') {
      // Odia – actual support depends on device TTS engine
      langCode = 'or-IN';
    } else {
      // Default English India
      langCode = 'en-IN';
    }

    await _flutterTts.setLanguage(langCode);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.55);
  }

  Future<void> _speak(String text) async {
    try {
      await _configureTtsLanguage();
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

  /// Called only AFTER user confirms and enters PIN
  void _showPinPopupAndComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PinPopup(
        onComplete: (enteredPin) async {
          // ❌ Do NOT end transaction or logout here
          // PhishSafeTrackerManager().markTransactionEnd();

          // ✅ Record within-bank transfer amount ONLY after confirmation
          PhishSafeTrackerManager().recordWithinBankTransferAmount(amount);

          // Close the PIN popup
          Navigator.of(context).pop();

          // ✅ Show a success dialog but STAY on WithinBankTransferPage
          _showSuccessDialogAndReset();
        },
      ),
    );
  }

  void _showSuccessDialogAndReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('within_bank_success_title'.tr()), // e.g. "Transfer Successful"
        content: Text(
          'within_bank_success_body'.tr(namedArgs: {
            'account': accountNumber,
            'amount': amount,
          }),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog

              // ✅ Reset the form & clear local state
              setState(() {
                accountNumber = '';
                amount = '';
                remarks = '';
              });
              _formKey.currentState?.reset();
            },
            child: Text('within_bank_success_done'.tr()), // "Done"
          ),
        ],
      ),
    );
  }

  Future<void> _submitTransfer() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Beneficiary name is fixed as "Manya" for now
      const beneficiaryName = 'Manya';

      // 🔊 Localized spoken message (English / Odia)
      final speakText = 'within_bank_tts_message'.tr(namedArgs: {
        'amount': amount,
        'beneficiary': beneficiaryName,
      });

      // 1️⃣ Speak the confirmation in current language
      await _speak(speakText);

      // 2️⃣ Show a confirmation dialog on screen
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('within_bank_confirm_title'.tr()),
          content: Text(
            'within_bank_confirm_body'.tr(namedArgs: {
              'beneficiary': beneficiaryName,
              'account': accountNumber,
              'amount': amount,
            }),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Cancel
              },
              child: Text('within_bank_confirm_cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close dialog
                // 3️⃣ Now show PIN popup & complete flow
                _showPinPopupAndComplete();
              },
              child: Text('within_bank_confirm_confirm'.tr()),
            ),
          ],
        ),
      );
    }
  }

  /// Helper to map tap local position to a 3x3 zone string
  String getTapZone(Offset localPosition, Size size) {
    final zoneWidth = size.width / 3;
    final zoneHeight = size.height / 3;

    final col = (localPosition.dx / zoneWidth).floor().clamp(0, 2);
    final row = (localPosition.dy / zoneHeight).floor().clamp(0, 2);

    const zoneMap = {
      0: {0: 'top_left', 1: 'top_center', 2: 'top_right'},
      1: {0: 'middle_left', 1: 'center', 2: 'middle_right'},
      2: {0: 'bottom_left', 1: 'bottom_center', 2: 'bottom_right'},
    };

    return zoneMap[row]?[col] ?? 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (TapDownDetails details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final size = box.size;

        final zone = getTapZone(localPosition, size);

        PhishSafeTrackerManager().recordTapPosition(
          screenName: 'WithinBankTransferPage',
          tapPosition: details.globalPosition,
          tapZone: zone,
        );
      },
      child: RouteAwareWrapper(
        screenName: 'WithinBankTransferPage',
        observer: routeObserver,
        child: GestureWrapper(
          screenName: 'WithinBankTransferPage',
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'within_bank_appbar_title'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
              backgroundColor: const Color(0xFF3B5EDF),
              iconTheme: const IconThemeData(
                color: Colors.white,
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildField(
                      label: 'within_bank_beneficiary_label'.tr(),
                      hint: 'within_bank_beneficiary_hint'.tr(),
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                      val == null || val.isEmpty
                          ? 'within_bank_error_required'.tr()
                          : null,
                      onSaved: (val) => accountNumber = val ?? '',
                    ),
                    _buildField(
                      label: 'within_bank_amount_label'.tr(),
                      hint: 'within_bank_amount_hint'.tr(),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'within_bank_error_required'.tr();
                        }
                        final n = num.tryParse(val);
                        if (n == null || n <= 0) {
                          return 'within_bank_error_amount_invalid'.tr();
                        }
                        return null;
                      },
                      onSaved: (val) => amount = val ?? '',
                    ),
                    _buildField(
                      label: 'within_bank_remarks_label'.tr(),
                      hint: 'within_bank_remarks_hint'.tr(),
                      keyboardType: TextInputType.text,
                      validator: null,
                      onSaved: (val) => remarks = val ?? '',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitTransfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B5EDF),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Text(
                        'within_bank_proceed_button'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
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
    required Function(String?) onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }
}
