import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ===================================================================
//  TWILIO CONFIG – same values as in registration.dart
//  (⚠️ In production, move these to a secure backend or .env)
// ===================================================================
const String _twilioAccountSid = 'REMOVED_TWILIO_SID';
const String _twilioAuthToken = '5634e36661315510658327b090905cc4';
const String _twilioVerifyServiceSid = 'VAfeb60a838a103b8411b75e90a4fddf05';

class BehaviourManager {
  // Trust Score Variables
  int _trustScore = 100;
  Map<String, dynamic>? _userBaseline;

  // Behavior thresholds
  static const int _veryShortSessionThreshold = 10;
  static const int _highRiskActionThreshold = 3;
  static const int _veryFastTapThreshold = 100;
  static const int _verySlowTapThreshold = 2000;
  static const int _excessiveScrollThreshold = 20;
  static const int _screenRevisitThreshold = 5;
  static const int _otpSkipThreshold = 2;
  static const int _rapidScreenTransitionThreshold = 3;
  static const int _failedPinThreshold = 3;
  static const int _multipleLoansThreshold = 3;
  static const int _rapidTapBurstThreshold = 3;
  static const int _inactiveAreaThreshold = 3;
  static const int _rapidAccountSwitchThreshold = 3;
  static const int _failedAuthThreshold = 3;

  // Timers and counters
  DateTime? _sessionStartTime;
  int _highRiskActionCount = 0;
  int _scrollCount = 0;
  final Map<String, int> _screenVisitCounts = {};
  int _otpSkipCount = 0;
  int _failedPinCount = 0;
  int _loansViewedCount = 0;
  int _inactiveAreaTapCount = 0;
  int _accountSwitchCount = 0;
  int _failedAuthCount = 0;
  Timer? _scrollResetTimer;
  Timer? _highRiskActionResetTimer;
  Timer? _tapSpeedTimer;
  Timer? _accountSwitchResetTimer;
  final List<DateTime> _recentTaps = [];

  // Context & logs
  BuildContext? _context;
  final List<Map<String, dynamic>> _behaviorLogs = [];
  final List<int> _appliedPenalties = [];
  int _authResetCount = 0;
  static const int _maxAuthResets = 3;
  VoidCallback? _onLogout;

  // NEW: Separate flags
  bool _otpSmsSentThisSession = false;     // has SMS been sent this session?
  bool _otpVerifiedThisSession = false;    // has OTP been successfully verified this session?

  // (old backendUrl kept if you ever want Flask again – not used for OTP now)
  static const String backendUrl = "http://172.20.10.2:5001/";

  // Behavior → Penalty Mapping
  static const Map<int, int> _behaviourPenalties = {
    1: -15,
    2: -15,
    3: -15,
    4: -10,
    5: -15,
    6: -6,
    7: -6,
    8: -10,
    9: -6,
    10: -6,
    11: -6,
    12: -6,
    13: -6,
    14: -5,
    15: -4,
    16: -4,
    17: -6,
    18: -4,
    19: -6,
    20: -4,
    21: -10,
    22: -4,
    23: -6,
    24: -5,
    25: -5,
    26: -4,
    27: -4,
    28: -4,
    29: -4,
    30: -4,
    33: -15,
    34: -15,
    42: -10,
    43: -15,
    44: -15,
    45: -20,
    50: -15,
  };

  // Singleton
  static final BehaviourManager _instance = BehaviourManager._internal();
  factory BehaviourManager() => _instance;
  BehaviourManager._internal() {
    _initializeBaseline();
  }

  // ======================
  // Public Interface
  // ======================

  void setLogoutCallback(VoidCallback callback) => _onLogout = callback;
  int get trustScore => _trustScore;
  int getTrustScore() => _trustScore;
  List<int> getAppliedPenalties() => _appliedPenalties;
  List<Map<String, dynamic>> getBehaviorLogs() => _behaviorLogs;
  void setContext(BuildContext context) => _context = context;

  // ======================
  // Session Management
  // ======================

