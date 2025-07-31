import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class SmsReaderPage extends StatefulWidget {
  const SmsReaderPage({super.key});

  @override
  _SmsReaderPageState createState() => _SmsReaderPageState();
}

class _SmsReaderPageState extends State<SmsReaderPage> {
  final Telephony telephony = Telephony.instance;
  List<SmsMessage> bankMessages = [];

  // Replace with user's actual bank account number
  final String userAccountNumber = '1007135544';

  @override
  void initState() {
    super.initState();
    requestPermissionsAndFetchSms();
  }

  void requestPermissionsAndFetchSms() async {
    bool permissionsGranted = await telephony.requestSmsPermissions ?? false;
    if (permissionsGranted) {
      fetchBankSms();
    } else {
      print('SMS permission denied');
    }
  }

  // ✅ Fix: match both Acc: and Acct:
  String? extractAccountNumber(String? smsBody) {
    if (smsBody == null) return null;
    final regExp = RegExp(r'Acc[t]?:\s*(\d{6,12})');
    final match = regExp.firstMatch(smsBody);
    return match?.group(1);
  }

  Map<String, dynamic>? parseTransaction(String? smsBody) {
    if (smsBody == null) return null;

    try {
      // Normalize text
      final text = smsBody.replaceAll('\r', '').trim();
      final lines = text.split('\n').map((l) => l.trim()).toList();

      // ✅ Account number (Acc or Acct)
      final accMatch = RegExp(r'Acc[t]?:\s*(\d{6,12})').firstMatch(text);
      final accNum = accMatch?.group(1);

      // ✅ Fix: Allow amounts with or without decimals
      final amtMatch = RegExp(r'MWK\s*([\d,]+(?:\.\d+)?)(CR|DR)', caseSensitive: false)
          .firstMatch(text);
      final amount = amtMatch != null ? double.parse(amtMatch.group(1)!.replaceAll(',', '')) : 0.0;
      final effect = amtMatch != null ? amtMatch.group(2)!.toLowerCase() : 'cr';

      // ✅ Transaction ID with fallback
      final refLine = lines.firstWhere((l) => l.startsWith('Ref:'), orElse: () => '');
      final transId = refLine.isNotEmpty
          ? refLine.substring(4).split('\\').first.trim()
          : 'TXN-${DateTime.now().millisecondsSinceEpoch}';

      // ✅ Description nullable
      final descLine = lines.firstWhere((l) => l.startsWith('Desc:'), orElse: () => '');
      final description = descLine.isNotEmpty ? descLine.substring(5).trim() : null;

      // ✅ Date parsing
      final dateLine = lines.firstWhere((l) => l.startsWith('Date/Time:'), orElse: () => '');
      DateTime date = DateTime.now();
      if (dateLine.isNotEmpty) {
        final dateStr = dateLine.substring(10).trim();
        final formatter = DateFormat('dd/MM/yy HH:mm');
        date = formatter.parse(dateStr);
      }

      print('Parsed transaction: ID=$transId, Amount=$amount, Effect=$effect, Desc=$description');

      return {
        'trans_id': transId,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'effect': effect,
        'account_number': accNum,
      };
    } catch (e, st) {
      print('❌ Failed to parse SMS: $smsBody');
      print('Error: $e\n$st');
      return null;
    }
  }

  void fetchBankSms() async {
    final lastRead = await DatabaseHelper.instance.getLastReadTimestamp();
    final sixMonthsAgo = DateTime.now().subtract(Duration(days: 180));
    final cutoff = lastRead != null
        ? DateTime.fromMillisecondsSinceEpoch(lastRead)
        : sixMonthsAgo;

    List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.ADDRESS).equals('626626'),
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    final filtered = messages.where((msg) {
      final msgDate = DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0);
      if (!msgDate.isAfter(cutoff)) return false;

      final accNum = extractAccountNumber(msg.body);
      return accNum == userAccountNumber;
    }).toList();

    print('Found ${filtered.length} bank messages after cutoff $cutoff');

    for (var msg in filtered) {
      final transactionData = parseTransaction(msg.body);
      if (transactionData == null) {
        print('⚠️ Skipped unparsed message: ${msg.body}');
        continue;
      }

      try {
        await DatabaseHelper.instance.insert('transactions', {
          'trans_id': transactionData['trans_id'],
          'description': transactionData['description'],
          'amount': transactionData['amount'],
          'date': transactionData['date'],
          'effect': transactionData['effect'],
          'account': 1, // hardcoded valid account_id
          'category': null,
        });
        print('✅ Inserted transaction: ${transactionData['trans_id']}');
      } catch (e) {
        print('❌ DB insert failed for ${transactionData['trans_id']} | Error: $e');
      }
    }

    if (filtered.isNotEmpty) {
      final newestDate = filtered.map((m) => m.date ?? 0).reduce((a, b) => a > b ? a : b);
      await DatabaseHelper.instance.saveLastReadTimestamp(newestDate);
    }

    setState(() {
      bankMessages = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bank SMS Messages')),
      body: ListView.builder(
        itemCount: bankMessages.length,
        itemBuilder: (_, index) {
          final msg = bankMessages[index];
          return ListTile(
            title: Text(msg.body ?? ''),
            subtitle: Text(
              DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0).toString(),
            ),
          );
        },
      ),
    );
  }
}
