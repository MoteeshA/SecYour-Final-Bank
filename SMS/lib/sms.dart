import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

/// ⚠️ REPLACE THIS WITH YOUR OWN KEY LOCALLY.
/// Do NOT commit the real key to Git or share it publicly,
/// and rotate your key on the OpenAI dashboard if it was exposed.
const String openAIApiKey = 'YOUR_OPENAI_API_KEY';

/// Holds AI analysis for a message.
class MessageAnalysis {
  final bool isLegit;
  final String explanationOdia;
  final String explanationEnglish;

  MessageAnalysis({
    required this.isLegit,
    required this.explanationOdia,
    required this.explanationEnglish,
  });
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final Telephony _telephony = Telephony.instance;
  final Color primaryBlue = const Color(0xFF3B5EDF);

  List<SmsMessage> _messages = [];
  bool _loading = false;
  String? _error;

  /// Messages hidden by swipe-to-delete.
  Set<String> _hiddenMessageIds = {};

  /// Cache of AI analysis per message key.
  final Map<String, MessageAnalysis> _analysisCache = {};

  bool _analyzing = false; // for showing a small indicator if needed

  /// If OpenAI is unreachable (no internet / DNS error), stop further calls.
  bool _openAIUnavailable = false;

  @override
  void initState() {
    super.initState();
    _initMessages();
  }

  Future<void> _initMessages() async {
    await _loadHiddenMessages();
    await _loadMessages();
  }

