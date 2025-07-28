import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:intl/intl.dart'; // Add intl: ^0.18.0 (or latest) to pubspec.yaml
import 'database_helper.dart';

class SmsReaderPage extends StatefulWidget {
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
      // Handle permission denied
    }
  }

  String? extractAccountNumber(String? smsBody) {
    if (smsBody == null) return null;
    final regExp = RegExp(r'Acc:\s*(\d{6,12})');
    final match = regExp.firstMatch(smsBody);
    return match != null ? match.group(1) : null;
  }

  Map<String, dynamic>? parseTransaction(String? smsBody) {
    if (smsBody == null) return null;

    try {
      final lines = smsBody.split('\n').map((line) => line.trim()).toList();

      final refLine = lines.firstWhere((l) => l.startsWith('Ref:'), orElse: () => '');
      final transId = refLine.isNotEmpty ? refLine.substring(4).split('\\').first.trim() : '';

      final descLine = lines.firstWhere((l) => l.startsWith('Desc:'), orElse: () => '');
      final description = descLine.isNotEmpty ? descLine.substring(5).trim() : '';

      final amountLine = lines.firstWhere((l) => l.contains('MWK'), orElse: () => '');
      final amountMatch = RegExp(r'MWK\s*([\d,]+\.?\d*)').firstMatch(amountLine);
      double amount = 0;
      if (amountMatch != null) {
        final rawAmount = amountMatch.group(1)?.replaceAll(',', '') ?? '0';
        amount = double.parse(rawAmount);
      }

      final effect = amountLine.length >= 2
          ? amountLine.substring(amountLine.length - 2).toLowerCase()
          : '';

      final dateLine = lines.firstWhere((l) => l.startsWith('Date/Time:'), orElse: () => '');
      DateTime date = DateTime.now();
      if (dateLine.isNotEmpty) {
        final dateStr = dateLine.substring(10).trim(); // e.g., '28/07/25 12:30'
        final formatter = DateFormat('dd/MM/yy HH:mm');
        date = formatter.parse(dateStr);
      }

      return {
        'trans_id': transId,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'effect': effect == 'dr' ? 'dr' : 'cr',
      };
    } catch (e) {
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

    for (var msg in filtered) {
      final transactionData = parseTransaction(msg.body);
      if (transactionData != null) {
        await DatabaseHelper.instance.insert('transactions', {
          'trans_id': transactionData['trans_id'],
          'description': transactionData['description'],
          'amount': transactionData['amount'],
          'date': transactionData['date'],
          'effect': transactionData['effect'],
          'account': userAccountNumber, 
          'category': null,
        });
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
