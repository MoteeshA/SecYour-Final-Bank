import 'package:dummy_bank/screens/pay_n_transfer/transactions/demand_draft_page.dart';
import 'package:dummy_bank/screens/pay_n_transfer/transactions/other_bank_transfer_page.dart';
import 'package:dummy_bank/screens/pay_n_transfer/transactions/upi_transfer.dart';
import 'package:flutter/material.dart';
import 'within_bank_transfer_page.dart';
import 'package:phishsafe_sdk/phishsafe_sdk.dart';
import 'package:phishsafe_sdk/route_aware_wrapper.dart';
import 'package:phishsafe_sdk/src/integrations/gesture_wrapper.dart';
import 'package:dummy_bank/observer.dart';
import 'package:easy_localization/easy_localization.dart';

class TransferTypePage extends StatefulWidget {
  @override
  _TransferTypePageState createState() => _TransferTypePageState();
}

class _TransferTypePageState extends State<TransferTypePage> {
  @override
  Widget build(BuildContext context) {
    // ✅ Localized options list
    final List<Map<String, dynamic>> options = [
      {
        'title': 'within_bank_transfer'.tr(),
        'icon': Icons.account_balance,
        'screen': WithinBankTransferPage(),
      },
      {
        'title': 'other_bank_transfer'.tr(),
        'icon': Icons.account_balance_outlined,
        'screen': OtherBankTransferPage(),
      },
      {
        'title': 'demand_draft'.tr(),
        'icon': Icons.insert_drive_file,
        'screen': DemandDraftPage(),
      },
      {
        'title': 'upi_transfer'.tr(),
        'icon': Icons.qr_code_scanner,
        'screen': UpiTransferPage(),
      },
    ];

    return RouteAwareWrapper(
      screenName: 'TransferTypePage',
      observer: routeObserver,
      child: GestureWrapper(
        screenName: 'TransferTypePage',
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'send_money'.tr(), // ✅ localized “Send Money”
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF3B5EDF),
            iconTheme: const IconThemeData(
              color: Colors.white,
            ),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final item = options[index];
              return InkWell(
                onTap: item['screen'] != null
                    ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => item['screen'] as Widget,
                  ),
                )
                    : null,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 3),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFE8ECFB),
                        child: Icon(item['icon'] as IconData,
                            color: const Color(0xFF3B5EDF)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
