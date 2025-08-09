import 'package:telephony/telephony.dart';
import 'package:intl/intl.dart';
import '../dao/account_dao.dart';
import '../dao/bank_dao.dart';
import '../dao/transaction_dao.dart';
import '../models/transaction_model.dart';
import 'database_helper.dart';
import 'transactions_notifier.dart'; 

class SmsWatcher {
  final Telephony telephony = Telephony.instance;
  final TransactionDao _txDao = TransactionDao();

  Future<void> startWatching() async {
    bool permissionsGranted = await telephony.requestSmsPermissions ?? false;
    if (!permissionsGranted) {
      print('SMS permission denied');
      return;
    }

    final accounts = await AccountDao().getAllAccounts();
    if (accounts.isEmpty) {
      print('No accounts found. Skipping SMS watcher.');
      return;
    }

    final activeAccount = accounts.firstWhere(
      (acc) => acc.isActive, 
      orElse: () {
        print('Warning: No active account found, using first account');
        return accounts.first;
      }
    );
    
    print('Active account ID: ${activeAccount.accountId}');
    print('Active account number: ${activeAccount.accountNumber}');
    print('Active account bank ID: ${activeAccount.bankId}');
    
    final banks = await BankDao().getAllBanks();
    
    final bankSms = banks.firstWhere(
      (b) => b.bankId == activeAccount.bankId,
      orElse: () {
        print('Error: Bank not found for account ${activeAccount.accountId}');
        print('Available banks: ${banks.map((b) => 'ID: ${b.bankId}').join(', ')}');
        throw Exception('Bank not found for active account');
      },
    );
    
    print('Bank SMS address: ${bankSms.smsAddressBox}');

    await _fetchBankSms(
      activeAccount.accountNumber, 
      bankSms.smsAddressBox, 
      activeAccount.accountId!
    );
  }

  Future<void> _fetchBankSms(
      String userAccountNumber, String bankAddress, int accountId) async {
    
    print("Fetching SMS for account ID: $accountId");
    
    final lastRead = await AccountDao().getLastReadForAccount(accountId);
    print("Last read timestamp: $lastRead");
    
    final sixMonthsAgo = DateTime.now().subtract(Duration(days: 1500)); // Fixed: 6 months = ~180 days
    final cutoff = lastRead != null
        ? DateTime.fromMillisecondsSinceEpoch(lastRead)
        : sixMonthsAgo;
    print("Cutoff date being used: $cutoff");

    List<SmsMessage> messages;
    try {
      messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals(bankAddress),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );
      print("Total messages fetched: ${messages.length}");
    } catch (e) {
      print("Error fetching SMS messages: $e");
      return;
    }

