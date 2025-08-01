import 'package:telephony/telephony.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'account_dao.dart';
import 'bank_dao.dart';

class SmsWatcher {
  final Telephony telephony = Telephony.instance;

  Future<void> startWatching() async {
    bool permissionsGranted = await telephony.requestSmsPermissions ?? false;
    if (!permissionsGranted) {
      print('SMS permission denied');
      return;
    }

    // Get account number and bank address from DB
    final accounts = await AccountDao().getAllAccounts();
    if (accounts.isEmpty) {
      print('No accounts found. Skipping SMS watcher.');
      return;
    }

    final account = accounts.first;
    final bank = await BankDao().getAllBanks();
    final bankSms = bank.firstWhere(
      (b) => b.bankId == account.bankId,
      orElse: () => bank.first,
    );

    final userAccountNumber = account.accountNumber;
    final bankAddress = bankSms.smsAddressBox;

    // Pass the accountId as well
    await _fetchBankSms(userAccountNumber, bankAddress, account.accountId);
  }

  Future<void> _fetchBankSms(
    String userAccountNumber, String bankAddress, int? accountId) async {
  final lastRead = await DatabaseHelper.instance.getLastReadTimestamp();
  final sixMonthsAgo = DateTime.now().subtract(Duration(days: 180));
  final cutoff = lastRead != null
      ? DateTime.fromMillisecondsSinceEpoch(lastRead)
      : sixMonthsAgo;

  List<SmsMessage> messages = await telephony.getInboxSms(
    columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
    filter: SmsFilter.where(SmsColumn.ADDRESS).equals(bankAddress),
    sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
  );

  final filtered = messages.where((msg) {
    final msgDate = DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0);
    if (!msgDate.isAfter(cutoff)) return false;

    final accNum = _extractAccountNumber(msg.body);
    return accNum == userAccountNumber;
  }).toList();

  for (var msg in filtered) {
    final transactionData = _parseTransaction(msg.body);
    if (transactionData == null) continue;

    try {
      await DatabaseHelper.instance.insert('transactions', {
        'trans_id': transactionData['trans_id'],
        'description': transactionData['description'],
        'amount': transactionData['amount'],
        'date': transactionData['date'],
        'effect': transactionData['effect'],
        'account': accountId, // now using the passed ID
        'category': null,
      });
      print('Inserted transaction: ${transactionData['trans_id']}');
    } catch (e) {
      print('DB insert failed: $e');
    }
  }

  if (filtered.isNotEmpty) {
    final newestDate = filtered.map((m) => m.date ?? 0).reduce((a, b) => a > b ? a : b);
    await DatabaseHelper.instance.saveLastReadTimestamp(newestDate);
  }
}


  String? _extractAccountNumber(String? smsBody) {
    if (smsBody == null) return null;
    final regExp = RegExp(r'Acc[t]?:\s*(\d{6,12})');
    final match = regExp.firstMatch(smsBody);
    return match?.group(1);
  }

  Map<String, dynamic>? _parseTransaction(String? smsBody) {
    if (smsBody == null) return null;
    try {
      final text = smsBody.replaceAll('\r', '').trim();
      final lines = text.split('\n').map((l) => l.trim()).toList();

      final amtMatch = RegExp(r'MWK\s*([\d,]+(?:\.\d+)?)(CR|DR)', caseSensitive: false)
          .firstMatch(text);
      final amount = amtMatch != null ? double.parse(amtMatch.group(1)!.replaceAll(',', '')) : 0.0;
      final effect = amtMatch != null ? amtMatch.group(2)!.toLowerCase() : 'cr';

      final refLine = lines.firstWhere((l) => l.startsWith('Ref:'), orElse: () => '');
      final transId = refLine.isNotEmpty
          ? refLine.substring(4).split('\\').first.trim()
          : 'TXN-${DateTime.now().millisecondsSinceEpoch}';

      final descLine = lines.firstWhere((l) => l.startsWith('Desc:'), orElse: () => '');
      final description = descLine.isNotEmpty ? descLine.substring(5).trim() : null;

      final dateLine = lines.firstWhere((l) => l.startsWith('Date/Time:'), orElse: () => '');
      DateTime date = DateTime.now();
      if (dateLine.isNotEmpty) {
        final dateStr = dateLine.substring(10).trim();
        final formatter = DateFormat('dd/MM/yy HH:mm');
        date = formatter.parse(dateStr);
      }

      return {
        'trans_id': transId,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'effect': effect,
      };
    } catch (_) {
      return null;
    }
  }
}