  void startSession(BuildContext context) {
    _context = context;
    _sessionStartTime = DateTime.now();
    _resetCounters();
    _authResetCount = 0;
    _otpSmsSentThisSession = false;
    _otpVerifiedThisSession = false;
    print(" Behavior monitoring session started");
    _checkForBaselineCreation();
  }

  void endSession() {
    _sessionStartTime = null;
    _resetCounters();
    _scrollResetTimer?.cancel();
    _highRiskActionResetTimer?.cancel();
    _tapSpeedTimer?.cancel();
    _accountSwitchResetTimer?.cancel();
    _otpSmsSentThisSession = false;
    _otpVerifiedThisSession = false;
    print(" Behavior monitoring session ended");
  }

  // ======================
  // Behavior Tracking
  // ======================

  void trackFDBroken() {
    detectBehavior(2);
    print(" FD broken behavior tracked");
  }

  void trackOtpSkip() {
    _otpSkipCount++;
    if (_otpSkipCount >= _otpSkipThreshold) detectBehavior(10);
    print(" OTP skip tracked (count: $_otpSkipCount)");
  }

  void trackLoanViewed() {
    _loansViewedCount++;
    if (_loansViewedCount >= _multipleLoansThreshold) detectBehavior(23);
    print(" Loan viewed tracked (count: $_loansViewedCount)");
  }

  void trackInactiveAreaTap() {
    _inactiveAreaTapCount++;
    if (_inactiveAreaTapCount >= _inactiveAreaThreshold) detectBehavior(22);
    print(" Inactive area tap tracked (count: $_inactiveAreaTapCount)");
  }

  void trackScreenVisit(String screenName) {
    _screenVisitCounts.update(screenName, (count) => count + 1, ifAbsent: () => 1);
    print(" Screen visit tracked: $screenName (count: ${_screenVisitCounts[screenName]})");
    if (_screenVisitCounts[screenName]! >= _screenRevisitThreshold) detectBehavior(9);
  }

  void trackImmediateTransaction() {
    detectBehavior(1);
    print(" Immediate transaction after login detected");
  }

  void trackLoanApplication() {
    detectBehavior(3);
    print(" Loan application after login detected");
  }

  void trackInactiveToActiveTransfer() {
    detectBehavior(33);
    print(" Sudden transfer after inactivity detected");
  }

  void trackQuickFDWithdrawal() {
    detectBehavior(34);
    print(" FD created and quickly withdrawn detected");
  }

  void trackAccountSwitching() {
    _accountSwitchCount++;
    _accountSwitchResetTimer?.cancel();
    _accountSwitchResetTimer = Timer(const Duration(seconds: 5), () {
      _accountSwitchCount = 0;
    });

    print(" Account switch tracked (count: $_accountSwitchCount)");
    if (_accountSwitchCount >= _rapidAccountSwitchThreshold) {
      detectBehavior(42);
      print(" Multiple account switches detected");
    }
  }

  void trackOtpBypassAttempt() {
    detectBehavior(43);
    print(" OTP bypass attempt detected");
  }

  void trackFailedAuthentication() {
    _failedAuthCount++;
    print(" Failed authentication tracked (count: $_failedAuthCount)");
    if (_failedAuthCount >= _failedAuthThreshold) {
      detectBehavior(44);
      print(" Multiple failed authentications detected");
    }
  }

  void trackLargeTransaction(double amount) {
    print(" Large transaction amount tracked: ₹$amount");
    if (amount >= 50000) {
      detectBehavior(50, amount);
      print(" Large transaction detected: ₹$amount");
    }
  }

  void trackScreenRecordingDetected() {
    detectBehavior(45);
    print(" Screen recording detected");
  }

  // ======================
  // Core Detection Logic
  // ======================

