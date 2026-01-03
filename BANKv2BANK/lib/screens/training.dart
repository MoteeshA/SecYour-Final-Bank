import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> with TickerProviderStateMixin {
  // Collected samples
  final List<int> _tapDurations = [];
  final List<double> _swipeSpeeds = [];
  final List<int> _typingIntervals = [];

  // For tracking timing
  DateTime? _lastTapTime;
  DateTime? _lastKeyTime;

  // Step tracker
  int _currentStep = 0;

  // Animation controllers
  late AnimationController _tapAnimationController;
  late Animation<double> _tapScaleAnimation;
  late AnimationController _swipeAnimationController;
  late Animation<Offset> _swipeOffsetAnimation;

  // Interaction counters
  int _tapCount = 0;
  int _swipeCount = 0;
  int _typingCount = 0;

  // Text editing controller
  final TextEditingController _textController = TextEditingController();

  // Swipe direction tracking
  String _lastSwipeDirection = "";

  // Typing sentences
  final List<String> _typingSentences = [
    "The quick brown fox jumps over the lazy dog",
    "Flutter is Google's UI toolkit for building beautiful applications",
    "Hello world, this is my behavioral pattern training",
    "Typing rhythm can be a unique identifier for users",
    "Please type this sentence at your natural pace"
  ];
  int _currentSentenceIndex = 0;

  // Swipe direction prompts
  final List<String> _swipeDirections = ["→", "←", "↓", "↑"];
  int _currentSwipeDirectionIndex = 0;
  bool _isCurrentDirectionCompleted = false;

  @override
  void initState() {
    super.initState();

    // Initialize tap animation
    _tapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _tapScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 1),
    ]).animate(_tapAnimationController);

    // Initialize swipe animation
    _swipeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _swipeOffsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_swipeAnimationController);
  }

  @override
  void dispose() {
    _tapAnimationController.dispose();
    _swipeAnimationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _recordTap() {
    final now = DateTime.now();
    if (_lastTapTime != null) {
      _tapDurations.add(now.difference(_lastTapTime!).inMilliseconds);
    }
    _lastTapTime = now;

    setState(() {
      _tapCount++;
    });

    // Trigger tap animation
    _tapAnimationController.forward(from: 0.0);

    // Automatically progress after 8 taps
    if (_tapCount >= 8 && _currentStep == 0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() => _currentStep++);
      });
    }
  }

  void _recordSwipe(DragUpdateDetails details) {
    // Track swipe direction for visual feedback
    if (details.primaryDelta != null) {
      if (details.primaryDelta! > 3) {
        setState(() {
          _lastSwipeDirection = "→";
        });
      } else if (details.primaryDelta! < -3) {
        setState(() {
          _lastSwipeDirection = "←";
        });
      }
    }
  }

  void _completeSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    final isHorizontalSwipe = _currentSwipeDirectionIndex < 2; // First two directions are horizontal

    // Validate swipe direction
    bool isCorrectDirection = false;

    if (isHorizontalSwipe) {
      // For horizontal swipes (→ and ←)
      if (_currentSwipeDirectionIndex == 0 && velocity > 0) {
        // Swipe left to right when prompt is →
        isCorrectDirection = true;
      } else if (_currentSwipeDirectionIndex == 1 && velocity < 0) {
        // Swipe right to left when prompt is ←
        isCorrectDirection = true;
      }
    } else {
      // For vertical swipes (↓ and ↑)
      final verticalVelocity = details.velocity.pixelsPerSecond.dy;

      if (_currentSwipeDirectionIndex == 2 && verticalVelocity > 0) {
        // Swipe bottom to top when prompt is ↓
        isCorrectDirection = true;
      } else if (_currentSwipeDirectionIndex == 3 && verticalVelocity < 0) {
        // Swipe top to bottom when prompt is ↑
        isCorrectDirection = true;
      }
    }

    if (isCorrectDirection) {
      _swipeSpeeds.add(velocity.abs());

      setState(() {
        _swipeCount++;
        _isCurrentDirectionCompleted = true;
      });

      // Move to next direction after a short delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (_currentSwipeDirectionIndex < _swipeDirections.length - 1) {
          setState(() {
            _currentSwipeDirectionIndex++;
            _isCurrentDirectionCompleted = false;
          });
        }
      });
    } else {
      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please swipe ${_swipeDirections[_currentSwipeDirectionIndex]} as indicated"),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1000),
        ),
      );
    }

    // Automatically progress after 5 swipes
    if (_swipeCount >= 5 && _currentStep == 1) {
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() => _currentStep++);
      });
    }
  }

  void _recordTyping(String text) {
    final now = DateTime.now();
    if (_lastKeyTime != null && text.isNotEmpty && text.length > _typingCount) {
      _typingIntervals.add(now.difference(_lastKeyTime!).inMilliseconds);
    }
    _lastKeyTime = now;

    setState(() {
      _typingCount = text.length;
    });
  }

  void _resetTrainingData() {
    setState(() {
      _tapDurations.clear();
      _swipeSpeeds.clear();
      _typingIntervals.clear();
      _tapCount = 0;
      _swipeCount = 0;
      _typingCount = 0;
      _textController.clear();
      _lastTapTime = null;
      _lastKeyTime = null;
      _lastSwipeDirection = "";
      _currentSentenceIndex = 0;
      // Reset new swipe variables
      _currentSwipeDirectionIndex = 0;
      _isCurrentDirectionCompleted = false;
    });
  }

  void _nextSentence() {
    setState(() {
      _currentSentenceIndex = (_currentSentenceIndex + 1) % _typingSentences.length;
      _textController.clear();
      _typingCount = 0;
      _lastKeyTime = null;
    });
  }

  Future<void> _finishTraining() async {
    if (_tapCount < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete at least 8 taps"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_swipeCount < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete at least 5 swipes"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_typingCount < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please type at least 20 characters"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final avgTap = _tapDurations.isEmpty
        ? 0
        : _tapDurations.reduce((a, b) => a + b) ~/ _tapDurations.length;
    final avgSwipe = _swipeSpeeds.isEmpty
        ? 0
        : _swipeSpeeds.reduce((a, b) => a + b) / _swipeSpeeds.length;
    final avgTyping = _typingIntervals.isEmpty
        ? 0
        : _typingIntervals.reduce((a, b) => a + b) ~/ _typingIntervals.length;

    await prefs.setDouble("avgTap", avgTap.toDouble());
    await prefs.setDouble("avgSwipe", avgSwipe.toDouble());
    await prefs.setDouble("avgTyping", avgTyping.toDouble());
    await prefs.setBool("trained", true);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Training Complete - Your behavior pattern has been recorded"),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStepCircle(0, Icons.touch_app, "Tap"),
          _buildStepLine(),
          _buildStepCircle(1, Icons.swipe, "Swipe"),
          _buildStepLine(),
          _buildStepCircle(2, Icons.keyboard, "Type"),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int index, IconData icon, String label) {
    final bool isActive = index == _currentStep;
    final bool isCompleted = index < _currentStep;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.blue.shade700
                : isCompleted
                ? Colors.green
                : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive || isCompleted ? Colors.white : Colors.grey.shade600,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.blue.shade700 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(height: 2, color: Colors.grey.shade300),
    );
  }

  Widget _buildStep() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: SizeTransition(sizeFactor: anim, axis: Axis.vertical, axisAlignment: -1, child: child)),
      child: _getStepContent(),
    );
  }

  Widget _getStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildTapStep();
      case 1:
        return _buildSwipeStep();
      case 2:
        return _buildTypingStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTapStep() {
    return Column(
      key: const ValueKey(0),
      children: [
        const Text("Tap Pattern Training", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.4),
            children: const [
              TextSpan(text: "Tap the blue area repeatedly at your "),
              TextSpan(text: "natural pace", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              TextSpan(text: "\nWe're recording the rhythm between your taps"),
            ],
          ),
        ),
        const SizedBox(height: 30),
        ScaleTransition(
          scale: _tapScaleAnimation,
          child: GestureDetector(
            onTap: _recordTap,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.blue.shade100, Colors.blue.shade300]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade400, width: 2),
                boxShadow: [BoxShadow(color: Colors.blue.shade200, blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.touch_app, size: 40, color: Colors.blue),
                  const SizedBox(height: 10),
                  const Text("TAP HERE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.blue, letterSpacing: 1.2)),
                  const SizedBox(height: 5),
                  Text("$_tapCount taps recorded", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  if (_tapCount < 8)
                    Text("Tap ${8 - _tapCount} more times", style: TextStyle(color: Colors.blue.shade700, fontStyle: FontStyle.italic))
                  else
                    const Text("✓ Tap training complete!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Tip: Tap naturally as you would on your phone normally. Don't rush or slow down intentionally.",
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeStep() {
    return Column(
      key: const ValueKey(1),
      children: [
        const Text("Swipe Pattern Training", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.4),
            children: const [
              TextSpan(text: "Swipe in the "),
              TextSpan(text: "direction indicated", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              TextSpan(text: " across the green area\nWe're measuring your swipe speed and style"),
            ],
          ),
        ),
        const SizedBox(height: 30),
        GestureDetector(
          onHorizontalDragUpdate: _currentSwipeDirectionIndex < 2 ? _recordSwipe : null,
          onHorizontalDragEnd: _currentSwipeDirectionIndex < 2 ? _completeSwipe : null,
          onVerticalDragUpdate: _currentSwipeDirectionIndex >= 2 ? _recordSwipe : null,
          onVerticalDragEnd: _currentSwipeDirectionIndex >= 2 ? _completeSwipe : null,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.green.shade100, Colors.green.shade300]
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade400, width: 2),
              boxShadow: [BoxShadow(color: Colors.green.shade200, blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Swipe ${_swipeDirections[_currentSwipeDirectionIndex]}",
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 10),
                const Text("SWIPE AS INDICATED", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.green, letterSpacing: 1.2)),
                const SizedBox(height: 5),
                Text("$_swipeCount swipes recorded", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                if (_isCurrentDirectionCompleted)
                  const Text("✓ Direction completed!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                if (_swipeCount < 5)
                  Text("${5 - _swipeCount} more swipes needed", style: TextStyle(color: Colors.green.shade700, fontStyle: FontStyle.italic))
                else
                  const Text("✓ Swipe training complete!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.green.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text("Tip: Follow the direction prompt exactly. Swipe with your natural speed and pressure.",
                    style: TextStyle(color: Colors.green.shade700, fontSize: 14)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypingStep() {
    return Column(
      key: const ValueKey(2),
      children: [
        const Text("Typing Pattern Training", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.4),
            children: const [
              TextSpan(text: "Type the sentence below at your natural pace\nWe're recording your "),
              TextSpan(text: "typing rhythm and speed", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _typingSentences[_currentSentenceIndex],
                  style: TextStyle(fontSize: 16, color: Colors.purple.shade800, fontStyle: FontStyle.italic),
                ),
              ),
              IconButton(icon: Icon(Icons.refresh, color: Colors.purple.shade700), onPressed: _nextSentence, tooltip: "Next sentence"),
            ],
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _textController,
          onChanged: _recordTyping,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Type the sentence above here...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.purple.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.purple.shade400, width: 2)),
            filled: true,
            fillColor: Colors.purple.shade50,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields, size: 16, color: Colors.purple.shade600),
                const SizedBox(width: 5),
                Text("Characters: $_typingCount/20", style: TextStyle(color: Colors.purple.shade600, fontSize: 14, fontWeight: _typingCount >= 20 ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
            if (_typingCount >= 20)
              const Text("✓ Minimum reached", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.purple.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text("Tip: Type at your normal pace - we're measuring the timing between your keystrokes. Don't correct mistakes, just keep typing.", style: TextStyle(color: Colors.purple.shade700, fontSize: 14)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ important for keyboard safety
      appBar: AppBar(
        title: const Text("Behavioral Pattern Training"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        actions: [
          if (_currentStep > 0)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _resetTrainingData, tooltip: "Reset Training"),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView( // ✅ makes content scrollable
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (_currentStep + 1) / 3,
                backgroundColor: Colors.grey.shade300,
                color: Colors.blue.shade700,
                minHeight: 6,
              ),
              const SizedBox(height: 20),
              _buildStep(), // ✅ removed Expanded
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _currentStep--),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text("Back"),
                    )
                  else
                    const SizedBox(width: 100),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_currentStep < 2) {
                        setState(() => _currentStep++);
                      } else {
                        _finishTraining();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(_currentStep == 2 ? Icons.check_circle : Icons.arrow_forward, size: 18),
                    label: Text(_currentStep == 2 ? "Finish Training" : "Next"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}