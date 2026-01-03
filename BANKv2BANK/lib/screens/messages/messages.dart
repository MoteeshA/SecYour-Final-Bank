import 'dart:io';
import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Set<String> _hiddenMessageIds = {};

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

  /// ===================== SIMPLE LEGIT CHECK =====================
  ///
  /// This is a basic rule-based check:
  /// - If it contains typical bank / OTP / transaction keywords → LEGIT (green)
  /// - If it contains promo / lottery / "click here" style keywords → NOT LEGIT (red)
  /// - Otherwise default → LEGIT (you can change this to false if you want).
  bool _isLegit(SmsMessage msg) {
    final body = (msg.body ?? "").toLowerCase();
    final address = (msg.address ?? "").toLowerCase();

    // You can edit these lists as you like
    const legitKeywords = [
      'otp',
      'one time password',
      'verification code',
      'transaction',
      'txn',
      'debited',
      'credited',
      'rs.',
      'inr',
      'upi',
      'account',
      'acc ',
      'netbanking',
      'login',
      'bank',
      'card payment',
      'atm',
    ];

    const suspiciousKeywords = [
      'win',
      'winner',
      'lottery',
      'jackpot',
      'prize',
      'lucky draw',
      'click here',
      'tap here',
      'http://',
      'https://',
      'bit.ly',
      'tinyurl',
      'offer',
      'limited time',
      'sale',
      'discount',
      'free gift',
      'urgent',
      'call now',
      'instant loan',
      'pre-approved loan',
    ];

    // If clearly looks like bank / OTP / transaction → mark as legit
    if (legitKeywords.any((k) => body.contains(k))) {
      return true;
    }

    // If clearly looks like promo / lottery / suspicious marketing → not legit
    if (suspiciousKeywords.any((k) => body.contains(k))) {
      return false;
    }

    // If from a normal-looking phone number (personal contact),
    // we treat as legit by default.
    final isPhoneLike =
    RegExp(r'^[0-9+()\s-]{6,}$').hasMatch(address.trim());
    if (isPhoneLike) {
      return true;
    }

    // Default behaviour: consider legit
    // (change to 'false' if you want unknown messages to be red).
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Messages",
          style: TextStyle(color: Colors.black),
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
        child: Text(
          "No SMS messages found.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
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

          final bool isLegit = _isLegit(msg);
          final Color statusColor =
          isLegit ? Colors.green.shade50 : Colors.red.shade50;
          final Color indicatorColor =
          isLegit ? Colors.green : Colors.red;
          final String statusText = isLegit ? "Legit" : "Not legit";
          final Color statusBgColor =
          isLegit ? Colors.green.shade100 : Colors.red.shade100;
          final Color statusTextColor =
          isLegit ? Colors.green.shade800 : Colors.red.shade800;

          return Dismissible(
            key: ValueKey(keyString),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              color: statusColor, // 🔴/🟢 background tint
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          horizontal: 8, vertical: 4),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MessageDetailPage(
                        message: msg,
                        primaryBlue: primaryBlue,
                        isLegit: isLegit,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}";
  }
}

/// ===================== DETAIL PAGE =====================

class MessageDetailPage extends StatelessWidget {
  final SmsMessage message;
  final Color primaryBlue;
  final bool isLegit;

  const MessageDetailPage({
    Key? key,
    required this.message,
    required this.primaryBlue,
    required this.isLegit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final address = message.address ?? "Unknown";
    final body = message.body ?? "";
    final date = DateTime.fromMillisecondsSinceEpoch(message.date ?? 0);

    final Color indicatorColor =
    isLegit ? Colors.green : Colors.red;
    final String statusText = isLegit ? "Legit message" : "Not legit message";
    final Color statusBgColor =
    isLegit ? Colors.green.shade100 : Colors.red.shade100;
    final Color statusTextColor =
    isLegit ? Colors.green.shade800 : Colors.red.shade800;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title:
        const Text("Message Details", style: TextStyle(color: Colors.black)),
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
                      backgroundColor: primaryBlue.withOpacity(0.15),
                      child: Text(
                        address[0].toUpperCase(),
                        style: TextStyle(color: primaryBlue),
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
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLegit
                                ? Icons.verified_rounded
                                : Icons.warning_amber_rounded,
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
                    child: Text(
                      body,
                      style: const TextStyle(fontSize: 15, height: 1.5),
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