  void detectBehavior(int behaviorId, [dynamic extraData]) {
    if (!_behaviourPenalties.containsKey(behaviorId)) {
      print(" Unknown behavior ID: $behaviorId");
      return;
    }

    _behaviorLogs.add({
      'id': behaviorId,
      'timestamp': DateTime.now().toIso8601String(),
      'penalty': _behaviourPenalties[behaviorId],
      'description': _getBehaviorDescription(behaviorId),
      'extra_data': extraData,
    });

    applyBehaviour(behaviorId);

    switch (behaviorId) {
      case 1:
        print(" Transaction immediately after login detected");
        break;
      case 2:
        print(" Fixed deposit broken behavior detected");
        break;
      case 3:
        print(" Loan application right after login detected");
        break;
      case 4:
        _handleVeryShortSession();
        break;
      case 5:
        _handleHighRiskActions();
        break;
      case 6:
      case 7:
        _handleTapSpeed(behaviorId, extraData as int?);
        break;
      case 8:
        _handleExcessiveScrolling();
        break;
      case 9:
        print(" Repeated screen revisits detected");
        break;
      case 10:
        print(" OTP skip detected");
        break;
      case 21:
        _handleFailedPinAttempts();
        break;
      case 22:
        print(" Tapping in inactive areas detected");
        break;
      case 23:
        print(" Multiple loans viewed without applying");
        break;
      case 33:
        print(" Sudden transfer after inactivity detected");
        break;
      case 34:
        print(" FD created and quickly withdrawn detected");
        break;
      case 42:
        print(" Multiple account switches detected");
        break;
      case 43:
        print(" OTP bypass attempt detected");
        break;
      case 44:
        print(" Multiple failed authentications detected");
        break;
      case 45:
        print(" Screen recording detected");
        break;
      case 50:
        print(" Large transaction detected: ₹${extraData ?? 'unknown amount'}");
        break;
    }
  }

  String _getBehaviorDescription(int id) {
    switch (id) {
      case 1:
        return 'Immediate transaction after login';
      case 2:
        return 'FD broken';
      case 3:
        return 'Loan application after login';
      case 4:
        return 'Very short session';
      case 5:
        return 'Multiple high-risk actions';
      case 6:
        return 'Very fast tap';
      case 7:
        return 'Very slow tap';
      case 8:
        return 'Excessive scrolling';
      case 9:
        return 'Repeated screen revisits';
      case 10:
        return 'OTP skip';
      case 21:
        return 'Multiple failed PIN attempts';
      case 22:
        return 'Tapping in inactive areas';
      case 23:
        return 'Multiple loans viewed without applying';
      case 33:
        return 'Sudden transfer after inactivity';
      case 34:
        return 'FD created and quickly withdrawn';
      case 42:
        return 'Multiple account switches';
      case 43:
        return 'OTP bypass attempt';
      case 44:
        return 'Multiple failed authentications';
      case 45:
        return 'Screen recording detected';
      case 50:
        return 'Large transaction';
      default:
        return 'Unknown behavior';
    }
  }

  void applyBehaviour(int behaviourId) {
    final penalty = _behaviourPenalties[behaviourId] ?? 0;
    _trustScore += penalty;
    _trustScore = _trustScore.clamp(0, 100);
    _appliedPenalties.add(behaviourId);
    print(" Behavior $behaviourId detected → Penalty $penalty → Trust: $_trustScore");
    _checkAndShowPopup();
  }

  // ======================
  // Trust Score Calculation
  // ======================

  double calculateFinalTrustScore({
    required int sessionCount,
    required double mlModelScore,
    required Map<String, dynamic> currentSession,
  }) {
    int totalPenalty = _appliedPenalties
        .map((id) => BehaviourManager._behaviourPenalties[id] ?? 0)
        .fold(0, (a, b) => a + b);
    double behavioralScore =
    (100 + totalPenalty).clamp(0, 100).toDouble();
    double mlScore = (mlModelScore.clamp(0.0, 1.0)) * 100;

    if (_userBaseline == null || sessionCount < 5) {
      print(" No baseline yet. Using: 70% Behavior + 30% ML");
      return (behavioralScore * 0.7) + (mlScore * 0.3);
    }

    double profileScore =
    _computeUserProfileScore(_userBaseline!, currentSession);
    print(" Baseline ready. Using: 60% Profile + 30% ML + 10% Behavior");

    return (profileScore * 0.6) +
        (mlScore * 0.3) +
        (behavioralScore * 0.1);
  }