    final filtered = messages.where((msg) {
      final msgDate = DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0);
      final accNum = _extractAccountNumber(msg.body);
      final userAccNum = userAccountNumber.trim(); // ✅ Trim whitespace

      print('Comparing: "$accNum" vs "$userAccNum"');

      if (!msgDate.isAfter(cutoff)) {
        print('Skipping: Message date ($msgDate) <= cutoff ($cutoff)');
        return false;
      }
      if (accNum != userAccNum) { // Now compares trimmed values
        print('Skipping: Account number mismatch');
        return false;
      }
      return true;
    }).toList();

    print("Messages after filtering: ${filtered.length}");

    int successfulInserts = 0;
    for (var msg in filtered) {
      print("Processing message body: ${msg.body}");
      
      final data = _parseTransaction(msg.body, msg.date ?? DateTime.now().millisecondsSinceEpoch); // Pass SMS timestamp
      if (data == null) {
        print('Failed to parse transaction data from message body');
        continue;
      }

      final tx = Transaction(
        transId: data['trans_id'],
        description: data['description'] ?? '',
        amount: data['amount'],
        date: data['date'],
        effect: data['effect'],
        account: accountId,
      );

      try {
        await _txDao.insertTransaction(tx);
        successfulInserts++;
        print('✓ Inserted transaction: ${tx.transId}');
      } catch (e) {
        print('✗ DB insert failed for transaction ${tx.transId}: $e');
      }
    }

    print("Successfully inserted $successfulInserts transactions");

    if (filtered.isNotEmpty) {
      final newestDate =
          filtered.map((m) => m.date ?? 0).reduce((a, b) => a > b ? a : b);
      print('Updating last read timestamp to: $newestDate');

      final accountDao = AccountDao();
      await accountDao.updateLastReadTimestamp(accountId, newestDate);

      TransactionsNotifier.instance.notify();
      print('✓ Updated last read timestamp and notified');
    } else {
      print('No new messages to update last read timestamp.');
    }
    
    if (successfulInserts > 0) {
      TransactionsNotifier.instance.refresh();
    }
  }

  String? _extractAccountNumber(String? smsBody) {
    if (smsBody == null) return null;
  
    final patterns = [
      RegExp(r'Acc[t]?:\s*(\d{6,12})'),
      RegExp(r'Account:\s*(\d{6,12})'),
      RegExp(r'A/C:\s*(\d{6,12})'),
      RegExp(r'Account\s+No:\s*(\d{6,12})'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(smsBody);
      if (match != null) {
        final accNum = match.group(1)?.trim(); // ✅ Trim whitespace
        print('Extracted account number: "$accNum"');
        return accNum;
      }
    }
    print('No account number found in SMS body');
    return null;
  }

  Map<String, dynamic>? _parseTransaction(String? smsBody, int smsReceivedTime) {
    if (smsBody == null) {
      print('SMS body is null');
      return null;
    }
    
    try {
      final text = smsBody.replaceAll('\r', '').trim();
      final lines = text.split('\n').map((l) => l.trim()).toList();

      print('Parsing SMS lines: ${lines.join(' | ')}');

      // Parse amount and effect
      final amtMatch = RegExp(r'MWK\s*([\d,]+(?:\.\d+)?)(CR|DR)', caseSensitive: false).firstMatch(text);
      if (amtMatch == null) {
        print('No amount pattern found in SMS');
        return null;
      }
      
      final amount = double.parse(amtMatch.group(1)!.replaceAll(',', ''));
      final effect = amtMatch.group(2)!.toLowerCase();

      // Parse transaction ID
      final refLine = lines.firstWhere((l) => l.startsWith('Ref:'), orElse: () => '');
      final transId = refLine.isNotEmpty
          ? refLine.substring(4).split('\\').first.trim()
          : 'TXN-${DateTime.now().millisecondsSinceEpoch}';

      // Parse description
      final descLine = lines.firstWhere((l) => l.startsWith('Desc:'), orElse: () => '');
      final description = descLine.isNotEmpty ? descLine.substring(5).trim() : null;

      // Parse date (prioritize SMS body, fall back to received time)
      DateTime date;
      final dateLine = lines.firstWhere((l) => l.startsWith('Date/Time:'), orElse: () => '');
      if (dateLine.isNotEmpty) {
        final dateStr = dateLine.substring(10).trim();
        try {
          date = DateFormat('dd/MM/yy HH:mm').parse(dateStr);
          print('Using parsed SMS body date: $date');
        } catch (e) {
          print('Failed to parse SMS body date, using received time');
          date = DateTime.fromMillisecondsSinceEpoch(smsReceivedTime);
        }
      } else {
        date = DateTime.fromMillisecondsSinceEpoch(smsReceivedTime);
        print('No date in SMS body, using received time: $date');
      }

      print('✓ Parsed transaction - ID: $transId, Amount: $amount, Effect: $effect, Date: $date');

      return {
        'trans_id': transId,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'effect': effect,
      };
    } catch (e) {
      print('Error parsing transaction: $e');
      print('SMS body was: $smsBody');
      return null;
    }
  }
}