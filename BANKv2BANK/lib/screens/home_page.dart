import 'package:flutter/material.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:dummy_bank/screens/deposits/fixed_deposit_page.dart';
import 'package:dummy_bank/screens/deposits/manage_deposits_page.dart';
import 'package:dummy_bank/screens/pay_n_transfer/loan/loan_page.dart';
import 'package:dummy_bank/screens/pay_n_transfer/transactions/transfer_type_page.dart';
import 'package:dummy_bank/screens/pay_n_transfer/transactions/transaction_history_page.dart';
import 'package:dummy_bank/screens/pay_n_transfer/transactions/upi_transfer.dart';
import 'package:dummy_bank/screens/pay_n_transfer/beneficiaries/beneficiaries_page.dart';
import 'package:dummy_bank/screens/accounts_n_services/card_page.dart';
import 'package:dummy_bank/screens/login_page.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:dummy_bank/observer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

// ✅ NEW: Messages screen import
import 'package:dummy_bank/screens/messages/messages.dart';

/// Helper for tap zone
String getTapZone(Offset localPosition, Size widgetSize) {
  final zoneWidth = widgetSize.width / 3;
  final zoneHeight = widgetSize.height / 3;
  int col = (localPosition.dx / zoneWidth).floor().clamp(0, 2);
  int row = (localPosition.dy / zoneHeight).floor().clamp(0, 2);

  const zoneMap = {
    0: {0: 'top_left', 1: 'top_center', 2: 'top_right'},
    1: {0: 'middle_left', 1: 'center', 2: 'middle_right'},
    2: {0: 'bottom_left', 1: 'bottom_center', 2: 'bottom_right'},
  };

  return zoneMap[row]?[col] ?? 'unknown';
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryBlue = const Color(0xFF3B5EDF);
  final Color lightBg = const Color(0xFFF5F7FA);

  String? userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();

    // 🔐 Start / continue session for this HomePage
    PhishSafeSDK.initSession();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      PhishSafeTrackerManager().setContext(context);
      PhishSafeTrackerManager().setLogoutCallback(() {
        // 👇 SDK-forced logout (low trust score etc.)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
        );
      });
    });
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("name") ?? "Customer";
    });
  }

  @override
  void dispose() {
    // ❌ Removed PhishSafeSDK.endSession() here
    // Session end is handled explicitly on logout / SDK callback
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final size = box.size;

        final zone = getTapZone(localPosition, size);
        PhishSafeTrackerManager().recordTapPosition(
          screenName: 'HomePage',
          tapPosition: details.globalPosition,
          tapZone: zone,
        );
      },
      child: RouteAwareWrapper(
        screenName: 'HomePage',
        observer: routeObserver,
        child: GestureWrapper(
          screenName: 'HomePage',
          child: Scaffold(
            backgroundColor: lightBg,
            appBar: _buildAppBar(),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _portfolioCard(),
                  const SizedBox(height: 16),
                  _sectionTitle('quick_actions'.tr()),
                  _iconGrid([
                    {
                      'label': 'send_money'.tr(),
                      'icon': Icons.send,
                      'action': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransferTypePage(),
                          ),
                        );
                      }
                    },
                    {
                      'label': 'account_summary'.tr(),
                      'icon': Icons.account_balance
                    },
                    {
                      'label': 'pay_bills'.tr(),
                      'icon': Icons.receipt,
                    },
                    {
                      'label': 'fixed_deposit'.tr(),
                      'icon': Icons.savings,
                      'action': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FixedDepositPage(),
                          ),
                        );
                      }
                    },
                    {'label': 'rewards'.tr(), 'icon': Icons.card_giftcard},
                    {'label': 'recharge'.tr(), 'icon': Icons.phone_android},
                    {
                      'label': 'statements'.tr(),
                      'icon': Icons.insert_drive_file,
                      'action': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransactionHistoryPage(),
                          ),
                        );
                      }
                    },
                    {'label': 'accounts'.tr(), 'icon': Icons.account_box},
                  ]),
                  const SizedBox(height: 16),
                  _promoBanner(
                    'promo_medical_title'.tr(),
                    'promo_medical_sub'.tr(),
                    Icons.health_and_safety,
                    Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('pay_transfer'.tr()),
                  _iconGrid([
                    {
                      'label': 'send_money'.tr(),
                      'icon': Icons.send,
                      'action': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransferTypePage(),
                          ),
                        );
                      }
                    },
                    {
                      'label': 'direct_pay'.tr(),
                      'icon': Icons.qr_code_scanner,
                      'action': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UpiTransferPage(),
                          ),
                        );
                      }
                    },
                    {'label': 'epassbook'.tr(), 'icon': Icons.book},
                    {
                      'label': 'beneficiaries'.tr(),
                      'icon': Icons.group,
                      'action': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BeneficiariesPage(),
                          ),
                        );
                      }
                    },
                  ]),
                  _iconGrid([
                    {'label': 'cardless'.tr(), 'icon': Icons.credit_card_off},
                    {
                      'label': 'loan'.tr(),
                      'icon': Icons.currency_rupee,
                      'action': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LoanPage(),
                          ),
                        );
                      }
                    },
                    {
                      'label': 'history'.tr(),
                      'icon': Icons.history,
                      'action': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransactionHistoryPage(),
                          ),
                        );
                      }
                    },
                    {'label': 'manage'.tr(), 'icon': Icons.settings},
                  ]),
                  const SizedBox(height: 16),
                  _promoBanner(
                    'promo_upi_title'.tr(),
                    'promo_upi_sub'.tr(),
                    Icons.money,
                    Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('accounts_services'.tr()),
                  _iconGrid([
                    {
                      'label': 'account_summary'.tr(),
                      'icon': Icons.account_balance
                    },
                    {'label': 'passbook'.tr(), 'icon': Icons.menu_book},
                    {
                      'label': 'statements'.tr(),
                      'icon': Icons.description,
                      'action': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransactionHistoryPage(),
                          ),
                        );
                      }
                    },
                    {'label': 'settings'.tr(), 'icon': Icons.settings},
                  ]),
                  _iconGrid([
                    {
                      'label': 'credit_card'.tr(),
                      'icon': Icons.add_card_rounded,
                      'action': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CardsPage(),
                          ),
                        );
                      }
                    },
                    {
                      'label': 'debit_card'.tr(),
                      'icon': Icons.credit_card,
                      'action': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CardsPage(),
                          ),
                        );
                      }
                    },
                    {'label': 'security'.tr(), 'icon': Icons.security},
                    {'label': 'calculator'.tr(), 'icon': Icons.calculate},
                  ]),
                  const SizedBox(height: 16),
                  _sectionTitle('deposits'.tr()),
                  _iconGrid([
                    {'label': 'fd_calculator'.tr(), 'icon': Icons.calculate},
                    {
                      'label': 'deposit_history'.tr(),
                      'icon': Icons.list_alt
                    },
                    {
                      'label': 'manage_deposits'.tr(),
                      'icon': Icons.folder,
                      'action': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManageDepositsPage(),
                          ),
                        );
                      }
                    },
                    {'label': 'certificates'.tr(), 'icon': Icons.verified},
                  ]),
                  const SizedBox(height: 24),
                  _promoBanner(
                    'promo_cc_title'.tr(),
                    'promo_cc_sub'.tr(),
                    Icons.credit_card,
                    primaryBlue,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNav(),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    title: Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: primaryBlue,
          child: Text(
            (userName != null && userName!.isNotEmpty)
                ? userName![0].toUpperCase()
                : 'U',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'home_dear'.tr(
            namedArgs: {'name': userName ?? 'Customer'},
          ),
          style: const TextStyle(color: Colors.black, fontSize: 20),
        ),
      ],
    ),
    actions: [
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.search, color: Colors.black),
      ),
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.notifications_none, color: Colors.black),
      ),
      IconButton(
        onPressed: () {
          // ⚡ Fast logout: navigate immediately, end session in background
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
          PhishSafeSDK.endSession(); // no await → non-blocking
        },
        icon: const Icon(Icons.power_settings_new, color: Colors.black),
        tooltip: 'Logout',
      ),
    ],
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _portfolioCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF3B5EDF), Color(0xFF4C84EF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: Offset(0, 4),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: Text(
                (userName != null && userName!.isNotEmpty)
                    ? userName![0].toUpperCase()
                    : "U",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'ac_masked'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'primary_account'.tr(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildPortfolioItemWithAmount(
              Icons.account_balance_wallet,
              'portfolio_savings'.tr(),
              "₹85,430",
            ),
            _buildPortfolioItemWithAmount(
              Icons.description,
              'portfolio_od_account'.tr(),
              "₹25,000",
            ),
            _buildPortfolioItemWithAmount(
              Icons.archive,
              'portfolio_deposits'.tr(),
              "₹10,000",
            ),
            _buildPortfolioItemWithAmount(
              Icons.account_balance,
              'portfolio_loans'.tr(),
              "₹5,000",
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildPortfolioItemWithAmount(
      IconData icon,
      String label,
      String amount,
      ) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style:
                      const TextStyle(color: Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _promoBanner(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      ) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _iconGrid(List<Map<String, dynamic>> items) => GridView.count(
    crossAxisCount: 4,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: items.map((item) {
      return InkWell(
        onTap: item['action'],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(item['icon'], color: primaryBlue),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                item['label'],
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );

  // ✅ UPDATED BOTTOM NAV WITH LOCALIZED LABELS
  Widget _buildBottomNav() => BottomNavigationBar(
    selectedItemColor: primaryBlue,
    unselectedItemColor: Colors.grey,
    backgroundColor: Colors.white,
    type: BottomNavigationBarType.fixed,
    onTap: (index) {
      switch (index) {
        case 0:
        // All – current HomePage
          break;
        case 1:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CardsPage()),
          );
          break;
        case 2:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionHistoryPage(),
            ),
          );
          break;
        case 3:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MessagesPage(),
            ),
          );
          break;
        case 4:
        // More – future settings/profile
          break;
      }
    },
    items: [
      BottomNavigationBarItem(
        icon: const Icon(Icons.apps),
        label: 'nav_all'.tr(),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.credit_card),
        label: 'nav_cards'.tr(),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.history),
        label: 'nav_transactions'.tr(),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.message),
        label: 'nav_messages'.tr(),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.more_horiz),
        label: 'nav_more'.tr(),
      ),
    ],
  );
}