  double _computeUserProfileScore(
      Map<String, dynamic> baseline, Map<String, dynamic> session) {
    final tapDuration = (baseline['avg_tap_ms'] ?? 0).toDouble();
    final swipeSpeed = (baseline['avg_swipe_speed'] ?? 0).toDouble();
    final tapSamples = (baseline['tap_samples'] ?? 0).toDouble();
    final swipeSamples = (baseline['swipe_samples'] ?? 0).toDouble();

    final taps = session['tap_durations_ms'] ?? [];
    final swipes = session['swipe_events'] ?? [];

    double avgTap = taps is List && taps.isNotEmpty
        ? taps
        .map((e) => (e as num).toDouble())
        .reduce((a, b) => a + b) /
        taps.length
        : tapDuration;

    double avgSwipe = swipes is List && swipes.isNotEmpty
        ? swipes
        .map((e) => (e['speed_px_per_ms'] ?? 0.0).toDouble())
        .reduce((a, b) => a + b) /
        swipes.length
        : swipeSpeed;

    double tapDeviation = (avgTap - tapDuration).abs();
    double swipeDeviation = (avgSwipe - swipeSpeed).abs();

    double tapScore =
        100 -
            ((tapDeviation / (tapDuration == 0 ? 1 : tapDuration)) *
                100)
                .clamp(0, 100);
    double swipeScore =
        100 -
            ((swipeDeviation / (swipeSpeed == 0 ? 1 : swipeSpeed)) *
                100)
                .clamp(0, 100);

    double totalSamples = tapSamples + swipeSamples;
    if (totalSamples > 0) {
      return ((tapScore * tapSamples) + (swipeScore * swipeSamples)) /
          totalSamples;
    } else {
      return (tapScore + swipeScore) / 2;
    }
  }

  // ======================
  // Baseline Functionality
  // ======================

  Future<void> _initializeBaseline() async {
    try {
      await _loadUserBaseline();
      if (_userBaseline == null) {
        await _checkForBaselineCreation();
      }
    } catch (e) {
      print(" Error initializing baseline: $e");
    }
  }

  Future<void> _loadUserBaseline() async {
    try {
      final file = File('/sdcard/Download/PhishSafe/user_profile.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        _userBaseline = jsonDecode(contents);
        print(" Loaded user baseline: $_userBaseline");
      } else {
        print(" No baseline file found at ${file.path}");
      }
    } catch (e) {
      print(" Error loading baseline: $e");
    }
  }

  Future<void> _checkForBaselineCreation() async {
    try {
      final baselineBuilder = BaselineBuilder();
      final sessionFiles = await baselineBuilder.getSessionFiles();
      print(" Found ${sessionFiles.length} session logs");

      final isBuilt = await baselineBuilder.isBaselineBuilt();

      if (!isBuilt || sessionFiles.length % 5 == 0) {
        print(" Rebuilding baseline from latest 5 sessions...");
        final baseline = await baselineBuilder.buildBaselineFromFirst5();
        await baselineBuilder.saveBaseline(baseline);
        _userBaseline = baseline;
        print(" Baseline auto-updated from latest sessions");
      } else {
        print(" Baseline already exists and not due for update");
        await _loadUserBaseline();
      }
    } catch (e) {
      print(" Error during baseline check/update: $e");
    }
  }