  Future<void> _loadHiddenMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('hidden_message_ids') ?? [];
    _hiddenMessageIds = list.toSet();
  }

  Future<void> _saveHiddenMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('hidden_message_ids', _hiddenMessageIds.toList());
  }

  Future<void> _loadMessages() async {
    if (!Platform.isAndroid) {
      setState(() {
        _error = "SMS inbox is only accessible on Android devices.";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bool? granted = await _telephony.requestPhoneAndSmsPermissions;

      if (granted != true) {
        setState(() {
          _loading = false;
          _error = "SMS permission not granted. Please enable it in settings.";
        });
        return;
      }

      final List<SmsMessage> inboxMessages = await _telephony.getInboxSms(
        columns: [
          SmsColumn.ID,
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
        ],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      final List<SmsMessage> visibleMessages = inboxMessages.where((msg) {
        return !_hiddenMessageIds.contains(_messageKey(msg));
      }).toList();

      setState(() {
        _messages = visibleMessages;
        _loading = false;
      });

      // Reset the "unavailable" flag on refresh.
      _openAIUnavailable = false;

      // 🔍 After loading, analyze ONLY the latest 5 messages with OpenAI
      _analyzeLatestMessagesWithGPT();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Failed to load messages: $e";
      });
    }
  }

  String _messageKey(SmsMessage msg) {
    final id = msg.id?.toString() ?? "no_id";
    final addr = msg.address ?? "no_addr";
    final ts = msg.date?.toString() ?? "no_ts";
    final bodyHash = msg.body?.hashCode.toString() ?? "0";

    return "$id-$addr-$ts-$bodyHash";
  }

  /// ===================== AI ANALYSIS (OpenAI) =====================

  Future<void> _analyzeLatestMessagesWithGPT() async {
    if (_messages.isEmpty || openAIApiKey.startsWith('YOUR_OPENAI_API_KEY')) {
      // No messages or key not configured
      return;
    }

    // If we already found OpenAI unreachable, don't retry.
    if (_openAIUnavailable) return;

    setState(() {
      _analyzing = true;
    });

    // Analyze only the most recent 5 messages to control cost/latency.
    final toAnalyze = _messages.take(5).toList();

    for (final msg in toAnalyze) {
      if (_openAIUnavailable)
        break; // stop loop if network error already detected

      final key = _messageKey(msg);
      if (_analysisCache.containsKey(key)) continue;

      final analysis = await _callOpenAIForMessage(msg);
      if (_openAIUnavailable) break;

      if (analysis != null) {
        if (!mounted) return;
        setState(() {
          _analysisCache[key] = analysis;
        });
      }
    }

    if (!mounted) return;
    setState(() {
      _analyzing = false;
    });
  }

  Future<MessageAnalysis?> _callOpenAIForMessage(SmsMessage msg) async {
    final body = msg.body ?? '';
    if (body.trim().isEmpty) return null;

    final sender = msg.address ?? "Unknown";

    try {
      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'response_format': {'type': 'json_object'},
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a cybersecurity assistant for banking and digital payments. '
                  'Given an SMS text and sender, decide if it is LEGIT (safe/normal message) or FRAUD (phishing/scam). '
                  'VERY IMPORTANT:\n'
                  '- Normal bank OTP messages for login, UPI, or transactions should usually be marked as LEGIT, '
                  '  even though they say "do not share OTP".\n'
                  '- Only mark OTP messages as FRAUD if they clearly try to trick the user, '
                  '  e.g., asking to send the OTP to someone, click a suspicious link, or call an unknown number.\n'
                  '- Promotional offers, lottery, prize, or unknown links should be treated carefully and often as FRAUD.\n'
                  'Reply ONLY as JSON with keys:\n'
                  '  is_legit (boolean),\n'
                  '  explanation_odia (string in Odia language explaining why it is safe or unsafe),\n'
                  '  explanation_english (string in English explaining the reasoning).\n'
                  'Keep explanations short and simple so a normal user in Odisha can understand.',
            },
            {
              'role': 'user',
              'content':
                  'Sender: "$sender"\n'
                  'SMS text: "$body"',
            },
          ],
          'max_tokens': 250,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final decoded = jsonDecode(content);

        return MessageAnalysis(
          isLegit: decoded['is_legit'] == true,
          explanationOdia: (decoded['explanation_odia'] ?? '').toString(),
          explanationEnglish: (decoded['explanation_english'] ?? '').toString(),
        );
      } else {
        debugPrint('OpenAI error: ${response.statusCode} ${response.body}');
      }
    } on SocketException catch (e) {
      // 🔴 THIS is the error you are seeing: no internet / DNS failure.
      debugPrint('OpenAI network error (no internet / DNS issue?): $e');

      if (mounted) {
        setState(() {
          _openAIUnavailable = true;
        });

        // Optional: show only one SnackBar to the user.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "AI analysis is offline. Check your internet connection.",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('OpenAI exception: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text("Messages", style: TextStyle(color: Colors.black)),
            if (_analyzing) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Text("No SMS messages found.", style: TextStyle(fontSize: 16)),
      );
    }

    return Column(
      children: [
        if (_openAIUnavailable)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Material(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "AI analysis is currently offline.\n"
                        "Please check your internet connection and pull to refresh.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadMessages,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final address = msg.address ?? "Unknown";
                final body = msg.body ?? "";
                final date = DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0);
                final keyString = _messageKey(msg);

                final analysis = _analysisCache[keyString];
                final bool? isLegit = analysis?.isLegit;

                // UI when AI analysis is available vs not analyzed.
                Color statusColor;
                Color indicatorColor;
                String statusText;
                Color statusBgColor;
                Color statusTextColor;

                if (analysis == null) {
                  // Not analyzed (older messages beyond top 5)
                  statusColor = Colors.white;
                  indicatorColor = Colors.grey;
                  statusText = "Not analyzed";
                  statusBgColor = Colors.grey.shade200;
                  statusTextColor = Colors.grey.shade800;
                } else {
                  final bool legit = isLegit ?? true;
                  statusColor = legit
                      ? Colors.green.shade50
                      : Colors.red.shade50;
                  indicatorColor = legit ? Colors.green : Colors.red;
                  statusText = legit ? "Real (AI)" : "Fake (AI)";
                  statusBgColor = legit
                      ? Colors.green.shade100
                      : Colors.red.shade100;
                  statusTextColor = legit
                      ? Colors.green.shade800
                      : Colors.red.shade800;
                }

                return Dismissible(
                  key: ValueKey(keyString),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) async {
                    setState(() {
                      _hiddenMessageIds.add(keyString);
                      _messages.removeAt(index);
                    });
                    await _saveHiddenMessages();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Message deleted.")),
                    );
                  },
                  child: Card(
                    color: statusColor,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: indicatorColor.withOpacity(0.6),
                        width: 1.2,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: indicatorColor.withOpacity(0.12),
                        child: Text(
                          address[0].toUpperCase(),
                          style: TextStyle(color: indicatorColor),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              address,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        final analysis = _analysisCache[keyString];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MessageDetailPage(
                              message: msg,
                              primaryBlue: primaryBlue,
                              analysis: analysis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}";
  }
}

/// ===================== DETAIL PAGE WITH TTS =====================

class MessageDetailPage extends StatefulWidget {
  final SmsMessage message;
  final Color primaryBlue;
  final MessageAnalysis? analysis;

  const MessageDetailPage({
    Key? key,
    required this.message,
    required this.primaryBlue,
    required this.analysis,
  }) : super(key: key);

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    // General configuration. Language is set per call.
    await _tts.setPitch(1.0);
    // ⬇️ Slower / more natural speed
    await _tts.setSpeechRate(0.5);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> _speakOdia(String text) async {
    await _tts.stop();
    await _tts.setLanguage("or-IN"); // Odia (India)
    await _tts.speak(text);
  }

  Future<void> _speakEnglish(String text) async {
    await _tts.stop();
    await _tts.setLanguage("en-IN"); // English (India accent)
    await _tts.speak(text);
  }

  Future<void> _speakMessageBody(String text) async {
    // You can choose language based on your preference; here using English (India)
    await _tts.stop();
    await _tts.setLanguage("en-IN");
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final analysis = widget.analysis;

    final address = msg.address ?? "Unknown";
    final body = msg.body ?? "";
    final date = DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0);

    final bool? isLegit = analysis?.isLegit;

    final explanationOdia = analysis?.explanationOdia.isNotEmpty == true
        ? analysis!.explanationOdia
        : "ଏହି ମେସେଜ୍ ପାଇଁ ଏଆଇ ବିଶ୍ଲେଷଣ ଉପଲବ୍ଧ ନାହିଁ।";
    final explanationEnglish = analysis?.explanationEnglish.isNotEmpty == true
        ? analysis!.explanationEnglish
        : "AI explanation is not available for this message.";

    Color indicatorColor;
    String statusText;
    Color statusBgColor;
    Color statusTextColor;

    if (isLegit == null) {
      indicatorColor = Colors.blueGrey;
      statusText = "Not analyzed by AI";
      statusBgColor = Colors.blueGrey.shade100;
      statusTextColor = Colors.blueGrey.shade800;
    } else if (isLegit == true) {
      indicatorColor = Colors.green;
      statusText = "Real / Legit message (AI)";
      statusBgColor = Colors.green.shade100;
      statusTextColor = Colors.green.shade800;
    } else {
      indicatorColor = Colors.red;
      statusText = "Fake / Not legit message (AI)";
      statusBgColor = Colors.red.shade100;
      statusTextColor = Colors.red.shade800;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Message Details",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: indicatorColor.withOpacity(0.6),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: widget.primaryBlue.withOpacity(0.15),
                      child: Text(
                        address[0].toUpperCase(),
                        style: TextStyle(color: widget.primaryBlue),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLegit == null
                                ? Icons.help_outline
                                : (isLegit
                                      ? Icons.verified_rounded
                                      : Icons.warning_amber_rounded),
                            size: 16,
                            color: statusTextColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _formatFullDateTime(date),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const Divider(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Message:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up),
                              tooltip: "Read message (English)",
                              onPressed: () => _speakMessageBody(body),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Text(
                              "Why (Odia):",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up),
                              onPressed: () => _speakOdia(explanationOdia),
                              tooltip: "Speak in Odia",
                            ),
                          ],
                        ),
                        Text(
                          explanationOdia,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text(
                              "Explanation (English):",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up),
                              onPressed: () =>
                                  _speakEnglish(explanationEnglish),
                              tooltip: "Speak in English",
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          explanationEnglish,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatFullDateTime(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }
}