  void recordTapDuration({required String screenName, required int durationMs}) {
    _recentTaps.add(DateTime.now());
    _recentTaps.removeWhere(
            (tap) => DateTime.now().difference(tap).inSeconds > 5);

    if (_recentTaps.length >= _rapidTapBurstThreshold) {
      final timeDiff =
          _recentTaps.last.difference(_recentTaps.first).inMilliseconds;
      if (timeDiff > 0) {
        final tapsPerSecond =
            (_recentTaps.length / timeDiff) * 1000;
        if (tapsPerSecond > _rapidTapBurstThreshold) {
          detectBehavior(19);
        }
      }
    }

    if (_userBaseline != null &&
        _userBaseline!.containsKey('avg_tap_ms')) {
      double avg = (_userBaseline!['avg_tap_ms'] ?? 0).toDouble();
      if (durationMs < avg * 0.5) {
        detectBehavior(6, durationMs);
      } else if (durationMs > avg * 2.0) {
        detectBehavior(7, durationMs);
      }
    } else {
      if (durationMs < _veryFastTapThreshold) {
        detectBehavior(6, durationMs);
      } else if (durationMs > _verySlowTapThreshold) {
        detectBehavior(7, durationMs);
      }
    }
  }

  void recordSwipe({required double speed}) {
    if (_userBaseline != null &&
        _userBaseline!.containsKey('avg_swipe_speed')) {
      double avg =
      (_userBaseline!['avg_swipe_speed'] ?? 0).toDouble();
      if (speed < avg * 0.5) {
        detectBehavior(14);
      } else if (speed > avg * 2.0) {
        detectBehavior(15);
      }
    }
  }

  // ======================
  // Popup & Auth Logic
  // ======================

  void _checkAndShowPopup() {
    if (_context == null) {
      print(" Cannot show popup - no context available");
      return;
    }

    if (_authResetCount >= _maxAuthResets) {
      print(" Max authentication resets reached");
      return;
    }

    switch (currentAction) {
      case 'logout':
        _showLogoutDialog();
        break;
      case 'otp':
      // Multiple OTP popups allowed, but only one SMS and stop once verified
        if (_otpVerifiedThisSession) {
          print(" OTP already verified this session, no more OTP needed");
          return;
        }
        _showOtpDialog();
        break;
      case 'auth_question':
        _showQuestionDialog();
        break;
      case 'safe':
        print(" Trust score is safe: $_trustScore");
        return;
    }
  }

  // trustScore:
  // 0–20   => logout
  // 21–40  => OTP
  // 41–70  => auth question
  // 71–100 => safe
  String get currentAction {
    if (_trustScore <= 20) return 'logout';
    if (_trustScore <= 40) return 'otp'; // 20–40 = OTP band
    if (_trustScore <= 70) return 'auth_question';
    return 'safe';
  }

  void _showLogoutDialog() {
    if (_context == null || !Navigator.of(_context!).mounted) return;

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text(' Logged Out'),
        content: const Text(
            'You are logged out due to suspicious activity.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(_context!);
              await Future.delayed(
                  const Duration(milliseconds: 300));
              _performLogout();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    _resetCounters();
    _trustScore = 100;
    _otpSmsSentThisSession = false;
    _otpVerifiedThisSession = false;
    endSession();

    if (_onLogout != null) {
      _onLogout!();
    } else if (_context != null &&
        Navigator.of(_context!).mounted) {
      try {
        Navigator.of(_context!).pushNamedAndRemoveUntil(
          '/login',
              (Route<dynamic> route) => false,
        );
      } catch (e) {
        print(" Logout navigation failed: $e");
      }
    }
    print(" User logged out due to suspicious activity");
  }

  // ==========================================================
  //  OTP POPUP USING TWILIO VERIFY – multiple popups,
  //  one SMS per session, master code 123456
  // ==========================================================
  void _showOtpDialog() async {
    if (_context == null || !Navigator.of(_context!).mounted) return;

    final prefs = await SharedPreferences.getInstance();
    String phone = prefs.getString("phone") ?? "";

    if (phone.isEmpty) {
      print("⚠️ No registered phone found in SharedPreferences");
      return;
    }

    // Normalize to +91XXXXXXXXXX
    if (!phone.startsWith('+')) {
      phone = '+91${phone.replaceAll(RegExp(r'^\+?91'), '')}';
    }

    final authHeader = 'Basic ' +
        base64Encode(
            utf8.encode('$_twilioAccountSid:$_twilioAuthToken'));

    // 1) SEND OTP via Twilio ONLY ONCE per session
    if (!_otpSmsSentThisSession) {
      final sendUri = Uri.https(
        'verify.twilio.com',
        '/v2/Services/$_twilioVerifyServiceSid/Verifications',
      );

      try {
        final sendResp = await http.post(
          sendUri,
          headers: {
            'Authorization': authHeader,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'To': phone,
            'Channel': 'sms',
          },
        );

        if (sendResp.statusCode < 200 ||
            sendResp.statusCode >= 300) {
          print(
              "❌ Twilio send error: ${sendResp.statusCode} ${sendResp.body}");
          ScaffoldMessenger.of(_context!).showSnackBar(
            const SnackBar(content: Text('Error sending OTP')),
          );
          return;
        }

        _otpSmsSentThisSession = true; // mark SMS as sent
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(content: Text('OTP sent to $phone')),
        );
      } catch (e) {
        print("❌ Exception sending OTP: $e");
        return;
      }
    } else {
      print("Reusing existing OTP, not sending new SMS");
    }

    // 2) SHOW DIALOG + VERIFY
    final TextEditingController _otpCtrl = TextEditingController();

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('OTP Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter the OTP sent to $phone"),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              decoration:
              const InputDecoration(hintText: 'Enter OTP'),
            ),
          ],
        ),
        actions: [
          // CANCEL button → treated as failure
          TextButton(
            onPressed: () {
              Navigator.pop(_context!);
              applyBehaviour(10); // OTP skip / failure
              ScaffoldMessenger.of(_context!).showSnackBar(
                const SnackBar(content: Text('OTP cancelled')),
              );
            },
            child: const Text('Cancel'),
          ),
          // OK button
          TextButton(
            onPressed: () async {
              final code = _otpCtrl.text.trim();

              // Empty code → treat as cancel/failure
              if (code.isEmpty) {
                Navigator.pop(_context!);
                applyBehaviour(10);
                ScaffoldMessenger.of(_context!).showSnackBar(
                  const SnackBar(
                      content: Text('OTP not entered')),
                );
                return;
              }

              // Master dev code: 123456 → immediate success (no Twilio)
              if (code == '123456') {
                Navigator.pop(_context!);
                _authResetCount++;
                _otpVerifiedThisSession = true;
                restoreTrust();
                ScaffoldMessenger.of(_context!).showSnackBar(
                  const SnackBar(
                      content: Text('Trust score restored')),
                );
                return;
              }

              // If not 6-digit, treat as failure immediately
              if (code.length != 6) {
                Navigator.pop(_context!);
                applyBehaviour(10);
                ScaffoldMessenger.of(_context!).showSnackBar(
                  const SnackBar(content: Text('Incorrect OTP')),
                );
                return;
              }

              final verifyUri = Uri.https(
                'verify.twilio.com',
                '/v2/Services/$_twilioVerifyServiceSid/VerificationCheck',
              );

              try {
                final verifyResp = await http.post(
                  verifyUri,
                  headers: {
                    'Authorization': authHeader,
                    'Content-Type':
                    'application/x-www-form-urlencoded',
                  },
                  body: {
                    'To': phone,
                    'Code': code,
                  },
                );

                final data = jsonDecode(verifyResp.body)
                as Map<String, dynamic>?;

                if (verifyResp.statusCode >= 200 &&
                    verifyResp.statusCode < 300 &&
                    data != null &&
                    data['status'] == 'approved') {
                  Navigator.pop(_context!);
                  _authResetCount++;
                  _otpVerifiedThisSession = true;
                  restoreTrust();
                  ScaffoldMessenger.of(_context!).showSnackBar(
                    const SnackBar(
                        content: Text('Trust score restored')),
                  );
                } else {
                  Navigator.pop(_context!);
                  // failure, but we do NOT block future popups
                  applyBehaviour(10); // treat as OTP failure
                  ScaffoldMessenger.of(_context!).showSnackBar(
                    const SnackBar(content: Text('Incorrect OTP')),
                  );
                }
              } catch (e) {
                Navigator.pop(_context!);
                print("❌ Exception verifying OTP: $e");
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showQuestionDialog() async {
    if (_context == null || !Navigator.of(_context!).mounted) return;

    final prefs = await SharedPreferences.getInstance();
    String savedQuestion =
        prefs.getString("security_question") ?? "Security Question";
    String savedAnswer = prefs.getString("security_answer") ?? "";

    TextEditingController _answerController =
    TextEditingController();

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Authentication Question'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(savedQuestion),
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                  hintText: 'Answer here'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_answerController.text
                  .trim()
                  .toLowerCase() ==
                  savedAnswer.toLowerCase()) {
                Navigator.pop(_context!);
                _authResetCount++;
                restoreTrust();
                ScaffoldMessenger.of(_context!).showSnackBar(
                  const SnackBar(
                      content: Text('Trust score restored')),
                );
              } else {
                Navigator.pop(_context!);
                applyBehaviour(44);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ======================
  // Helper Handlers & Reset
  // ======================

  void _handleVeryShortSession() {
    if (_sessionStartTime == null) return;
    final sessionDuration =
        DateTime.now().difference(_sessionStartTime!).inSeconds;
    if (sessionDuration < _veryShortSessionThreshold) {
      print(
          " Very short session detected: $sessionDuration seconds");
    }
  }

  void _handleHighRiskActions() {
    _highRiskActionCount++;
    _highRiskActionResetTimer?.cancel();
    _highRiskActionResetTimer =
        Timer(const Duration(seconds: 10), () {
          _highRiskActionCount = 0;
        });

    if (_highRiskActionCount >= _highRiskActionThreshold) {
      print(
          " Multiple high-risk actions detected: $_highRiskActionCount");
    }
  }

  void _handleTapSpeed(int behaviorId, int? tapDurationMs) {
    if (tapDurationMs == null) return;
    if (behaviorId == 6 &&
        tapDurationMs < _veryFastTapThreshold) {
      print(" Very fast tap detected: $tapDurationMs ms");
    } else if (behaviorId == 7 &&
        tapDurationMs > _verySlowTapThreshold) {
      print(" Very slow tap detected: $tapDurationMs ms");
    }
  }

  void _handleExcessiveScrolling() {
    _scrollCount++;
    _scrollResetTimer?.cancel();
    _scrollResetTimer =
        Timer(const Duration(seconds: 5), () {
          _scrollCount = 0;
        });

    if (_scrollCount >= _excessiveScrollThreshold) {
      print(
          " Excessive scrolling detected: $_scrollCount scrolls");
    }
  }

  void _handleFailedPinAttempts() {
    _failedPinCount++;
    if (_failedPinCount >= _failedPinThreshold) {
      print(
          " Multiple failed PIN attempts: $_failedPinCount");
    }
  }

  void _resetCounters() {
    _highRiskActionCount = 0;
    _scrollCount = 0;
    _screenVisitCounts.clear();
    _otpSkipCount = 0;
    _failedPinCount = 0;
    _loansViewedCount = 0;
    _inactiveAreaTapCount = 0;
    _accountSwitchCount = 0;
    _failedAuthCount = 0;
    _recentTaps.clear();
    _appliedPenalties.clear();
  }

  void restoreTrust() {
    _trustScore = 100;
    _resetCounters();
    // Do NOT reset _otpSmsSentThisSession or _otpVerifiedThisSession here.
    // They are managed where needed.
    print(" Trust score restored to 100.");
  }

  void printTrustScoreDebug() {
    print(" Trust Score: $_trustScore");
    print(" Penalties Applied: $_appliedPenalties");
    print(
        " Recent Behaviors: ${_behaviorLogs.take(5).toList()}");
  }
}

// ======================
// BaselineBuilder
// ======================

class BaselineBuilder {
  static const sessionFolder = '/sdcard/Download/PhishSafe';
  static const profileFile = 'user_profile.json';

  Future<bool> isBaselineBuilt() async {
    try {
      final file = File('$sessionFolder/$profileFile');
      return await file.exists();
    } catch (e) {
      print(" Error checking baseline existence: $e");
      return false;
    }
  }

  Future<List<File>> getSessionFiles() async {
    try {
      final dir = Directory(sessionFolder);
      if (!(await dir.exists())) {
        print(
            " Creating PhishSafe directory as it doesn't exist");
        await dir.create(recursive: true);
        return [];
      }

      final files = (await dir.list().toList())
          .whereType<File>()
          .where((f) =>
          basename(f.path).startsWith('session_log'))
          .toList();

      files.sort((a, b) => a.path.compareTo(b.path));
      print(" Found ${files.length} session logs");
      return files;
    } catch (e) {
      print(" Error getting session files: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> buildBaselineFromFirst5() async {
    try {
      final files = await getSessionFiles();
      final sessions = <Map<String, dynamic>>[];

      print(
          " Processing ${files.length >= 5 ? 5 : files.length} sessions...");

      for (var i = 0;
      i < (files.length >= 5 ? 5 : files.length);
      i++) {
        try {
          final content = await files[i].readAsString();
          sessions.add(jsonDecode(content));
          print(
              " Processed session ${i + 1}/${files.length >= 5 ? 5 : files.length}");
        } catch (e) {
          print(
              " Error reading session file ${files[i].path}: $e");
        }
      }

      double totalTap = 0;
      int tapCount = 0;
      double totalSwipe = 0;
      int swipeCount = 0;

      for (var session in sessions) {
        final taps = session['tap_durations_ms'];
        if (taps is List) {
          for (var ms in taps) {
            if (ms is num) {
              totalTap += ms.toDouble();
              tapCount++;
            }
          }
        } else if (taps is Map) {
          taps.forEach((_, ms) {
            if (ms is num) {
              totalTap += ms.toDouble();
              tapCount++;
            }
          });
        }

        final swipes = session['swipe_events'] ?? [];
        for (var swipe in swipes) {
          final speed = swipe['speed_px_per_ms'];
          if (speed != null && speed is num) {
            totalSwipe += speed.toDouble();
            swipeCount++;
          }
        }

        final screenSwipes = session['screens_visited'];
        if (screenSwipes is List) {
          for (var screen in screenSwipes) {
            final nestedSwipes =
                screen['swipe_events'] ?? [];
            for (var swipe in nestedSwipes) {
              final speed = swipe['speed_px_per_ms'];
              if (speed != null && speed is num) {
                totalSwipe += speed.toDouble();
                swipeCount++;
              }
            }
          }
        }
      }

      final baseline = {
        'avg_tap_ms': tapCount > 0 ? totalTap / tapCount : 0,
        'avg_swipe_speed':
        swipeCount > 0 ? totalSwipe / swipeCount : 0,
        'created_at': DateTime.now().toIso8601String(),
        'sessions_used': sessions.length,
        'tap_samples': tapCount,
        'swipe_samples': swipeCount,
      };

      print(" Baseline stats:");
      print(
          "- Avg tap: ${baseline['avg_tap_ms']}ms (from $tapCount samples)");
      print(
          "- Avg swipe: ${baseline['avg_swipe_speed']} (from $swipeCount samples)");
      print(
          "- Created from ${baseline['sessions_used']} sessions");

      return baseline;
    } catch (e) {
      print(" Error building baseline: $e");
      return {};
    }
  }

  Future<void> saveBaseline(Map<String, dynamic> data) async {
    try {
      final dir = Directory(sessionFolder);
      if (!(await dir.exists())) {
        print(" Creating directory $sessionFolder");
        await dir.create(recursive: true);
      }

      final file = File('$sessionFolder/$profileFile');
      final jsonData =
      const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonData);
      print(" Saved user baseline to: ${file.path}");
      print(" File size: ${jsonData.length} bytes");
    } catch (e) {
      print(" Error saving baseline: $e");
      rethrow;
    }
  }
}
